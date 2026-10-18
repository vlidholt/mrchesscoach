import 'package:dartchess/dartchess.dart';

import '../coach/position_facts.dart';
import '../generated/protocol.dart';

/// Parses [fen] into a standard chess position.
Position positionFromFen(String? fen) =>
    fen == null ? Chess.initial : Chess.fromSetup(Setup.parseFen(fen));

/// Converts a line of UCI moves played from [start] to SAN. Stops at the
/// first illegal move.
List<String> uciLineToSan(Position start, Iterable<String> uciLine) {
  final san = <String>[];
  var position = start;
  for (final uci in uciLine) {
    final move = Move.parse(uci);
    if (move == null || !position.isLegal(move)) break;
    final (next, s) = position.makeSan(move);
    san.add(s);
    position = next;
  }
  return san;
}

/// A game replayed from its start position.
class ReplayedGame {
  ReplayedGame._(
    this.startPosition,
    this.position,
    this.uciMoves,
    this.sanMoves,
    this._seen,
  );

  /// Replays [uciMoves] from [startFen], or the initial position.
  ///
  /// Throws [ChessGameException] if a move is malformed or illegal.
  factory ReplayedGame.fromMoves(List<String> uciMoves, {String? startFen}) {
    final start = positionFromFen(startFen);
    final game = ReplayedGame._(start, start, [], [], {});
    game._remember();
    for (final uci in uciMoves) {
      game.play(uci);
    }
    return game;
  }

  final Position startPosition;
  Position position;

  /// The position before the move at [ply] (0-based).
  Position positionAt(int ply) {
    var p = startPosition;
    for (final uci in uciMoves.take(ply)) {
      p = p.play(Move.parse(uci)!);
    }
    return p;
  }

  final List<String> uciMoves;
  final List<String> sanMoves;

  /// How often each position (ignoring the move clocks) has occurred.
  final Map<String, int> _seen;

  Side get turn => position.turn;

  /// Plays [uci] and returns its SAN.
  ///
  /// Throws [ChessGameException] if the move is malformed or illegal.
  String play(String uci) {
    final move = _parse(uci);
    if (move == null || !position.isLegal(move)) {
      throw ChessGameException(message: 'Illegal move: $uci');
    }
    final (next, san) = position.makeSan(move);
    position = next;
    uciMoves.add(move.uci);
    sanMoves.add(san);
    _remember();
    return san;
  }

  /// Returns the SAN of [uci] in the current position, without playing it.
  String sanOf(String uci) {
    final move = _parse(uci);
    if (move == null || !position.isLegal(move)) {
      throw ChessGameException(message: 'Illegal move: $uci');
    }
    return position.makeSan(move).$2;
  }

  /// Every legal move in the current position, UCI to SAN. Castling is
  /// listed as the two-square king move and promotions once per piece.
  Map<String, String> get legalMoves => legalMovesOf(position);

  /// The result if the game is over, or null if it continues.
  ({GameEndReason reason, Side? winner})? get outcome {
    if (position.isCheckmate) {
      return (reason: GameEndReason.checkmate, winner: position.turn.opposite);
    }
    if (position.isStalemate) {
      return (reason: GameEndReason.stalemate, winner: null);
    }
    if (position.isInsufficientMaterial) {
      return (reason: GameEndReason.insufficientMaterial, winner: null);
    }
    if ((_seen[_key] ?? 0) >= 3) {
      return (reason: GameEndReason.threefoldRepetition, winner: null);
    }
    if (position.halfmoves >= 100) {
      return (reason: GameEndReason.fiftyMoveRule, winner: null);
    }
    return null;
  }

  String get _key => position.fen.split(' ').take(4).join(' ');

  void _remember() => _seen[_key] = (_seen[_key] ?? 0) + 1;

  /// Parses UCI notation. King-to-rook castling is turned into the standard
  /// two-square king move, which is what Stockfish expects.
  NormalMove? _parse(String uci) {
    if (!RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(uci)) return null;
    final move = Move.parse(uci);
    if (move is! NormalMove) return null;
    final piece = position.board.pieceAt(move.from);
    final target = position.board.pieceAt(move.to);
    if (piece?.role == Role.king &&
        target?.role == Role.rook &&
        target?.color == piece?.color) {
      final file = move.to.file > move.from.file ? File.g : File.c;
      return NormalMove(
        from: move.from,
        to: Square.fromCoords(file, move.from.rank),
      );
    }
    return move;
  }
}
