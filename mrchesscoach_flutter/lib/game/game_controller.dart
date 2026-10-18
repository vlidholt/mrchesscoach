import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import 'chess_model.dart';

/// Holds one game against the computer and talks to the server.
///
/// The player's move is shown at once; the computer's reply arrives with the
/// server response. The server stays the authority: whatever it returns
/// replaces the local state. With the coach on, the server may pause the
/// game after a mistake (`awaitingDecision`) until the player retries or
/// plays on.
class GameController extends ChangeNotifier {
  GameController(ChessGame game, {required this.level, this.openingPlies = 0})
    : _game = game {
    _apply(game);
    unawaited(_loadVerdicts());
  }

  /// The level the computer plays at, if known.
  final ChessLevel? level;

  /// Plies of an opening course played before the game started. They can't
  /// be taken back.
  final int openingPlies;

  ChessGame _game;
  ChessGame get game => _game;

  late BoardState _position;
  BoardState get position => _position;

  late List<String> _sanMoves;
  List<String> get sanMoves => _sanMoves;

  Move? _lastMove;
  Move? get lastMove => _lastMove;

  /// The computer is choosing its move.
  bool get thinking => _thinking;
  bool _thinking = false;

  /// Which action is waiting for the server, if any.
  PendingAction? get pending => _pending;
  PendingAction? _pending;

  /// Called with a message for the player, e.g. after a network error.
  void Function(String message)? onMessage;

  // ---------------------------------------------------------------------------
  // Coach state

  /// Verdicts by ply, for badges in the move list and on the board.
  final verdicts = <int, MoveAnalysis>{};

  /// The verdict on the player's latest move.
  MoveAnalysis? get playerFeedback => _playerFeedback;
  MoveAnalysis? _playerFeedback;

  /// The verdict on the computer's latest move.
  MoveAnalysis? get opponentFeedback => _opponentFeedback;
  MoveAnalysis? _opponentFeedback;

  /// Plies whose explanation is being fetched.
  final explaining = <int>{};

  /// The current step of the hint ladder, if a hint is shown.
  CoachHint? get hint => _hint;
  CoachHint? _hint;

  ThreatInsight? get threat => _threat;
  ThreatInsight? _threat;

  /// The best move to show after "Show best move" (UCI, for an arrow).
  String? get bestMoveArrow => _bestMoveArrow;
  String? _bestMoveArrow;

  Side get playerSide =>
      _game.playerColor == PlayerColor.white ? Side.white : Side.black;

  bool get coachOn => _game.coachEnabled;

  bool get isOver => _game.status != GameStatus.active;

  bool get awaitingDecision => _game.awaitingDecision;

  bool get canMove =>
      !isOver &&
      !awaitingDecision &&
      _pending == null &&
      _position.turn == playerSide;

  /// Legal destinations per origin square, empty when the player can't move.
  Map<Square, Set<Square>> get legalMoves {
    if (!canMove) return const {};
    final result = <Square, Set<Square>>{};
    for (final uci in _game.legalMoves?.keys ?? const <String>[]) {
      final move = Move.parse(uci);
      if (move != null) (result[move.from] ??= {}).add(move.to);
    }
    return result;
  }

  /// Whether the side to move is in check, read from the last move's SAN.
  bool get isCheck =>
      _sanMoves.isNotEmpty && RegExp(r'[+#]$').hasMatch(_sanMoves.last);

  /// Whether a takeback is possible: the player has made a move of their
  /// own, and the game was not resigned.
  bool get canUndo =>
      _pending == null &&
      !awaitingDecision &&
      _game.endReason != GameEndReason.resignation &&
      _game.moves.length > openingPlies + (playerSide == _startSide ? 0 : 1);

  Side get _startSide {
    final fen = _game.startFen;
    if (fen == null) return Side.white;
    return fen.split(' ')[1] == 'b' ? Side.black : Side.white;
  }

  // ---------------------------------------------------------------------------
  // Actions

