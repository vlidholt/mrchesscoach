/// A small, display-only chess model.
///
/// The server owns the rules and sends the legal moves, so the app only needs
/// to read FEN, show pieces and apply a move for instant feedback. (The
/// `dartchess` rules package uses 64-bit bitboards and doesn't run on the
/// web.)
library;

enum Side {
  white,
  black;

  Side get opposite => this == white ? black : white;
}

enum Role {
  pawn('p'),
  knight('n'),
  bishop('b'),
  rook('r'),
  queen('q'),
  king('k');

  const Role(this.letter);

  /// Lower-case letter as used in FEN and UCI.
  final String letter;

  static Role? fromLetter(String ch) =>
      Role.values.where((r) => r.letter == ch.toLowerCase()).firstOrNull;
}

class Piece {
  const Piece(this.color, this.role);

  final Side color;
  final Role role;

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.role == role;

  @override
  int get hashCode => Object.hash(color, role);
}

/// A square, 0 = a1 … 63 = h8.
extension type const Square(int index) {
  Square.fromCoords(int file, int rank) : this(rank * 8 + file);

  /// Parses a name like `e4`.
  static Square? parse(String name) {
    if (name.length != 2) return null;
    final file = name.codeUnitAt(0) - 0x61;
    final rank = name.codeUnitAt(1) - 0x31;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return Square.fromCoords(file, rank);
  }

  /// 0 (a-file) to 7 (h-file).
  int get file => index & 7;

  /// 0 (1st rank) to 7 (8th rank).
  int get rank => index >> 3;

  String get fileName => String.fromCharCode(0x61 + file);
  String get rankName => '${rank + 1}';
  String get name => '$fileName$rankName';

  bool get isLight => (file + rank).isOdd;
}

/// A move in UCI terms.
class Move {
  const Move(this.from, this.to, [this.promotion]);

  final Square from;
  final Square to;
  final Role? promotion;

  static Move? parse(String uci) {
    if (uci.length < 4 || uci.length > 5) return null;
    final from = Square.parse(uci.substring(0, 2));
    final to = Square.parse(uci.substring(2, 4));
    if (from == null || to == null) return null;
    final promotion = uci.length == 5 ? Role.fromLetter(uci[4]) : null;
    return Move(from, to, promotion);
  }

  String get uci => '${from.name}${to.name}${promotion?.letter ?? ''}';
}

/// Pieces on the board plus the side to move.
class BoardState {
  BoardState._(this.pieces, this.turn);

  /// Reads the piece placement and side to move from [fen].
  factory BoardState.fromFen(String fen) {
    final parts = fen.split(' ');
    final pieces = <Square, Piece>{};
    var rank = 7;
    var file = 0;
    for (final ch in parts.first.split('')) {
      if (ch == '/') {
        rank--;
        file = 0;
      } else if (int.tryParse(ch) case final empty?) {
        file += empty;
      } else {
        final role = Role.fromLetter(ch);
        if (role != null) {
          final color = ch == ch.toUpperCase() ? Side.white : Side.black;
          pieces[Square.fromCoords(file, rank)] = Piece(color, role);
        }
        file++;
      }
    }
    final turn = parts.length > 1 && parts[1] == 'b' ? Side.black : Side.white;
    return BoardState._(Map.unmodifiable(pieces), turn);
  }

  static final initial = BoardState.fromFen(
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w',
  );

  final Map<Square, Piece> pieces;
  final Side turn;

  Piece? pieceAt(Square square) => pieces[square];

  Square? kingOf(Side side) => pieces.entries
      .where((e) => e.value == Piece(side, Role.king))
      .map((e) => e.key)
      .firstOrNull;

  /// The board after [move], which is assumed to be legal. Handles castling,
  /// en passant and promotion.
  BoardState play(Move move) {
    final next = Map.of(pieces);
    final piece = next.remove(move.from);
    if (piece == null) return this;
    // En passant: a pawn moving diagonally onto an empty square.
    if (piece.role == Role.pawn &&
        move.from.file != move.to.file &&
        !next.containsKey(move.to)) {
      next.remove(Square.fromCoords(move.to.file, move.from.rank));
    }
    // Castling: the king moves two files and the rook jumps over it.
    if (piece.role == Role.king && (move.to.file - move.from.file).abs() == 2) {
      final kingside = move.to.file > move.from.file;
      final rookFrom = Square.fromCoords(kingside ? 7 : 0, move.from.rank);
      final rookTo = Square.fromCoords(kingside ? 5 : 3, move.from.rank);
      final rook = next.remove(rookFrom);
      if (rook != null) next[rookTo] = rook;
    }
    next[move.to] = move.promotion == null
        ? piece
        : Piece(piece.color, move.promotion!);
    return BoardState._(Map.unmodifiable(next), turn.opposite);
  }

  /// The piece placement as a string, for change detection.
  String get placementKey => [
    for (var i = 0; i < 64; i++)
      switch (pieces[Square(i)]) {
        null => '.',
        final p =>
          p.color == Side.white ? p.role.letter.toUpperCase() : p.role.letter,
      },
  ].join();
}
