@Timeout(Duration(minutes: 5))
library;

import 'package:dartchess/dartchess.dart' show Chess, Setup;
import 'package:mrchesscoach_server/src/coach/content/content_types.dart';
import 'package:mrchesscoach_server/src/coach/content/lessons.dart';
import 'package:stockfish_dart/stockfish_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Given the position lessons', () {
    test('when checking metadata then every lesson is complete', () {
      final ids = positionLessons.map((l) => l.id).toSet();
      expect(ids, hasLength(positionLessons.length));
      for (final l in positionLessons) {
        expect(l.tagline.length, lessThanOrEqualTo(60), reason: l.id);
        expect(l.tips.length, inInclusiveRange(2, 4), reason: l.id);
        expect(l.concept, isNotEmpty, reason: l.id);
        expect(['endgame', 'middlegame'], contains(l.category));
        expect(l.difficulty, inInclusiveRange(1, 3), reason: l.id);
        if (l.goal != LessonGoal.win) {
          expect(l.targetMoves, greaterThan(0), reason: l.id);
        }
      }
    });

    test('when parsing the positions then they are legal and playable', () {
      for (final l in positionLessons) {
        final p = Chess.fromSetup(Setup.parseFen(l.fen));
        expect(p.isGameOver, isFalse, reason: l.id);
        expect(p.legalMoves, isNotEmpty, reason: l.id);
      }
    });

    test('when Stockfish evaluates them then the goal is achievable', () async {
      final engine = await Stockfish.start();
      addTearDown(engine.dispose);
      for (final l in positionLessons) {
        final r = await engine.bestMove(
          Position.fromFen(l.fen),
          limits: const SearchLimits(
            depth: 18,
            moveTime: Duration(milliseconds: 1500),
          ),
        );
        final score = r.lines.first.score!;
        final (cp, mate) = switch (score) {
          CentipawnScore(:final centipawns) => (centipawns, null),
          MateScore(:final moves) => (null, moves),
        };
        switch (l.goal) {
          case LessonGoal.win:
            expect(
              (mate != null && mate > 0) || (cp != null && cp >= 300),
              isTrue,
              reason: '${l.id}: $score',
            );
          case LessonGoal.keepAdvantage:
            expect(
              (mate != null && mate > 0) || (cp != null && cp >= 70),
              isTrue,
              reason: '${l.id}: $score',
            );
          case LessonGoal.draw:
            expect(
              mate == null && cp != null && cp >= -150,
              isTrue,
              reason: '${l.id}: $score',
            );
        }
      }
    });
  });
}
