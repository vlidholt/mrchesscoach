import 'dart:math';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:synchronized/synchronized.dart';

import '../coach/content/catalog.dart';
import '../coach/content/content_types.dart';
import '../coach/game_coach.dart';
import '../coach/move_classifier.dart';
import '../coach/stats_service.dart';
import '../generated/protocol.dart';
import 'chess_engine.dart';
import 'chess_rules.dart';
import 'levels.dart';

/// Plays chess against the computer. Every game belongs to the signed-in
/// user, and the server is the authority on the rules.
///
/// With the coach on, every move gets a verdict, and after a mistake the
/// game pauses until the player retries or plays on.
class GameEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Serializes changes to the same game, e.g. a double-tapped move.
  static final _gameLocks = <int, Lock>{};

  static final _random = Random();

  /// The difficulty levels, weakest first.
  Future<List<ChessLevel>> levels(Session session) async => chessLevels;

  /// Starts a new game. If [color] is null the side is picked at random.
  ///
  /// Any unfinished game is marked as abandoned. When the player is Black,
  /// the computer has already made its first move in the returned game.
  Future<ChessGame> startGame(
    Session session,
    int level,
    PlayerColor? color,
    bool coachEnabled,
  ) async {
    if (level < 0 || level >= levelSpecs.length) {
      throw ChessGameException(message: 'Unknown level: $level');
    }
    return createGame(
      session,
      level: level,
      color:
          color ??
          PlayerColor.values[_random.nextInt(PlayerColor.values.length)],
      coachEnabled: coachEnabled,
    );
  }

  /// The user's unfinished game, if any.
  Future<ChessGame?> activeGame(Session session) async {
    final userId = session.authenticated!.authUserId;
    final game = await ChessGame.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.status.equals(GameStatus.active),
      orderBy: (t) => t.updatedAt.desc(),
    );
    return game == null ? null : present(game);
  }

  /// The user's finished games, most recent first.
  Future<List<ChessGame>> finishedGames(Session session) {
    final userId = session.authenticated!.authUserId;
    return ChessGame.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.status.notInSet({GameStatus.active, GameStatus.abandoned}),
      orderBy: (t) => t.updatedAt.desc(),
      limit: 30,
    );
  }

  /// One of the user's games.
  Future<ChessGame> getGame(Session session, int gameId) async =>
      present(await load(session, gameId));

  /// Plays the player's [uci] move. With the coach on and a mistake played,
  /// the game pauses (`awaitingDecision`); otherwise the computer replies.
  Future<ChessGame> move(Session session, int gameId, String uci) =>
      locked(gameId, () async {
        final game = await load(session, gameId);
        if (game.awaitingDecision) {
          throw ChessGameException(
            message: 'Retry your move or play on first.',
          );
        }
        final replay = _activeOnPlayersTurn(game);
        final coach = GameCoach(session, game);
        final ply = replay.uciMoves.length;
        await coach.analysisAt(replay.uciMoves, ply);
        replay.play(uci);
        final feedback = await coach.record(replay, ply, byPlayer: true);
        var updated = _snapshot(game, replay);
        if (game.coachEnabled &&
            replay.outcome == null &&
            pausingClasses.contains(feedback.classification)) {
          updated = updated.copyWith(
            awaitingDecision: true,
            evalCp: feedback.evalCp,
            evalMate: feedback.evalMate,
            analysisCache: coach.encodeCache(ply + 1),
          );
          final saved = await _save(session, updated);
          return saved.copyWith(lastFeedback: feedback);
        }
        return _finishTurn(session, coach, updated, replay, feedback);
      });

  /// Takes back the move the coach paused on, so the player can try again.
  Future<ChessGame> retry(Session session, int gameId) =>
      locked(gameId, () async {
        final game = await load(session, gameId);
        if (!game.awaitingDecision) {
          throw ChessGameException(message: 'There is nothing to retry.');
        }
        final moves = [...game.moves]..removeLast();
        final retracted = await MoveAnalysis.db.findFirstRow(
          session,
          where: (t) =>
              t.gameId.equals(gameId) &
              t.ply.equals(moves.length) &
              t.retracted.equals(false),
        );
        if (retracted != null) {
          await MoveAnalysis.db.updateRow(
            session,
            retracted.copyWith(retracted: true),
          );
        }
        final coach = GameCoach(session, game);
        final pre = await coach.analysisAt(moves, moves.length);
        final replay = ReplayedGame.fromMoves(moves, startFen: game.startFen);
        return _save(
          session,
          _snapshot(game, replay).copyWith(
            awaitingDecision: false,
            retries: game.retries + 1,
            evalCp: pre.best?.cp,
            evalMate: pre.best?.mate,
            analysisCache: coach.encodeCache(moves.length),
          ),
        );
      });

  /// Keeps the move the coach paused on and lets the computer reply.
  Future<ChessGame> playOn(Session session, int gameId) =>
      locked(gameId, () async {
        final game = await load(session, gameId);
        if (!game.awaitingDecision) {
          throw ChessGameException(message: 'The game is not paused.');
        }
        final replay = ReplayedGame.fromMoves(
          game.moves,
          startFen: game.startFen,
        );
        return _finishTurn(
          session,
          GameCoach(session, game),
          game.copyWith(awaitingDecision: false),
          replay,
          null,
        );
      });

  /// Takes back the player's last move (and the computer's reply to it).
  ///
  /// Also reopens a game that ended on the board, but not a resigned one.
  Future<ChessGame> undo(Session session, int gameId) =>
      locked(gameId, () async {
        final game = await load(session, gameId);
        if (game.status == GameStatus.abandoned ||
            game.endReason == GameEndReason.resignation) {
          throw ChessGameException(message: 'This game can no longer change.');
        }
        final playerSide = _side(game.playerColor);
        final start = positionFromFen(game.startFen).turn;
        final moves = [...game.moves];
        Side moverOf(int ply) => ply.isEven ? start : start.opposite;
        // Drop moves until it is the player's turn again, after removing at
        // least one of the player's own moves.
        var removedOwnMove = false;
        while (moves.isNotEmpty) {
          final moverIsPlayer = moverOf(moves.length - 1) == playerSide;
          moves.removeLast();
          if (moverIsPlayer) {
            removedOwnMove = true;
            break;
          }
        }
        if (!removedOwnMove) {
          throw ChessGameException(message: 'There is no move to take back.');
        }
        await MoveAnalysis.db.deleteWhere(
          session,
          where: (t) =>
              t.gameId.equals(gameId) &
              (t.ply >= moves.length) &
              t.retracted.equals(false),
        );
        final coach = GameCoach(session, game);
        final pre = await coach.analysisAt(moves, moves.length);
        final replay = ReplayedGame.fromMoves(moves, startFen: game.startFen);
        return _save(
          session,
          _snapshot(game, replay).copyWith(
            status: GameStatus.active,
            endReason: null,
            awaitingDecision: false,
            takebacks: game.takebacks + 1,
            evalCp: pre.best?.cp,
            evalMate: pre.best?.mate,
            analysisCache: coach.encodeCache(moves.length),
          ),
        );
      });

  /// Resigns the game.
  Future<ChessGame> resign(Session session, int gameId) =>
      locked(gameId, () async {
        final game = await load(session, gameId);
        if (game.status != GameStatus.active) {
          throw ChessGameException(message: 'The game is already over.');
        }
        final saved = await _save(
          session,
          game.copyWith(
            status: GameStatus.computerWon,
            endReason: GameEndReason.resignation,
            awaitingDecision: false,
          ),
        );
        await StatsService.touch(session, game.userId!);
        return saved;
      });

  // ---------------------------------------------------------------------------
  // Shared with the other endpoints

  /// Creates a game for the signed-in user, abandoning any unfinished one.
  /// [moves] are played from [startFen] before the game starts. If it is
  /// the computer's turn, it moves before the game is returned.
  static Future<ChessGame> createGame(
    Session session, {
    required int level,
    required PlayerColor color,
    bool coachEnabled = true,
    String? startFen,
    List<String> moves = const [],
    String? lessonId,
  }) async {
    final userId = session.authenticated!.authUserId;
    final unfinished = await ChessGame.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.status.equals(GameStatus.active),
    );
    if (unfinished.isNotEmpty) {
      await ChessGame.db.update(session, [
        for (final g in unfinished)
          g.copyWith(
            status: GameStatus.abandoned,
            endReason: GameEndReason.abandoned,
            awaitingDecision: false,
            updatedAt: DateTime.now(),
          ),
      ]);
    }

    final replay = ReplayedGame.fromMoves(moves, startFen: startFen);
    var game = await ChessGame.db.insertRow(
      session,
      _snapshot(
        ChessGame(
          userId: userId,
          level: level,
          playerColor: color,
          moves: [],
          sanMoves: [],
          fen: replay.position.fen,
          status: GameStatus.active,
          coachEnabled: coachEnabled,
          startFen: startFen,
          lessonId: lessonId,
        ),
        replay,
      ),
    );
    final coach = GameCoach(session, game);
    if (replay.turn != _side(color)) {
      return _finishTurn(session, coach, game, replay, null);
    }
    final pre = await coach.analysisAt(replay.uciMoves, replay.uciMoves.length);
    game = await _save(
      session,
      game.copyWith(
        evalCp: pre.best?.cp,
        evalMate: pre.best?.mate,
        analysisCache: coach.encodeCache(replay.uciMoves.length),
      ),
    );
    await StatsService.touch(session, userId);
    return game;
  }

  /// Serializes work on one game.
  static Future<T> locked<T>(int gameId, Future<T> Function() action) =>
      _gameLocks.putIfAbsent(gameId, Lock.new).synchronized(action);

  /// Loads one of the signed-in user's games.
  static Future<ChessGame> load(Session session, int gameId) async {
    final game = await ChessGame.db.findById(session, gameId);
    if (game == null || game.userId != session.authenticated!.authUserId) {
      throw ChessGameException(message: 'Game not found.');
    }
    return game;
  }

  /// Adds the player's legal moves when it is their turn.
  static ChessGame present(ChessGame game) {
    if (game.status != GameStatus.active || game.awaitingDecision) return game;
    final replay = ReplayedGame.fromMoves(game.moves, startFen: game.startFen);
    if (replay.turn != _side(game.playerColor)) return game;
    return game.copyWith(legalMoves: replay.legalMoves);
  }

  // ---------------------------------------------------------------------------

  /// Lets the computer reply (unless the game is over), evaluates the new
  /// position, checks a lesson goal and saves.
  static Future<ChessGame> _finishTurn(
    Session session,
    GameCoach coach,
    ChessGame game,
    ReplayedGame replay,
    MoveAnalysis? playerFeedback,
  ) async {
    MoveAnalysis? opponentFeedback;
    if (replay.outcome == null) {
      final ply = replay.uciMoves.length;
      final uci = await ChessEngine.instance.bestMove(
        replay.uciMoves,
        levelSpecs[game.level],
        startFen: game.startFen,
      );
      replay.play(uci);
      opponentFeedback = await coach.record(replay, ply, byPlayer: false);
    }
    var updated = _snapshot(game, replay).copyWith(awaitingDecision: false);
    final plies = replay.uciMoves.length;
    if (updated.status == GameStatus.active) {
      final pre = await coach.analysisAt(replay.uciMoves, plies);
      updated = updated.copyWith(
        evalCp: pre.best?.cp,
        evalMate: pre.best?.mate,
      );
      updated = _checkLessonGoal(updated, replay);
    } else {
      updated = updated.copyWith(
        evalCp: updated.status == GameStatus.draw ? 0 : null,
        evalMate: null,
      );
    }
    final saved = await _save(
      session,
      updated.copyWith(analysisCache: coach.encodeCache(plies)),
    );
    if (saved.status != GameStatus.active) {
      await _recordFinish(session, saved);
    }
    return saved.copyWith(
      lastFeedback: playerFeedback,
      opponentFeedback: opponentFeedback,
    );
  }

  /// Ends a lesson game once its goal is reached.
  static ChessGame _checkLessonGoal(ChessGame game, ReplayedGame replay) {
    final lesson = lessonById(game.lessonId);
    if (lesson == null || lesson.goal == LessonGoal.win) return game;
    final playerSide = _side(game.playerColor);
    final start = replay.startPosition.turn;
    var playerMoves = 0;
    for (var ply = 0; ply < replay.uciMoves.length; ply++) {
      final mover = ply.isEven ? start : start.opposite;
      if (mover == playerSide) playerMoves++;
    }
    if (playerMoves < lesson.targetMoves) return game;
    final whiteWin = whiteWinChance(cp: game.evalCp, mate: game.evalMate);
    final playerWin = moverChance(
      whiteWin,
      whiteMoved: playerSide == Side.white,
    );
    return switch (lesson.goal) {
      LessonGoal.draw when playerWin >= 30 => game.copyWith(
        status: GameStatus.draw,
        endReason: GameEndReason.goalReached,
      ),
      LessonGoal.keepAdvantage when playerWin >= 56 => game.copyWith(
        status: GameStatus.playerWon,
        endReason: GameEndReason.goalReached,
      ),
      _ => game,
    };
  }

  static Future<void> _recordFinish(Session session, ChessGame game) async {
    await StatsService.touch(session, game.userId!);
    final lessonId = game.lessonId;
    final lesson = lessonById(lessonId);
    if (lessonId == null || lesson == null) return;
    final success =
        game.status == GameStatus.playerWon ||
        (lesson.goal == LessonGoal.draw && game.status == GameStatus.draw);
    if (success) {
      await StatsService.lessonProgress(
        session,
        game.userId!,
        lessonId: lessonId,
        kind: 'lesson',
        completed: true,
      );
    }
  }

  static Future<ChessGame> _save(Session session, ChessGame game) async =>
      present(
        await ChessGame.db.updateRow(
          session,
          game.copyWith(updatedAt: DateTime.now()),
        ),
      );

  ReplayedGame _activeOnPlayersTurn(ChessGame game) {
    if (game.status != GameStatus.active) {
      throw ChessGameException(message: 'The game is already over.');
    }
    final replay = ReplayedGame.fromMoves(game.moves, startFen: game.startFen);
    if (replay.turn != _side(game.playerColor)) {
      throw ChessGameException(message: 'It is not your turn.');
    }
    return replay;
  }

  /// Copies the moves, position and result of [replay] into [game].
  static ChessGame _snapshot(ChessGame game, ReplayedGame replay) {
    final outcome = replay.outcome;
    final playerSide = _side(game.playerColor);
    return game.copyWith(
      moves: [...replay.uciMoves],
      sanMoves: [...replay.sanMoves],
      fen: replay.position.fen,
      status: switch (outcome) {
        null => GameStatus.active,
        (winner: null, reason: _) => GameStatus.draw,
        (:final winner, reason: _) when winner == playerSide =>
          GameStatus.playerWon,
        _ => GameStatus.computerWon,
      },
      endReason: outcome?.reason,
    );
  }

  static Side _side(PlayerColor color) =>
      color == PlayerColor.white ? Side.white : Side.black;
}
