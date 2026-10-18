import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import '../widgets/ask_coach_dialog.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
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

/// Plays one game against the computer with the coach at your side.
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
    return controller;
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {
      if (!_controller.isOver) _overlayDismissed = false;
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _showMessage(String message) {
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
        body: 'The game will be recorded as a loss.',
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
      MaterialPageRoute<void>(
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
    } catch (_) {
      _showMessage('Could not start a new game. Try again.');
    } finally {
      if (mounted) setState(() => _startingRematch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              return wide ? _buildWide(constraints) : _buildNarrow(constraints);
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts

  Widget _buildWide(BoxConstraints c) {
    const sidePanel = 400.0;
    const evalWidth = 22.0;
    final boardSize = min(
      c.maxHeight - 2 * 64 - 110,
      c.maxWidth - sidePanel - evalWidth - 140,
    ).clamp(280.0, 880.0);
    return Column(
      children: [
        TopBar(onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: boardSize,
                  child: EvalBar(
                    game: _controller.game,
                    orientation: _orientation,
                    width: evalWidth,
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: boardSize,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _opponentBar(),
                      const SizedBox(height: 14),
                      _board(boardSize),
                      const SizedBox(height: 14),
                      _playerBar(),
                    ],
                  ),
                ),
                const SizedBox(width: 36),
                SizedBox(
                  width: sidePanel,
                  height: boardSize + 2 * 64,
                  child: _sidePanel(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BoxConstraints c) {
    const evalWidth = 12.0;
    final boardSize = min(
      c.maxWidth - 32 - evalWidth - 8,
      c.maxHeight - 300,
    ).clamp(240.0, 720.0);
    return Column(
      children: [
        TopBar(onBack: () => Navigator.of(context).pop(), compact: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: boardSize + evalWidth + 8,
                child: Column(
                  children: [
                    if (widget.lesson != null) ...[
                      _LessonBanner(lesson: widget.lesson!),
                      const SizedBox(height: 10),
                    ],
                    _opponentBar(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          height: boardSize,
                          child: EvalBar(
                            game: _controller.game,
                            orientation: _orientation,
                            width: evalWidth,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _board(boardSize),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _playerBar(),
                    const SizedBox(height: 14),
                    CoachPanel(
                      controller: _controller,
                      onAsk: _ask,
                      lessonTips: widget.lesson?.tips ?? const [],
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    _gameControls(),
                    const SizedBox(height: 12),
                    Panel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      radius: 16,
                      child: MoveList(
                        sanMoves: _controller.sanMoves,
                        verdicts: _verdicts,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pieces of the screen

  Map<int, MoveClass> get _verdicts => {
    for (final e in _controller.verdicts.entries)
      if (_controller.coachOn || _controller.isOver)
        e.key: e.value.classification,
  };

  Widget _board(double size) {
    final c = _controller;
    final arrows = <BoardArrow>[
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
    final lastPly = c.game.moves.length - 1;
    final lastVerdict = c.verdicts[lastPly];
    final showBadge =
        lastVerdict != null &&
        c.lastMove != null &&
        (c.coachOn || c.isOver) &&
        (lastVerdict.byPlayer || lastVerdict.classification.isError);
    final hintSquare = c.hint != null && c.hint!.level == 2
        ? Square.parse(c.hint!.square ?? '')
        : null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChessBoardView(
            position: c.position,
            orientation: _orientation,
            legalMoves: c.legalMoves,
            lastMove: c.lastMove,
            arrows: arrows,
            markedSquare: hintSquare,
            badge: showBadge
                ? (c.lastMove!.to, lastVerdict.classification)
                : null,
            inCheck: c.isCheck,
            onMove: c.play,
          ),
          if (c.isOver && !_overlayDismissed)
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

  Widget _opponentBar() {
    final c = _controller;
    final level = c.level;
    return PlayerBar(
      name: 'Stockfish',
      subtitle: level == null ? 'Computer' : '${level.name} · ≈${level.rating}',
      side: c.playerSide.opposite,
      balance: MaterialBalance(c.position),
      active: !c.isOver && c.position.turn != c.playerSide,
      thinking: c.thinking,
      isComputer: true,
    );
  }

  Widget _playerBar() {
    final c = _controller;
    return PlayerBar(
      name: 'You',
      subtitle: c.playerSide == Side.white ? 'Playing White' : 'Playing Black',
      side: c.playerSide,
      balance: MaterialBalance(c.position),
      active: !c.isOver && c.position.turn == c.playerSide,
    );
  }

  Widget _gameControls() {
    final c = _controller;
    return Row(
      children: [
        Expanded(
          child: GhostButton(
            label: 'Undo',
            icon: Icons.undo_rounded,
            tooltip: 'Take back your last move',
            busy: c.pending == PendingAction.undo,
            onPressed: c.canUndo ? c.undo : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GhostButton(
            label: 'Flip',
            icon: Icons.swap_vert_rounded,
            tooltip: 'Flip the board',
            onPressed: () =>
                setState(() => _orientation = _orientation.opposite),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: c.isOver
              ? GhostButton(
                  label: 'Review',
                  icon: Icons.insights_rounded,
                  tooltip: 'Review the game with the coach',
                  onPressed: _review,
                )
              : GhostButton(
                  label: 'Resign',
                  icon: Icons.flag_outlined,
                  tooltip: 'Resign the game',
                  busy: c.pending == PendingAction.resign,
                  onPressed: c.pending == null ? _resign : null,
                ),
        ),
      ],
    );
  }

  Widget _sidePanel() {
    final c = _controller;
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.lesson != null) ...[
            _LessonBanner(lesson: widget.lesson!),
            const SizedBox(height: 14),
          ],
          CoachPanel(
            controller: c,
            onAsk: _ask,
            lessonTips: widget.lesson?.tips ?? const [],
          ),
          const SizedBox(height: 14),
          Container(
            height: 0.7,
            color: Palette.goldDeep.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('MOVES', style: Typo.label()),
              const Spacer(),
              _StatusLine(controller: c),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: MoveList(sanMoves: c.sanMoves, verdicts: _verdicts),
          ),
          const SizedBox(height: 12),
          _gameControls(),
        ],
      ),
    );
  }
}

class _LessonBanner extends StatelessWidget {
  const _LessonBanner({required this.lesson});

  final GameLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Palette.gold.withValues(alpha: 0.16),
            Palette.gold.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Palette.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Palette.gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: Typo.title(18)),
                Text(lesson.goal, style: Typo.body(12, color: Palette.gold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final (text, color) = switch (c.game.status) {
      GameStatus.playerWon => ('You won', Palette.win),
      GameStatus.computerWon => ('Stockfish won', Palette.loss),
      GameStatus.draw => ('Draw', Palette.draw),
      GameStatus.abandoned => ('Abandoned', Palette.muted),
      GameStatus.active when c.awaitingDecision => (
        'Coach paused the game',
        Palette.gold,
      ),
      GameStatus.active when c.thinking => (
        'Stockfish is thinking…',
        Palette.gold,
      ),
      GameStatus.active when c.isCheck && c.canMove => ('Check!', Palette.loss),
      GameStatus.active when c.canMove => ('Your move', Palette.ivory),
      GameStatus.active => ('Waiting…', Palette.muted),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Row(
        key: ValueKey(text),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Typo.body(12, color: color, weight: FontWeight.w700),
          ),
        ],
      ),
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
    final (title, accent) = switch (game.status) {
      _ when goal => ('Lesson complete', Palette.win),
      GameStatus.playerWon => ('Victory', Palette.win),
      GameStatus.computerWon => ('Defeat', Palette.loss),
      _ => ('Draw', Palette.draw),
    };
    final reason = reasonText(game.endReason);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.45 * t),
            child: Center(
              child: Opacity(
                opacity: t,
                child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
              ),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        // Scales down to fit small boards on phones.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _gameOverPanel(title, accent, goal, reason),
          ),
        ),
      ),
    );
  }

  Widget _gameOverPanel(String title, Color accent, bool goal, String reason) {
    return Panel(
      highlight: true,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lesson == null ? 'GAME OVER' : 'LESSON',
            style: Typo.label(color: accent),
          ),
          const SizedBox(height: 10),
          FittedBox(child: Text(title, style: Typo.display(60))),
          const SizedBox(height: 6),
          if (reason.isNotEmpty && !goal)
            Text(
              reason[0].toUpperCase() + reason.substring(1),
              style: Typo.body(14),
            ),
          if (goal && lesson != null) Text(lesson!.goal, style: Typo.body(14)),
          const SizedBox(height: 22),
          GoldButton(
            label: 'Review with coach',
            icon: Icons.insights_rounded,
            onPressed: onReview,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              TextAction(
                label: busy ? 'Starting…' : 'Play again',
                onTap: busy ? null : onRematch,
              ),
              if (canUndo) TextAction(label: 'Take back', onTap: onUndo),
              TextAction(label: 'Look at board', onTap: onLook),
              TextAction(label: 'Lobby', onTap: onLobby),
            ],
          ),
        ],
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

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.onBack,
    this.compact = false,
    this.title,
    this.trailing,
  });

  final VoidCallback onBack;
  final bool compact;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 20, 8, 20, compact ? 4 : 0),
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
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title ?? 'Mr. Chess Coach',
              overflow: TextOverflow.ellipsis,
              style: Typo.display(compact ? 22 : 26, color: Palette.gold),
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Panel(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Typo.display(34)),
              const SizedBox(height: 10),
              Text(body, style: Typo.body(14)),
              const SizedBox(height: 24),
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
    );
  }
}
