import 'package:dartchess/dartchess.dart';

/// Material values in pawns.
const pieceValues = {
  Role.pawn: 1,
  Role.knight: 3,
  Role.bishop: 3,
  Role.rook: 5,
  Role.queen: 9,
  Role.king: 0,
};

String roleName(Role role) => switch (role) {
  Role.pawn => 'pawn',
  Role.knight => 'knight',
  Role.bishop => 'bishop',
  Role.rook => 'rook',
  Role.queen => 'queen',
  Role.king => 'king',
};

String sideName(Side side) => side == Side.white ? 'White' : 'Black';

/// Material of [side] in pawns.
int material(Position position, Side side) => position.board.pieces
    .where((p) => p.$2.color == side)
    .fold(0, (sum, p) => sum + pieceValues[p.$2.role]!);

/// Material balance from [side]'s point of view.
int materialBalance(Position position, Side side) =>
    material(position, side) - material(position, side.opposite);

/// Plays up to [count] UCI moves of [line] from [start] and returns the
/// position reached (stopping early at an illegal move).
Position playLine(Position start, Iterable<String> line, {int? count}) {
  var position = start;
  for (final uci in count == null ? line : line.take(count)) {
    final move = Move.parse(uci);
    if (move == null || !position.isLegal(move)) break;
    position = position.play(move);
  }
  return position;
}

/// All legal moves of [position], UCI to SAN. Castling is listed as the
/// two-square king move and promotions once per piece.
Map<String, String> legalMovesOf(Position position) {
  final result = <String, String>{};
  for (final MapEntry(key: from, value: dests) in position.legalMoves.entries) {
    final piece = position.board.pieceAt(from)!;
    for (final to in dests.squares) {
      final target = position.board.pieceAt(to);
      final castling = piece.role == Role.king && target?.color == piece.color;
      final dest = castling
          ? Square.fromCoords(to.file > from.file ? File.g : File.c, from.rank)
          : to;
      final promotes =
          piece.role == Role.pawn &&
          (to.rank == Rank.first || to.rank == Rank.eighth);
      for (final promotion
          in promotes
              ? const [Role.queen, Role.rook, Role.bishop, Role.knight]
              : const [null]) {
        final move = NormalMove(from: from, to: dest, promotion: promotion);
        result[move.uci] = position.makeSan(move).$2;
      }
    }
  }
  return result;
}

/// Pieces of [side] that the opponent can win: attacked and undefended, or
/// attacked by a cheaper piece.
List<String> loosePieces(Position position, Side side) {
  final result = <String>[];
  for (final (square, piece) in position.board.pieces) {
    if (piece.color != side || piece.role == Role.king) continue;
    final attackers = position.kingAttackers(square, side.opposite);
    if (attackers.isEmpty) continue;
    final defenders = position.kingAttackers(square, side);
    final cheapest = attackers.squares
        .map((s) => pieceValues[position.board.pieceAt(s)!.role]!)
        .reduce((a, b) => a < b ? a : b);
    final value = pieceValues[piece.role]!;
    if (defenders.isEmpty || (cheapest > 0 && cheapest < value)) {
      result.add('${roleName(piece.role)} on ${square.name}');
    }
  }
  return result;
}

/// The pieces of both sides in a compact, readable list.
String pieceList(Position position) {
  String sideList(Side side) {
    final pieces = position.board.pieces.where((p) => p.$2.color == side);
    final order = [
      Role.king,
      Role.queen,
      Role.rook,
      Role.bishop,
      Role.knight,
      Role.pawn,
    ];
    final parts = <String>[];
    for (final role in order) {
      final squares = [
        for (final (s, p) in pieces)
          if (p.role == role) s.name,
      ]..sort();
      if (squares.isEmpty) continue;
      parts.add(
        role == Role.pawn
            ? 'pawns ${squares.join(' ')}'
            : squares.map((s) => '${role.uppercaseLetter}$s').join(' '),
      );
    }
    return '${sideName(side)}: ${parts.join(', ')}';
  }

  return '${sideList(Side.white)}\n${sideList(Side.black)}';
}

/// Opening, middlegame or endgame, judged by the material left.
String gamePhase(Position position, int ply) {
  final nonPawn = position.board.pieces
      .where((p) => p.$2.role != Role.pawn && p.$2.role != Role.king)
      .fold(0, (sum, p) => sum + pieceValues[p.$2.role]!);
  if (nonPawn <= 26) return 'endgame';
  if (ply < 20) return 'opening';
  return 'middlegame';
}

/// A UCI move as a friendly phrase, e.g. "the knight on f3".
String pieceOn(Position position, String square) {
  final sq = Square.parse(square);
  final piece = sq == null ? null : position.board.pieceAt(sq);
  return piece == null ? square : 'the ${roleName(piece.role)} on $square';
}

/// A SAN line with move numbers, e.g. "12. Nf3 Nc6 13. Bb5".
String numberedLine(Position start, List<String> sanLine) {
  final buffer = StringBuffer();
  var moveNumber = start.fullmoves;
  var white = start.turn == Side.white;
  for (final (i, san) in sanLine.indexed) {
    if (white) {
      buffer.write('$moveNumber. $san ');
    } else {
      buffer.write(i == 0 ? '$moveNumber... $san ' : '$san ');
      moveNumber++;
    }
    white = !white;
  }
  return buffer.toString().trim();
}

/// A short description of what happens to the material along [uciLine]
/// from [start], for [side].
String materialStory(Position start, List<String> uciLine, Side side) {
  final before = materialBalance(start, side);
  final after = materialBalance(playLine(start, uciLine), side);
  final diff = after - before;
  if (diff == 0) return 'Material stays level along this line.';
  final who = diff > 0 ? sideName(side) : sideName(side.opposite);
  return '$who wins about ${diff.abs()} pawn${diff.abs() == 1 ? '' : 's'} '
      'worth of material along this line.';
}
