import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:serverpod/serverpod.dart';
import 'package:stockfish_dart/stockfish_dart.dart' show SearchLimits;

import '../chess/chess_engine.dart';
import '../chess/chess_rules.dart';
import '../generated/protocol.dart';
import 'move_classifier.dart';
import 'opening_book.dart';
import 'position_facts.dart';

/// Analyses the moves of one game and records the coach's verdicts.
///
/// Every position is analysed once with two engine lines: as the "before"
/// position of one move it is also the "after" position of the previous
/// one. Recent analyses are cached on the game so the next request does not
/// repeat them.
class GameCoach {
  GameCoach(this.session, this.game) : _cache = _decode(game.analysisCache);

  final Session session;
  final ChessGame game;
  final Map<int, PositionAnalysis> _cache;

  /// Faster limits for filling in older games in bulk.
  static const backfillLimits = SearchLimits(
    depth: 14,
    moveTime: Duration(milliseconds: 250),
  );

  /// The analysis of the position before move [ply] of [moves].
  Future<PositionAnalysis> analysisAt(
    List<String> moves,
    int ply, {
    SearchLimits limits = ChessEngine.coachLimits,
  }) async {
    final cached = _cache[ply];
    if (cached != null) return cached;
    final analysis = await ChessEngine.instance.analyse(
      moves.take(ply).toList(),
      startFen: game.startFen,
      multiPv: 2,
      limits: limits,
    );
    return _cache[ply] = analysis;
  }

  /// The cache to store on the game, keeping positions near [currentPly].
  String encodeCache(int currentPly) => jsonEncode({
    for (final e in _cache.entries)
      if (e.key >= currentPly - 2 && e.key <= currentPly)
        '${e.key}': e.value.toJson(),
  });

  /// Analyses, classifies and stores the move at [ply] of [replay].
  Future<MoveAnalysis> record(
    ReplayedGame replay,
    int ply, {
    required bool byPlayer,
    SearchLimits limits = ChessEngine.coachLimits,
  }) async {
    final moves = replay.uciMoves;
    final before = replay.positionAt(ply);
    final move = Move.parse(moves[ply])!;
    final after = before.play(move);
    final pre = await analysisAt(moves, ply, limits: limits);
    final post = after.isGameOver
        ? const PositionAnalysis([])
        : await analysisAt(moves, ply + 1, limits: limits);

    final whiteMoved = before.turn == Side.white;
    double winOf(EngineLine? line) => line == null
        ? 50
        : moverChance(
            whiteWinChance(cp: line.cp, mate: line.mate),
            whiteMoved: whiteMoved,
          );

    final best = pre.best;
    final bestWin = best == null ? 50.0 : winOf(best);
    final double playedWin = after.isCheckmate
        ? 100
        : after.isGameOver
        ? 50
        : winOf(post.best);
    final isBest = best != null && best.move == moves[ply];
    // The engine's own line is the more reliable score for its top move.
    final classifiedWin = isBest ? max(bestWin, playedWin) : playedWin;

    var sacrifice = false;
    final reply = post.best;
    if (reply != null) {
      final balanceBefore = materialBalance(before, before.turn);
      final balanceAfter = materialBalance(
        playLine(after, reply.pv, count: 2),
        before.turn,
      );
      sacrifice = balanceAfter <= balanceBefore - 2;
    }

    final previous = ply == 0
        ? null
        : await MoveAnalysis.db.findFirstRow(
            session,
            where: (t) =>
                t.gameId.equals(game.id!) &
                t.ply.equals(ply - 1) &
                t.retracted.equals(false),
          );

    final legalCount = before.legalMoves.values.fold(
      0,
      (sum, s) => sum + s.size,
    );
    final classification = classifyMove(
      MoveFacts(
        bestWin: bestWin,
        playedWin: classifiedWin,
        isBest: isBest,
        secondBestWin: pre.lines.length > 1 ? winOf(pre.lines[1]) : null,
        sacrifice: sacrifice,
        book:
            game.startFen == null &&
            ply < 24 &&
            OpeningBook.instance.contains(after),
        opponentJustErred:
            previous != null &&
            (previous.classification == MoveClass.mistake ||
                previous.classification == MoveClass.blunder),
        legalMoves: legalCount,
      ),
    );

    final analysis = MoveAnalysis(
      gameId: game.id!,
      userId: game.userId,
      ply: ply,
      uci: moves[ply],
      san: replay.sanMoves[ply],
      byPlayer: byPlayer,
      classification: classification,
      winBefore: bestWin,
      winAfter: classifiedWin,
      accuracy: moveAccuracy(bestWin - classifiedWin),
      evalCp: after.isGameOver ? (after.isCheckmate ? null : 0) : reply?.cp,
      evalMate: after.isCheckmate ? 0 : (after.isGameOver ? null : reply?.mate),
      bestUci: best?.move,
      bestSan: best == null
          ? null
          : uciLineToSan(before, [best.move]).firstOrNull,
      bestLine: best == null ? [] : uciLineToSan(before, best.pv.take(8)),
      replyLine: reply == null ? [] : uciLineToSan(after, reply.pv.take(8)),
      replyUci: reply?.pv.firstOrNull,
      fenBefore: before.fen,
    );
    return MoveAnalysis.db.insertRow(session, analysis);
  }

  /// Analyses every move of [replay] that has no verdict yet, e.g. the
  /// prefilled moves of an opening game or games from before the coach.
  Future<List<MoveAnalysis>> backfill(ReplayedGame replay) async {
    final existing = await MoveAnalysis.db.find(
      session,
      where: (t) => t.gameId.equals(game.id!) & t.retracted.equals(false),
      orderBy: (t) => t.ply,
    );
    final byPly = {for (final a in existing) a.ply: a};
    final playerSide = game.playerColor == PlayerColor.white
        ? Side.white
        : Side.black;
    for (var ply = 0; ply < replay.uciMoves.length; ply++) {
      final current = byPly[ply];
      if (current != null && current.uci == replay.uciMoves[ply]) continue;
      if (current != null) {
        await MoveAnalysis.db.deleteRow(session, current);
      }
      byPly[ply] = await record(
        replay,
        ply,
        byPlayer: replay.positionAt(ply).turn == playerSide,
        limits: backfillLimits,
      );
    }
    return [
      for (var ply = 0; ply < replay.uciMoves.length; ply++) byPly[ply]!,
    ];
  }

  static Map<int, PositionAnalysis> _decode(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          int.parse(e.key): PositionAnalysis.fromJson(
            (e.value as Map).cast<String, dynamic>(),
          ),
      };
    } catch (_) {
      return {};
    }
  }
}
