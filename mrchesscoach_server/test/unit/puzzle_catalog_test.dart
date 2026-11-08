import 'package:mrchesscoach_server/src/coach/puzzles.dart';
import 'package:test/test.dart';

void main() {
  test('the puzzles are compiled into the server', () {
    // Production images may not carry any data files next to the
    // executable, so the catalog must not depend on one.
    final catalog = PuzzleCatalog.instance;
    expect(catalog.puzzles, hasLength(4894));
    for (final set in puzzleSetCatalog) {
      expect(catalog.countFor(set.key), greaterThan(0), reason: set.key);
    }
  });
}