  /// Plays the player's [move] and waits for the coach and the computer.
  Future<void> play(Move move) async {
    final san = _game.legalMoves?[move.uci];
    if (!canMove || san == null) return;
    _position = _position.play(move);
    _sanMoves = [..._sanMoves, san];
    _lastMove = move;
    _clearCoachExtras();
    _pending = PendingAction.move;
    _thinking = !san.endsWith('#');
    notifyListeners();

    final started = DateTime.now();
    await _run(() async {
      final updated = await client.game.move(_game.id!, move.uci);
      // Let the player's piece land before the reply starts to move.
      final wait =
          const Duration(milliseconds: 650) -
          DateTime.now().difference(started);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      return updated;
    });
  }

  /// Takes back the move the coach paused on. With [showBest], the engine's
  /// move is drawn as an arrow afterwards.
  Future<void> retry({bool showBest = false}) async {
    if (!awaitingDecision || _pending != null) return;
    final best = showBest ? _playerFeedback?.bestUci : null;
    _pending = PendingAction.retry;
    notifyListeners();
    await _run(() => client.game.retry(_game.id!));
    if (best != null) {
      _bestMoveArrow = best;
      notifyListeners();
    }
  }

  /// Keeps the paused move and lets the computer reply.
  Future<void> playOn() async {
    if (!awaitingDecision || _pending != null) return;
    _pending = PendingAction.playOn;
    _thinking = true;
    notifyListeners();
    await _run(() => client.game.playOn(_game.id!));
  }

  Future<void> undo() async {
    if (!canUndo) return;
    _pending = PendingAction.undo;
    _clearCoachExtras();
    notifyListeners();
    await _run(() => client.game.undo(_game.id!));
  }

  Future<void> resign() async {
    if (isOver || _pending != null) return;
    _pending = PendingAction.resign;
    notifyListeners();
    await _run(() => client.game.resign(_game.id!));
  }

  /// Climbs one step up the hint ladder: idea, piece, move.
  Future<void> nextHint() async {
    if (!canMove) return;
    final level = (_hint?.level ?? 0) + 1;
    if (level > 3) return;
    _pending = PendingAction.hint;
    _threat = null;
    notifyListeners();
    try {
      _hint = await client.coach.hint(_game.id!, level);
      _game = _game.copyWith(hintsUsed: _game.hintsUsed + 1);
    } on ChessGameException catch (e) {
      onMessage?.call(e.message);
    } catch (_) {
      onMessage?.call('The coach could not be reached. Try again.');
    } finally {
      _pending = null;
      notifyListeners();
    }
  }

  /// Asks the coach what the opponent is threatening.
  Future<void> findThreat() async {
    if (!canMove) return;
    _pending = PendingAction.threat;
    _hint = null;
    notifyListeners();
    try {
      _threat = await client.coach.threat(_game.id!);
    } on ChessGameException catch (e) {
      onMessage?.call(e.message);
    } catch (_) {
      onMessage?.call('The coach could not be reached. Try again.');
    } finally {
      _pending = null;
      notifyListeners();
    }
  }

  void dismissCoachExtras() {
    _clearCoachExtras();
    notifyListeners();
  }

