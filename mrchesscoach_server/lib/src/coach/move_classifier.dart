import 'dart:math';

import '../generated/protocol.dart';

/// White's winning chances (0–100) for an engine score, using the curve
/// Lichess fitted to real games.
double whiteWinChance({int? cp, int? mate}) {
  if (mate != null) return mate > 0 ? 100 : (mate < 0 ? 0 : 50);
  final c = (cp ?? 0).clamp(-1000, 1000);
  return 50 + 50 * (2 / (1 + exp(-0.00368208 * c)) - 1);
}

/// The mover's winning chances, given White's.
double moverChance(double whiteChance, {required bool whiteMoved}) =>
    whiteMoved ? whiteChance : 100 - whiteChance;

/// Accuracy (0–100) of a move that dropped the mover's winning chances by
/// [drop] points (Lichess' formula).
double moveAccuracy(double drop) =>
    (103.1668 * exp(-0.04354 * max(0, drop)) - 3.1669).clamp(0, 100);

/// The accuracy of a series of moves: the mean, pulled towards the worst
/// moves the way Lichess does (average of arithmetic and harmonic means).
double gameAccuracy(Iterable<double> moveAccuracies) {
  final list = moveAccuracies.toList();
  if (list.isEmpty) return 100;
  final mean = list.reduce((a, b) => a + b) / list.length;
  final harmonic =
      list.length / list.map((a) => 1 / max(a, 1)).reduce((a, b) => a + b);
  return (mean + harmonic) / 2;
}

/// Everything the classifier needs to know about a move.
class MoveFacts {
  const MoveFacts({
    required this.bestWin,
    required this.playedWin,
    required this.isBest,
    this.secondBestWin,
    this.sacrifice = false,
    this.book = false,
    this.opponentJustErred = false,
    this.legalMoves = 20,
  });

  /// The mover's winning chances after the engine's best move.
  final double bestWin;

  /// The mover's winning chances after the move played.
  final double playedWin;

  /// The move played is the engine's first choice.
  final bool isBest;

  /// The mover's winning chances after the engine's second choice.
  final double? secondBestWin;

  /// The move gives up material that is not won back two plies later.
  final bool sacrifice;

  /// The move reaches a position from the opening library.
  final bool book;

  /// The opponent's previous move was a mistake or a blunder.
  final bool opponentJustErred;
  final int legalMoves;

  double get drop => max(0, bestWin - playedWin);
}

/// Classifies a move like chess.com's game review.
MoveClass classifyMove(MoveFacts f) {
  final drop = f.drop;
  if (f.legalMoves <= 1) return MoveClass.best;
  if (f.book && drop < 5) return MoveClass.book;
  if (f.isBest || drop < 1.5) {
    final notYetDecided = f.bestWin < 97;
    if (f.sacrifice && f.playedWin >= 45 && notYetDecided) {
      return MoveClass.brilliant;
    }
    final second = f.secondBestWin;
    if (f.isBest &&
        second != null &&
        f.bestWin - second >= 18 &&
        f.playedWin >= 35 &&
        notYetDecided) {
      return MoveClass.great;
    }
    return f.isBest ? MoveClass.best : MoveClass.excellent;
  }
  if (drop < 2.5) return MoveClass.excellent;
  if (drop < 5) return MoveClass.good;
  if (f.opponentJustErred && drop >= 8 && f.playedWin >= 35) {
    return MoveClass.miss;
  }
  if (drop < 10) return MoveClass.inaccuracy;
  if (drop < 20) return MoveClass.mistake;
  return MoveClass.blunder;
}

/// Classes the coach pauses the game for.
const pausingClasses = {MoveClass.mistake, MoveClass.blunder, MoveClass.miss};

/// Classes that make a move a key moment worth explaining unprompted.
const keyClasses = {
  MoveClass.brilliant,
  MoveClass.great,
  MoveClass.inaccuracy,
  MoveClass.mistake,
  MoveClass.miss,
  MoveClass.blunder,
};

/// Human-friendly name of a class, e.g. "a blunder".
String classPhrase(MoveClass c) => switch (c) {
  MoveClass.brilliant => 'a brilliant move',
  MoveClass.great => 'a great move',
  MoveClass.best => 'the best move',
  MoveClass.excellent => 'an excellent move',
  MoveClass.good => 'a good move',
  MoveClass.book => 'a book move',
  MoveClass.inaccuracy => 'an inaccuracy',
  MoveClass.mistake => 'a mistake',
  MoveClass.miss => 'a missed chance',
  MoveClass.blunder => 'a blunder',
};
