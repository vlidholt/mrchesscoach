import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../theme.dart';
import '../widgets/ask_coach_dialog.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
import '../widgets/fx.dart';
import '../widgets/game_panels.dart';
import '../widgets/move_badge.dart';
import 'game_screen.dart';
import 'puzzle_screen.dart';

enum _Mode { learn, drill, done }

const _startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const _red = Color(0xFFD9443E);
const _paleGold = Color(0xFFF1D79B);

/// Learn an opening: a narrated walkthrough, then drill your side's moves,
/// then play the position out against the coach.
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

  /// Whether the last change of position was a single step forward, so the
  /// board may play its move effects.
  bool _forward = true;
  Timer? _autoplay;

  // Drill state.
  Map<String, String> _legal = const {};
  int _misses = 0;
  int _hints = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _waiting = false;
  (Square, MoveClass)? _badge;
  BoardState? _wrongPosition;
  Move? _wrongMove;

  /// How much help the student has had at each ply: 1 = told it's wrong,
  /// 2 = given the idea, 3 = shown the move.
  final _help = <int, int>{};

  /// Bumped whenever a drill starts or stops, to end stale async loops.
  int _drillRun = 0;

  /// What the coach has said during the drill, newest last.
  final _lines = <CoachLine>[];
  int _lineId = 0;
  CoachMood _mood = CoachMood.neutral;
  Color _accent = Palette.gold;

  // Completion.
  bool _flawless = false;
  bool _cardVisible = false;
  late int _level;
  bool _starting = false;

  // Effects.
  final _fx = GlobalKey<FxScopeState>();
  final _boardKey = GlobalKey();
  Color _tint = Palette.gold;
  double _intensity = 0.3;
  Timer? _tintTimer;

  static final _initial = BoardState.initial;

  @override
  void initState() {
    super.initState();
    final levels = widget.levels;
    _level = levels.any((l) => l.index == 2)
        ? 2
        : (levels.firstOrNull?.index ?? 2);
    _load();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _tintTimer?.cancel();
    _drillRun++;
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final course = await client.learn.opening(widget.openingId);
      if (!mounted) return;
      setState(() => _course = course);
      _pulse(Palette.gold, 0.7, seconds: 1.4);
    } catch (_) {
      if (mounted) setState(() => _error = 'I couldn\'t open this course.');
    }
  }

  List<OpeningStep> get _steps => _course?.steps ?? const [];

  BoardState get _position =>
      _wrongPosition ??
      (_shown == 0 ? _initial : BoardState.fromFen(_steps[_shown - 1].fen));

  Move? get _lastMove =>
      _wrongMove ?? (_shown == 0 ? null : Move.parse(_steps[_shown - 1].uci));

  String get _fen => _shown == 0 ? _startFen : _steps[_shown - 1].fen;

  Side get _studentSide =>
      _course?.side == PlayerColor.black ? Side.black : Side.white;

  int get _studentTotal => _steps.where((s) => s.byStudent).length;

  int get _studentMade => _steps.take(_shown).where((s) => s.byStudent).length;

  bool get _playing => _autoplay != null;

  bool get _studentToMove =>
      _mode == _Mode.drill &&
      _shown < _steps.length &&
      _steps[_shown].byStudent;

  // ---------------------------------------------------------------------------
  // Effects

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

  /// Fires [effect] at a point of the board, given the board's size.
  void _fxOnBoard(
    Offset Function(double size) where,
    void Function(FxScopeState scope, Offset at, double square) effect, {
    Duration delay = Duration.zero,
  }) {
    void fire() {
      final ctx = _boardKey.currentContext;
      if (!mounted || ctx == null) return;
      final size = ctx.size?.width ?? 0;
      if (size <= 0) return;
      final square = boardSquareSize(size);
      ctx.fx(where(size), (scope, at) => effect(scope, at, square));
    }

    if (delay == Duration.zero) {
      fire();
    } else {
      Timer(delay, fire);
    }
  }

  void _fxOnSquare(
    Square square,
    void Function(FxScopeState scope, Offset at, double square) effect, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _fxOnBoard((size) => _squareCenter(square, size), effect, delay: delay);
  }

  Offset _squareCenter(Square s, double size) =>
      boardSquareCenter(s, size, _studentSide);

  void _correctFx(Square to) {
    final big = _streak >= 3;
    _pulse(Palette.gold, big ? 1 : 0.85);
    _fxOnSquare(to, (scope, at, sq) {
      scope.fx
        ..sparks(
          at,
          Palette.gold,
          count: big ? 38 : 24,
          speed: sq * 7,
          size: 2.6,
          life: 0.8,
        )
        ..stars(
          at,
          _paleGold,
          count: big ? 12 : 7,
          speed: sq * 3.2,
          size: sq * 0.34,
        )
        ..shockwave(at, Palette.gold, radius: sq * 1.9, width: 4);
      if (big) {
        scope.fx
          ..flare(at, Palette.gold, size: sq * 2.8)
          ..shockwave(
            at,
            _paleGold,
            radius: sq * 3.4,
            width: 3,
            delay: 0.12,
          );
      }
    });
  }

  void _wrongFx(Square to) {
    _fx.currentState?.shake(6);
    _pulse(_red, 0.6);
    _fxOnSquare(to, (scope, at, sq) {
      scope.fx.smoke(at, size: sq * 0.9, count: 8);
    });
  }

  void _celebrate(bool flawless) {
    final fx = _fx.currentState;
    if (fx == null) return;
    final size = fx.size;
    fx.flash(Palette.gold);
    fx.fx.confetti(Offset.zero & size, count: flawless ? 200 : 130);
    final rnd = Random();
    final colors = [Palette.gold, MoveClass.brilliant.color, _paleGold];
    for (var i = 0; i < (flawless ? 7 : 4); i++) {
      fx.fx.firework(
        Offset(
          size.width * (0.15 + 0.7 * rnd.nextDouble()),
          size.height * (0.1 + 0.35 * rnd.nextDouble()),
        ),
        colors[i % colors.length],
        delay: 0.2 + i * 0.32,
      );
    }
    _fxOnBoard((s) => Offset(s / 2, s / 2), (scope, at, sq) {
      scope.fx
        ..shockwave(at, Palette.gold, radius: sq * 6, width: 6)
        ..shockwave(at, _paleGold, radius: sq * 4, width: 3, delay: 0.15)
        ..flare(at, Palette.gold, size: sq * 5, life: 0.9);
    });
    _pulse(Palette.gold, 1, seconds: 5);
  }

  // ---------------------------------------------------------------------------
  // Learn mode

  void _go(int shown, {bool fromAutoplay = false}) {
    final next = shown.clamp(0, _steps.length);
    if (!fromAutoplay) _stopAutoplay();
    if (next == _shown) {
      setState(() {});
      return;
    }
    final forward = next == _shown + 1;
    setState(() {
      _forward = forward;
      _shown = next;
    });
    if (forward) _stepFx(next);
  }

  void _stepFx(int shown) {
    final step = _steps[shown - 1];
    final to = Move.parse(step.uci)?.to;
    if (step.byStudent && to != null) {
      _fxOnSquare(to, (scope, at, sq) {
        scope.fx.motes(at, Palette.gold, count: 7, radius: sq * 0.3, size: 9);
      });
    }
    if (shown == _steps.length) {
      _pulse(Palette.gold, 0.75, seconds: 2.4);
      _fxOnBoard(
        (s) => Offset(s / 2, s / 2),
        (scope, at, sq) {
          scope.fx
            ..stars(at, Palette.gold, count: 14, speed: sq * 4, size: sq * 0.4)
            ..shockwave(at, Palette.gold, radius: sq * 4.5, width: 4);
        },
        delay: const Duration(milliseconds: 420),
      );
    }
  }

  void _stopAutoplay() {
    _autoplay?.cancel();
    _autoplay = null;
  }

  void _toggleAutoplay() {
    if (_playing) {
      setState(_stopAutoplay);
      return;
    }
    if (_shown >= _steps.length) {
      _go(0);
      _scheduleAutoplay(const Duration(milliseconds: 700));
    } else {
      _scheduleAutoplay(const Duration(milliseconds: 300));
    }
    setState(() {});
  }

  void _scheduleAutoplay(Duration delay) {
    _autoplay?.cancel();
    _autoplay = Timer(delay, () {
      if (!mounted || _mode != _Mode.learn) return;
      if (_shown >= _steps.length) {
        setState(() => _autoplay = null);
        return;
      }
      _go(_shown + 1, fromAutoplay: true);
      if (_shown >= _steps.length) {
        setState(() => _autoplay = null);
      } else {
        // Time to read what was just said.
        final chars = _steps[_shown - 1].comment.length;
        _scheduleAutoplay(
          Duration(milliseconds: (1600 + chars * 30).clamp(2600, 6500)),
        );
      }
    });
  }

  void _toLearn() {
    if (_mode == _Mode.learn) return;
    _drillRun++;
    setState(() {
      _mode = _Mode.learn;
      _forward = false;
      _shown = 0;
      _badge = null;
      _wrongPosition = null;
      _wrongMove = null;
      _legal = const {};
      _cardVisible = false;
      _waiting = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Drill mode

  /// Adds a speech bubble to the drill chat; call inside setState.
  void _say(
    String text, {
    Color accent = Palette.gold,
    List<Widget> tags = const [],
  }) {
    _lines.add(
      CoachLine(
        id: 'drill-${_lineId++}',
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: tags,
              ),
              const SizedBox(height: 6),
            ],
            TypewriterText(text, style: BubbleText.body),
          ],
        ),
      ),
    );
    while (_lines.length > 3) {
      _lines.removeAt(0);
    }
  }

  Future<void> _startDrill() async {
    final course = _course;
    if (course == null) return;
    _stopAutoplay();
    final run = ++_drillRun;
    setState(() {
      _mode = _Mode.drill;
      _forward = false;
      _shown = 0;
      _misses = 0;
      _hints = 0;
      _streak = 0;
      _bestStreak = 0;
      _badge = null;
      _wrongPosition = null;
      _wrongMove = null;
      _legal = const {};
      _help.clear();
      _cardVisible = false;
      _waiting = false;
      _mood = CoachMood.neutral;
      _accent = Palette.gold;
      _lines.clear();
      _say(
        'Your turn to play the ${course.name} from memory. I\'ll take the '
        'other side.',
      );
    });
    _pulse(Palette.gold, 0.7);
    _fxOnBoard(
      (s) => Offset(s / 2, s / 2),
      (scope, at, sq) =>
          scope.fx.shockwave(at, Palette.gold, radius: sq * 6, width: 4),
      delay: const Duration(milliseconds: 60),
    );
    await _advanceOpponent(run);
  }

  /// Plays the opponent's book moves until it is the student's turn.
  Future<void> _advanceOpponent(int run) async {
    while (_shown < _steps.length && !_steps[_shown].byStudent) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || run != _drillRun || _mode != _Mode.drill) return;
      setState(() {
        _forward = true;
        _badge = null;
        _shown++;
      });
    }
    if (!mounted || run != _drillRun) return;
    if (_shown >= _steps.length) {
      await _finishDrill(run);
      return;
    }
    await _loadLegal(run);
  }

  Future<void> _loadLegal(int run) async {
    setState(() => _waiting = true);
    try {
      final legal = await client.learn.legalMoves(_fen);
      if (mounted && run == _drillRun) setState(() => _legal = legal);
    } catch (_) {
      _snack('I lost the connection for a moment. Try again.');
    } finally {
      if (mounted && run == _drillRun) setState(() => _waiting = false);
    }
  }

  Future<void> _onDrillMove(Move move) async {
    if (_mode != _Mode.drill ||
        _waiting ||
        _wrongPosition != null ||
        _shown >= _steps.length) {
      return;
    }
    final run = _drillRun;
    final ply = _shown;
    final expected = _steps[ply];
    if (move.uci == expected.uci) {
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
      final clean = (_help[ply] ?? 0) == 0;
      setState(() {
        _forward = true;
        _badge = (move.to, MoveClass.book);
        _legal = const {};
        _shown++;
        _mood = CoachMood.happy;
        _accent = clean ? Palette.gold : Palette.win;
        _say(
          expected.comment,
          accent: _accent,
          tags: [
            _Tag(
              clean ? 'BOOK MOVE' : 'THAT\'S IT',
              Palette.win,
              icon: FluentIcons.checkmark_24_regular,
            ),
            Text(_moveLabel(ply, expected.san), style: BubbleText.move),
            if (_streak >= 3)
              _Tag(
                '$_streak IN A ROW',
                Palette.goldDeep,
                icon: FluentIcons.fire_24_filled,
              ),
          ],
        );
      });
      _correctFx(move.to);
      await _advanceOpponent(run);
      return;
    }

    // Wrong: show it briefly, then take it back.
    final san = _legal[move.uci] ?? move.uci;
    final help = (_help[ply] ?? 0) + 1;
    _help[ply] = help;
    _misses++;
    _streak = 0;
    setState(() {
      _forward = true;
      _wrongPosition = _position.play(move);
      _wrongMove = move;
      _badge = (move.to, MoveClass.inaccuracy);
      _mood = CoachMood.surprised;
      _accent = _red;
      _say(switch (help) {
        1 => 'Hmm, $san isn\'t our line. What\'s the idea here?',
        2 => 'Here\'s a clue: ${expected.comment}',
        _ => 'It\'s ${expected.san} here. Follow my arrow.',
      }, accent: _red);
    });
    _wrongFx(move.to);
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted || run != _drillRun) return;
    setState(() {
      _forward = false;
      _wrongPosition = null;
      _wrongMove = null;
      _badge = null;
    });
  }

  int get _helpHere => _help[_shown] ?? 0;

  void _hint() {
    if (!_studentToMove) return;
    final expected = _steps[_shown];
    final help = max(_helpHere + 1, 2);
    _help[_shown] = help;
    _hints++;
    _streak = 0;
    setState(() {
      _mood = CoachMood.thoughtful;
      _accent = BoardArrow.idea;
      _say(
        help >= 3
            ? 'It\'s ${expected.san}. Follow my arrow.'
            : 'Think about this: ${expected.comment}',
        accent: BoardArrow.idea,
        tags: [
          _Tag(
            help >= 3 ? 'THE MOVE' : 'A CLUE',
            BoardArrow.idea,
            icon: FluentIcons.lightbulb_24_regular,
          ),
        ],
      );
    });
    _pulse(BoardArrow.idea, 0.6);
  }

  Future<void> _finishDrill(int run) async {
    final course = _course!;
    final flawless = _misses == 0 && _hints == 0;
    setState(() {
      _mode = _Mode.done;
      _legal = const {};
      _flawless = flawless;
      _mood = CoachMood.happy;
      _accent = flawless ? Palette.gold : Palette.win;
      _say(
        flawless
            ? 'Flawless! You know the ${course.name} by heart.'
            : _misses == 0
            ? 'All done, with a little help. Once more without hints?'
            : 'Done! $_misses slip${_misses == 1 ? '' : 's'} along the way. '
                  'Once more and it\'ll stick.',
        accent: _accent,
        tags: [
          _Tag(
            flawless ? 'FLAWLESS' : 'COURSE COMPLETE',
            flawless ? Palette.goldDeep : Palette.win,
            icon: FluentIcons.trophy_24_regular,
          ),
        ],
      );
      _say('Now let\'s play it out. Pick my level and we\'ll go from here.');
    });
    // Let the last move land before the big moment.
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted || run != _drillRun || _mode != _Mode.done) return;
      setState(() => _cardVisible = true);
      _celebrate(flawless);
    });
    try {
      await client.learn.completeOpening(widget.openingId);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Elsewhere

  Future<void> _playOut() async {
    final course = _course;
    if (course == null || _starting) return;
    setState(() => _starting = true);
    try {
      final game = await client.learn.startOpeningGame(
        widget.openingId,
        _level,
      );
      if (!mounted) return;
      _fx.currentState?.flash(Palette.gold);
      await Navigator.of(context).push(
        FxPageRoute<void>(
          builder: (_) => GameScreen(
            game: game,
            levels: widget.levels,
            lesson: GameLesson(
              title: course.name,
              goal: 'Play on from the main line and use its ideas',
              tips: course.ideas.take(3).toList(),
              openingPlies: _steps.length,
            ),
          ),
        ),
      );
    } catch (_) {
      _snack('I couldn\'t set up the game. Try again.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _traps() {
    final course = _course;
    if (course == null) return;
    _stopAutoplay();
    Navigator.of(context).push(
      FxPageRoute<void>(
        builder: (_) => PuzzleScreen(
          setKey: 'opening:${course.family}',
          title: '${course.name} traps',
        ),
      ),
    );
  }

  void _ask() {
    final course = _course;
    if (course == null) return;
    setState(_stopAutoplay);
    showAskCoach(
      context,
      conversationKey: 'opening-${course.id}-$_shown',
      fen: _fen,
      recentSan: [for (final s in _steps.take(_shown)) s.san],
      studentColor: course.side,
      suggestions: const [
        'Why is this move played?',
        'What are the plans for both sides?',
        'What are common mistakes here?',
      ],
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  if (_mode == _Mode.learn) _go(_shown - 1);
                },
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  if (_mode == _Mode.learn) _go(_shown + 1);
                },
                const SingleActivator(LogicalKeyboardKey.space): () {
                  if (_mode == _Mode.learn) _toggleAutoplay();
                },
              },
              child: Focus(
                autofocus: true,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final h = c.maxHeight;
                    final wide =
                        w >= Breakpoints.desktop ||
                        (w >= Breakpoints.tablet && w > h * 1.15);
                    if (_course == null) return _buildLoading(compact: !wide);
                    return wide ? _buildWide(c) : _buildColumn(c);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading({required bool compact}) {
    return Column(
      children: [
        _topBar(compact: compact),
        Expanded(
          child: Center(
            child: _error == null
                ? const CoachThinking(
                    label: 'Setting up the board',
                    color: Palette.parchment,
                  )
                : Entrance(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CoachAvatar(size: 72, mood: CoachMood.surprised),
                        const SizedBox(height: 16),
                        Text(_error!, style: Typo.display(26)),
                        const SizedBox(height: 16),
                        GhostButton(
                          label: 'Try again',
                          icon: FluentIcons.arrow_clockwise_24_regular,
                          onPressed: _load,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Phones and tablets in portrait: everything stacked, nothing scrolls.
  Widget _buildColumn(BoxConstraints c) {
    final tablet = c.maxWidth >= Breakpoints.tablet;
    final short = c.maxHeight < 700;
    final width = tablet ? min(c.maxWidth, 760.0) : c.maxWidth;
    final topBar = tablet ? 64.0 : 54.0;
    final actionHeight = tablet ? 72.0 : (short ? 56.0 : 62.0);
    final stripHeight = tablet ? 48.0 : (short ? 38.0 : 42.0);
    const progressHeight = 12.0;
    final chatMin = tablet ? 200.0 : 104.0;
    final fixed = topBar + progressHeight + stripHeight + actionHeight;
    final boardSize = min(
      width - (tablet ? 32 : 0),
      c.maxHeight - fixed - chatMin,
    ).clamp(200.0, 820.0);
    return Center(
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Entrance(
              offset: const Offset(0, -14),
              duration: const Duration(milliseconds: 500),
              child: _topBar(compact: !tablet),
            ),
            Expanded(
              child: Entrance(
                delay: const Duration(milliseconds: 220),
                offset: const Offset(-18, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 10, 2),
                  child: _chat(avatarSize: tablet ? 72 : 54),
                ),
              ),
            ),
            Entrance(
              delay: const Duration(milliseconds: 90),
              scale: 0.92,
              offset: const Offset(0, 18),
              child: _board(boardSize),
            ),
            SizedBox(
              height: progressHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(child: _progress()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _strip(stripHeight),
            ),
            Entrance(
              delay: const Duration(milliseconds: 320),
              offset: const Offset(0, 22),
              child: _bottomBar(actionHeight),
            ),
          ],
        ),
      ),
    );
  }

  /// Landscape tablets and desktops: the board, and a panel beside it.
  Widget _buildWide(BoxConstraints c) {
    final side = (c.maxWidth * 0.3).clamp(340.0, 460.0);
    const topBar = 64.0;
    final boardSize = min(
      c.maxHeight - topBar - 36,
      c.maxWidth - side - 84,
    ).clamp(260.0, 940.0);
    return Column(
      children: [
        Entrance(
          offset: const Offset(0, -14),
          duration: const Duration(milliseconds: 500),
          child: _topBar(compact: false),
        ),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Entrance(
                  delay: const Duration(milliseconds: 90),
                  scale: 0.92,
                  offset: const Offset(-24, 0),
                  child: _board(boardSize),
                ),
                const SizedBox(width: 28),
                Entrance(
                  delay: const Duration(milliseconds: 220),
                  offset: const Offset(28, 0),
                  child: SizedBox(
                    width: side,
                    height: boardSize,
                    child: _sidePanel(compact: boardSize < 470),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidePanel({required bool compact}) {
    final course = _course!;
    final learn = _mode == _Mode.learn;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            Row(
              children: [
                Text(
                  '${course.eco} · ${course.level.toUpperCase()}',
                  style: Typo.label(),
                ),
                const Spacer(),
                Text(
                  'You play ${_sideName(course.side)}',
                  style: Typo.body(12, color: Palette.muted),
                ),
              ],
            ),
            if (course.tagline.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                course.tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Typo.display(20, color: Palette.parchment),
              ),
            ],
            const SizedBox(height: 10),
          ],
          Expanded(
            flex: 6,
            child: _chat(avatarSize: compact ? 56 : 76),
          ),
          const SizedBox(height: 8),
          Container(
            height: 0.7,
            color: Palette.goldDeep.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 6),
          if (!compact) ...[
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Text(learn ? 'THE LINE' : 'YOUR MOVES', style: Typo.label()),
                  const Spacer(),
                  if (learn) ...[
                    StepButton(
                      icon: FluentIcons.chevron_left_24_regular,
                      tooltip: 'Previous move (←)',
                      onTap: _shown > 0 ? () => _go(_shown - 1) : null,
                    ),
                    StepButton(
                      icon: FluentIcons.chevron_right_24_regular,
                      tooltip: 'Next move (→)',
                      onTap: _shown < _steps.length
                          ? () => _go(_shown + 1)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: learn
                  ? MoveList(
                      sanMoves: [for (final s in _steps) s.san],
                      selectedPly: _shown - 1,
                      onTap: (ply) => _go(ply + 1),
                    )
                  : MoveList(
                      sanMoves: [for (final s in _steps.take(_shown)) s.san],
                      verdicts: _drillVerdicts,
                    ),
            ),
            const SizedBox(height: 4),
          ],
          SizedBox(height: 12, child: Center(child: _progress())),
          if (compact || !learn) _strip(compact ? 40 : 46),
          const SizedBox(height: 4),
          _bottomBar(66),
        ],
      ),
    );
  }

  Widget _topBar({required bool compact}) {
    final course = _course;
    return TopBar(
      onBack: () => Navigator.of(context).pop(),
      compact: compact,
      title: course?.name ?? 'Opening',
      titleBadge: compact ? null : course?.eco,
      subtitle: course == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (course.completed || _mode == _Mode.done) ...[
                  const Icon(
                    FluentIcons.checkmark_starburst_24_filled,
                    size: 13,
                    color: Palette.win,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    'You play ${_sideName(course.side)} · '
                    '${_capitalized(course.level)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.body(12, color: Palette.gold),
                  ),
                ),
              ],
            ),
      trailing: course == null
          ? null
          : Padding(
              padding: EdgeInsets.only(right: compact ? 6 : 0),
              child: _ModeSwitch(
                drill: _mode != _Mode.learn,
                onLearn: _toLearn,
                onDrill: () {
                  if (_mode == _Mode.learn) _startDrill();
                },
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // The coach

  Widget _chat({required double avatarSize}) {
    final learn = _mode == _Mode.learn;
    return CoachChat(
      lines: learn ? _learnLines(_course!) : List.of(_lines),
      mood: learn ? _learnMood : _mood,
      accent: learn ? _learnAccent : _accent,
      avatarSize: avatarSize,
      speaking: learn ? _playing : _mode == _Mode.done,
    );
  }

  OpeningStep? get _step => _shown == 0 ? null : _steps[_shown - 1];

  CoachMood get _learnMood {
    final step = _step;
    if (step == null || _shown >= _steps.length) return CoachMood.neutral;
    return step.arrows.isNotEmpty ? CoachMood.thoughtful : CoachMood.neutral;
  }

  Color get _learnAccent {
    final step = _step;
    if (step == null) return Palette.gold;
    if (step.arrows.isNotEmpty) return BoardArrow.idea;
    return step.byStudent ? Palette.gold : Palette.muted;
  }

  List<CoachLine> _learnLines(OpeningCourseInfo course) {
    final step = _step;
    if (step == null) {
      return [
        CoachLine(
          id: 'intro',
          accent: Palette.goldDeep,
          child: TypewriterText(course.summary, style: BubbleText.body),
        ),
        if (course.ideas.isNotEmpty)
          CoachLine(
            id: 'ideas',
            child: _Ideas(ideas: course.ideas),
          ),
      ];
    }
    return [
      CoachLine(
        id: 'step-$_shown',
        accent: _learnAccent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    _moveLabel(_shown - 1, step.san),
                    style: BubbleText.headline,
                  ),
                ),
                const SizedBox(width: 8),
                _Tag(
                  step.byStudent ? 'YOUR MOVE' : 'THEIR MOVE',
                  step.byStudent ? Palette.goldDeep : Palette.inkMuted,
                ),
                const Spacer(),
                Text('$_shown / ${_steps.length}', style: BubbleText.small),
              ],
            ),
            const SizedBox(height: 5),
            TypewriterText(step.comment, style: BubbleText.body),
          ],
        ),
      ),
      if (_shown >= _steps.length)
        CoachLine(
          id: 'end',
          accent: Palette.win,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Tag(
                'MAIN LINE DONE',
                Palette.win,
                icon: FluentIcons.flag_24_filled,
              ),
              const SizedBox(height: 6),
              TypewriterText(
                'That\'s the whole line. Ready to play it from memory?',
                style: BubbleText.body,
              ),
            ],
          ),
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Board

  Widget _board(double size) {
    final legal = <Square, Set<Square>>{};
    if (_studentToMove && !_waiting && _wrongPosition == null) {
      for (final uci in _legal.keys) {
        final m = Move.parse(uci);
        if (m != null) (legal[m.from] ??= {}).add(m.to);
      }
    }
    final arrows = <BoardArrow>[];
    final step = _step;
    if (_mode == _Mode.learn && step != null) {
      for (final a in step.arrows) {
        final arrow = BoardArrow.fromUci(a, color: BoardArrow.idea);
        if (arrow != null) arrows.add(arrow);
      }
    }
    if (_studentToMove && _helpHere >= 3) {
      final arrow = BoardArrow.fromUci(_steps[_shown].uci);
      if (arrow != null) arrows.add(arrow);
    }
    final san = _wrongPosition != null ? '' : (step?.san ?? '');
    return SizedBox(
      key: _boardKey,
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChessBoardView(
            position: _position,
            orientation: _studentSide,
            legalMoves: legal,
            lastMove: _lastMove,
            arrows: arrows,
            badge: _badge,
            inCheck: san.endsWith('+') || san.endsWith('#'),
            onMove: _onDrillMove,
            effects: _forward,
          ),
          if (_mode == _Mode.done && _cardVisible)
            Positioned.fill(
              child: _CompleteCard(
                courseName: _course!.name,
                flawless: _flawless,
                moves: _studentTotal,
                misses: _misses,
                hints: _hints,
                bestStreak: _bestStreak,
                level: _levelInfo,
                busy: _starting,
                onPlay: _playOut,
                onAgain: _startDrill,
                onLook: () => setState(() => _cardVisible = false),
              ),
            ),
        ],
      ),
    );
  }

  ChessLevel? get _levelInfo =>
      widget.levels.where((l) => l.index == _level).firstOrNull;

  Map<int, MoveClass> get _drillVerdicts => {
    for (var i = 0; i < _shown && i < _steps.length; i++)
      if (_steps[i].byStudent)
        i: (_help[i] ?? 0) == 0 ? MoveClass.book : MoveClass.inaccuracy,
  };

  // ---------------------------------------------------------------------------
  // Strips and bars

  Widget _progress() {
    if (_mode == _Mode.learn) {
      return _Progress(
        segments: [
          for (var i = 0; i < _steps.length; i++)
            i < _shown
                ? (_steps[i].byStudent ? Palette.gold : Palette.ivory)
                : null,
        ],
        current: _shown - 1,
        onTap: (i) => _go(i + 1),
      );
    }
    final student = [
      for (var i = 0; i < _steps.length; i++)
        if (_steps[i].byStudent) i,
    ];
    final next = student.indexWhere((i) => i >= _shown);
    return _Progress(
      segments: [
        for (final i in student)
          i < _shown
              ? ((_help[i] ?? 0) == 0 ? Palette.gold : Palette.loss)
              : null,
      ],
      current: next < 0 ? student.length - 1 : next,
      pulseCurrent: next >= 0,
    );
  }

  Widget _strip(double height) {
    final Widget child = switch (_mode) {
      _Mode.learn => MoveStrip(
        key: const ValueKey('learn'),
        sanMoves: [for (final s in _steps) s.san],
        selectedPly: _shown >= _steps.length ? null : _shown - 1,
        onSelect: (ply) => _go(ply == null ? _steps.length : ply + 1),
        height: height,
      ),
      _Mode.drill => _DrillStatus(
        key: const ValueKey('drill'),
        height: height,
        yourMove: _studentToMove && !_waiting,
        wrong: _wrongPosition != null,
        lastMove: _shown == 0 || _steps[_shown - 1].byStudent
            ? null
            : _moveLabel(_shown - 1, _steps[_shown - 1].san),
        made: _studentMade,
        total: _studentTotal,
        streak: _streak,
      ),
      _Mode.done => _LevelPicker(
        key: const ValueKey('done'),
        height: height,
        levels: widget.levels,
        level: _level,
        onChanged: (l) => setState(() => _level = l),
      ),
    };
    return SizedBox(
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _bottomBar(double height) {
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
      child: KeyedSubtree(
        key: ValueKey(_mode),
        child: ActionBar(height: height, items: _actions()),
      ),
    );
  }

  List<ActionItem> _actions() {
    final ask = ActionItem(
      label: 'Ask',
      icon: FluentIcons.chat_multiple_24_regular,
      tooltip: 'Ask me about this position',
      onTap: _ask,
    );
    final traps = ActionItem(
      label: 'Traps',
      icon: FluentIcons.puzzle_piece_24_regular,
      tooltip: 'Traps and tactics in this opening',
      onTap: _traps,
    );
    switch (_mode) {
      case _Mode.learn:
        final atEnd = _shown >= _steps.length;
        return [
          ActionItem(
            label: 'Restart',
            icon: FluentIcons.arrow_previous_24_regular,
            tooltip: 'Back to the starting position',
            onTap: _shown > 0 ? () => _go(0) : null,
          ),
          ActionItem(
            label: _playing ? 'Pause' : 'Auto-play',
            icon: _playing
                ? FluentIcons.pause_24_filled
                : Icons.play_arrow_rounded,
            tooltip: 'Play through the line (space)',
            highlight: _playing,
            onTap: _toggleAutoplay,
          ),
          if (atEnd)
            ActionItem(
              label: 'Drill it',
              icon: FluentIcons.dumbbell_24_regular,
              tooltip: 'Play your moves from memory',
              highlight: true,
              onTap: _startDrill,
            )
          else
            ActionItem(
              label: 'Next',
              icon: FluentIcons.next_24_regular,
              tooltip: 'Next move (→)',
              highlight: _shown == 0 && !_playing,
              onTap: () => _go(_shown + 1),
            ),
          ask,
          traps,
        ];
      case _Mode.drill:
        final help = _helpHere;
        return [
          ActionItem(
            label: 'Restart',
            icon: FluentIcons.arrow_counterclockwise_24_regular,
            tooltip: 'Start the drill again',
            onTap: _startDrill,
          ),
          ActionItem(
            label: help >= 2 ? 'Show me' : 'Hint',
            icon: FluentIcons.lightbulb_24_regular,
            tooltip: 'First a clue, then the move',
            highlight: help >= 2,
            onTap: _studentToMove && help < 3 && _wrongPosition == null
                ? _hint
                : null,
          ),
          ask,
          ActionItem(
            label: 'Learn',
            icon: FluentIcons.book_open_24_regular,
            tooltip: 'Back to the walkthrough',
            onTap: _toLearn,
          ),
          traps,
        ];
      case _Mode.done:
        return [
          ActionItem(
            label: 'Again',
            icon: FluentIcons.arrow_counterclockwise_24_regular,
            tooltip: 'Drill it again',
            onTap: _startDrill,
          ),
          ask,
          traps,
          ActionItem(
            label: 'Play it out',
            icon: FluentIcons.chess_20_regular,
            tooltip: 'Play on from here against me',
            highlight: true,
            busy: _starting,
            onTap: _playOut,
          ),
        ];
    }
  }

  String _moveLabel(int ply, String san) =>
      ply.isEven ? '${ply ~/ 2 + 1}. $san' : '${ply ~/ 2 + 1}… $san';
}

String _sideName(PlayerColor side) =>
    side == PlayerColor.white ? 'White' : 'Black';

String _capitalized(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// =============================================================================
// Pieces

/// Learn / Drill: a compact segmented pill with a sliding gold thumb.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.drill,
    required this.onLearn,
    required this.onDrill,
  });

  final bool drill;
  final VoidCallback onLearn;
  final VoidCallback onDrill;

  static const _tab = 58.0;
  static const _height = 32.0;

  @override
  Widget build(BuildContext context) {
    Widget tab(
      String label,
      IconData icon,
      bool selected,
      VoidCallback onTap,
    ) => Pressable(
      onTap: onTap,
      scale: 0.9,
      child: SizedBox(
        width: _tab,
        height: _height - 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Palette.onyx : Palette.parchment,
            ),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: Typo.body(
                12,
                color: selected ? Palette.onyx : Palette.parchment,
                weight: FontWeight.w800,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
    return Container(
      width: _tab * 2 + 8,
      height: _height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.6)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            left: drill ? _tab + 2 : 0,
            top: 0,
            bottom: 0,
            width: _tab,
            child: Shine(
              period: const Duration(milliseconds: 4200),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_paleGold, Palette.gold, Palette.goldDeep],
                  ),
                  boxShadow: [
                    BoxShadow(color: Palette.goldGlow, blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              tab('Learn', FluentIcons.book_open_24_regular, !drill, onLearn),
              const SizedBox(width: 2),
              tab('Drill', FluentIcons.dumbbell_24_regular, drill, onDrill),
            ],
          ),
        ],
      ),
    );
  }
}

