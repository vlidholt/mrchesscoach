import 'package:dartchess/dartchess.dart';
import 'package:mrchesscoach_server/src/coach/content/content_types.dart';
import 'package:mrchesscoach_server/src/coach/content/openings.dart';
import 'package:test/test.dart';

final _arrowPattern = RegExp(r'^[a-h][1-8][a-h][1-8]$');
final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
final _ecoPattern = RegExp(r'^[A-E][0-9]{2}$');
const _levels = {'Beginner', 'Intermediate', 'Advanced'};

String _stripSuffix(String san) => san.replaceAll(RegExp(r'[+#]$'), '');

void main() {
  test('Given the opening courses then there are twelve with unique ids', () {
    expect(openingCourses, hasLength(12));
    final ids = openingCourses.map((c) => c.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  for (final course in openingCourses) {
    group('Given the ${course.name} course', () {
      test('then the metadata is well-formed', () {
        expect(course.id, matches(_idPattern));
        expect(course.name, isNotEmpty);
        expect(course.eco, matches(_ecoPattern));
        expect(_levels, contains(course.level));
        expect(course.tagline, isNotEmpty);
        expect(course.tagline.length, lessThanOrEqualTo(60));
        expect(course.summary, isNotEmpty);
        expect(course.lichessFamily, isNotEmpty);
        expect(course.ideas.length, inInclusiveRange(3, 5));
        for (final idea in course.ideas) {
          expect(idea.trim(), isNotEmpty);
        }
      });

      test('then it has 10 to 16 plies with comments and valid arrows', () {
        expect(course.moves.length, inInclusiveRange(10, 16));
        for (final move in course.moves) {
          expect(move.comment.trim(), isNotEmpty, reason: move.san);
          for (final arrow in move.arrows) {
            expect(arrow, matches(_arrowPattern), reason: move.san);
            expect(
              arrow.substring(0, 2),
              isNot(arrow.substring(2)),
              reason: '${move.san}: $arrow',
            );
          }
        }
      });

      test('then every move is legal and written in standard SAN', () {
        Position position = Chess.initial;
        for (final (index, OpeningMove(:san)) in course.moves.indexed) {
          final move = position.parseSan(san);
          expect(move, isNotNull, reason: 'ply ${index + 1}: $san');
          expect(position.isLegal(move!), isTrue, reason: san);
          final (next, canonical) = position.makeSan(move);
          expect(
            _stripSuffix(san),
            _stripSuffix(canonical),
            reason: 'ply ${index + 1}',
          );
          position = next;
        }
      });
    });
  }
}
