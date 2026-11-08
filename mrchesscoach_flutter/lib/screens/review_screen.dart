import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../theme.dart';
import '../widgets/ask_coach_dialog.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
import '../widgets/fx.dart';
import '../widgets/game_panels.dart';
import '../widgets/move_badge.dart';
import 'game_screen.dart' show TextAction, TopBar, reasonText;
import 'puzzle_screen.dart' show PuzzleScreen, mistakesSetKey;

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

const _red = Color(0xFFD9443E);

/// A darker green that reads on the coach's paper bubbles.
const _paperGreen = Color(0xFF3F8A3A);

/// The full review of a finished game: accuracy, the winning-chances graph,
/// a verdict on every move and the coach's comments on the key moments.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.gameId, required this.levels});

  final int gameId;
  final List<ChessLevel> levels;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _focus = FocusNode(debugLabel: 'review');
  final _fx = GlobalKey<FxScopeState>();

  /// The context of the board that is on screen, for effects on a square.
  /// (Not a GlobalKey: two boards briefly coexist while the board and the
  /// summary cross-fade.)
  BuildContext? _boardContext;

  GameReview? _review;
  ChessGame? _game;
  String? _error;

  /// Positions by index: 0 is the start, `i + 1` is the board after move i.
  List<BoardState> _positions = const [];
  List<Move?> _moves = const [];
  List<String> _san = const [];
  Map<int, MoveClass> _verdicts = const {};

  /// Indexes (into the move list) of the key moments, in game order.
  List<int> _keyIndexes = const [];
  int _startMove = 1;
  bool _blackFirst = false;

  /// The selected move; -1 is the starting position.
  int _selected = -1;

  /// Shows the position before an error with the best move drawn on it.
  bool _showBest = false;
  Side _orientation = Side.white;

  /// The post-match intro (result, accuracy) is showing.
  bool _intro = true;

  /// The summary is showing: instead of the board on phones and portrait
  /// tablets, in the side panel on wide screens.
  bool _summary = false;

  /// Whether the board plays its move effects for the current change (only
  /// when stepping one move forward).
  bool _boardFx = false;

  /// A verdict stamped over the board: (move index, serial).
  (int, int)? _stamp;
  int _stampSerial = 0;

  Color _tint = Palette.gold;
  double _intensity = 0.3;
  Timer? _tintTimer;
  final _timers = <Timer>[];

  final _explained = <int, MoveAnalysis>{};
  final _explaining = <int>{};
  final _failed = <int>{};

  /// Comments that have not been read yet, so they are typed out.
  final _fresh = <int>{-1};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tintTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    _focus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        client.coach.review(widget.gameId),
        client.game.getGame(widget.gameId),
      ]);
      if (!mounted) return;
      _prepare(results[0] as GameReview, results[1] as ChessGame);
    } on ChessGameException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'I couldn\'t reach the server. Check your connection and try '
              'again.',
        );
      }
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _review = null;
    });
    _load();
  }

  void _prepare(GameReview review, ChessGame game) {
    final startFen = game.startFen ?? _initialFen;
    final fields = startFen.split(' ');
    var board = BoardState.fromFen(startFen);
    final positions = [board];
    final moves = <Move?>[];
    for (final a in review.moves) {
      final move = Move.parse(a.uci);
      moves.add(move);
      if (move != null) board = board.play(move);
      positions.add(board);
    }
    final indexOfPly = {for (final (i, a) in review.moves.indexed) a.ply: i};
    final keys = {
      for (final ply in review.keyMoments) ?indexOfPly[ply],
    }.toList()..sort();

    setState(() {
      _review = review;
      _game = game;
      _positions = positions;
      _moves = moves;
      _san = [for (final a in review.moves) a.san];
      _verdicts = {
        for (final (i, a) in review.moves.indexed) i: a.classification,
      };
      _keyIndexes = keys;
      _blackFirst = fields.length > 1 && fields[1] == 'b';
      _startMove = fields.length > 5 ? int.tryParse(fields[5]) ?? 1 : 1;
      _orientation = _playerSide;
      _selected = -1;
      _showBest = false;
      _intro = true;
      _summary = false;
    });
    // Have the first key moment ready by the time the user gets there.
    if (keys.isNotEmpty) _maybeExplain(keys.first);
    _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Side get _playerSide =>
      _game?.playerColor == PlayerColor.black ? Side.black : Side.white;

  bool get _goal => _game?.endReason == GameEndReason.goalReached;

  bool get _won => _goal || _game?.status == GameStatus.playerWon;

  ChessLevel? get _level =>
      widget.levels.where((l) => l.index == _game?.level).firstOrNull;

  MoveAnalysis _analysis(int i) => _explained[i] ?? _review!.moves[i];

  /// "12." for White's move, "12…" for Black's.
  String _moveNumber(int i) {
    final k = i + (_blackFirst ? 1 : 0);
    final number = _startMove + k ~/ 2;
    return k.isEven ? '$number.' : '$number…';
  }

  /// The FEN of the position after move [i] (-1 for the start).
  String _fenAt(int i) {
    final moves = _review!.moves;
    if (i + 1 < moves.length) return moves[i + 1].fenBefore;
    return _game!.fen;
  }

  void _maybeExplain(int i) {
    if (i < 0 || !_keyIndexes.contains(i)) return;
    if (_analysis(i).explanation != null) return;
    if (_explaining.contains(i) || _failed.contains(i)) return;
    _explain(i);
  }

  Future<void> _explain(int i) async {
    if (_explaining.contains(i)) return;
    final ply = _review!.moves[i].ply;
    setState(() {
      _explaining.add(i);
      _failed.remove(i);
    });
    try {
      final result = await client.coach.explainMove(widget.gameId, ply);
      if (!mounted) return;
      setState(() {
        _explained[i] = result;
        if (result.explanation == null) {
          _failed.add(i);
        } else {
          _fresh.add(i);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed.add(i));
    } finally {
      if (mounted) setState(() => _explaining.remove(i));
    }
  }

  // ---------------------------------------------------------------------------
  // Effects

  /// The post-match moment: fireworks for a win, a soft glow otherwise.
  void _celebrate() {
    final fx = _fx.currentState;
    final game = _game;
    if (!mounted || fx == null || game == null) return;
    final size = fx.size;
    if (size.isEmpty) return;
    if (_won) {
      fx.fx.confetti(Offset.zero & size, count: 150);
      final rnd = Random();
      for (var i = 0; i < 5; i++) {
        final at = Offset(
          size.width * (0.15 + 0.7 * rnd.nextDouble()),
          size.height * (0.1 + 0.3 * rnd.nextDouble()),
        );
        final color = [
          Palette.gold,
          MoveClass.brilliant.color,
          const Color(0xFFF1D79B),
        ][i % 3];
        // Like FxController.firework, but cancelled if the screen closes.
        _timers.add(
          Timer(Duration(milliseconds: 350 + i * 300), () {
            if (!mounted) return;
            fx.fx
              ..sparks(
                at,
                color,
                count: 46,
                speed: 360,
                gravity: 260,
                life: 1.3,
              )
              ..stars(at, color, count: 10, speed: 160, size: 18)
              ..flare(at, color, size: 120, life: 0.5);
          }),
        );
      }
      fx.flash(Palette.gold);
      _pulse(Palette.gold, 1, seconds: 4);
    } else if (game.status == GameStatus.draw) {
      fx.fx.confetti(
        Offset.zero & size,
        count: 60,
        colors: const [Palette.parchment, Palette.draw, Palette.gold],
      );
      _pulse(Palette.draw, 0.6, seconds: 3);
    } else {
      fx.fx.motes(
        Offset(size.width / 2, size.height * 0.32),
        Palette.gold,
        count: 18,
        radius: 120,
        size: 26,
        rise: 40,
        life: 2.4,
      );
      _pulse(const Color(0xFF8C8270), 0.25, seconds: 3);
    }
  }

  /// Tints the room's light for a moment.
  void _pulse(Color tint, double intensity, {double seconds = 1.8}) {
    _tintTimer?.cancel();
    setState(() {
      _tint = tint;
      _intensity = intensity;
    });
    _tintTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () {
      if (!mounted) return;
      setState(() {
        _tint = Palette.gold;
        _intensity = 0.3;
      });
    });
  }

  /// Screen-wide reactions to the move just selected.
  void _react(int i, {required bool jumped}) {
    final a = _review!.moves[i];
    final cls = a.classification;
    final fx = _fx.currentState;
    var stamp = false;
    switch (cls) {
      case MoveClass.brilliant:
        fx?.flash(cls.color);
        _pulse(cls.color, 1);
        stamp = true;
      case MoveClass.great:
        _pulse(cls.color, 0.9);
        stamp = true;
      case MoveClass.best when a.byPlayer:
        _pulse(Palette.gold, 0.7);
      case MoveClass.mistake:
        _pulse(cls.color, 0.6);
        if (a.byPlayer) fx?.shake(4);
      case MoveClass.miss || MoveClass.blunder:
        stamp = true;
        if (a.byPlayer) {
          fx?.shake(10);
          fx?.flash(_red);
          _pulse(_red, 0.85);
        } else {
          // My slip was your chance.
          _pulse(MoveClass.brilliant.color, 0.8);
        }
      default:
    }
    // The board only plays its own effects when stepping one move forward.
    if (jumped) _squareFx(i);
    setState(() => _stamp = stamp ? (i, ++_stampSerial) : null);
  }

  /// Fires the verdict's effect on the target square of move [i].
  void _squareFx(int i) {
    final move = _moves[i];
    if (move == null) return;
    final cls = _review!.moves[i].classification;
    Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final ctx = _boardContext;
      if (ctx == null || !ctx.mounted) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return;
      final size = box.size.width;
      final sq = boardSquareSize(size);
      final local = boardSquareCenter(move.to, size, _orientation);
      final color = cls.color;
      ctx.fx(local, (s, at) {
        final fx = s.fx;
        switch (cls) {
          case MoveClass.brilliant:
            fx
              ..flare(at, color, size: sq * 4.2, life: 0.9)
              ..stars(at, color, count: 22, speed: sq * 5, size: sq * 0.45)
              ..shockwave(at, color, radius: sq * 3.4, width: sq * 0.1)
              ..shockwave(
                at,
                Colors.white,
                radius: sq * 2.2,
                width: sq * 0.05,
                delay: 0.1,
              );
          case MoveClass.great:
            fx
              ..flare(at, color, size: sq * 3.2, life: 0.8)
              ..stars(at, color, count: 14, speed: sq * 4, size: sq * 0.4)
              ..shockwave(at, color, radius: sq * 2.6, width: sq * 0.08);
          case MoveClass.best:
            fx
              ..flare(at, color, size: sq * 2.2, life: 0.6)
              ..stars(
                at,
                Palette.gold,
                count: 8,
                speed: sq * 3,
                size: sq * 0.3,
              );
          case MoveClass.inaccuracy || MoveClass.mistake:
            fx
              ..shockwave(at, color, radius: sq * 1.6, width: sq * 0.05)
              ..smoke(at, size: sq * 0.7, count: 6);
          case MoveClass.miss || MoveClass.blunder:
            fx
              ..shockwave(at, color, radius: sq * 2.8, width: sq * 0.09)
              ..shockwave(
                at,
                color,
                radius: sq * 1.6,
                width: sq * 0.05,
                delay: 0.12,
              )
              ..smoke(at, size: sq, count: 10)
              ..sparks(
                at,
                color,
                count: 18,
                speed: sq * 4,
                size: 2.4,
                gravity: sq * 6,
              );
          default:
            fx.motes(
              at,
              color,
              count: 6,
              radius: sq * 0.35,
              size: sq * 0.22,
              rise: sq * 0.8,
            );
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Navigation

  void _select(int i) {
    final review = _review;
    if (review == null) return;
    if (!_focus.hasFocus) _focus.requestFocus();
    final next = i.clamp(-1, review.moves.length - 1);
    if (_intro) setState(() => _intro = false);
    if (next == _selected) return;
    final forward = next == _selected + 1;
    setState(() {
      _fresh.remove(_selected);
      _selected = next;
      _showBest = false;
      _boardFx = forward;
      _stamp = null;
    });
    _maybeExplain(next);
    if (next >= 0) _react(next, jumped: !forward);
  }

  void _step(int delta) => _select(_selected + delta);

  /// Selects move [i] and shows it on the board.
  void _open(int i) {
    if (_summary) setState(() => _summary = false);
    _select(i);
  }

  /// Jumps to the next (or previous) key moment, wrapping around.
  void _jumpKey(int direction) {
    if (_keyIndexes.isEmpty) return;
    final target = direction > 0
        ? _keyIndexes.firstWhere(
            (k) => k > _selected,
            orElse: () => _keyIndexes.first,
          )
        : _keyIndexes.lastWhere(
            (k) => k < _selected,
            orElse: () => _keyIndexes.last,
          );
    _open(target);
  }

  /// Jumps to the next move with verdict [cls] by the player or by me.
  void _jumpToClass(MoveClass cls, {required bool byPlayer}) {
    final moves = _review!.moves;
    final n = moves.length;
    for (var k = 1; k <= n; k++) {
      final i = (_selected + k) % n;
      if (moves[i].classification == cls && moves[i].byPlayer == byPlayer) {
        _open(i);
        return;
      }
    }
  }

  void _toggleBest() => setState(() {
    _showBest = !_showBest;
    _boardFx = false;
  });

  void _toggleSummary() => setState(() => _summary = !_summary);

  void _flip() => setState(() {
    _orientation = _orientation.opposite;
    _boardFx = false;
  });

  void _startReview({bool summary = false}) {
    if (!_intro) return;
    setState(() {
      _intro = false;
      _summary = summary;
    });
    _fx.currentState?.flash(Palette.gold);
    _pulse(Palette.gold, 0.7);
    _focus.requestFocus();
  }

  void _ask() {
    final review = _review;
    final game = _game;
    if (review == null || game == null) return;
    showAskCoach(
      context,
      conversationKey: 'review-${widget.gameId}-$_selected',
      fen: _fenAt(_selected),
      recentSan: _san.take(_selected + 1).toList(),
      studentColor: game.playerColor,
    );
  }

  void _practice() {
    Navigator.of(context).push(
      FxPageRoute<void>(
        builder: (_) =>
            const PuzzleScreen(setKey: mistakesSetKey, title: 'Your mistakes'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FxScope(
        key: _fx,
        child: AmbientBackground(
          spotlight: const Alignment(0, -0.75),
          tint: _tint,
          intensity: _intensity,
          child: SafeArea(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                    _step(-1),
                const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                    _step(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _jumpKey(-1),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _jumpKey(1),
                const SingleActivator(LogicalKeyboardKey.home): () =>
                    _select(-1),
                const SingleActivator(LogicalKeyboardKey.end): () =>
                    _select(1 << 20),
                const SingleActivator(LogicalKeyboardKey.enter): () =>
                    _startReview(),
                const SingleActivator(LogicalKeyboardKey.escape): () {
                  if (_intro) {
                    _startReview();
                  } else if (_summary) {
                    _toggleSummary();
                  }
                },
                const SingleActivator(LogicalKeyboardKey.keyS): () {
                  if (_review == null) return;
                  if (_intro) {
                    _startReview(summary: true);
                  } else {
                    _toggleSummary();
                  }
                },
              },
              child: Focus(
                focusNode: _focus,
                autofocus: true,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final h = c.maxHeight;
                    final wide =
                        w >= Breakpoints.desktop ||
                        (w >= Breakpoints.tablet && w > h * 1.15);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 650),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.96, end: 1.0).animate(a),
                          child: child,
                        ),
                      ),
                      child: _body(c, wide),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BoxConstraints c, bool wide) {
    final compact = c.maxWidth < Breakpoints.tablet;
    if (_error case final message?) {
      return Column(
        key: const ValueKey('error'),
        children: [
          _topBar(compact: compact),
          Expanded(
            child: _ErrorView(
              message: message,
              onRetry: _retry,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }
    if (_review == null || _game == null) {
      return Column(
        key: const ValueKey('loading'),
        children: [
          _topBar(compact: compact),
          const Expanded(child: _LoadingView()),
        ],
      );
    }
    if (_intro) {
      return Column(
        key: const ValueKey('intro'),
        children: [
          _topBar(compact: compact),
          Expanded(child: _introView()),
        ],
      );
    }
    return KeyedSubtree(
      key: const ValueKey('main'),
      child: wide ? _buildWide(c) : _buildColumn(c),
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts

  /// Phones and tablets in portrait: everything stacked, nothing scrolls.
  Widget _buildColumn(BoxConstraints c) {
    final tablet = c.maxWidth >= Breakpoints.tablet;
    final width = min(c.maxWidth, tablet ? 760.0 : c.maxWidth);
    final topBar = tablet ? 64.0 : 54.0;
    final chanceHeight = tablet ? 46.0 : 36.0;
    final stripHeight = tablet ? 48.0 : 42.0;
    final actionHeight = tablet ? 72.0 : 62.0;
    final chatMin = tablet ? 200.0 : 104.0;
    final fixed = topBar + chanceHeight + stripHeight + actionHeight;
    final boardSize = min(
      width - (tablet ? 32 : 0),
      c.maxHeight - fixed - chatMin,
    ).clamp(160.0, 820.0);
    return Center(
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            _topBar(compact: !tablet),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) {
                  final summary = child.key == const ValueKey('summary');
                  return FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(summary ? 0.12 : -0.12, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  );
                },
                child: _summary
                    ? KeyedSubtree(
                        key: const ValueKey('summary'),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: _summaryContent(
                            panels: true,
                            gauge: tablet ? 104 : 92,
                            graphHeight: tablet ? 110 : 88,
                          ),
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('board'),
                        child: Column(
                          children: [
                            Entrance(
                              offset: const Offset(0, -12),
                              child: SizedBox(
                                height: chanceHeight,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    6,
                                  ),
                                  child: _chanceStrip(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Entrance(
                                delay: const Duration(milliseconds: 90),
                                offset: const Offset(0, 14),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    10,
                                    2,
                                  ),
                                  child: _coachChat(
                                    avatarSize: tablet ? 72 : 54,
                                  ),
                                ),
                              ),
                            ),
                            Entrance(
                              delay: const Duration(milliseconds: 160),
                              offset: Offset.zero,
                              scale: 0.94,
                              child: _board(boardSize),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _moveStrip(stripHeight),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Entrance(
              delay: const Duration(milliseconds: 240),
              offset: const Offset(0, 30),
              child: ActionBar(
                height: actionHeight,
                items: _actions(wide: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _graphHeader = 26.0;

  /// Landscape tablets and desktops: the board, and a panel beside it.
  Widget _buildWide(BoxConstraints c) {
    final side = (c.maxWidth * 0.3).clamp(340.0, 460.0);
    const barWidth = 18.0;
    const topBar = 64.0;
    const graphHeight = 70.0;
    const graphBlock = 12 + _graphHeader + graphHeight;
    final showGraph = c.maxHeight >= 560;
    final boardSize = min(
      c.maxHeight - topBar - (showGraph ? graphBlock : 0) - 28,
      c.maxWidth - side - barWidth - 20 - 28 - 64,
    ).clamp(160.0, 900.0);
    final panelHeight = boardSize + (showGraph ? graphBlock : 0);
    return Column(
      children: [
        _topBar(compact: false),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Entrance(
                  offset: const Offset(-24, 0),
                  child: SizedBox(
                    height: boardSize,
                    child: _winBar(barWidth),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: boardSize,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Entrance(
                        offset: Offset.zero,
                        scale: 0.94,
                        child: _board(boardSize),
                      ),
                      if (showGraph) ...[
                        const SizedBox(height: 12),
                        Entrance(
                          delay: const Duration(milliseconds: 220),
                          child: _graphSection(graphHeight),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Entrance(
                  delay: const Duration(milliseconds: 120),
                  offset: const Offset(32, 0),
                  child: SizedBox(
                    width: side,
                    height: panelHeight,
                    child: _sidePanel(panelHeight, graph: !showGraph),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidePanel(double height, {required bool graph}) {
    final roomy = height >= 520;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Tabs(
            labels: const ['Coach', 'Summary'],
            index: _summary ? 1 : 0,
            onChanged: (i) => setState(() => _summary = i == 1),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(
                      child.key == const ValueKey('side-summary')
                          ? 0.08
                          : -0.08,
                      0,
                    ),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: _summary
                  ? KeyedSubtree(
                      key: const ValueKey('side-summary'),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _summaryContent(
                          panels: false,
                          gauge: 96,
                          graphHeight: graph ? 80 : null,
                        ),
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('side-coach'),
                      child: _coachTab(roomy),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          ActionBar(height: roomy ? 66 : 56, items: _actions(wide: true)),
        ],
      ),
    );
  }

  Widget _coachTab(bool roomy) {
    final n = _san.length;
    final i = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: _coachChat(avatarSize: roomy ? 76 : 56),
        ),
        if (roomy) ...[
          if (_keyIndexes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _keyMomentRow(),
          ],
          const SizedBox(height: 10),
          Container(
            height: 0.7,
            color: Palette.goldDeep.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('MOVES', style: Typo.label()),
              const Spacer(),
              StepButton(
                icon: Icons.first_page_rounded,
                tooltip: 'Start (Home)',
                onTap: i > -1 ? () => _select(-1) : null,
              ),
              StepButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous move (←)',
                onTap: i > -1 ? () => _step(-1) : null,
              ),
              StepButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next move (→)',
                onTap: i < n - 1 ? () => _step(1) : null,
              ),
              StepButton(
                icon: Icons.last_page_rounded,
                tooltip: 'Last move (End)',
                onTap: i < n - 1 ? () => _select(n - 1) : null,
              ),
            ],
          ),
          Expanded(
            flex: 4,
            child: MoveList(
              sanMoves: _san,
              verdicts: _verdicts,
              selectedPly: _selected,
              onTap: _select,
              plyOffset: (_startMove - 1) * 2,
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bars

  Widget _topBar({required bool compact}) {
    final review = _review;
    final game = _game;
    final ready = review != null && game != null;
    return TopBar(
      onBack: () => Navigator.of(context).pop(),
      compact: compact,
      title: 'Review',
      titleBadge: ready ? _resultBadge(review, game) : null,
      subtitle: ready
          ? Text(
              _subtitle(review),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Typo.body(12, color: Palette.muted),
            )
          : null,
      trailing: ready && !_intro
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ask me about this position',
                  onPressed: _ask,
                  icon: const Icon(
                    Icons.forum_outlined,
                    color: Palette.parchment,
                  ),
                ),
                IconButton(
                  tooltip: 'Flip the board',
                  onPressed: _flip,
                  icon: const Icon(
                    Icons.swap_vert_rounded,
                    color: Palette.parchment,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  String _resultBadge(GameReview review, ChessGame game) {
    final word = switch (game.status) {
      _ when _goal => 'Goal reached',
      GameStatus.playerWon => 'Won',
      GameStatus.computerWon => 'Lost',
      GameStatus.draw => 'Draw',
      GameStatus.abandoned => 'Abandoned',
      GameStatus.active => 'In progress',
    };
    return '$word · ${review.playerAccuracy.round()}% accuracy';
  }

  String _subtitle(GameReview review) {
    final level = _level;
    return [
      level == null ? 'vs Coach' : 'vs Coach · ${level.name}',
      if (review.openingName case final o? when o.isNotEmpty) o,
    ].join(' · ');
  }

  List<ActionItem> _actions({required bool wide}) {
    final i = _selected;
    final a = i >= 0 ? _analysis(i) : null;
    final canBest =
        a != null &&
        a.classification.isError &&
        a.bestUci != null &&
        a.bestSan != null &&
        (wide || !_summary);
    final keys = _keyIndexes.isNotEmpty;
    return [
      ActionItem(
        label: _showBest ? 'My move' : 'Best',
        icon: _showBest ? Icons.undo_rounded : Icons.auto_awesome_rounded,
        tooltip: _showBest
            ? 'Back to the move that was played'
            : 'Show the best move on the board',
        highlight: _showBest,
        color: canBest ? BoardArrow.best : null,
        onTap: canBest ? _toggleBest : null,
      ),
      ActionItem(
        label: 'Prev key',
        icon: Icons.fast_rewind_rounded,
        tooltip: 'Previous key moment (↑)',
        onTap: keys ? () => _jumpKey(-1) : null,
      ),
      if (!wide)
        ActionItem(
          label: _summary ? 'Board' : 'Summary',
          icon: _summary ? Icons.grid_on_rounded : Icons.insights_rounded,
          tooltip: _summary
              ? 'Back to the board (S)'
              : 'Accuracy, graph and key moments (S)',
          highlight: _summary,
          onTap: _toggleSummary,
        ),
      ActionItem(
        label: 'Next key',
        icon: Icons.fast_forward_rounded,
        tooltip: 'Next key moment (↓)',
        highlight: keys && i < 0 && !_summary,
        onTap: keys ? () => _jumpKey(1) : null,
      ),
      ActionItem(
        label: 'Practice',
        icon: Icons.fitness_center_rounded,
        tooltip: 'Practise positions from your mistakes',
        onTap: _practice,
      ),
    ];
  }

  Widget _moveStrip(double height) {
    final n = _san.length;
    return MoveStrip(
      sanMoves: _san,
      selectedPly: _selected >= n - 1 ? null : _selected,
      onSelect: (ply) => _select(ply ?? n - 1),
      verdicts: _verdicts,
      plyOffset: (_startMove - 1) * 2 + (_blackFirst ? 1 : 0),
      height: height,
    );
  }

  // ---------------------------------------------------------------------------
  // Intro

  Widget _introView() {
    final game = _game!;
    final review = _review!;
    final won = _won;
    final (title, accent) = switch (game.status) {
      _ when _goal => ('Lesson complete', Palette.win),
      GameStatus.playerWon => ('Victory', Palette.gold),
      GameStatus.computerWon => ('Defeat', Palette.loss),
      GameStatus.draw => ('Draw', Palette.draw),
      GameStatus.abandoned => ('Abandoned', Palette.muted),
      GameStatus.active => ('In progress', Palette.gold),
    };
    final (line, mood) = switch (game.status) {
      _ when _goal => (
        'Goal reached! Let\'s see what went well.',
        CoachMood.happy,
      ),
      GameStatus.playerWon => (
        'Well played, you got me! Let\'s see how you did it.',
        CoachMood.happy,
      ),
      GameStatus.computerWon => (
        'Good game! Let\'s find the moment it turned.',
        CoachMood.happy,
      ),
      GameStatus.draw => (
        'A hard-fought draw. Let\'s look back at it together.',
        CoachMood.neutral,
      ),
      _ => ('Let\'s look back at this one together.', CoachMood.neutral),
    };
    final reason = reasonText(game.endReason);
    final fullMoves = (review.moves.length + 1) ~/ 2;
    final details = [
      if (reason.isNotEmpty && !_goal)
        reason[0].toUpperCase() + reason.substring(1),
      '$fullMoves ${fullMoves == 1 ? 'move' : 'moves'}',
    ].join('  ·  ');

    Duration ms(int v) => Duration(milliseconds: v);

    final card = SizedBox(
      width: 400,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -190,
            child: SizedBox(
              width: 560,
              height: 560,
              child: LightRays(
                color: accent,
                opacity: won ? 0.45 : 0.16,
                rays: 18,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Entrance(
                offset: const Offset(0, -10),
                child: Text(
                  _game!.lessonId != null ? 'LESSON' : 'GAME OVER',
                  style: Typo.label(color: accent),
                ),
              ),
              const SizedBox(height: 10),
              Entrance(
                delay: ms(80),
                duration: ms(900),
                offset: Offset.zero,
                scale: 0.55,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: won
                      ? Shine(child: GoldText(title, style: Typo.display(84)))
                      : Text(
                          title,
                          style: Typo.display(84, color: Palette.ivory),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Entrance(
                delay: ms(250),
                child: Text(
                  details,
                  textAlign: TextAlign.center,
                  style: Typo.body(14),
                ),
              ),
              const SizedBox(height: 22),
              Entrance(delay: ms(380), child: _accuracy(108)),
              const SizedBox(height: 16),
              Entrance(delay: ms(700), child: _highlightChips()),
              const SizedBox(height: 18),
              Entrance(
                delay: ms(900),
                child: CoachSays(
                  mood: mood,
                  accent: accent,
                  speaking: true,
                  avatarSize: 54,
                  child: TypewriterText(line, style: BubbleText.body),
                ),
              ),
              const SizedBox(height: 22),
              Entrance(
                delay: ms(1100),
                scale: 0.8,
                child: Shine(
                  period: const Duration(milliseconds: 2800),
                  child: GoldButton(
                    label: 'Review with me',
                    icon: Icons.insights_rounded,
                    onPressed: _startReview,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Entrance(
                delay: ms(1250),
                child: TextAction(
                  label: 'Straight to the summary',
                  onTap: () => _startReview(summary: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startReview,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FittedBox(fit: BoxFit.scaleDown, child: card),
        ),
      ),
    );
  }

  /// The player's standout verdicts: "2 Brilliant · 5 Best move · 1 Blunder".
  Widget _highlightChips() {
    final counts = _review!.playerCounts;
    const shown = [
      MoveClass.brilliant,
      MoveClass.great,
      MoveClass.best,
      MoveClass.mistake,
      MoveClass.blunder,
    ];
    final chips = [
      for (final cls in shown)
        if ((counts[cls.name] ?? 0) > 0) (cls, counts[cls.name]!),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (k, (cls, count)) in chips.indexed)
          Entrance(
            delay: Duration(milliseconds: 700 + k * 110),
            offset: Offset.zero,
            scale: 0.4,
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: cls.color.withValues(alpha: 0.12),
                border: Border.all(color: cls.color.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: cls.color.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoveBadge(cls, size: 20),
                  const SizedBox(width: 7),
                  _CountUp(
                    value: count,
                    delay: 700 + k * 110,
                    style: Typo.mono(
                      14,
                      color: Palette.ivory,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cls.label,
                    style: Typo.body(
                      12,
                      color: cls.color,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Coach

  Widget _coachChat({required double avatarSize}) {
    final i = _selected;
    final a = i >= 0 ? _analysis(i) : null;
    return CoachChat(
      lines: _lines(),
      mood: _mood(),
      accent: a?.classification.color ?? Palette.gold,
      avatarSize: avatarSize,
      speaking: _explaining.contains(i) || _fresh.contains(i),
    );
  }

  CoachMood _mood() {
    final i = _selected;
    if (i < 0) return CoachMood.neutral;
    if (_explaining.contains(i)) return CoachMood.thoughtful;
    final a = _analysis(i);
    return switch (a.classification) {
      MoveClass.blunder || MoveClass.miss => CoachMood.surprised,
      MoveClass.mistake || MoveClass.inaccuracy => CoachMood.thoughtful,
      MoveClass.brilliant ||
      MoveClass.great ||
      MoveClass.best ||
      MoveClass.excellent ||
      MoveClass.good when a.byPlayer => CoachMood.happy,
      _ => CoachMood.neutral,
    };
  }

  List<CoachLine> _lines() {
    final i = _selected;
    if (i < 0) {
      final n = _keyIndexes.length;
      final text = n == 0
          ? 'Let\'s go through our game together. Step through it with the '
                'arrows below.'
          : 'Let\'s go through our game. I marked $n key '
                'moment${n == 1 ? '' : 's'}: tap Next key to jump there.';
      return [
        CoachLine(
          id: 'intro',
          child: _say(text, fresh: _fresh.contains(-1)),
        ),
      ];
    }
    final a = _analysis(i);
    final cls = a.classification;
    return [
      CoachLine(id: 'move-$i', accent: cls.color, child: _verdictBubble(i)),
      if (_explaining.contains(i))
        CoachLine(
          id: 'why-$i-wait',
          accent: cls.color,
          child: const CoachThinking(
            label: 'Let me think about this one',
            color: Palette.inkMuted,
          ),
        )
      else if (a.explanation != null)
        CoachLine(id: 'why-$i', accent: cls.color, child: _whyBubble(a, i)),
    ];
  }

  Widget _say(String text, {required bool fresh}) => fresh
      ? TypewriterText(text, style: BubbleText.body)
      : Text(text, style: BubbleText.body);

  Widget _verdictBubble(int i) {
    final a = _analysis(i);
    final cls = a.classification;
    final loading = _explaining.contains(i);
    final failed = _failed.contains(i);
    final canBest =
        cls.isError &&
        a.bestUci != null &&
        a.bestSan != null &&
        a.bestSan != a.san;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MoveBadge(cls, size: 22),
            const SizedBox(width: 7),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: cls.label,
                      style: Typo.body(
                        13.5,
                        color: Color.lerp(cls.color, Palette.ink, 0.3)!,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: '${_moveNumber(i)} ${a.san}',
                      style: BubbleText.move,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _Tag(
              label: a.byPlayer ? 'YOU' : 'ME',
              color: a.byPlayer ? Palette.goldDeep : Palette.inkMuted,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(_quickLine(a), style: BubbleText.body),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (canBest)
              _InlineLink(
                icon: _showBest
                    ? Icons.undo_rounded
                    : Icons.visibility_outlined,
                label: _showBest ? 'Back to the game' : 'Show me ${a.bestSan}',
                color: _paperGreen,
                onTap: _toggleBest,
              ),
            if (a.explanation == null && !loading)
              _InlineLink(
                icon: Icons.help_outline_rounded,
                label: failed ? 'Ask again' : 'Why?',
                onTap: () => _explain(i),
              ),
            _ChanceShift(
              before: a.winBefore,
              after: a.winAfter,
              byPlayer: a.byPlayer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _whyBubble(MoveAnalysis a, int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.headline case final headline?) ...[
          Text(headline, style: BubbleText.headline),
          const SizedBox(height: 4),
        ],
        if (a.explanation case final e?) _say(e, fresh: _fresh.contains(i)),
      ],
    );
  }

  /// One short line about a move, in my voice.
  static String _quickLine(MoveAnalysis a) {
    final san = a.san;
    final best = a.bestSan;
    final better = best != null && best != san;
    if (!a.byPlayer) {
      return switch (a.classification) {
        MoveClass.brilliant =>
          'One of my favourite moves of the game, if I say so myself.',
        MoveClass.great => 'I had to find $san here. It was the only move.',
        MoveClass.best => '$san. I was happy with that one.',
        MoveClass.excellent => '$san kept things under control for me.',
        MoveClass.good => '$san, a steady move from me.',
        MoveClass.book => '$san, straight out of the opening books.',
        MoveClass.inaccuracy => '$san was a little loose of me.',
        MoveClass.mistake =>
          'I slipped with $san.${better ? ' $best was better.' : ''}',
        MoveClass.miss => 'I let a big chance go with $san.',
        MoveClass.blunder =>
          'Ouch, $san was a real blunder of mine. Did you catch it?',
      };
    }
    return switch (a.classification) {
      MoveClass.brilliant =>
        'Brilliant! $san gives something up for much more.',
      MoveClass.great => 'The only good move here, and you found it.',
      MoveClass.best => '$san is exactly what I would have played.',
      MoveClass.excellent => 'Excellent. $san keeps everything under control.',
      MoveClass.good =>
        'A solid move.${better ? ' $best was a touch stronger.' : ''}',
      MoveClass.book => '$san is a well-known opening move.',
      MoveClass.inaccuracy =>
        'A little imprecise.${better ? ' $best was cleaner.' : ''}',
      MoveClass.mistake =>
        '$san let me back in.${better ? ' $best was the move.' : ''}',
      MoveClass.miss =>
        'You had a chance here!${better ? ' $best was much stronger.' : ''}',
      MoveClass.blunder =>
        'Ouch, $san gives a lot away.${better ? ' $best was needed.' : ''}',
    };
  }

  // ---------------------------------------------------------------------------
  // Board

  Widget _board(double size) {
    final i = _selected;
    final a = i >= 0 ? _analysis(i) : null;
    final best =
        _showBest &&
        a != null &&
        a.classification.isError &&
        a.bestUci != null &&
        i < _positions.length - 1;
    final position = best ? _positions[i] : _positions[i + 1];
    final Move? lastMove = best
        ? (i > 0 ? _moves[i - 1] : null)
        : (i >= 0 ? _moves[i] : null);
    final arrows = <BoardArrow>[
      if (best) ?BoardArrow.fromUci(a.bestUci, color: BoardArrow.best),
    ];
    final check =
        !best && a != null && (a.san.contains('+') || a.san.contains('#'));
    final stamp = _stamp;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Builder(
            builder: (context) {
              _boardContext = context;
              return const SizedBox.expand();
            },
          ),
          ChessBoardView(
            position: position,
            orientation: _orientation,
            legalMoves: const {},
            onMove: (_) {},
            lastMove: lastMove,
            arrows: arrows,
            inCheck: check,
            effects: _boardFx,
            badge: !best && a != null && lastMove != null
                ? (lastMove.to, a.classification)
                : null,
          ),
          Positioned(
            top: size * 0.07,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: best
                      ? _BoardPill(
                          key: ValueKey('best-$i'),
                          text: 'BEST WAS ${a.bestSan ?? ''}'.trim(),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          if (stamp != null && stamp.$1 == i && !best)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: _VerdictStamp(
                    key: ValueKey('stamp-${stamp.$2}'),
                    classification: _analysis(i).classification,
                    boardSize: size,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _winBar(double width) {
    final values = _review!.winGraph;
    final white = values.isEmpty
        ? 50.0
        : values[(_selected + 1).clamp(0, values.length - 1)];
    return _WinBar(
      white: white / 100,
      orientation: _orientation,
      width: width,
      label: _selected < 0 ? '' : _evalText(_analysis(_selected)),
    );
  }

  static String _evalText(MoveAnalysis a) {
    if (a.evalMate case final mate?) return mate == 0 ? '#' : 'M${mate.abs()}';
    final cp = a.evalCp;
    if (cp == null) return '';
    final pawns = cp / 100;
    return '${pawns >= 0 ? '+' : '−'}${pawns.abs().toStringAsFixed(1)}';
  }

  // ---------------------------------------------------------------------------
  // Charts

  List<(int, Color)> get _marks => [
    for (final k in _keyIndexes)
      (k + 1, _review!.moves[k].classification.color),
  ];

  /// The player's winning chances for the selected position, 0-100.
  double _myChances(int index) {
    final values = _review!.winGraph;
    final white = values.isEmpty ? 50.0 : values[index];
    return _playerSide == Side.white ? white : 100 - white;
  }

  int get _graphIndex {
    final values = _review!.winGraph;
    return values.isEmpty ? 0 : (_selected + 1).clamp(0, values.length - 1);
  }

  /// A compact winning-chances sparkline above the coach, for scrubbing.
  Widget _chanceStrip() {
    final index = _graphIndex;
    final mine = _myChances(index);
    final color = mine >= 60
        ? Palette.win
        : mine <= 40
        ? Palette.loss
        : Palette.gold;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOU', style: Typo.label(size: 8.5, color: Palette.muted)),
              const SizedBox(height: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(end: mine),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '${v.round()}%',
                  style: Typo.mono(
                    14,
                    color: color,
                  ).copyWith(fontWeight: FontWeight.w700, height: 1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Tooltip(
            message: 'Your winning chances. Drag to scrub through the game.',
            waitDuration: const Duration(milliseconds: 800),
            child: _WinGraph(
              values: _review!.winGraph,
              selected: index,
              whiteAtBottom: _playerSide == Side.white,
              marks: _marks,
              mini: true,
              onSelect: (k) => _select(k - 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _graphSection(double height) {
    final index = _graphIndex;
    final mine = _myChances(index);
    final i = _selected;
    return Column(
      children: [
        SizedBox(
          height: _graphHeader,
          child: Row(
            children: [
              Text('WINNING CHANCES', style: Typo.label(size: 10)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  i < 0 ? 'Start' : '${_moveNumber(i)} ${_san[i]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.mono(12, color: Palette.muted),
                ),
              ),
              Text(
                'You ${mine.round()}%',
                style: Typo.mono(12, color: Palette.gold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: _WinGraph(
            values: _review!.winGraph,
            selected: index,
            whiteAtBottom: _playerSide == Side.white,
            marks: _marks,
            onSelect: (index) => _select(index - 1),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Summary

  Widget _summaryContent({
    required bool panels,
    required double gauge,
    double? graphHeight,
  }) {
    final summary = _review!.summary;
    final hasSummary = summary != null && summary.trim().isNotEmpty;
    final sections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_header(), const SizedBox(height: 18), _accuracy(gauge)],
      ),
      if (hasSummary) _SummaryCard(text: summary),
      if (graphHeight != null) _graphSection(graphHeight),
      _keyMoments(),
      _table(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, s) in sections.indexed) ...[
          if (k > 0) panels ? const SizedBox(height: 12) : const _Divider(),
          Entrance(
            delay: Duration(milliseconds: 70 * k),
            child: panels && s is! _SummaryCard
                ? Panel(
                    radius: 18,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: s,
                  )
                : s,
          ),
        ],
      ],
    );
  }

  Widget _header() {
    final game = _game!;
    final review = _review!;
    final (title, accent) = switch (game.status) {
      _ when _goal => ('Lesson complete', Palette.win),
      GameStatus.playerWon => ('Victory', Palette.win),
      GameStatus.computerWon => ('Defeat', Palette.loss),
      GameStatus.draw => ('Draw', Palette.draw),
      GameStatus.abandoned => ('Abandoned', Palette.muted),
      GameStatus.active => ('In progress', Palette.gold),
    };
    final reason = reasonText(game.endReason);
    final level = _level;
    final fullMoves = (review.moves.length + 1) ~/ 2;
    final details = [
      if (reason.isNotEmpty) reason[0].toUpperCase() + reason.substring(1),
      '$fullMoves ${fullMoves == 1 ? 'move' : 'moves'}',
      level == null ? 'vs Coach' : 'vs Coach · ${level.name} ≈${level.rating}',
    ].join('  ·  ');
    final opening = review.openingName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('RESULT', style: Typo.label(color: accent)),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _won
              ? Shine(child: GoldText(title, style: Typo.display(46)))
              : Text(title, style: Typo.display(46)),
        ),
        const SizedBox(height: 8),
        Text(details, style: Typo.body(13)),
        if (opening != null && opening.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 15,
                color: Palette.gold,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  opening,
                  style: Typo.body(
                    13,
                    color: Palette.ivory,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _accuracy(double size) {
    final review = _review!;
    final level = _level;
    final side = _playerSide;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AccuracyGauge(
            value: review.playerAccuracy,
            name: 'You',
            subtitle: side == Side.white ? 'White' : 'Black',
            side: side,
            color: Palette.gold,
            size: size,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: size * 0.32),
          child: Column(
            children: [
              Text('ACCURACY', style: Typo.label(size: 10)),
              const SizedBox(height: 6),
              Text('vs', style: Typo.display(24, color: Palette.muted)),
            ],
          ),
        ),
        Expanded(
          child: _AccuracyGauge(
            value: review.opponentAccuracy,
            name: 'Coach',
            subtitle: level == null
                ? (side == Side.white ? 'Black' : 'White')
                : '${level.name} · ≈${level.rating}',
            side: side.opposite,
            coach: true,
            color: Palette.parchment,
            size: size,
            delay: 160,
          ),
        ),
      ],
    );
  }

  /// Key moments as a horizontal row of chips, for the side panel.
  Widget _keyMomentRow() {
    final review = _review!;
    return SizedBox(
      height: 34,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.92, 1],
        ).createShader(r),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _keyIndexes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, n) {
            final k = _keyIndexes[n];
            return _MomentChip(
              classification: review.moves[k].classification,
              number: _moveNumber(k),
              san: review.moves[k].san,
              selected: k == _selected,
              onTap: () => _select(k),
            );
          },
        ),
      ),
    );
  }

  Widget _keyMoments() {
    final review = _review!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('KEY MOMENTS', style: Typo.label()),
            const Spacer(),
            if (_keyIndexes.isNotEmpty)
              Text(
                '${_keyIndexes.length}',
                style: Typo.mono(12, color: Palette.muted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_keyIndexes.isEmpty)
          Text(
            'No big turning points. A steady game.',
            style: Typo.body(13, color: Palette.muted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in _keyIndexes)
                _MomentChip(
                  classification: review.moves[k].classification,
                  number: _moveNumber(k),
                  san: review.moves[k].san,
                  selected: k == _selected,
                  onTap: () => _open(k),
                ),
            ],
          ),
      ],
    );
  }

  Widget _table() {
    final review = _review!;
    final side = _playerSide;
    Widget header(Widget icon, String name) => SizedBox(
      width: _ClassRow.countWidth,
      child: Column(
        children: [
          SizedBox.square(dimension: 28, child: Center(child: icon)),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Typo.body(11, color: Palette.muted, weight: FontWeight.w700),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            header(
              Image.asset(
                pieceAsset(side, Role.king),
                width: 28,
                height: 28,
                filterQuality: FilterQuality.medium,
              ),
              'You',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'MOVE QUALITY',
                  textAlign: TextAlign.center,
                  style: Typo.label(size: 10),
                ),
              ),
            ),
            header(const CoachAvatar(size: 26), 'Coach'),
          ],
        ),
        const SizedBox(height: 10),
        for (final (row, cls) in MoveClass.values.indexed)
          _ClassRow(
            classification: cls,
            you: review.playerCounts[cls.name] ?? 0,
            them: review.opponentCounts[cls.name] ?? 0,
            shaded: row.isEven,
            onYou: () => _jumpToClass(cls, byPlayer: true),
            onThem: () => _jumpToClass(cls, byPlayer: false),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Loading and error states

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  static const _lines = [
    'Grading every move',
    'Finding the turning points',
    'Measuring your accuracy',
    'Writing my notes',
  ];

  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final Timer _timer;
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _line = (_line + 1) % _lines.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: LightRays(opacity: 0.22, rays: 12, speed: 0.08),
                    ),
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _spin,
                        builder: (context, _) => CustomPaint(
                          painter: _OrbitPainter(_spin.value),
                        ),
                      ),
                    ),
                    const CoachAvatar(
                      size: 92,
                      speaking: true,
                      mood: CoachMood.thoughtful,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Let me look over our game…',
                textAlign: TextAlign.center,
                style: Typo.display(34),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: CoachThinking(
                  key: ValueKey(_line),
                  label: _lines[_line],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Every move gets a verdict. Long games take a few seconds.',
                textAlign: TextAlign.center,
                style: Typo.body(13, color: Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.goldDeep.withValues(alpha: 0.35),
    );
    const sweep = pi * 0.7;
    final start = t * 2 * pi - pi / 2;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [Palette.gold.withValues(alpha: 0), Palette.gold],
        stops: const [0, 1],
        endAngle: sweep,
        transform: GradientRotation(start),
      ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, arc);
    final head =
        center + Offset(cos(start + sweep), sin(start + sweep)) * radius;
    canvas.drawCircle(
      head,
      6,
      Paint()
        ..color = Palette.goldGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(head, 3.2, Paint()..color = const Color(0xFFF1D79B));
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Entrance(
            scale: 0.9,
            offset: Offset.zero,
            child: Panel(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoachAvatar(size: 72, mood: CoachMood.surprised),
                  const SizedBox(height: 18),
                  Text(
                    'The review didn\'t load',
                    textAlign: TextAlign.center,
                    style: Typo.display(32),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Typo.body(14),
                  ),
                  const SizedBox(height: 24),
                  GoldButton(
                    label: 'Try again',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: 6),
                  TextAction(label: 'Back', onTap: onBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Building blocks

/// Counts up from zero to [value] after [delay] milliseconds.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style, this.delay = 0});

  final int value;
  final TextStyle style;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final total = 700 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// A two-way switch with a sliding gold pill.
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                left: index * w,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE9C981),
                        Palette.gold,
                        Palette.goldDeep,
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(color: Palette.goldGlow, blurRadius: 14),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (i, label) in labels.indexed)
                    Expanded(
                      child: Pressable(
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 260),
                            style: Typo.body(
                              13,
                              color: i == index
                                  ? Palette.onyx
                                  : Palette.parchment,
                              weight: FontWeight.w800,
                            ),
                            child: Text(label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A verdict that slams onto the board and fades away.
class _VerdictStamp extends StatelessWidget {
  const _VerdictStamp({
    super.key,
    required this.classification,
    required this.boardSize,
  });

  final MoveClass classification;
  final double boardSize;

  @override
  Widget build(BuildContext context) {
    final cls = classification;
    final color = cls.color;
    final text = cls.glyph == null
        ? cls.label.toUpperCase()
        : '${cls.label.toUpperCase()} ${cls.glyph}';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, t, child) {
        final pop = Curves.easeOutBack.transform((t / 0.24).clamp(0.0, 1.0));
        final fadeIn = (t / 0.1).clamp(0.0, 1.0);
        final fadeOut = t < 0.62
            ? 1.0
            : (1 - (t - 0.62) / 0.38).clamp(0.0, 1.0);
        return Opacity(
          opacity: fadeIn * fadeOut,
          child: Transform.rotate(
            angle: -0.1,
            child: Transform.scale(scale: 1.9 - 0.9 * pop, child: child),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: boardSize * 0.04,
          vertical: boardSize * 0.02,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(boardSize * 0.03),
          color: Palette.onyx.withValues(alpha: 0.72),
          border: Border.all(color: color, width: max(2.0, boardSize * 0.008)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: boardSize * 0.08,
            ),
          ],
        ),
        child: Text(
          text,
          style: Typo.display(boardSize * 0.085, color: color),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Container(
        height: 0.7,
        color: Palette.goldDeep.withValues(alpha: 0.4),
      ),
    );
  }
}

/// A small label on the coach's paper, e.g. "YOU".
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(
        label,
        style: Typo.label(
          color: Color.lerp(color, Palette.ink, 0.25)!,
          size: 9.5,
        ),
      ),
    );
  }
}

/// A tappable link inside a speech bubble.
class _InlineLink extends StatelessWidget {
  const _InlineLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Palette.goldDeep,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Typo.body(13, color: color, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Your chances 62% → 31%", on the coach's paper.
class _ChanceShift extends StatelessWidget {
  const _ChanceShift({
    required this.before,
    required this.after,
    required this.byPlayer,
  });

  final double before;
  final double after;
  final bool byPlayer;

  @override
  Widget build(BuildContext context) {
    final delta = after - before;
    final color = delta <= -8
        ? const Color(0xFFB4442F)
        : delta >= 4
        ? const Color(0xFF4F7F3A)
        : Palette.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          byPlayer ? 'Your chances' : 'My chances',
          style: Typo.body(
            12,
            color: Palette.inkMuted,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${before.round()}%',
          style: Typo.mono(12, color: Palette.ink),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(Icons.arrow_right_alt_rounded, size: 16, color: color),
        ),
        Text(
          '${after.round()}%',
          style: Typo.mono(
            12,
            color: color,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BoardPill extends StatelessWidget {
  const _BoardPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Palette.onyx.withValues(alpha: 0.82),
        border: Border.all(color: BoardArrow.best.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: BoardArrow.best.withValues(alpha: 0.35),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: BoardArrow.best),
          const SizedBox(width: 6),
          Text(text, style: Typo.label(color: BoardArrow.best, size: 10)),
        ],
      ),
    );
  }
}

class _MomentChip extends StatefulWidget {
  const _MomentChip({
    required this.classification,
    required this.number,
    required this.san,
    required this.selected,
    required this.onTap,
  });

  final MoveClass classification;
  final String number;
  final String san;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MomentChip> createState() => _MomentChipState();
}

class _MomentChipState extends State<_MomentChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cls = widget.classification;
    final selected = widget.selected;
    return Tooltip(
      message: cls.label,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Pressable(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: selected
                  ? Palette.gold.withValues(alpha: 0.16)
                  : cls.color.withValues(alpha: _hover ? 0.14 : 0.07),
              border: Border.all(
                color: selected
                    ? Palette.gold
                    : cls.color.withValues(alpha: _hover ? 0.8 : 0.45),
                width: selected ? 1.2 : 0.8,
              ),
              boxShadow: [
                if (selected)
                  const BoxShadow(
                    color: Palette.goldGlow,
                    blurRadius: 14,
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MoveBadge(cls, size: 20),
                const SizedBox(width: 7),
                Text(widget.number, style: Typo.mono(12, color: Palette.muted)),
                const SizedBox(width: 3),
                Text(
                  widget.san,
                  style: Typo.mono(
                    13,
                    color: selected ? Palette.ivory : Palette.parchment,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of the verdict table: "3  ★ Best move  5".
class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.classification,
    required this.you,
    required this.them,
    required this.shaded,
    required this.onYou,
    required this.onThem,
  });

  static const countWidth = 66.0;

  final MoveClass classification;
  final int you;
  final int them;
  final bool shaded;
  final VoidCallback onYou;
  final VoidCallback onThem;

  @override
  Widget build(BuildContext context) {
    final cls = classification;
    final empty = you == 0 && them == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: shaded ? Colors.white.withValues(alpha: 0.025) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _CountCell(count: you, color: cls.color, onTap: onYou),
          Expanded(
            child: Opacity(
              opacity: empty ? 0.5 : 1,
              child: Row(
                children: [
                  MoveBadge(cls, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      cls.label,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.body(
                        13,
                        color: Palette.ivory,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CountCell(count: them, color: cls.color, onTap: onThem),
        ],
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({
    required this.count,
    required this.color,
    required this.onTap,
  });

  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: count),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, n, _) => Text(
        '$n',
        textAlign: TextAlign.center,
        style: Typo.mono(
          16,
          color: count > 0 ? color : Palette.muted.withValues(alpha: 0.45),
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
    return SizedBox(
      width: _ClassRow.countWidth,
      child: count == 0
          ? text
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: text,
              ),
            ),
    );
  }
}

/// The coach's written summary, in a speech bubble: a paragraph, then up to
/// three lessons.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = [
      for (final l in text.split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final bullets = [
      for (final l in lines)
        if (l.startsWith('•')) l.substring(1).trim(),
    ];
    final paragraph = [
      for (final l in lines)
        if (!l.startsWith('•')) l,
    ].join(' ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoachAvatar(size: 46, mood: CoachMood.happy),
        const SizedBox(width: 14),
        Expanded(
          child: CoachBubble(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY VERDICT',
                  style: Typo.label(color: Palette.goldDeep, size: 10),
                ),
                if (paragraph.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(paragraph, style: BubbleText.body),
                ],
                if (bullets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'TAKE AWAY',
                    style: Typo.label(color: Palette.goldDeep, size: 10),
                  ),
                  for (final b in bullets)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 10),
                            child: Transform.rotate(
                              angle: pi / 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                color: Palette.goldDeep,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              b,
                              style: BubbleText.small.copyWith(
                                color: Palette.ink,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Accuracy gauge

class _AccuracyGauge extends StatelessWidget {
  const _AccuracyGauge({
    required this.value,
    required this.name,
    required this.subtitle,
    required this.side,
    required this.color,
    this.coach = false,
    this.size = 100,
    this.delay = 0,
  });

  final double value;
  final String name;
  final String subtitle;
  final Side side;
  final Color color;
  final bool coach;
  final double size;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final total = 1500 + delay;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 100).toDouble()),
          duration: Duration(milliseconds: total),
          curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
          builder: (context, v, _) => SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _GaugePainter(v / 100, color),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: size * 0.04),
                  child: Text(
                    v.toStringAsFixed(1),
                    style: Typo.display(size * 0.31),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (coach)
              const CoachAvatar(size: 22)
            else
              Image.asset(
                pieceAsset(side, Role.king),
                width: 20,
                height: 20,
                filterQuality: FilterQuality.medium,
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: Typo.title(18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Typo.body(11, color: Palette.muted),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.progress, this.color);

  final double progress;
  final Color color;

  /// The arc opens at the bottom: 300° starting at 120° (clockwise from 3
  /// o'clock).
  static const _start = pi * 2 / 3;
  static const _sweep = pi * 5 / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Tick marks every 10%.
    final tick = Paint()
      ..color = Palette.goldDeep.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final inner = radius - stroke / 2 - 4;
    for (var k = 0; k <= 10; k++) {
      final a = _start + _sweep * k / 10;
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(
        center + dir * inner,
        center + dir * (inner - (k % 5 == 0 ? 5 : 3)),
        tick,
      );
    }

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final sweep = _sweep * p;
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.8),
    );
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          endAngle: _sweep + 0.4,
          colors: [
            Color.lerp(color, Colors.black, 0.45)!,
            color,
            Color.lerp(color, Colors.white, 0.35)!,
          ],
          stops: const [0, 0.6, 1],
          transform: const GradientRotation(_start - 0.2),
        ).createShader(rect),
    );
    final end = _start + sweep;
    final tip = center + Offset(cos(end), sin(end)) * radius;
    canvas.drawCircle(
      tip,
      stroke * 1.1,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.7),
    );
    canvas.drawCircle(
      tip,
      stroke * 0.36,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}

// -----------------------------------------------------------------------------
// Evaluation bar

/// A vertical ivory/onyx bar of White's winning chances.
class _WinBar extends StatelessWidget {
  const _WinBar({
    required this.white,
    required this.orientation,
    required this.width,
    required this.label,
  });

  /// White's share, 0 to 1.
  final double white;
  final Side orientation;
  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    final whiteAhead = white >= 0.5;
    final whiteAtBottom = orientation == Side.white;
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width / 2),
        border: Border.all(color: Palette.goldDeep, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width / 2),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: white.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF26231E), Color(0xFF0E0D0B)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    height: h * value,
                    top: whiteAtBottom ? null : 0,
                    bottom: whiteAtBottom ? 0 : null,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF8E8), Color(0xFFE2D5B8)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: h / 2 - 0.5,
                    height: 1,
                    child: ColoredBox(
                      color: Palette.gold.withValues(alpha: 0.7),
                    ),
                  ),
                  if (label.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: whiteAhead == whiteAtBottom ? null : 6,
                      bottom: whiteAhead == whiteAtBottom ? 6 : null,
                      child: RotatedBox(
                        quarterTurns: width < 20 ? 3 : 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: Typo.mono(
                              width < 20 ? 8 : 9,
                              color: whiteAhead ? Palette.onyx : Palette.ivory,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Winning-chances graph

class _WinGraph extends StatefulWidget {
  const _WinGraph({
    required this.values,
    required this.selected,
    required this.whiteAtBottom,
    required this.marks,
    required this.onSelect,
    this.mini = false,
  });

  /// White's winning chances (0-100) before the first move and after each.
  final List<double> values;

  /// The selected index into [values].
  final int selected;
  final bool whiteAtBottom;

  /// Dots on the curve: index into [values] and colour.
  final List<(int, Color)> marks;
  final ValueChanged<int> onSelect;

  /// A slim sparkline with smaller marks.
  final bool mini;

  @override
  State<_WinGraph> createState() => _WinGraphState();
}

class _WinGraphState extends State<_WinGraph> {
  int? _hover;

  int _indexAt(double x, double width) {
    final n = widget.values.length;
    if (n < 2 || width <= 0) return 0;
    return ((x / width) * (n - 1)).round().clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.mini ? 8.0 : 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void pick(Offset p) {
          final i = _indexAt(p.dx, width);
          if (i != widget.selected) widget.onSelect(i);
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (e) =>
              setState(() => _hover = _indexAt(e.localPosition.dx, width)),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onHorizontalDragStart: (d) => pick(d.localPosition),
            onHorizontalDragUpdate: (d) => pick(d.localPosition),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Palette.goldDeep.withValues(alpha: 0.6),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: widget.mini ? 10 : 18,
                    offset: Offset(0, widget.mini ? 4 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius - 1),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOutCubic,
                  builder: (context, t, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _WinGraphPainter(
                      values: widget.values,
                      selected: widget.selected,
                      hover: _hover,
                      marks: widget.marks,
                      whiteAtBottom: widget.whiteAtBottom,
                      progress: t,
                      mini: widget.mini,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WinGraphPainter extends CustomPainter {
  _WinGraphPainter({
    required this.values,
    required this.selected,
    required this.hover,
    required this.marks,
    required this.whiteAtBottom,
    required this.progress,
    required this.mini,
  });

  final List<double> values;
  final int selected;
  final int? hover;
  final List<(int, Color)> marks;
  final bool whiteAtBottom;
  final double progress;
  final bool mini;

  static const _light = [Color(0xFFFFF8E8), Color(0xFFE2D5B8)];
  static const _dark = [Color(0xFF2A2620), Color(0xFF100E0C)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = values.length;
    final bounds = Offset.zero & size;
    final dot = mini ? 0.6 : 1.0;

    double xAt(int i) => n < 2 ? 0 : i / (n - 1) * w;
    Offset point(int i) {
      final white = n == 0 ? 50.0 : values[i].clamp(0.0, 100.0);
      final bottom = (whiteAtBottom ? white : 100 - white).clamp(3.0, 97.0);
      return Offset(xAt(i), h * (1 - bottom / 100));
    }

    // The top side's share fills the background; the bottom side's share is
    // the area under the curve.
    final topColors = whiteAtBottom ? _dark : _light;
    final bottomColors = whiteAtBottom ? _light : _dark;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: topColors,
        ).createShader(bounds),
    );

    final reveal = w * progress;
    if (n >= 2) {
      final curve = Path()..moveTo(0, point(0).dy);
      for (var i = 1; i < n; i++) {
        final p = point(i);
        curve.lineTo(p.dx, p.dy);
      }
      final area = Path.from(curve)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, reveal, h));
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bottomColors,
          ).createShader(bounds),
      );
      canvas.drawPath(
        curve,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.gold.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        curve,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.gold.withValues(alpha: 0.8),
      );
      canvas.restore();
      // The leading edge of the reveal glows while the curve draws in.
      if (progress < 1) {
        canvas.drawLine(
          Offset(reveal, 0),
          Offset(reveal, h),
          Paint()
            ..color = Palette.gold.withValues(alpha: 0.6 * (1 - progress))
            ..strokeWidth = 3
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, h / 2, w, h / 2),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bottomColors,
          ).createShader(bounds),
      );
    }

    // Dashed midline.
    final mid = Paint()
      ..color = Palette.gold.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var x = 0.0; x < w; x += 8) {
      canvas.drawLine(Offset(x, h / 2), Offset(min(x + 4, w), h / 2), mid);
    }

    if (n == 0) return;

    // Hover guide.
    if (hover case final i? when i != selected) {
      final x = xAt(i).clamp(1.0, w - 1);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = Palette.gold.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
    }

    // Key moments.
    for (final (i, color) in marks) {
      if (i < 0 || i >= n) continue;
      final p = point(i);
      if (p.dx > reveal + 0.5) continue;
      canvas.drawCircle(
        p,
        7 * dot,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        p,
        5.2 * dot,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      canvas.drawCircle(p, 4 * dot, Paint()..color = color);
    }

    // The selected move.
    final s = selected.clamp(0, n - 1);
    final x = xAt(s).clamp(1.0, w - 1);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, h),
      Paint()
        ..color = Palette.goldGlow
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, h),
      Paint()
        ..color = Palette.gold
        ..strokeWidth = mini ? 1.5 : 2,
    );
    final at = Offset(x, point(s).dy);
    canvas.drawCircle(at, 5.5 * dot + 0.5, Paint()..color = Palette.onyx);
    canvas.drawCircle(at, 4 * dot + 0.5, Paint()..color = Palette.gold);
  }

  @override
  bool shouldRepaint(_WinGraphPainter old) =>
      old.values != values ||
      old.selected != selected ||
      old.hover != hover ||
      old.whiteAtBottom != whiteAtBottom ||
      old.progress != progress ||
      old.mini != mini ||
      old.marks.length != marks.length;
}
