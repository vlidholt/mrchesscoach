import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import '../widgets/ask_coach_dialog.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
import '../widgets/fx.dart';
import '../widgets/game_panels.dart';
import '../widgets/move_badge.dart';
import 'review_screen.dart';

/// What a game practises, if it is part of a lesson or opening course.
class GameLesson {
  const GameLesson({
    required this.title,
    required this.goal,
    this.tips = const [],
    this.openingPlies = 0,
  });

  final String title;

  /// One line describing the goal, e.g. "Hold the draw for 15 moves".
  final String goal;
  final List<String> tips;

  /// Plies of an opening course played before the game started.
  final int openingPlies;
}

/// Plays one game against the coach, who also coaches you through it.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.game,
    required this.levels,
    this.lesson,
  });

  final ChessGame game;
  final List<ChessLevel> levels;
  final GameLesson? lesson;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  late Side _orientation;
  bool _overlayDismissed = false;
  bool _startingRematch = false;

  /// The ply whose position is shown while browsing (−1 is the start), or
  /// null for the live game.
  int? _viewPly;

  final _fx = GlobalKey<FxScopeState>();
  Color _tint = Palette.gold;
  double _intensity = 0.3;
  Timer? _tintTimer;

  int? _seenFeedback;
  GameStatus? _seenStatus;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.game);
  }

  GameController _createController(ChessGame game) {
    final controller =
        GameController(
            game,
            level: widget.levels
                .where((l) => l.index == game.level)
                .firstOrNull,
            openingPlies: widget.lesson?.openingPlies ?? 0,
          )
          ..onMessage = _showMessage
          ..addListener(_onChanged);
    _orientation = controller.playerSide;
    _overlayDismissed = false;
    _viewPly = null;
    _seenFeedback = controller.playerFeedback?.id;
    _seenStatus = game.status;
    return controller;
  }

  void _onChanged() {
    if (!mounted) return;
    final c = _controller;
    // Something new happened: jump back to the live game.
    if (c.pending != null) _viewPly = null;
    _react(c);
    setState(() {
      if (!c.isOver) _overlayDismissed = false;
    });
  }

  /// Screen-wide effects for big moments.
  void _react(GameController c) {
    final fx = _fx.currentState;
    final feedback = c.playerFeedback;
    if (feedback != null && feedback.id != _seenFeedback) {
      _seenFeedback = feedback.id;
      if (c.coachOn) {
        switch (feedback.classification) {
          case MoveClass.brilliant:
            fx?.flash(MoveClass.brilliant.color);
            _pulse(MoveClass.brilliant.color, 1);
          case MoveClass.great:
            _pulse(MoveClass.great.color, 0.9);
          case MoveClass.best:
            _pulse(Palette.gold, 0.8);
          case MoveClass.mistake:
            fx?.shake(5);
            _pulse(MoveClass.mistake.color, 0.6);
          case MoveClass.miss || MoveClass.blunder:
            fx?.shake(13);
            fx?.flash(const Color(0xFFD9443E));
            _pulse(const Color(0xFFD9443E), 0.8);
          default:
        }
      }
    }
    final status = c.game.status;
    if (status != _seenStatus) {
      final was = _seenStatus;
      _seenStatus = status;
      if (was == GameStatus.active) _celebrate(status);
    }
  }

  void _celebrate(GameStatus status) {
    final fx = _fx.currentState;
    if (fx == null) return;
    final size = fx.size;
    if (status == GameStatus.playerWon) {
      fx.fx.confetti(Offset.zero & size, count: 180);
      final rnd = Random();
      for (var i = 0; i < 6; i++) {
        fx.fx.firework(
          Offset(
            size.width * (0.15 + 0.7 * rnd.nextDouble()),
            size.height * (0.12 + 0.35 * rnd.nextDouble()),
          ),
          [Palette.gold, MoveClass.brilliant.color, const Color(0xFFF1D79B)][i %
              3],
          delay: 0.25 + i * 0.35,
        );
      }
      fx.flash(Palette.gold);
      _pulse(Palette.gold, 1, seconds: 5);
    } else if (status == GameStatus.draw) {
      fx.fx.confetti(
        Offset.zero & size,
        count: 60,
        colors: const [Palette.parchment, Palette.draw, Palette.gold],
      );
    } else {
      _pulse(const Color(0xFF8C8270), 0.2, seconds: 4);
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

  @override
  void dispose() {
    _tintTimer?.cancel();
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const ConfirmDialog(
        title: 'Resign this game?',
        body:
            'I\'ll count it as a win for me. We can still go through it '
            'together afterwards.',
        confirm: 'Resign',
      ),
    );
    if (confirmed == true) await _controller.resign();
  }

  void _ask() {
    final c = _controller;
    showAskCoach(
      context,
      conversationKey: 'game-${c.game.id}-${c.game.moves.length}',
      fen: c.game.fen,
      recentSan: c.sanMoves,
      studentColor: c.game.playerColor,
    );
  }

  Future<void> _review() async {
    await Navigator.of(context).push(
      FxPageRoute<void>(
        builder: (_) =>
            ReviewScreen(gameId: _controller.game.id!, levels: widget.levels),
      ),
    );
  }

  Future<void> _rematch() async {
    setState(() => _startingRematch = true);
    try {
      final old = _controller.game;
      final ChessGame game;
      if (old.lessonId != null && old.startFen != null) {
        game = await client.learn.startLesson(old.lessonId!);
      } else if (old.lessonId != null) {
        game = await client.learn.startOpeningGame(old.lessonId!, old.level);
      } else {
        game = await client.game.startGame(
          old.level,
          old.playerColor,
          old.coachEnabled,
        );
      }
      if (!mounted) return;
      setState(() {
        _controller
          ..removeListener(_onChanged)
          ..dispose();
        _controller = _createController(game);
      });
      _fx.currentState?.flash(Palette.gold);
    } catch (_) {
      _showMessage('Could not start a new game. Try again.');
    } finally {
      if (mounted) setState(() => _startingRematch = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Browsing

  void _view(int? ply) {
    final moves = _controller.game.moves.length;
    setState(() {
      _viewPly = ply == null || ply >= moves - 1 ? null : max(-1, ply);
    });
  }

  BoardState _positionAt(int ply) {
    final game = _controller.game;
    var board = game.startFen == null
        ? BoardState.initial
        : BoardState.fromFen(game.startFen!);
    for (var i = 0; i <= ply && i < game.moves.length; i++) {
      final move = Move.parse(game.moves[i]);
      if (move != null) board = board.play(move);
    }
    return board;
  }

  void _step(int delta) {
    final last = _controller.game.moves.length - 1;
    final current = _viewPly ?? last;
    _view((current + delta).clamp(-1, last));
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
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    _view(null),
              },
              child: Focus(
                autofocus: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final wide =
                        w >= Breakpoints.desktop ||
                        (w >= Breakpoints.tablet && w > h * 1.15);
                    return wide
                        ? _buildWide(constraints)
                        : _buildColumn(constraints);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts

  /// Phones and tablets in portrait: everything stacked, nothing scrolls.
  Widget _buildColumn(BoxConstraints c) {
    final tablet = c.maxWidth >= Breakpoints.tablet;
    final width = min(c.maxWidth, tablet ? 760.0 : c.maxWidth);
    // The rows under the board are kept tight so the coach has room to talk.
    final actionHeight = tablet ? 66.0 : 56.0;
    final stripHeight = tablet ? 40.0 : 34.0;
    final materialHeight = tablet ? 20.0 : 16.0;
    final topBar = tablet ? 64.0 : 54.0;
    const evalHeight = 22.0;
    final chatMin = tablet ? 180.0 : 120.0;
    final fixed =
        topBar + evalHeight + materialHeight + 2 + stripHeight + actionHeight;
    final boardSize = [
      width - (tablet ? 32 : 0),
      c.maxHeight - fixed - chatMin,
      // On tall tablets, leave the coach room to talk.
      if (tablet) c.maxHeight * 0.56,
    ].reduce(min).clamp(200.0, 820.0);
    return Center(
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            _topBar(compact: !tablet),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: EvalStrip(
                game: _controller.game,
                playerSide: _controller.playerSide,
                height: evalHeight - 8,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 2),
                child: GameCoachChat(
                  controller: _controller,
                  lessonTips: widget.lesson?.tips ?? const [],
                  avatarSize: tablet ? 72 : 54,
                ),
              ),
            ),
            _board(boardSize),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: MaterialRow(
                balance: MaterialBalance(_controller.position),
                playerSide: _controller.playerSide,
                size: materialHeight - 4,
              ),
            ),
            Padding(
              padding: EdgeInsets.zero,
              child: MoveStrip(
                sanMoves: _controller.sanMoves,
                selectedPly: _viewPly,
                onSelect: _view,
                verdicts: _verdicts,
                plyOffset: _plyOffset,
                height: stripHeight,
              ),
            ),
            _bottomBar(actionHeight),
          ],
        ),
      ),
    );
  }

  /// Landscape tablets and desktops: the board, and a panel beside it.
  Widget _buildWide(BoxConstraints c) {
    final side = (c.maxWidth * 0.3).clamp(340.0, 460.0);
    const evalWidth = 18.0;
    const topBar = 64.0;
    final boardSize = min(
      c.maxHeight - topBar - 52,
      c.maxWidth - side - evalWidth - 100,
    ).clamp(280.0, 940.0);
    return Column(
      children: [
        _topBar(compact: false),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: boardSize * 0.88,
                  child: EvalBar(
                    game: _controller.game,
                    orientation: _orientation,
                    width: evalWidth,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: boardSize,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _board(boardSize),
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: boardSize * 0.06,
                        ),
                        child: MaterialRow(
                          balance: MaterialBalance(_controller.position),
                          playerSide: _controller.playerSide,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: side,
                  height: boardSize + 30,
                  child: _sidePanel(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidePanel() {
    final c = _controller;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: GameCoachChat(
              controller: c,
              lessonTips: widget.lesson?.tips ?? const [],
              avatarSize: 76,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 0.7,
            color: Palette.goldDeep.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('MOVES', style: Typo.label()),
              const Spacer(),
              StepButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous move (←)',
                onTap: c.game.moves.isNotEmpty && (_viewPly ?? 0) > -1
                    ? () => _step(-1)
                    : null,
              ),
              StepButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next move (→)',
                onTap: _viewPly != null ? () => _step(1) : null,
              ),
            ],
          ),
          Expanded(
            flex: 4,
            child: MoveList(
              sanMoves: c.sanMoves,
              verdicts: _verdicts,
              selectedPly: _viewPly,
              plyOffset: _plyOffset,
              onTap: _view,
            ),
          ),
          const SizedBox(height: 8),
          _bottomBar(66),
        ],
      ),
    );
  }

  int get _plyOffset {
    final fen = _controller.game.startFen;
    return fen != null && fen.split(' ')[1] == 'b' ? 1 : 0;
  }

  Map<int, MoveClass> get _verdicts => {
    for (final e in _controller.verdicts.entries)
      if (_controller.coachOn || _controller.isOver)
        e.key: e.value.classification,
  };

  Widget _topBar({required bool compact}) {
    final c = _controller;
    final lesson = widget.lesson;
    final level = c.level;
    final status = _StatusLine.of(c);
    return TopBar(
      onBack: () => Navigator.of(context).pop(),
      compact: compact,
      title: lesson?.title ?? 'Coach',
      subtitle: lesson != null
          ? Text(
              lesson.goal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Typo.body(12, color: Palette.gold),
            )
          : status == null
          ? null
          : _StatusLine(status: status),
      trailing: lesson == null && level != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LevelBadge(level: level),
            )
          : null,
    );
  }

  Widget _bottomBar(double height) {
    final c = _controller;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: c.awaitingDecision && c.playerFeedback != null
          ? Padding(
              key: const ValueKey('pause'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PauseBar(controller: c, height: height),
            )
          : KeyedSubtree(
              key: ValueKey('actions-${c.isOver}'),
              child: ActionBar(height: height, items: _actions()),
            ),
    );
  }

  List<ActionItem> _actions() {
    final c = _controller;
    if (c.isOver) {
      return [
        ActionItem(
          label: 'Play again',
          icon: Icons.replay_rounded,
          busy: _startingRematch,
          onTap: _rematch,
        ),
        ActionItem(
          label: 'Review',
          icon: Icons.insights_rounded,
          highlight: true,
          onTap: _review,
        ),
        ActionItem(label: 'Ask', icon: Icons.forum_outlined, onTap: _ask),
        ActionItem(
          label: 'Take back',
          icon: Icons.undo_rounded,
          busy: c.pending == PendingAction.undo,
          onTap: c.canUndo ? c.undo : null,
        ),
      ];
    }
    final hintLevel = c.hint?.level ?? 0;
    return [
      ActionItem(
        label: 'Resign',
        icon: Icons.flag_outlined,
        tooltip: 'Resign the game',
        busy: c.pending == PendingAction.resign,
        onTap: c.pending == null ? _resign : null,
      ),
      ActionItem(
        label: switch (hintLevel) {
          1 => 'More',
          2 => 'Show me',
          _ => 'Hint',
        },
        icon: Icons.lightbulb_outline_rounded,
        tooltip: 'Hint: first the idea, then the piece, then the move',
        highlight: c.hint != null,
        busy: c.pending == PendingAction.hint,
        onTap: c.canMove && hintLevel < 3 ? c.nextHint : null,
      ),
      ActionItem(
        label: 'Threats',
        icon: Icons.warning_amber_rounded,
        tooltip: 'What am I threatening?',
        highlight: c.threat != null,
        busy: c.pending == PendingAction.threat,
        onTap: c.canMove ? c.findThreat : null,
      ),
      ActionItem(
        label: 'Ask',
        icon: Icons.forum_outlined,
        tooltip: 'Ask me about this position',
        onTap: _ask,
      ),
      ActionItem(
        label: 'Undo',
        icon: Icons.undo_rounded,
        tooltip: 'Take back your last move',
        busy: c.pending == PendingAction.undo,
        onTap: c.canUndo ? c.undo : null,
      ),
    ];
  }

  Widget _board(double size) {
    final c = _controller;
    final browsing = _viewPly != null;
    final viewPly = _viewPly;
    final position = viewPly == null ? c.position : _positionAt(viewPly);
    final lastMove = viewPly == null
        ? c.lastMove
        : (viewPly >= 0 ? Move.parse(c.game.moves[viewPly]) : null);
    final arrows = browsing
        ? const <BoardArrow>[]
        : <BoardArrow>[
            if (c.hint?.level == 3) ?BoardArrow.fromUci(c.hint!.uci),
            if (c.threat?.uci != null)
              ?BoardArrow.fromUci(c.threat!.uci, color: BoardArrow.threat),
            if (c.bestMoveArrow != null)
              ?BoardArrow.fromUci(c.bestMoveArrow, color: BoardArrow.best),
            if (c.awaitingDecision && c.playerFeedback?.replyUci != null)
              ?BoardArrow.fromUci(
                c.playerFeedback!.replyUci,
                color: BoardArrow.threat,
              ),
          ];
    final shownPly = viewPly ?? c.game.moves.length - 1;
    final verdict = c.verdicts[shownPly];
    final showBadge =
        verdict != null &&
        lastMove != null &&
        (c.coachOn || c.isOver) &&
        (verdict.byPlayer || verdict.classification.isError);
    final hintSquare = !browsing && c.hint != null && c.hint!.level == 2
        ? Square.parse(c.hint!.square ?? '')
        : null;
    final san = viewPly == null || viewPly < 0 ? '' : c.sanMoves[viewPly];
    final inCheck = browsing
        ? san.endsWith('+') || san.endsWith('#')
        : c.isCheck;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChessBoardView(
            position: position,
            orientation: _orientation,
            legalMoves: browsing ? const {} : c.legalMoves,
            lastMove: lastMove,
            arrows: arrows,
            markedSquare: hintSquare,
            badge: showBadge ? (lastMove.to, verdict.classification) : null,
            inCheck: inCheck,
            onMove: c.play,
            effects: !browsing,
          ),
          if (browsing)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _view(null),
                child: Align(
                  alignment: const Alignment(0, -0.97),
                  child: Entrance(
                    key: const ValueKey('browsing'),
                    offset: const Offset(0, -10),
                    duration: const Duration(milliseconds: 350),
                    child: _BrowsePill(
                      label: viewPly! < 0
                          ? 'Starting position'
                          : 'Move ${(viewPly + _plyOffset) ~/ 2 + 1}'
                                '${(viewPly + _plyOffset).isEven ? '' : '…'}'
                                ' $san',
                    ),
                  ),
                ),
              ),
            ),
          if (c.isOver && !_overlayDismissed && !browsing)
            Positioned.fill(
              child: _GameOverCard(
                game: c.game,
                lesson: widget.lesson,
                canUndo: c.canUndo,
                busy: _startingRematch,
                onRematch: _rematch,
                onUndo: c.undo,
                onReview: _review,
                onLook: () => setState(() => _overlayDismissed = true),
                onLobby: () => Navigator.of(context).pop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrowsePill extends StatelessWidget {
  const _BrowsePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Palette.onyx.withValues(alpha: 0.86),
        border: Border.all(color: Palette.gold, width: 1),
        boxShadow: [BoxShadow(color: Palette.goldGlow, blurRadius: 14)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Typo.body(
              12.5,
              color: Palette.ivory,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Palette.gold,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fast_forward_rounded,
                  size: 14,
                  color: Palette.onyx,
                ),
                const SizedBox(width: 3),
                Text(
                  'Back to game',
                  style: Typo.body(
                    11.5,
                    color: Palette.onyx,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The coach's strength, e.g. "Casual · ≈1000".
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final ChessLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Palette.gold.withValues(alpha: 0.08),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.7)),
      ),
      child: Text(
        '${level.name} · ≈${level.rating}',
        style: Typo.body(12, color: Palette.parchment, weight: FontWeight.w700),
      ),
    );
  }
}

