import 'dart:io';
import 'dart:math';

/// A puzzle from the Lichess puzzle database (CC0).
class Puzzle {
  const Puzzle({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.themes,
    required this.openingTags,
  });

  final String id;

  /// The position before the opponent's setup move.
  final String fen;

  /// The setup move followed by the solution, alternating with the
  /// opponent's replies (UCI).
  final List<String> moves;
  final int rating;
  final List<String> themes;
  final List<String> openingTags;

  /// The moves the solver has to find.
  int get solverMoves => moves.length ~/ 2;
}

/// A named set of puzzles shown in the trainer.
class PuzzleSet {
  const PuzzleSet(this.key, this.name, this.description, this.category);

  /// A Lichess theme, or `opening:<Family>` for an opening's traps, or
  /// `mixed` for rated puzzles of every theme.
  final String key;
  final String name;
  final String description;

  /// `tactics`, `mates`, `endgames` or `openings`.
  final String category;
}

const puzzleSetCatalog = [
  PuzzleSet(
    'mixed',
    'Rated puzzles',
    'A mix of everything, matched to your rating.',
    'tactics',
  ),
  PuzzleSet('fork', 'Forks', 'One piece attacks two at once.', 'tactics'),
  PuzzleSet(
    'pin',
    'Pins',
    'A piece cannot move without exposing something more valuable.',
    'tactics',
  ),
  PuzzleSet(
    'skewer',
    'Skewers',
    'Attack a valuable piece and win what stands behind it.',
    'tactics',
  ),
  PuzzleSet(
    'discoveredAttack',
    'Discovered attacks',
    'Move one piece to unleash another.',
    'tactics',
  ),
  PuzzleSet(
    'doubleCheck',
    'Double check',
    'Two pieces give check at once. Only the king can move.',
    'tactics',
  ),
  PuzzleSet(
    'hangingPiece',
    'Loose pieces',
    'Spot and win undefended material.',
    'tactics',
  ),
  PuzzleSet(
    'trappedPiece',
    'Trapped pieces',
    'Corner a piece that has nowhere to go.',
    'tactics',
  ),
  PuzzleSet(
    'deflection',
    'Deflection',
    'Lure a defender away from its duty.',
    'tactics',
  ),
  PuzzleSet(
    'attraction',
    'Attraction',
    'Drag a piece onto a fatal square.',
    'tactics',
  ),
  PuzzleSet(
    'capturingDefender',
    'Remove the defender',
    'Capture the piece that holds everything together.',
    'tactics',
  ),
  PuzzleSet(
    'sacrifice',
    'Sacrifices',
    'Give material to get something bigger.',
    'tactics',
  ),
  PuzzleSet(
    'xRayAttack',
    'X-ray attacks',
    'Attack through an enemy piece.',
    'tactics',
  ),
  PuzzleSet(
    'intermezzo',
    'In-between moves',
    'Insert a stronger move before the expected one.',
    'tactics',
  ),
  PuzzleSet(
    'clearance',
    'Clearance',
    'Clear a square or line for another piece.',
    'tactics',
  ),
  PuzzleSet(
    'interference',
    'Interference',
    'Block the line between two enemy pieces.',
    'tactics',
  ),
  PuzzleSet(
    'quietMove',
    'Quiet moves',
    'The strongest move is not a check or capture.',
    'tactics',
  ),
  PuzzleSet(
    'defensiveMove',
    'Defence',
    'Find the only move that holds.',
    'tactics',
  ),
  PuzzleSet(
    'kingsideAttack',
    'Kingside attacks',
    'Break open the castled king.',
    'tactics',
  ),
  PuzzleSet(
    'exposedKing',
    'Exposed king',
    'Punish a king without shelter.',
    'tactics',
  ),
  PuzzleSet(
    'advancedPawn',
    'Advanced pawns',
    'A pawn close to promotion changes everything.',
    'tactics',
  ),
  PuzzleSet(
    'promotion',
    'Promotion',
    'Push the pawn through to a new queen.',
    'tactics',
  ),
  PuzzleSet('mateIn1', 'Mate in 1', 'Find the checkmate in one move.', 'mates'),
  PuzzleSet('mateIn2', 'Mate in 2', 'Force checkmate in two moves.', 'mates'),
  PuzzleSet('mateIn3', 'Mate in 3', 'Force checkmate in three moves.', 'mates'),
  PuzzleSet(
    'backRankMate',
    'Back-rank mates',
    'The king is trapped behind its own pawns.',
    'mates',
  ),
  PuzzleSet(
    'smotheredMate',
    'Smothered mates',
    'A knight mates a king boxed in by its own pieces.',
    'mates',
  ),
  PuzzleSet(
    'pawnEndgame',
    'Pawn endgames',
    'Opposition, races and breakthroughs.',
    'endgames',
  ),
  PuzzleSet(
    'rookEndgame',
    'Rook endgames',
    'The most common endgame, played precisely.',
    'endgames',
  ),
  PuzzleSet(
    'bishopEndgame',
    'Bishop endgames',
    'Good bishops, bad bishops and colour complexes.',
    'endgames',
  ),
  PuzzleSet(
    'knightEndgame',
    'Knight endgames',
    'Knights are tricky. Count every jump.',
    'endgames',
  ),
  PuzzleSet(
    'queenEndgame',
    'Queen endgames',
    'Checks, shelter and promotion races.',
    'endgames',
  ),
  PuzzleSet(
    'endgame',
    'Endgame mix',
    'All kinds of endgame technique.',
    'endgames',
  ),
];

