import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../theme.dart';
import '../widgets/ask_coach_dialog.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
import 'game_screen.dart';
import 'puzzle_screen.dart';

enum _Mode { learn, drill, done }

/// Learn an opening: a narrated walkthrough, then drill your side's moves,
/// then play the position out against Stockfish.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({
    super.key,
    required this.openingId,
    required this.levels,
  });

  final String openingId;
  final List<ChessLevel> levels;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  OpeningCourseInfo? _course;
  String? _error;

  _Mode _mode = _Mode.learn;

  /// The number of moves shown (0 = start position).
  int _shown = 0;
  Timer? _autoplay;

  // Drill state.
  Map<String, String> _legal = const {};
  int _misses = 0;
  bool _waiting = false;
  (Square, MoveClass)? _badge;
  String? _drillText;
  BoardState? _wrongPosition;
  Move? _wrongMove;

  int _level = 2;
  bool _starting = false;

  static final _initial = BoardState.initial;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final course = await client.learn.opening(widget.openingId);
      if (mounted) setState(() => _course = course);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load the opening.');
    }
  }

  List<OpeningStep> get _steps => _course?.steps ?? const [];

  BoardState get _position =>
      _wrongPosition ??
      (_shown == 0 ? _initial : BoardState.fromFen(_steps[_shown - 1].fen));

  Move? get _lastMove =>
      _wrongMove ?? (_shown == 0 ? null : Move.parse(_steps[_shown - 1].uci));

  Side get _studentSide =>
      _course?.side == PlayerColor.black ? Side.black : Side.white;

  // ---------------------------------------------------------------------------
  // Learn mode

  void _go(int shown) {
    setState(() => _shown = shown.clamp(0, _steps.length));
  }

  void _toggleAutoplay() {
    if (_autoplay != null) {
      _autoplay!.cancel();
      setState(() => _autoplay = null);
      return;
    }
    if (_shown >= _steps.length) _go(0);
    setState(() {
      _autoplay = Timer.periodic(const Duration(milliseconds: 3200), (t) {
        if (!mounted || _shown >= _steps.length) {
          t.cancel();
          if (mounted) setState(() => _autoplay = null);
          return;
        }
        _go(_shown + 1);
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Drill mode

  Future<void> _startDrill() async {
    _autoplay?.cancel();
    setState(() {
      _autoplay = null;
      _mode = _Mode.drill;
      _shown = 0;
      _misses = 0;
      _badge = null;
      _wrongPosition = null;
      _wrongMove = null;
      _drillText =
          'Play the ${_course!.name} from memory. I\'ll play the '
          'other side.';
    });
    await _advanceOpponent();
  }

  /// Plays the opponent's book moves until it is the student's turn.
  Future<void> _advanceOpponent() async {
    while (_shown < _steps.length && !_steps[_shown].byStudent) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || _mode != _Mode.drill) return;
      setState(() => _shown++);
    }
    if (_shown >= _steps.length) {
      await _finishDrill();
      return;
    }
    await _loadLegal();
  }

  Future<void> _loadLegal() async {
    final fen = _shown == 0
        ? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
        : _steps[_shown - 1].fen;
    setState(() => _waiting = true);
    try {
      final legal = await client.learn.legalMoves(fen);
      if (mounted) setState(() => _legal = legal);
    } catch (_) {
      _snack('Could not reach the server.');
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  Future<void> _onDrillMove(Move move) async {
    if (_mode != _Mode.drill || _waiting || _shown >= _steps.length) return;
    final expected = _steps[_shown];
    if (move.uci == expected.uci) {
      setState(() {
        _badge = (move.to, MoveClass.book);
        _legal = const {};
        _wrongPosition = null;
        _wrongMove = null;
        _shown++;
        _drillText = expected.comment;
      });
      await _advanceOpponent();
      return;
    }
    // Wrong: show it briefly, then take it back.
    final san = _legal[move.uci] ?? move.uci;
    setState(() {
      _misses++;
      _wrongPosition = _position.play(move);
      _wrongMove = move;
      _badge = (move.to, MoveClass.inaccuracy);
      final hints = [
        '$san isn\'t the main line here. Think about the idea of the opening.',
        'Hint: ${expected.comment}',
        'The book move is ${expected.san}: follow the arrow.',
      ];
      _drillText = hints[min(_stepMisses(expected), hints.length - 1)];
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _wrongPosition = null;
      _wrongMove = null;
      _badge = null;
    });
  }

  final _missesByStep = <int, int>{};

  int _stepMisses(OpeningStep step) {
    final i = _steps.indexOf(step);
    _missesByStep[i] = (_missesByStep[i] ?? 0) + 1;
    return _missesByStep[i]! - 1;
  }

  Future<void> _finishDrill() async {
    setState(() {
      _mode = _Mode.done;
      _legal = const {};
      _drillText = _misses == 0
          ? 'Flawless! You know the ${_course!.name} by heart.'
          : 'Done! $_misses slip${_misses == 1 ? '' : 's'} along the way. '
                'Run it again until it\'s automatic.';
    });
    try {
      await client.learn.completeOpening(widget.openingId);
    } catch (_) {}
  }

  Future<void> _playOut() async {
    setState(() => _starting = true);
    try {
      final game = await client.learn.startOpeningGame(
        widget.openingId,
        _level,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            game: game,
            levels: widget.levels,
            lesson: GameLesson(
              title: _course!.name,
              goal: 'Play on from the main line and use its ideas',
              tips: _course!.ideas.take(3).toList(),
              openingPlies: _steps.length,
            ),
          ),
        ),
      );
    } catch (_) {
      _snack('Could not start the game.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 1000;
              return Column(
                children: [
                  TopBar(
                    onBack: () => Navigator.of(context).pop(),
                    title: course?.name ?? 'Opening',
                    compact: !wide,
                    trailing: course == null
                        ? null
                        : IconButton(
                            tooltip: 'Ask the coach',
                            onPressed: () => showAskCoach(
                              context,
                              conversationKey: 'opening-${course.id}-$_shown',
                              fen: _shown == 0
                                  ? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
                                  : _steps[_shown - 1].fen,
                              recentSan: [
                                for (final s in _steps.take(_shown)) s.san,
                              ],
                              studentColor: course.side,
                              suggestions: [
                                'Why is this move played?',
                                'What are the plans for both sides?',
                                'What are common mistakes here?',
                              ],
                            ),
                            icon: const Icon(
                              Icons.forum_outlined,
                              color: Palette.gold,
                            ),
                          ),
                  ),
                  Expanded(
                    child: course == null
                        ? Center(
                            child: _error == null
                                ? const CircularProgressIndicator(
                                    color: Palette.gold,
                                  )
                                : Text(_error!, style: Typo.display(26)),
                          )
                        : wide
                        ? _wide(c)
                        : _narrow(c),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _wide(BoxConstraints c) {
    final boardSize = min(c.maxHeight - 110, c.maxWidth - 560).clamp(
      300.0,
      800.0,
    );
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _board(boardSize),
          const SizedBox(width: 36),
          SizedBox(
            width: 440,
            height: boardSize,
            child: Panel(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: _panel(scrollable: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrow(BoxConstraints c) {
    final boardSize = min(c.maxWidth - 32, c.maxHeight - 240).clamp(
      240.0,
      720.0,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Center(
        child: SizedBox(
          width: boardSize,
          child: Column(
            children: [
              _board(boardSize),
              const SizedBox(height: 16),
              _panel(scrollable: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board(double size) {
    final legal = <Square, Set<Square>>{};
    if (_mode == _Mode.drill && !_waiting && _wrongPosition == null) {
      for (final uci in _legal.keys) {
        final m = Move.parse(uci);
        if (m != null) (legal[m.from] ??= {}).add(m.to);
      }
    }
    final arrows = <BoardArrow>[];
    if (_mode == _Mode.learn && _shown > 0) {
      for (final a in _steps[_shown - 1].arrows) {
        final arrow = BoardArrow.fromUci(a, color: BoardArrow.idea);
        if (arrow != null) arrows.add(arrow);
      }
    }
    if (_mode == _Mode.drill &&
        _shown < _steps.length &&
        (_missesByStep[_shown] ?? 0) >= 3) {
      arrows.add(BoardArrow.fromUci(_steps[_shown].uci)!);
    }
    return SizedBox(
      width: size,
      height: size,
      child: ChessBoardView(
        position: _position,
        orientation: _studentSide,
        legalMoves: legal,
        lastMove: _lastMove,
        arrows: arrows,
        badge: _badge,
        onMove: _onDrillMove,
      ),
    );
  }

  Widget _panel({required bool scrollable}) {
    final course = _course!;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${course.eco} · ${course.level.toUpperCase()}',
              style: Typo.label(),
            ),
            const Spacer(),
            _ModeSwitch(
              mode: _mode,
              onLearn: () {
                setState(() {
                  _mode = _Mode.learn;
                  _shown = 0;
                  _badge = null;
                });
              },
              onDrill: _startDrill,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(course.name, style: Typo.display(34)),
        const SizedBox(height: 4),
        Text(
          'You play ${course.side == PlayerColor.white ? 'White' : 'Black'}',
          style: Typo.body(13, color: Palette.muted),
        ),
        const SizedBox(height: 16),
        if (_mode == _Mode.learn) ..._learnPanel(course) else ..._drillPanel(),
      ],
    );
    return scrollable ? SingleChildScrollView(child: content) : content;
  }

  List<Widget> _learnPanel(OpeningCourseInfo course) {
    final step = _shown == 0 ? null : _steps[_shown - 1];
    return [
      CoachSays(
        accent: step == null
            ? Palette.goldDeep
            : (step.byStudent ? Palette.gold : Palette.muted),
        child: step == null
            ? Column(
                key: const ValueKey('intro'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypewriterText(
                    course.summary,
                    style: Typo.body(
                      14,
                      color: Palette.ivory,
                    ).copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text('WHY IT WORKS', style: Typo.label(size: 10)),
                  const SizedBox(height: 6),
                  for (final idea in course.ideas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 15,
                              color: Palette.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(idea, style: Typo.body(13))),
                        ],
                      ),
                    ),
                ],
              )
            : Column(
                key: ValueKey('step-$_shown'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _moveLabel(_shown - 1, step.san),
                        style: Typo.title(22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        step.byStudent ? 'YOUR MOVE' : 'OPPONENT',
                        style: Typo.label(
                          size: 10,
                          color: step.byStudent ? Palette.gold : Palette.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TypewriterText(
                    step.comment,
                    style: Typo.body(
                      14,
                      color: Palette.ivory,
                    ).copyWith(height: 1.45),
                  ),
                ],
              ),
      ),
      const SizedBox(height: 16),
      _Progress(total: _steps.length, shown: _shown, onTap: _go),
      const SizedBox(height: 12),
      Row(
        children: [
          IconButton(
            tooltip: 'Start',
            onPressed: _shown > 0 ? () => _go(0) : null,
            icon: const Icon(Icons.first_page_rounded),
            color: Palette.parchment,
          ),
          IconButton(
            tooltip: 'Previous move',
            onPressed: _shown > 0 ? () => _go(_shown - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: Palette.parchment,
          ),
          Expanded(
            child: GoldButton(
              label: _autoplay != null
                  ? 'Pause'
                  : (_shown >= _steps.length ? 'Replay' : 'Play through'),
              icon: _autoplay != null
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              compact: true,
              onPressed: _toggleAutoplay,
            ),
          ),
          IconButton(
            tooltip: 'Next move',
            onPressed: _shown < _steps.length ? () => _go(_shown + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: Palette.parchment,
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (_shown >= _steps.length)
        SizedBox(
          width: double.infinity,
          child: GhostButton(
            label: 'Now drill it from memory',
            icon: Icons.fitness_center_rounded,
            onPressed: _startDrill,
          ),
        ),
      const SizedBox(height: 10),
      _trapsButton(course),
    ];
  }

  List<Widget> _drillPanel() {
    final course = _course!;
    final done = _mode == _Mode.done;
    final total = _steps.where((s) => s.byStudent).length;
    final made = _steps.take(_shown).where((s) => s.byStudent).length;
    return [
      CoachSays(
        accent: done ? Palette.win : Palette.gold,
        speaking: done,
        child: TypewriterText(
          _drillText ?? '',
          key: ValueKey(_drillText),
          style: Typo.body(14, color: Palette.ivory).copyWith(height: 1.45),
        ),
      ),
      const SizedBox(height: 16),
      Text('$made of $total moves', style: Typo.label(size: 10)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: total == 0 ? 0 : made / total),
          duration: const Duration(milliseconds: 400),
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 6,
            color: Palette.gold,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      if (done) ...[
        const SizedBox(height: 20),
        Text('PLAY IT OUT', style: Typo.label()),
        const SizedBox(height: 6),
        Text(
          'Continue from the end of the line against Stockfish, with the '
          'coach watching.',
          style: Typo.body(13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in widget.levels)
              ChoiceChip(
                label: Text(l.name, style: Typo.body(12, color: Palette.ivory)),
                selected: _level == l.index,
                onSelected: (_) => setState(() => _level = l.index),
                selectedColor: Palette.gold.withValues(alpha: 0.25),
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                side: BorderSide(
                  color: _level == l.index
                      ? Palette.gold
                      : Palette.goldDeep.withValues(alpha: 0.4),
                ),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            label: 'Play from here',
            icon: Icons.sports_esports_rounded,
            busy: _starting,
            onPressed: _playOut,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: GhostButton(
            label: 'Drill again',
            icon: Icons.replay_rounded,
            onPressed: _startDrill,
          ),
        ),
        const SizedBox(height: 10),
        _trapsButton(course),
      ],
    ];
  }

  Widget _trapsButton(OpeningCourseInfo course) => SizedBox(
    width: double.infinity,
    child: GhostButton(
      label: 'Traps & tactics in this opening',
      icon: Icons.extension_rounded,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PuzzleScreen(
            setKey: 'opening:${course.family}',
            title: '${course.name} traps',
          ),
        ),
      ),
    ),
  );

  String _moveLabel(int ply, String san) =>
      ply.isEven ? '${ply ~/ 2 + 1}. $san' : '${ply ~/ 2 + 1}… $san';
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.onLearn,
    required this.onDrill,
  });

  final _Mode mode;
  final VoidCallback onLearn;
  final VoidCallback onDrill;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: selected ? Palette.gold : Colors.transparent,
              ),
              child: Text(
                label,
                style: Typo.body(
                  12,
                  color: selected ? Palette.onyx : Palette.parchment,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab('Learn', mode == _Mode.learn, onLearn),
          tab('Drill', mode != _Mode.learn, onDrill),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.total,
    required this.shown,
    required this.onTap,
  });

  final int total;
  final int shown;
  final void Function(int shown) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i <= shown
                        ? (i.isOdd ? Palette.ivory : Palette.gold)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
