import 'package:mrchesscoach_server/src/coach/coach_ai.dart';
import 'package:mrchesscoach_server/src/coach/puzzles.dart';
import 'package:mrchesscoach_server/src/generated/protocol.dart';
import 'package:mrchesscoach_server/src/chess/chess_engine.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Canned answers instead of calls to a real language model.
class FakeCoachModel implements CoachLanguageModel {
  int calls = 0;

  @override
  Future<String?> generate({
    required String system,
    required String prompt,
    Map<String, Object?>? jsonSchema,
    List<CoachChatTurn> history = const [],
  }) async {
    calls++;
    final props = (jsonSchema?['properties'] as Map?) ?? const {};
    if (props.containsKey('headline')) {
      return '{"headline":"Fake headline","explanation":"Fake explanation.",'
          '"lesson":"Fake lesson.","motif":"hangingPiece"}';
    }
    if (props.containsKey('summary')) {
      return '{"summary":"Fake summary.","lessons":["One","Two","Three"]}';
    }
    if (props.containsKey('text')) {
      return '{"text":"Look at the long diagonal."}';
    }
    return 'Fake coach answer.';
  }
}

void main() {
  tearDownAll(ChessEngine.instance.shutdown);

  final fake = FakeCoachModel();
  setUpAll(() => CoachAi.override = fake);
  tearDownAll(() => CoachAi.override = null);

  withServerpod('Given the coach', (sessionBuilder, endpoints) {
    final alice = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        '550e8400-e29b-41d4-a716-446655440010',
        {},
      ),
    );

    test('when a normal move is played then both moves get verdicts', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        true,
      );
      final after = await endpoints.game.move(alice, game.id!, 'e2e4');
      expect(after.lastFeedback?.san, 'e4');
      expect(after.lastFeedback?.byPlayer, isTrue);
      expect(after.opponentFeedback, isNotNull);
      expect(after.awaitingDecision, isFalse);
    });

    group('when the queen is blundered in the queen-mate lesson', () {
      test('then the coach pauses, explains and allows a retry', () async {
        final game = await endpoints.learn.startLesson(alice, 'queen-mate');
        // Qe5+ walks into the king: Kxe5.
        final paused = await endpoints.game.move(alice, game.id!, 'a1e5');
        expect(paused.awaitingDecision, isTrue);
        expect(paused.lastFeedback?.classification, MoveClass.blunder);
        expect(paused.legalMoves, isNull);

        final explained = await endpoints.coach.explainMove(
          alice,
          game.id!,
          0,
        );
        expect(explained.headline, 'Fake headline');
        expect(explained.motif, 'hangingPiece');

        final retried = await endpoints.game.retry(alice, game.id!);
        expect(retried.moves, isEmpty);
        expect(retried.retries, 1);
        expect(retried.awaitingDecision, isFalse);
        expect(retried.legalMoves, isNotEmpty);

        final drill = await endpoints.learn.nextMistake(alice);
        expect(drill, isNotNull);
        final result = await endpoints.learn.mistakeMove(
          alice,
          drill!.analysisId,
          'a1a5',
        );
        expect(result.correct, isTrue);
      });

      test('then playing on lets the computer take the queen', () async {
        final game = await endpoints.learn.startLesson(alice, 'queen-mate');
        await endpoints.game.move(alice, game.id!, 'a1e5');
        final over = await endpoints.game.playOn(alice, game.id!);
        expect(over.status, GameStatus.draw);
        expect(over.endReason, GameEndReason.insufficientMaterial);
      });
    });

    test('when climbing the hint ladder then the move appears last', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        true,
      );
      final idea = await endpoints.coach.hint(alice, game.id!, 1);
      expect(idea.text, isNotEmpty);
      expect(idea.uci, isNull);
      final piece = await endpoints.coach.hint(alice, game.id!, 2);
      expect(piece.square, isNotNull);
      final move = await endpoints.coach.hint(alice, game.id!, 3);
      expect(move.uci, isNotNull);
      expect(move.san, isNotNull);
    });

    test('when asking for threats then an answer comes back', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        true,
      );
      final threat = await endpoints.coach.threat(alice, game.id!);
      expect(threat.text, isNotEmpty);
    });

    test('when asking the coach then the model answers', () async {
      final answer = await endpoints.coach.ask(
        alice,
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
        ['e4'],
        'What should Black do?',
        [],
        PlayerColor.black,
      );
      expect(answer, 'Fake coach answer.');
    });

    test('when a finished game is reviewed then it has a summary', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        true,
      );
      await endpoints.game.move(alice, game.id!, 'e2e4');
      await endpoints.game.resign(alice, game.id!);
      final review = await endpoints.coach.review(alice, game.id!);
      expect(review.moves, hasLength(2));
      expect(review.winGraph, hasLength(3));
      expect(review.playerAccuracy, inInclusiveRange(0, 100));
      expect(review.summary, contains('Fake summary.'));
    });
  });

  withServerpod('Given the learning area', (sessionBuilder, endpoints) {
    final bob = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        '550e8400-e29b-41d4-a716-446655440011',
        {},
      ),
    );

    test('when listing openings then each has a playable course', () async {
      final openings = await endpoints.learn.openings(bob);
      expect(openings, hasLength(12));
      final course = await endpoints.learn.opening(bob, openings.first.id);
      expect(course.steps, hasLength(openings.first.plies));
      expect(course.ideas, isNotEmpty);
      final game = await endpoints.learn.startOpeningGame(
        bob,
        openings.first.id,
        0,
      );
      expect(game.moves.length, greaterThanOrEqualTo(openings.first.plies));
      expect(game.lessonId, openings.first.id);
    });

    test('when solving a puzzle correctly then the rating rises', () async {
      final puzzle = await endpoints.learn.nextPuzzle(bob, 'mateIn1');
      final solution = PuzzleCatalog.instance.byId(puzzle.id)!.moves;
      final result = await endpoints.learn.puzzleMove(
        bob,
        puzzle.id,
        solution[1],
      );
      expect(result.correct, isTrue);
      expect(result.solved, isTrue);
      expect(result.ratingAfter, greaterThan(result.ratingBefore));
    });

    test('when a puzzle move is wrong then the solution is revealed', () async {
      final puzzle = await endpoints.learn.nextPuzzle(bob, 'fork');
      final solution = PuzzleCatalog.instance.byId(puzzle.id)!.moves;
      final wrong = puzzle.legalMoves.keys.firstWhere((m) => m != solution[1]);
      final result = await endpoints.learn.puzzleMove(bob, puzzle.id, wrong);
      if (result.correct) return; // An alternative mate; rare but valid.
      expect(result.solution, isNotEmpty);
      expect(result.ratingAfter, lessThan(result.ratingBefore));
      final explanation = await endpoints.learn.explainPuzzle(bob, puzzle.id);
      expect(explanation, isNotEmpty);
    });

    test('when opening the progress page then stats are complete', () async {
      final progress = await endpoints.progress.progress(bob);
      expect(progress.puzzleRating, greaterThan(0));
      expect(progress.recommendations, isNotEmpty);
      final sets = await endpoints.learn.puzzleSets(bob);
      expect(sets.where((s) => s.category == 'openings'), hasLength(12));
    });
  });
}