/// The puzzles shipped in `data/puzzles.csv`.
class PuzzleCatalog {
  PuzzleCatalog._(this.puzzles) : _byId = {for (final p in puzzles) p.id: p};

  static PuzzleCatalog? _instance;

  /// Loads the catalog once from `data/puzzles.csv` (relative to the
  /// server's working directory).
  static PuzzleCatalog get instance => _instance ??= _load();

  static PuzzleCatalog _load() {
    final file = File('data/puzzles.csv');
    final puzzles = <Puzzle>[];
    for (final line in file.readAsLinesSync()) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final f = line.split(',');
      if (f.length < 6) continue;
      puzzles.add(
        Puzzle(
          id: f[0],
          fen: f[1],
          moves: f[2].split(' '),
          rating: int.parse(f[3]),
          themes: f[4].split(' '),
          openingTags: f[5].isEmpty ? const [] : f[5].split(' '),
        ),
      );
    }
    return PuzzleCatalog._(puzzles);
  }

  final List<Puzzle> puzzles;
  final Map<String, Puzzle> _byId;
  final _random = Random();

  Puzzle? byId(String id) => _byId[id];

  Iterable<Puzzle> inSet(String key) {
    if (key == 'mixed') return puzzles;
    if (key.startsWith('opening:')) {
      final family = key.substring('opening:'.length);
      return puzzles.where(
        (p) =>
            p.themes.contains('opening') && p.openingTags.firstOrNull == family,
      );
    }
    return puzzles.where((p) => p.themes.contains(key));
  }

  int countFor(String key) => inSet(key).length;

  /// A puzzle from [key] close to [rating], avoiding [recent] ids.
  Puzzle? pick(String key, int rating, Set<String> recent) {
    final candidates = inSet(key).where((p) => !recent.contains(p.id)).toList();
    if (candidates.isEmpty) {
      final all = inSet(key).toList();
      return all.isEmpty ? null : all[_random.nextInt(all.length)];
    }
    for (final window in [100, 200, 350, 600, 3000]) {
      final near = candidates
          .where((p) => (p.rating - rating).abs() <= window)
          .toList();
      if (near.length >= 3 || window == 3000) {
        if (near.isEmpty) break;
        return near[_random.nextInt(near.length)];
      }
    }
    return candidates[_random.nextInt(candidates.length)];
  }
}