  /// Fetches the coach's explanation of the move at [ply] (cached on the
  /// server and here).
  Future<MoveAnalysis?> explain(int ply) async {
    final known = verdicts[ply];
    if (known?.explanation != null) return known;
    if (explaining.contains(ply)) return null;
    explaining.add(ply);
    notifyListeners();
    try {
      final explained = await client.coach.explainMove(_game.id!, ply);
      if (ply < _game.moves.length || explained.retracted) {
        verdicts[ply] = explained;
      }
      if (_playerFeedback?.id == explained.id) _playerFeedback = explained;
      if (_opponentFeedback?.id == explained.id) _opponentFeedback = explained;
      return explained;
    } catch (_) {
      onMessage?.call('The coach could not explain that move right now.');
      return null;
    } finally {
      explaining.remove(ply);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------

  void _clearCoachExtras() {
    _hint = null;
    _threat = null;
    _bestMoveArrow = null;
  }

  Future<void> _loadVerdicts() async {
    if (_game.id == null) return;
    try {
      final list = await client.coach.moveVerdicts(_game.id!);
      for (final v in list) {
        verdicts[v.ply] = v;
      }
      final last = _game.moves.length - 1;
      for (final ply in [last, last - 1]) {
        final v = verdicts[ply];
        if (v == null) continue;
        if (v.byPlayer) {
          _playerFeedback ??= v;
        } else {
          _opponentFeedback ??= v;
        }
      }
      notifyListeners();
    } catch (_) {
      // Badges are a nicety; the game works without them.
    }
  }

  /// Runs a server call that returns the updated game. On failure the last
  /// known server state is restored.
  Future<void> _run(Future<ChessGame> Function() call) async {
    try {
      _apply(await call());
    } on ChessGameException catch (e) {
      onMessage?.call(e.message);
      _apply(_game);
    } catch (_) {
      onMessage?.call('Could not reach the server. Try again.');
      _apply(_game);
    } finally {
      _pending = null;
      _thinking = false;
      notifyListeners();
    }
    _autoExplain();
  }

  /// Asks for explanations of key moments without being asked: the
  /// player's notable moves, good and bad.
  void _autoExplain() {
    if (!coachOn) return;
    final feedback = _playerFeedback;
    if (feedback == null || feedback.explanation != null) return;
    if (isKeyMoment(feedback.classification)) unawaited(explain(feedback.ply));
  }

  static bool isKeyMoment(MoveClass c) =>
      c == MoveClass.brilliant ||
      c == MoveClass.great ||
      c == MoveClass.inaccuracy ||
      c == MoveClass.mistake ||
      c == MoveClass.miss ||
      c == MoveClass.blunder;

  void _apply(ChessGame game) {
    _game = game;
    _position = BoardState.fromFen(game.fen);
    _sanMoves = game.sanMoves;
    _lastMove = game.moves.isEmpty ? null : Move.parse(game.moves.last);
    verdicts.removeWhere((ply, _) => ply >= game.moves.length);
    final player = game.lastFeedback;
    final opponent = game.opponentFeedback;
    if (player != null) {
      verdicts[player.ply] = player;
      _playerFeedback = player;
    }
    if (opponent != null) {
      verdicts[opponent.ply] = opponent;
      _opponentFeedback = opponent;
    }
    if ((_playerFeedback?.ply ?? -1) >= game.moves.length) {
      _playerFeedback = null;
    }
    if ((_opponentFeedback?.ply ?? -1) >= game.moves.length) {
      _opponentFeedback = null;
    }
  }
}

enum PendingAction { move, undo, hint, threat, resign, retry, playOn }

/// Material on the board, for the captured-pieces display.
class MaterialBalance {
  MaterialBalance(BoardState position) {
    for (final piece in position.pieces.values) {
      final counts = piece.color == Side.white ? _white : _black;
      counts[piece.role] = (counts[piece.role] ?? 0) + 1;
    }
  }

  final _white = <Role, int>{};
  final _black = <Role, int>{};

  static const _start = {
    Role.pawn: 8,
    Role.knight: 2,
    Role.bishop: 2,
    Role.rook: 2,
    Role.queen: 1,
  };

  static const values = {
    Role.pawn: 1,
    Role.knight: 3,
    Role.bishop: 3,
    Role.rook: 5,
    Role.queen: 9,
  };

  /// Pieces [side] has captured, most valuable first.
  List<Role> capturedBy(Side side) {
    final opponent = side == Side.white ? _black : _white;
    return [
      for (final role in [
        Role.queen,
        Role.rook,
        Role.bishop,
        Role.knight,
        Role.pawn,
      ])
        for (var i = 0; i < (_start[role]! - (opponent[role] ?? 0)); i++) role,
    ];
  }

  /// Material lead of [side] in pawns (negative when behind).
  int advantage(Side side) {
    int total(Map<Role, int> counts) => counts.entries.fold(
      0,
      (sum, e) => sum + (values[e.key] ?? 0) * e.value,
    );
    final diff = total(_white) - total(_black);
    return side == Side.white ? diff : -diff;
  }
}
