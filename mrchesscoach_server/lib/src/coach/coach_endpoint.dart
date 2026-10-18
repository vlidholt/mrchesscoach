import 'package:dartchess/dartchess.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:synchronized/synchronized.dart';

import '../chess/chess_engine.dart';
import '../chess/chess_rules.dart';
import '../chess/game_endpoint.dart';
import '../chess/levels.dart';
import '../generated/protocol.dart';
import 'coach_writer.dart';
import 'game_coach.dart';
import 'move_classifier.dart';
import 'opening_book.dart';
import 'position_facts.dart';
import 'stats_service.dart';

/// The AI coach: explanations, hints, threats, questions and reviews.
class CoachEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// One explanation at a time per move, so a double request doesn't call
  /// the language model twice.
  static final _explainLocks = <int, Lock>{};

  /// Language model calls per user in the current window.
  static final _usage = <UuidValue, List<DateTime>>{};
  static const _maxCallsPerWindow = 80;
  static const _window = Duration(minutes: 10);

  /// The coach's explanation of the move at [ply] of a game. Cached.
  Future<MoveAnalysis> explainMove(Session session, int gameId, int ply) async {
    final game = await GameEndpoint.load(session, gameId);
    final rows = await MoveAnalysis.db.find(
      session,
      where: (t) => t.gameId.equals(gameId) & t.ply.equals(ply),
      orderBy: (t) => t.id.desc(),
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) {
      throw ChessGameException(message: 'That move has not been analysed.');
    }
    return _explainLocks.putIfAbsent(row.id!, Lock.new).synchronized(() async {
      final current = await MoveAnalysis.db.findById(session, row.id!);
      if (current!.explanation != null) return current;
      final writer = await _writer(session, game: game);
      final explained = await writer.explainMove(current);
      return MoveAnalysis.db.updateRow(session, explained);
    });
  }

  /// The verdicts recorded so far for a game, in move order.
  Future<List<MoveAnalysis>> moveVerdicts(Session session, int gameId) async {
    await GameEndpoint.load(session, gameId);
    return MoveAnalysis.db.find(
      session,
      where: (t) => t.gameId.equals(gameId) & t.retracted.equals(false),
      orderBy: (t) => t.ply,
    );
  }

  /// A hint for the player's move: 1 = the idea, 2 = the piece, 3 = the move.
  Future<CoachHint> hint(Session session, int gameId, int level) async {
    final game = await GameEndpoint.load(session, gameId);
    final replay = _playersTurn(game);
    final coach = GameCoach(session, game);
    final ply = replay.uciMoves.length;
    final pre = await coach.analysisAt(replay.uciMoves, ply);
    final best = pre.best;
    if (best == null) {
      throw ChessGameException(message: 'There is no move to suggest.');
    }
    final writer = await _writer(session, game: game);
    final hint = await writer.hint(
      position: replay.position,
      bestUci: best.move,
      bestLine: uciLineToSan(replay.position, best.pv.take(6)),
      level: level.clamp(1, 3),
    );
    await GameEndpoint.locked(gameId, () async {
      final fresh = await GameEndpoint.load(session, gameId);
      await ChessGame.db.updateRow(
        session,
        fresh.copyWith(
          hintsUsed: fresh.hintsUsed + 1,
          analysisCache: coach.encodeCache(ply),
        ),
      );
    });
    return hint;
  }

  /// What the opponent threatens: their best move if they could move again.
  Future<ThreatInsight> threat(Session session, int gameId) async {
    final game = await GameEndpoint.load(session, gameId);
    final replay = _playersTurn(game);
    final position = replay.position;
    final opponent = position.turn.opposite;
    if (position.isCheck) {
      return ThreatInsight(
        hasThreat: true,
        text:
            'You are in check! Deal with the check first: move the king, '
            'block, or capture the checking piece.',
      );
    }
    final parts = position.fen.split(' ');
    parts[1] = parts[1] == 'w' ? 'b' : 'w';
    parts[3] = '-';
    final nullFen = parts.join(' ');
    final Position nullPosition;
    try {
      nullPosition = positionFromFen(nullFen);
    } catch (_) {
      return ThreatInsight(hasThreat: false, text: _noThreat(opponent));
    }
    final coach = GameCoach(session, game);
    final now = await coach.analysisAt(replay.uciMoves, replay.uciMoves.length);
    final ifTheyMoved = await ChessEngine.instance.analyse(
      [],
      startFen: nullFen,
    );
    final threatLine = ifTheyMoved.best;
    if (threatLine == null || now.best == null) {
      return ThreatInsight(hasThreat: false, text: _noThreat(opponent));
    }
    final whiteOpponent = opponent == Side.white;
    double opponentWin(EngineLine l) => moverChance(
      whiteWinChance(cp: l.cp, mate: l.mate),
      whiteMoved: whiteOpponent,
    );
    final gain = opponentWin(threatLine) - opponentWin(now.best!);
    final threatSanLine = uciLineToSan(nullPosition, threatLine.pv.take(5));
    if (gain < 6 || threatSanLine.isEmpty) {
      return ThreatInsight(hasThreat: false, text: _noThreat(opponent));
    }
    final writer = await _writer(session, game: game);
    final text = await writer.threat(
      position: position,
      nullMovePosition: nullPosition,
      threatSan: threatSanLine.first,
      threatLine: threatSanLine,
      gain: gain,
      defenceSan: uciLineToSan(position, [now.best!.move]).firstOrNull,
    );
    return ThreatInsight(
      hasThreat: true,
      uci: threatLine.move,
      san: threatSanLine.first,
      text: text,
    );
  }

  /// Answers a question about the position [fen].
  Future<String> ask(
    Session session,
    String fen,
    List<String> recentSan,
    String question,
    List<CoachChatTurn> history,
    PlayerColor? studentColor,
  ) async {
    final Position position;
    try {
      position = positionFromFen(fen);
    } catch (_) {
      throw ChessGameException(message: 'That position is not valid.');
    }
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw ChessGameException(message: 'Ask me something about the game!');
    }
    final analysis = position.isGameOver
        ? const PositionAnalysis([])
        : await ChessEngine.instance.analyse([], startFen: fen, multiPv: 3);
    final writer = await _writer(session);
    return writer.answer(
      position: position,
      recentSan: recentSan,
      lines: [
        for (final l in analysis.lines)
          (
            san: uciLineToSan(position, [l.move]).firstOrNull ?? l.move,
            cp: l.cp,
            mate: l.mate,
            line: uciLineToSan(position, l.pv.take(6)),
          ),
      ],
      question: trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed,
      history: history.length > 12
          ? history.sublist(history.length - 12)
          : history,
      studentSide: studentColor == null
          ? null
          : (studentColor == PlayerColor.white ? Side.white : Side.black),
    );
  }

  /// A full review of a game. Missing verdicts are filled in first, so this
  /// can take a few seconds for older games.
  Future<GameReview> review(Session session, int gameId) async {
    final game = await GameEndpoint.load(session, gameId);
    final replay = ReplayedGame.fromMoves(game.moves, startFen: game.startFen);
    final moves = await GameCoach(session, game).backfill(replay);
    final player = moves.where((m) => m.byPlayer).toList();
    final opponent = moves.where((m) => !m.byPlayer).toList();
    final playerAccuracy = gameAccuracy(player.map((m) => m.accuracy));
    final opponentAccuracy = gameAccuracy(opponent.map((m) => m.accuracy));

    final startWhite = replay.startPosition.turn == Side.white;
    double whiteWin(MoveAnalysis m, {required bool after}) {
      final whiteMoved = (m.ply.isEven) == startWhite;
      final v = after ? m.winAfter : m.winBefore;
      return whiteMoved ? v : 100 - v;
    }

    final graph = <double>[
      if (moves.isNotEmpty) whiteWin(moves.first, after: false) else 50,
      for (final m in moves) whiteWin(m, after: true),
    ];

    final swings =
        player.where((m) => keyClasses.contains(m.classification)).toList()
          ..sort(
            (a, b) =>
                (b.winBefore - b.winAfter).compareTo(a.winBefore - a.winAfter),
          );
    final opponentBlunders = opponent.where(
      (m) => m.classification == MoveClass.blunder,
    );
    final keyMoments = {
      ...swings.take(5).map((m) => m.ply),
      ...opponentBlunders.take(2).map((m) => m.ply),
    }.toList()..sort();

    Map<String, int> counts(List<MoveAnalysis> list) => {
      for (final c in MoveClass.values)
        c.name: list.where((m) => m.classification == c).length,
    };

    final positions = [
      for (var i = 1; i <= replay.uciMoves.length && i <= 24; i++)
        replay.positionAt(i),
    ];
    final openingName = game.startFen == null
        ? OpeningBook.instance.nameOf(positions)
        : null;

    String? summary;
    if (game.status != GameStatus.active && moves.isNotEmpty) {
      summary = await _summary(
        session,
        game,
        moves,
        playerAccuracy: playerAccuracy,
        opponentAccuracy: opponentAccuracy,
        openingName: openingName,
      );
    }

    return GameReview(
      gameId: gameId,
      playerAccuracy: playerAccuracy,
      opponentAccuracy: opponentAccuracy,
      moves: moves,
      keyMoments: keyMoments,
      playerCounts: counts(player),
      opponentCounts: counts(opponent),
      winGraph: graph,
      summary: summary,
      openingName: openingName,
    );
  }

  // ---------------------------------------------------------------------------

  Future<String?> _summary(
    Session session,
    ChessGame game,
    List<MoveAnalysis> moves, {
    required double playerAccuracy,
    required double opponentAccuracy,
    String? openingName,
  }) async {
    final cached = await GameSummary.db.findFirstRow(
      session,
      where: (t) => t.gameId.equals(game.id!),
    );
    if (cached != null && cached.plies == moves.length) return cached.summary;
    final writer = await _writer(session, game: game);
    final text = await writer.summarize(
      moves: moves,
      studentSide: game.playerColor == PlayerColor.white
          ? Side.white
          : Side.black,
      result: [
        switch (game.status) {
          GameStatus.playerWon => 'the student won',
          GameStatus.computerWon => 'the computer won',
          GameStatus.draw => 'draw',
          _ => 'unfinished',
        },
        if (game.endReason != null) '(${game.endReason!.name})',
        if (game.retries > 0)
          '; the student retried ${game.retries} move(s) after coach warnings',
        if (game.hintsUsed > 0) '; hints used: ${game.hintsUsed}',
      ].join(' '),
      playerAccuracy: playerAccuracy,
      opponentAccuracy: opponentAccuracy,
      openingName: openingName,
    );
    if (text == null) return null;
    if (cached != null) {
      await GameSummary.db.updateRow(
        session,
        cached.copyWith(summary: text, plies: moves.length),
      );
    } else {
      await GameSummary.db.insertRow(
        session,
        GameSummary(gameId: game.id!, summary: text, plies: moves.length),
      );
    }
    return text;
  }

  ReplayedGame _playersTurn(ChessGame game) {
    if (game.status != GameStatus.active) {
      throw ChessGameException(message: 'The game is already over.');
    }
    final replay = ReplayedGame.fromMoves(game.moves, startFen: game.startFen);
    final playerSide = game.playerColor == PlayerColor.white
        ? Side.white
        : Side.black;
    if (replay.turn != playerSide || game.awaitingDecision) {
      throw ChessGameException(message: 'It is not your turn.');
    }
    return replay;
  }

  /// A writer pitched at the player's strength, or a template-only writer
  /// when the player has used up their language model calls for now.
  static Future<CoachWriter> _writer(Session session, {ChessGame? game}) async {
    final userId = session.authenticated!.authUserId;
    final stats = await StatsService.load(session, userId);
    final attempts = stats.puzzlesSolved + stats.puzzlesFailed;
    final rating = attempts >= 10
        ? stats.puzzleRating
        : (game != null ? levelSpecs[game.level].rating : stats.puzzleRating);
    return CoachWriter(
      session,
      rating: rating.clamp(400, 2600),
      allowModel: _allowCall(userId),
    );
  }

  static bool _allowCall(UuidValue userId) {
    final now = DateTime.now();
    final calls = _usage.putIfAbsent(userId, () => [])
      ..removeWhere((t) => now.difference(t) > _window);
    if (calls.length >= _maxCallsPerWindow) return false;
    calls.add(now);
    return true;
  }

  static String _noThreat(Side opponent) =>
      '${sideName(opponent)} has no direct threat right now. Use the time '
      'to improve your worst piece or create a threat of your own.';
}
