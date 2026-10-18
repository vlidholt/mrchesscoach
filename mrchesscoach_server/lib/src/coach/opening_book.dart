import 'package:dartchess/dartchess.dart';

import 'content/openings.dart';

/// Positions from the opening courses, for "book move" verdicts and for
/// naming the opening of a game.
class OpeningBook {
  OpeningBook._() {
    for (final course in openingCourses) {
      Position position = Chess.initial;
      final family = _familyName(course.lichessFamily);
      for (final (i, step) in course.moves.indexed) {
        final move = position.parseSan(step.san);
        if (move == null) break;
        position = position.play(move);
        final key = positionKey(position);
        _positions.add(key);
        // Prefer the course whose line reaches the position soonest.
        final existing = _names[key];
        if (existing == null || existing.ply > i) {
          _names[key] = (name: course.name, family: family, ply: i);
        }
      }
    }
  }

  static final instance = OpeningBook._();

  final _positions = <String>{};
  final _names = <String, ({String name, String family, int ply})>{};

  /// Board, side to move, castling rights and en passant square.
  static String positionKey(Position position) =>
      position.fen.split(' ').take(4).join(' ');

  bool contains(Position position) =>
      _positions.contains(positionKey(position));

  /// The opening of a game: the course name if the game follows a course
  /// for at least six plies, otherwise the opening family (e.g. "Sicilian
  /// Defense").
  String? nameOf(Iterable<Position> positions) {
    ({String name, String family, int ply})? deepest;
    for (final p in positions) {
      final hit = _names[positionKey(p)];
      if (hit != null) deepest = hit;
    }
    if (deepest == null || deepest.ply < 1) return null;
    return deepest.ply >= 5 ? deepest.name : deepest.family;
  }

  /// `Queens_Gambit_Declined` → `Queen's Gambit Declined`.
  static String _familyName(String tag) => tag
      .replaceAll('_', ' ')
      .replaceAll('Queens', "Queen's")
      .replaceAll('Kings', "King's");
}
