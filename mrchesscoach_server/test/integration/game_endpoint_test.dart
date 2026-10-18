import 'package:mrchesscoach_server/src/generated/protocol.dart';
import 'package:mrchesscoach_server/src/chess/chess_engine.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  tearDownAll(ChessEngine.instance.shutdown);

  withServerpod('Given the game endpoint', (sessionBuilder, endpoints) {
    final alice = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        '550e8400-e29b-41d4-a716-446655440000',
        {},
      ),
    );
    final bob = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        '550e8400-e29b-41d4-a716-446655440001',
        {},
      ),
    );

    test('when signed out then starting a game is refused', () async {
      final anonymous = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.unauthenticated(),
      );
      await expectLater(
        endpoints.game.startGame(anonymous, 0, PlayerColor.white, false),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test('when listing levels then they run from Novice up', () async {
      final levels = await endpoints.game.levels(alice);
      expect(levels.first.name, 'Novice');
      expect(levels.length, 8);
    });

    test('when playing as White then the computer replies', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        false,
      );
      expect(game.moves, isEmpty);
      expect(game.legalMoves, hasLength(20));

      final after = await endpoints.game.move(alice, game.id!, 'e2e4');
      expect(after.moves, hasLength(2));
      expect(after.sanMoves.first, 'e4');
      expect(after.status, GameStatus.active);
      expect(after.evalCp ?? after.evalMate, isNotNull);
    });

    test('when playing as Black then the computer moves first', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.black,
        false,
      );
      expect(game.moves, hasLength(1));
      expect(game.status, GameStatus.active);
    });

    test('when the move is illegal then it is rejected', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        false,
      );
      await expectLater(
        endpoints.game.move(alice, game.id!, 'e2e5'),
        throwsA(isA<ChessGameException>()),
      );
    });

    test('when taking back then both moves are removed', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        false,
      );
      await endpoints.game.move(alice, game.id!, 'd2d4');
      final undone = await endpoints.game.undo(alice, game.id!);
      expect(undone.moves, isEmpty);
      expect(undone.takebacks, 1);
    });

    test('when resigning then the computer wins', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        false,
      );
      final resigned = await endpoints.game.resign(alice, game.id!);
      expect(resigned.status, GameStatus.computerWon);
      expect(resigned.endReason, GameEndReason.resignation);
      final finished = await endpoints.game.finishedGames(alice);
      expect(finished.map((g) => g.id), contains(game.id));
    });

    test('when starting a new game then the old one is abandoned', () async {
      final first = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        false,
      );
      final second = await endpoints.game.startGame(
        alice,
        1,
        PlayerColor.white,
        false,
      );
      final active = await endpoints.game.activeGame(alice);
      expect(active?.id, second.id);
      final old = await endpoints.game.getGame(alice, first.id!);
      expect(old.status, GameStatus.abandoned);
    });

    test('when another user opens the game then it is not found', () async {
      final game = await endpoints.game.startGame(
        alice,
        0,
        PlayerColor.white,
        false,
      );
      await expectLater(
        endpoints.game.getGame(bob, game.id!),
        throwsA(isA<ChessGameException>()),
      );
    });
  });
}
