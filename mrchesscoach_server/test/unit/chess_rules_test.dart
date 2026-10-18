import 'package:mrchesscoach_server/src/chess/chess_rules.dart';
import 'package:mrchesscoach_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Given a replayed game', () {
    test('when moves are replayed then SAN is recorded', () {
      final game = ReplayedGame.fromMoves(['e2e4', 'e7e5', 'g1f3']);
      expect(game.sanMoves, ['e4', 'e5', 'Nf3']);
      expect(game.outcome, isNull);
    });

    test('when a move is illegal then it throws', () {
      expect(
        () => ReplayedGame.fromMoves(['e2e5']),
        throwsA(isA<ChessGameException>()),
      );
    });

    test('when the notation is malformed then it throws', () {
      expect(
        () => ReplayedGame.fromMoves(['hello']),
        throwsA(isA<ChessGameException>()),
      );
    });

    test('when fool\'s mate is played then Black wins by checkmate', () {
      final game = ReplayedGame.fromMoves(['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(game.sanMoves.last, 'Qh4#');
      expect(game.outcome?.reason, GameEndReason.checkmate);
      expect(game.outcome?.winner?.name, 'black');
    });

    test('when castling is sent king-to-rook then it is stored as e1g1', () {
      final game = ReplayedGame.fromMoves([
        'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', //
      ]);
      game.play('e1h1');
      expect(game.uciMoves.last, 'e1g1');
      expect(game.sanMoves.last, 'O-O');
    });

    test(
      'when listing legal moves then castling and promotions are included',
      () {
        expect(ReplayedGame.fromMoves([]).legalMoves, hasLength(20));
        final castle = ReplayedGame.fromMoves([
          'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', //
        ]);
        expect(castle.legalMoves['e1g1'], 'O-O');
        final promote = ReplayedGame.fromMoves([
          'h2h4', 'a7a6', 'h4h5', 'a6a5', 'h5h6', 'a5a4', 'h6g7', 'a4a3', //
        ]);
        expect(promote.legalMoves['g7f8q'], 'gxf8=Q+');
        expect(promote.legalMoves.keys, contains('g7h8n'));
      },
    );

    test('when the same position occurs three times then it is a draw', () {
      final game = ReplayedGame.fromMoves([
        'g1f3', 'g8f6', 'f3g1', 'f6g8', //
        'g1f3', 'g8f6', 'f3g1', 'f6g8',
      ]);
      expect(game.outcome?.reason, GameEndReason.threefoldRepetition);
      expect(game.outcome?.winner, isNull);
    });
  });
}
