import 'package:mrchesscoach_server/src/coach/move_classifier.dart';
import 'package:mrchesscoach_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Given winning chances', () {
    test('when the score is level then both sides have 50%', () {
      expect(whiteWinChance(cp: 0), closeTo(50, 0.01));
    });

    test('when a side can mate then it has 100%', () {
      expect(whiteWinChance(mate: 3), 100);
      expect(whiteWinChance(mate: -2), 0);
    });

    test('when a pawn up then White is clearly ahead', () {
      expect(whiteWinChance(cp: 100), inInclusiveRange(55, 65));
    });
  });

  group('Given the move classifier', () {
    MoveClass classify({
      double best = 50,
      double played = 50,
      bool isBest = false,
      double? second,
      bool sacrifice = false,
      bool book = false,
      bool erred = false,
    }) => classifyMove(
      MoveFacts(
        bestWin: best,
        playedWin: played,
        isBest: isBest,
        secondBestWin: second,
        sacrifice: sacrifice,
        book: book,
        opponentJustErred: erred,
      ),
    );

    test('when the engine move is played then it is best', () {
      expect(classify(isBest: true), MoveClass.best);
    });

    test('when only one move holds then it is great', () {
      expect(classify(isBest: true, second: 20), MoveClass.great);
    });

    test('when a sound sacrifice is the best move then it is brilliant', () {
      expect(
        classify(isBest: true, sacrifice: true, best: 60, played: 60),
        MoveClass.brilliant,
      );
    });

    test('when a book position is reached then it is book', () {
      expect(classify(played: 48, book: true), MoveClass.book);
    });

    test('when winning chances drop then the verdict scales with the drop', () {
      expect(classify(played: 48), MoveClass.excellent);
      expect(classify(played: 46.5), MoveClass.good);
      expect(classify(played: 43), MoveClass.inaccuracy);
      expect(classify(played: 35), MoveClass.mistake);
      expect(classify(played: 20), MoveClass.blunder);
    });

    test(
      'when the opponent erred and it is not punished then it is a miss',
      () {
        expect(classify(best: 80, played: 65, erred: true), MoveClass.miss);
      },
    );
  });

  group('Given accuracy', () {
    test('when no chances are lost then accuracy is perfect', () {
      expect(moveAccuracy(0), closeTo(100, 0.1));
    });

    test('when one blunder spoils a game then accuracy drops a lot', () {
      final clean = gameAccuracy(List.filled(20, 100));
      final spoiled = gameAccuracy([...List.filled(19, 100.0), 5]);
      expect(clean, closeTo(100, 0.1));
      expect(spoiled, lessThan(clean - 20));
    });
  });
}