/// A line under the title for the moments that matter: check, a pause, the
/// result. Nothing while the game simply goes on.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final (String, Color) status;

  static (String, Color)? of(GameController c) => switch (c.game.status) {
    GameStatus.playerWon => ('You won!', Palette.win),
    GameStatus.computerWon => ('I won this one', Palette.loss),
    GameStatus.draw => ('Draw', Palette.draw),
    GameStatus.abandoned => ('Abandoned', Palette.muted),
    GameStatus.active when c.awaitingDecision => ('Paused', Palette.gold),
    GameStatus.active when c.isCheck && c.canMove => ('Check!', Palette.loss),
    GameStatus.active => null,
  };

  @override
  Widget build(BuildContext context) {
    final (text, color) = status;
    return Row(
      key: ValueKey(text),
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulseDot(color: color, pulsing: true),
        const SizedBox(width: 7),
        Text(
          text,
          style: Typo.body(12, color: color, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.pulsing ? _c.value : 0.5;
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 + 0.5 * t),
                blurRadius: 4 + 8 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

String reasonText(GameEndReason? reason) => switch (reason) {
  GameEndReason.checkmate => 'by checkmate',
  GameEndReason.resignation => 'by resignation',
  GameEndReason.stalemate => 'by stalemate',
  GameEndReason.insufficientMaterial => 'by insufficient material',
  GameEndReason.threefoldRepetition => 'by threefold repetition',
  GameEndReason.fiftyMoveRule => 'by the fifty-move rule',
  GameEndReason.goalReached => 'Lesson goal reached',
  GameEndReason.abandoned || null => '',
};

class _GameOverCard extends StatelessWidget {
  const _GameOverCard({
    required this.game,
    required this.lesson,
    required this.canUndo,
    required this.busy,
    required this.onRematch,
    required this.onUndo,
    required this.onReview,
    required this.onLook,
    required this.onLobby,
  });

  final ChessGame game;
  final GameLesson? lesson;
  final bool canUndo;
  final bool busy;
  final VoidCallback onRematch;
  final VoidCallback onUndo;
  final VoidCallback onReview;
  final VoidCallback onLook;
  final VoidCallback onLobby;

  @override
  Widget build(BuildContext context) {
    final goal = game.endReason == GameEndReason.goalReached;
    final won = goal || game.status == GameStatus.playerWon;
    final (title, accent) = switch (game.status) {
      _ when goal => ('Lesson complete', Palette.win),
      GameStatus.playerWon => ('Victory', Palette.gold),
      GameStatus.computerWon => ('Defeat', Palette.loss),
      _ => ('Draw', Palette.draw),
    };
    final reason = reasonText(game.endReason);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7 * t, sigmaY: 7 * t),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.5 * t),
            child: Center(
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * Curves.easeOutBack.transform(t),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        // Scales down to fit small boards on phones.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (won)
                  Positioned(
                    top: -150,
                    child: SizedBox(
                      width: 460,
                      height: 460,
                      child: LightRays(color: accent, opacity: 0.4, rays: 18),
                    ),
                  ),
                Panel(
                  highlight: true,
                  padding: const EdgeInsets.fromLTRB(30, 24, 30, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson == null ? 'GAME OVER' : 'LESSON',
                        style: Typo.label(color: accent),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        child: won
                            ? Shine(
                                child: GoldText(title, style: Typo.display(64)),
                              )
                            : Text(
                                title,
                                style: Typo.display(64, color: Palette.ivory),
                              ),
                      ),
                      const SizedBox(height: 6),
                      if (reason.isNotEmpty && !goal)
                        Text(
                          reason[0].toUpperCase() + reason.substring(1),
                          style: Typo.body(14),
                        ),
                      if (goal && lesson != null)
                        Text(lesson!.goal, style: Typo.body(14)),
                      const SizedBox(height: 20),
                      Shine(
                        period: const Duration(milliseconds: 2800),
                        child: GoldButton(
                          label: 'Review with me',
                          icon: Icons.insights_rounded,
                          onPressed: onReview,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        children: [
                          TextAction(
                            label: busy ? 'Starting…' : 'Play again',
                            onTap: busy ? null : onRematch,
                          ),
                          if (canUndo)
                            TextAction(label: 'Take back', onTap: onUndo),
                          TextAction(label: 'See board', onTap: onLook),
                          TextAction(label: 'Menu', onTap: onLobby),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextAction extends StatelessWidget {
  const TextAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: Palette.gold),
      child: Text(
        label,
        style: Typo.body(13, color: Palette.gold, weight: FontWeight.w700),
      ),
    );
  }
}

/// The bar at the top of a screen: back, a title, and actions.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.onBack,
    this.compact = false,
    this.title,
    this.titleBadge,
    this.subtitle,
    this.trailing,
  });

  final VoidCallback onBack;
  final bool compact;
  final String? title;

  /// A small chip next to the title, e.g. the level.
  final String? titleBadge;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 54 : 64,
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 4 : 16, 4, compact ? 4 : 16, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Palette.parchment,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title ?? 'Mr. Chess Coach',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Typo.display(
                            compact ? 24 : 28,
                            color: Palette.gold,
                          ),
                        ),
                      ),
                      if (titleBadge case final badge?) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Palette.goldDeep.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: Typo.body(
                              11,
                              color: Palette.parchment,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle case final s?) ...[
                    const SizedBox(height: 2),
                    s,
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirm,
  });

  final String title;
  final String body;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Entrance(
        scale: 0.85,
        offset: Offset.zero,
        duration: const Duration(milliseconds: 420),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Panel(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CoachAvatar(size: 46, mood: CoachMood.surprised),
                    const SizedBox(width: 14),
                    Expanded(child: Text(title, style: Typo.display(30))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(body, style: Typo.body(14)),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextAction(
                      label: 'Keep playing',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 8),
                    GoldButton(
                      label: confirm,
                      compact: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