/// A row of segments, one per move; null segments are still to come.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.segments,
    required this.current,
    this.onTap,
    this.pulseCurrent = false,
  });

  final List<Color?> segments;
  final int current;
  final void Function(int index)? onTap;
  final bool pulseCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < segments.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: MouseRegion(
                cursor: onTap == null
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: _Segment(
                    color: segments[i],
                    current: i == current,
                    pulse: pulseCurrent && i == current,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.color,
    required this.current,
    required this.pulse,
  });

  final Color? color;
  final bool current;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final lit = color != null;
    final bar = AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      height: current ? 6 : 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color ?? Colors.white.withValues(alpha: 0.08),
        boxShadow: [
          if (lit && current)
            BoxShadow(color: color!.withValues(alpha: 0.7), blurRadius: 10),
        ],
      ),
    );
    return pulse ? const _PulseSegment() : bar;
  }
}

/// The segment of the move the student has to find, breathing.
class _PulseSegment extends StatefulWidget {
  const _PulseSegment();

  @override
  State<_PulseSegment> createState() => _PulseSegmentState();
}

class _PulseSegmentState extends State<_PulseSegment>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
      builder: (context, _) => Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Palette.ivory.withValues(alpha: 0.12 + 0.3 * _c.value),
          border: Border.all(color: Palette.gold.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Palette.gold.withValues(alpha: 0.5 * _c.value),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Your move" / "My move" and the drill's score, in the strip slot.
class _DrillStatus extends StatelessWidget {
  const _DrillStatus({
    super.key,
    required this.height,
    required this.yourMove,
    required this.wrong,
    required this.lastMove,
    required this.made,
    required this.total,
    required this.streak,
  });

  final double height;
  final bool yourMove;
  final bool wrong;
  final String? lastMove;
  final int made;
  final int total;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final Widget status;
    if (wrong) {
      status = Text(
        'Not that one…',
        key: const ValueKey('wrong'),
        style: Typo.body(13.5, color: Palette.loss, weight: FontWeight.w800),
      );
    } else if (yourMove) {
      status = Text.rich(
        TextSpan(
          children: [
            if (lastMove != null)
              TextSpan(
                text: 'I played $lastMove · ',
                style: Typo.body(13, color: Palette.parchment),
              ),
            TextSpan(
              text: 'Your move',
              style: Typo.body(
                13.5,
                color: Palette.gold,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
        key: ValueKey('you-$lastMove'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      status = const CoachThinking(
        key: ValueKey('me'),
        label: 'My move',
        color: Palette.parchment,
      );
    }
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            _Dot(color: wrong ? Palette.loss : Palette.gold, live: yourMove),
            const SizedBox(width: 9),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: status,
              ),
            ),
            if (streak >= 2) ...[
              Entrance(
                key: ValueKey('streak-$streak'),
                scale: 0.4,
                offset: Offset.zero,
                duration: const Duration(milliseconds: 450),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FluentIcons.fire_24_filled,
                      size: 16,
                      color: Color(0xFFF0A040),
                    ),
                    Text(
                      '×$streak',
                      style: Typo.body(
                        13,
                        color: const Color(0xFFF0A040),
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              '$made / $total',
              style: Typo.mono(13.5, color: Palette.ivory),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.live});

  final Color color;
  final bool live;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
        final t = widget.live ? _c.value : 0.3;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 + 0.5 * t),
                blurRadius: 4 + 9 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ‹ level › for the play-out game.
class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    super.key,
    required this.height,
    required this.levels,
    required this.level,
    required this.onChanged,
  });

  final double height;
  final List<ChessLevel> levels;
  final int level;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final i = levels.indexWhere((l) => l.index == level);
    final current = i < 0 ? null : levels[i];
    return SizedBox(
      height: height,
      child: Row(
        children: [
          StepButton(
            icon: FluentIcons.chevron_left_24_regular,
            tooltip: 'Easier',
            onTap: i > 0 ? () => onChanged(levels[i - 1].index) : null,
          ),
          Expanded(
            child: Tooltip(
              message: current?.description ?? '',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PLAY IT OUT AGAINST ME AS', style: Typo.label(size: 9)),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: a, child: child),
                    ),
                    child: Text(
                      current == null
                          ? '—'
                          : '${current.name} · ≈${current.rating}',
                      key: ValueKey(level),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.body(
                        14,
                        color: Palette.ivory,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StepButton(
            icon: FluentIcons.chevron_right_24_regular,
            tooltip: 'Stronger',
            onTap: i >= 0 && i < levels.length - 1
                ? () => onChanged(levels[i + 1].index)
                : null,
          ),
        ],
      ),
    );
  }
}

/// A small label chip for inside a speech bubble (dark ink on paper).
class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color, {this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(color, Palette.ink, 0.45)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: ink),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Typo.body(
              10,
              color: ink,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

/// "Why it works": the opening's ideas, ticking in one by one.
class _Ideas extends StatelessWidget {
  const _Ideas({required this.ideas});

  final List<String> ideas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHY IT WORKS',
          style: Typo.label(color: Palette.goldDeep, size: 10),
        ),
        const SizedBox(height: 6),
        for (final (i, idea) in ideas.indexed)
          Entrance(
            delay: Duration(milliseconds: 450 + i * 160),
            offset: const Offset(-10, 0),
            duration: const Duration(milliseconds: 480),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      FluentIcons.checkmark_circle_24_filled,
                      size: 15,
                      color: Palette.goldDeep,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      idea,
                      style: Typo.body(
                        13.5,
                        color: Palette.ink,
                        weight: FontWeight.w600,
                      ).copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The big moment over the board when the drill is done.
class _CompleteCard extends StatelessWidget {
  const _CompleteCard({
    required this.courseName,
    required this.flawless,
    required this.moves,
    required this.misses,
    required this.hints,
    required this.bestStreak,
    required this.level,
    required this.busy,
    required this.onPlay,
    required this.onAgain,
    required this.onLook,
  });

  final String courseName;
  final bool flawless;
  final int moves;
  final int misses;
  final int hints;
  final int bestStreak;
  final ChessLevel? level;
  final bool busy;
  final VoidCallback onPlay;
  final VoidCallback onAgain;
  final VoidCallback onLook;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, int i) => Entrance(
      delay: Duration(milliseconds: 380 + i * 110),
      scale: 0.6,
      offset: const Offset(0, 10),
      duration: const Duration(milliseconds: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoldText(value, style: Typo.display(34)),
          const SizedBox(height: 2),
          Text(label, style: Typo.label(size: 9.5, color: Palette.parchment)),
        ],
      ),
    );

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
                Positioned(
                  top: -150,
                  child: SizedBox(
                    width: 480,
                    height: 480,
                    child: LightRays(
                      color: Palette.gold,
                      opacity: flawless ? 0.5 : 0.38,
                      rays: 18,
                    ),
                  ),
                ),
                Panel(
                  highlight: true,
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Entrance(
                        offset: const Offset(0, -8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              FluentIcons.trophy_24_regular,
                              size: 16,
                              color: Palette.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              flawless
                                  ? 'FLAWLESS RUN'
                                  : courseName.toUpperCase(),
                              style: Typo.label(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Entrance(
                        delay: const Duration(milliseconds: 120),
                        scale: 0.7,
                        offset: Offset.zero,
                        child: Shine(
                          child: GoldText(
                            'Course complete',
                            align: TextAlign.center,
                            style: Typo.display(54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          stat('$moves', 'MOVES', 0),
                          const SizedBox(width: 26),
                          stat('$misses', misses == 1 ? 'SLIP' : 'SLIPS', 1),
                          const SizedBox(width: 26),
                          stat(
                            hints > 0 ? '$hints' : '$bestStreak',
                            hints > 0
                                ? (hints == 1 ? 'HINT' : 'HINTS')
                                : 'BEST RUN',
                            2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Entrance(
                        delay: const Duration(milliseconds: 720),
                        offset: const Offset(0, 14),
                        child: Shine(
                          period: const Duration(milliseconds: 2800),
                          child: GoldButton(
                            label: 'Play it out',
                            icon: FluentIcons.chess_20_regular,
                            busy: busy,
                            onPressed: onPlay,
                          ),
                        ),
                      ),
                      if (level != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Against me as ${level!.name} · ≈${level!.rating}',
                          style: Typo.body(12, color: Palette.muted),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        children: [
                          TextAction(label: 'Drill again', onTap: onAgain),
                          TextAction(label: 'See board', onTap: onLook),
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
