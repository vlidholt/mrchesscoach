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
import '../widgets/fx.dart';
import '../widgets/game_panels.dart' show ActionBar, ActionItem;
import '../widgets/move_badge.dart';
import 'game_screen.dart' show TopBar;

/// The set key of the mistake trainer.
const mistakesSetKey = 'mistakes';

enum _Phase {
  loading,
  intro,
  solving,
  checking,
  wrong,
  solved,
  revealed,
  empty,
}

const _red = Color(0xFFD9443E);

/// One thing the coach said about the current puzzle.
class _Msg {
  const _Msg(
    this.id,
    this.text, {
    this.accent = Palette.gold,
    this.chip,
    this.chipColor = Palette.goldDeep,
    this.themes = const [],
    this.footnote,
  });

  final int id;
  final String text;
  final Color accent;
  final String? chip;
  final Color chipColor;
  final List<String> themes;
  final String? footnote;
}

/// Rated puzzles from a set, or the player's own mistakes to fix.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.setKey, required this.title});

  /// A puzzle set key, or [mistakesSetKey].
  final String setKey;
  final String title;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  _Phase _phase = _Phase.loading;
  String? _error;

  BoardState _position = BoardState.initial;
  BoardState? _before;
  Move? _lastMove;
  Move? _lastMoveBefore;
  Side _orientation = Side.white;
  Map<String, String> _legal = const {};
  bool _inCheck = false;

  PuzzleInfo? _puzzle;
  MistakeDrill? _drill;
  List<String> _solution = const [];
  String? _wrongSan;

  /// The legal moves to restore once a wrong move has been taken back.
  Map<String, String> _retryLegal = const {};
  bool _revertPending = false;

  int? _rating;
  int? _ratingDelta;
  int _streak = 0;
  int _solvedThisSession = 0;

  /// Moves found so far in the current puzzle.
  int _found = 0;
  int _hintLevel = 0;
  bool _failed = false;
  bool _milestone = false;

  /// Bumped for every new puzzle, so late work for an old one is dropped.
  int _round = 0;

  final _chat = <_Msg>[];
  int _msgId = 0;
  CoachMood _mood = CoachMood.neutral;
  Color _accent = Palette.gold;
  String? _explanation;
  bool _explaining = false;
  (Square, MoveClass)? _badge;
  List<BoardArrow> _arrows = const [];

  final _fx = GlobalKey<FxScopeState>();
  final _boardKey = GlobalKey();
  Color _tint = Palette.gold;
  double _intensity = 0.3;
  Timer? _tintTimer;

  bool get _mistakes => widget.setKey == mistakesSetKey;
  bool get _done => _phase == _Phase.solved || _phase == _Phase.revealed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tintTimer?.cancel();
    super.dispose();
  }

  /// Adds a bubble to the chat. Call inside [setState].
  void _say(
    String text, {
    Color accent = Palette.gold,
    CoachMood mood = CoachMood.neutral,
    String? chip,
    Color chipColor = Palette.goldDeep,
    List<String> themes = const [],
    String? footnote,
  }) {
    _chat.add(
      _Msg(
        ++_msgId,
        text,
        accent: accent,
        chip: chip,
        chipColor: chipColor,
        themes: themes,
        footnote: footnote,
      ),
    );
    if (_chat.length > 5) _chat.removeAt(0);
    _mood = mood;
    _accent = accent;
  }

  // ---------------------------------------------------------------------------
  // Loading

  Future<void> _load() async {
    final round = ++_round;
    setState(() {
      _phase = _Phase.loading;
      _error = null;
      _badge = null;
      _arrows = const [];
      _explanation = null;
      _explaining = false;
      _wrongSan = null;
      _ratingDelta = null;
      _solution = const [];
      _legal = const {};
      _found = 0;
      _hintLevel = 0;
      _failed = false;
      _milestone = false;
      _inCheck = false;
      _revertPending = false;
      _chat.clear();
      _mood = CoachMood.thoughtful;
      _accent = Palette.gold;
    });
    try {
      if (_mistakes) {
        await _loadMistake(round);
      } else {
        await _loadPuzzle(round);
      }
    } on ChessGameException catch (e) {
      if (!mounted || round != _round) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.empty;
      });
    } catch (_) {
      if (!mounted || round != _round) return;
      setState(() {
        _error =
            'I couldn\'t reach the server. Check your connection and '
            'try again.';
        _phase = _Phase.empty;
      });
    }
  }

  Future<void> _loadPuzzle(int round) async {
    final puzzle = await client.learn.nextPuzzle(widget.setKey);
    if (!mounted || round != _round) return;
    final start = BoardState.fromFen(puzzle.fen);
    setState(() {
      _puzzle = puzzle;
      _rating ??= puzzle.playerRating;
      _position = start;
      _lastMove = null;
      _orientation = start.turn.opposite;
      _legal = const {};
      _phase = _Phase.intro;
      _say('Here\'s one for you. Watch their move…');
    });
    _arrivalFx();
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted || round != _round) return;
    final setup = Move.parse(puzzle.setupMove)!;
    setState(() {
      _position = _position.play(setup);
      _lastMove = setup;
      _legal = puzzle.legalMoves;
      _phase = _Phase.solving;
      final side = _orientation == Side.white ? 'White' : 'Black';
      _say(
        puzzle.solutionMoves > 1
            ? 'Your move, $side. It takes ${puzzle.solutionMoves} good moves '
                  'to crack this one.'
            : 'Your move, $side. One move does it. Can you find it?',
      );
    });
  }

  Future<void> _loadMistake(int round) async {
    final drill = await client.learn.nextMistake();
    if (!mounted || round != _round) return;
    if (drill == null) {
      setState(() {
        _drill = null;
        _phase = _Phase.empty;
      });
      return;
    }
    final position = BoardState.fromFen(drill.fen);
    final label = drill.classification.label.toLowerCase();
    final article = 'aeiou'.contains(label[0]) ? 'an' : 'a';
    setState(() {
      _drill = drill;
      _position = position;
      _lastMove = null;
      _orientation = position.turn;
      _legal = drill.legalMoves;
      _phase = _Phase.solving;
      _say(
        'In your game you played ${drill.playedSan} here, $article $label. '
        'Let\'s find something stronger.',
        accent: drill.classification.color,
        mood: CoachMood.thoughtful,
        chip: 'FROM YOUR GAME',
        chipColor: drill.classification.color,
      );
    });
    _arrivalFx();
  }

  // ---------------------------------------------------------------------------
  // Moves

  Future<void> _onMove(Move move) async {
    if (_phase != _Phase.solving) return;
    final san = _legal[move.uci];
    if (san == null) return;
    final round = _round;
    final legal = _legal;
    setState(() {
      _before = _position;
      _lastMoveBefore = _lastMove;
      _position = _position.play(move);
      _lastMove = move;
      _inCheck = san.endsWith('+') || san.endsWith('#');
      _legal = const {};
      _arrows = const [];
      _phase = _Phase.checking;
      _mood = CoachMood.thoughtful;
    });
    try {
      if (_mistakes) {
        await _checkMistake(move, san, round);
      } else {
        await _checkPuzzle(move, san, round);
      }
    } catch (_) {
      if (!mounted || round != _round) return;
      setState(() {
        _position = _before!;
        _lastMove = _lastMoveBefore;
        _inCheck = false;
        _phase = _Phase.solving;
        _legal = legal;
        _mood = CoachMood.neutral;
      });
      _snack('I couldn\'t reach the server. Try that move again.');
    }
  }

  Future<void> _checkPuzzle(Move move, String san, int round) async {
    final puzzle = _puzzle!;
    final result = await client.learn.puzzleMove(puzzle.id, move.uci);
    if (!mounted || round != _round) return;
    final delta = result.ratingAfter - result.ratingBefore;
    if (result.correct && result.solved) {
      final streak = result.streak;
      final milestone = streak >= 3 && (streak == 3 || streak % 5 == 0);
      final perfect = !_failed && _hintLevel == 0;
      setState(() {
        _badge = (move.to, MoveClass.best);
        _streak = streak;
        _phase = _Phase.solved;
        _solvedThisSession++;
        _found = puzzle.solutionMoves;
        _milestone = milestone;
        if (delta != 0) {
          _ratingDelta = delta;
          _rating = result.ratingAfter;
        }
        _say(
          _praise(san, streak: milestone ? streak : null),
          accent: Palette.win,
          mood: CoachMood.happy,
          chip: delta > 0 ? 'SOLVED · +$delta' : 'SOLVED',
          chipColor: Palette.win,
          themes: _themeLabels,
          footnote: _footnote,
        );
      });
      _celebrate(move.to, milestone: milestone, perfect: perfect);
      return;
    }
    if (result.correct) {
      setState(() {
        _badge = (move.to, MoveClass.great);
        _streak = result.streak;
        _found++;
        _say(
          'Yes! Now keep the pressure on.',
          accent: MoveClass.great.color,
          mood: CoachMood.happy,
          chip: 'MOVE $_found OF ${puzzle.solutionMoves}',
          chipColor: MoveClass.great.color,
        );
      });
      _pulse(MoveClass.great.color, 0.7);
      _boardFx(move.to, (s, at, cell) {
        s.fx
          ..sparks(at, Palette.gold, count: 22, speed: 300, gravity: 500)
          ..stars(at, MoveClass.great.color, count: 8, size: cell * 0.4);
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || round != _round) return;
      final reply = Move.parse(result.replyUci!)!;
      setState(() {
        _badge = null;
        _position = _position.play(reply);
        _lastMove = reply;
        _inCheck = false;
        _legal = result.legalMoves ?? const {};
        _phase = _Phase.solving;
        _mood = CoachMood.neutral;
      });
      return;
    }
    setState(() {
      _badge = (move.to, MoveClass.blunder);
      _phase = _Phase.wrong;
      _wrongSan = san;
      _solution = result.solution ?? const [];
      _streak = 0;
      _failed = true;
      _retryLegal = result.legalMoves ?? const {};
      _revertPending = true;
      if (delta != 0) {
        _ratingDelta = delta;
        _rating = result.ratingAfter;
      }
      _say(
        'Ooh, not quite: $san doesn\'t work here. Try again, or ask me why.',
        accent: MoveClass.blunder.color,
        mood: CoachMood.surprised,
      );
    });
    _fx.currentState?.shake(5);
    _pulse(_red, 0.75, seconds: 2.2);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || round != _round) return;
    _revert();
  }

  Future<void> _checkMistake(Move move, String san, int round) async {
    final drill = _drill!;
    final result = await client.learn.mistakeMove(drill.analysisId, move.uci);
    if (!mounted || round != _round) return;
    final explanation = result.explanation.isEmpty ? null : result.explanation;
    if (result.correct) {
      final streak = _streak + 1;
      final milestone = streak >= 3 && (streak == 3 || streak % 5 == 0);
      final perfect = _hintLevel == 0;
      setState(() {
        _badge = (move.to, MoveClass.best);
        _phase = _Phase.solved;
        _streak = streak;
        _milestone = milestone;
        _solvedThisSession++;
        _explanation = explanation;
        _say(
          san == result.bestSan
              ? 'Exactly! $san is the move you missed in the game.'
              : 'Good! $san is just as strong as my pick, ${result.bestSan}.',
          accent: Palette.win,
          mood: CoachMood.happy,
          chip: milestone ? 'FIXED · $streak IN A ROW' : 'FIXED',
          chipColor: Palette.win,
        );
        if (explanation != null) {
          _say(
            explanation,
            mood: CoachMood.happy,
            chip: 'THE IDEA',
            chipColor: Palette.goldDeep,
          );
        }
      });
      _celebrate(move.to, milestone: milestone, perfect: perfect);
      return;
    }
    setState(() {
      _badge = (move.to, MoveClass.mistake);
      _phase = _Phase.revealed;
      _streak = 0;
      _explanation = explanation;
      _say(
        'Close, but not this time. My pick here is ${result.bestSan}.',
        accent: MoveClass.mistake.color,
        mood: CoachMood.surprised,
      );
      if (explanation != null) {
        _say(
          explanation,
          accent: BoardArrow.best,
          mood: CoachMood.surprised,
          chip: 'THE IDEA',
          chipColor: BoardArrow.best,
        );
      }
    });
    _fx.currentState?.shake(4);
    _pulse(MoveClass.mistake.color, 0.65, seconds: 2);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || round != _round) return;
    setState(() {
      _position = _before!;
      _lastMove = _lastMoveBefore;
      _inCheck = false;
      _badge = null;
      _mood = CoachMood.thoughtful;
      _arrows = [?BoardArrow.fromUci(result.bestUci, color: BoardArrow.best)];
    });
  }

  /// Takes back a wrong move, if it is still on the board.
  void _revert() {
    if (!_revertPending) return;
    setState(() {
      _revertPending = false;
      _position = _before!;
      _lastMove = _lastMoveBefore;
      _inCheck = false;
      _badge = null;
      _legal = _retryLegal;
    });
  }

  void _retry() {
    _revert();
    setState(() {
      _phase = _Phase.solving;
      _badge = null;
      _say('Take your time. Checks, captures, threats: look at all of them.');
    });
    _boardFx(null, (s, at, cell) {
      s.fx.shockwave(at, Palette.gold, radius: cell * 5, width: 3, life: 0.5);
    });
  }

  void _hint() {
    if (_phase != _Phase.solving || _hintLevel >= 2) return;
    setState(() {
      _hintLevel++;
      _say(
        _hintText(_hintLevel),
        accent: BoardArrow.idea,
        mood: CoachMood.thoughtful,
        chip: 'HINT $_hintLevel OF 2',
        chipColor: BoardArrow.idea,
      );
    });
    _pulse(BoardArrow.idea, 0.55);
    _boardFx(null, (s, at, cell) {
      s.fx.motes(
        at,
        BoardArrow.idea,
        count: 18,
        radius: cell * 3.5,
        size: cell * 0.4,
        rise: 60,
      );
    });
  }

  String _hintText(int level) {
    if (_mistakes) {
      final played = _drill?.playedSan ?? 'your move';
      return level == 1
          ? 'Start with checks, captures and threats, for both sides.'
          : 'Ask yourself what $played allowed in the game. Find the move '
                'that stops it, or does something even stronger.';
    }
    final themes = _puzzle?.themes ?? const <String>[];
    final mate = themes.any((t) => t.startsWith('mateIn'));
    if (level == 1) {
      return mate
          ? 'There\'s a forced mate here. Try every check first.'
          : 'Start with forcing moves: checks, captures and threats. One of '
                'them works.';
    }
    for (final entry in _themeHints.entries) {
      if (themes.contains(entry.key)) return entry.value;
    }
    return 'Look at which of their pieces are short of defenders.';
  }

  Future<void> _explainMiss() async {
    final puzzle = _puzzle;
    if (puzzle == null || _explaining) return;
    final round = _round;
    final wrong = _wrongSan;
    setState(() {
      _explaining = true;
      _mood = CoachMood.thoughtful;
    });
    try {
      final text = await client.learn.explainPuzzle(puzzle.id);
      if (!mounted || round != _round) return;
      setState(() {
        _explanation = text;
        _say(
          text,
          accent: BoardArrow.idea,
          mood: CoachMood.thoughtful,
          chip: wrong == null ? 'WHY' : 'WHY NOT $wrong',
          chipColor: BoardArrow.idea,
        );
      });
    } catch (_) {
      _snack('I couldn\'t put it into words just now. Try again in a moment.');
    } finally {
      if (mounted && round == _round) setState(() => _explaining = false);
    }
  }

  Future<void> _showSolution() async {
    final moves = _solution;
    if (moves.isEmpty) return;
    final round = _round;
    _revert();
    setState(() {
      _phase = _Phase.revealed;
      _legal = const {};
      _say(
        'Here\'s the solution. Watch the idea unfold.',
        accent: BoardArrow.best,
        mood: CoachMood.thoughtful,
      );
    });
    _pulse(BoardArrow.best, 0.5, seconds: 2.5);
    for (final (i, uci) in moves.indexed) {
      final move = Move.parse(uci)!;
      setState(() {
        _arrows = [BoardArrow(move.from, move.to, color: BoardArrow.best)];
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || round != _round) return;
      setState(() {
        _position = _position.play(move);
        _lastMove = move;
        _arrows = const [];
        _badge = i.isEven ? (move.to, MoveClass.best) : null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || round != _round) return;
    }
    setState(() {
      _say(
        'That\'s the idea. Ready for the next one?',
        accent: Palette.gold,
        themes: _themeLabels,
        footnote: _footnote,
      );
    });
  }

  void _ask() {
    showAskCoach(
      context,
      conversationKey: 'puzzle-${_puzzle?.id ?? _drill?.analysisId}',
      fen: _currentFen,
      studentColor: _orientation == Side.white
          ? PlayerColor.white
          : PlayerColor.black,
      suggestions: const [
        'What is the idea here?',
        'Why does my move fail?',
        'Which pieces are undefended?',
      ],
    );
  }

  /// A FEN for the coach. Castling and en passant details are not tracked
  /// on the client, so they are left out.
  String get _currentFen {
    final rows = <String>[];
    for (var rank = 7; rank >= 0; rank--) {
      var row = '';
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final p = _position.pieceAt(Square.fromCoords(file, rank));
        if (p == null) {
          empty++;
          continue;
        }
        if (empty > 0) row += '$empty';
        empty = 0;
        row += p.color == Side.white
            ? p.role.letter.toUpperCase()
            : p.role.letter;
      }
      if (empty > 0) row += '$empty';
      rows.add(row);
    }
    final turn = _position.turn == Side.white ? 'w' : 'b';
    return '${rows.join('/')} $turn - - 0 1';
  }

  List<String> get _themeLabels => [
    for (final t in _puzzle?.themes ?? const <String>[]) ?_themeNames[t],
  ];

  String? get _footnote {
    final puzzle = _puzzle;
    if (_mistakes || puzzle == null) return null;
    return 'Puzzle rated ${puzzle.rating} · from the Lichess puzzle database';
  }

  String _praise(String san, {int? streak}) {
    const lines = [
      'Brilliant! That\'s the one.',
      'Yes! Nicely calculated.',
      'Spot on!',
      'Lovely, that wins.',
      'Yes! Clean and precise.',
    ];
    final line = lines[Random().nextInt(lines.length)];
    return streak != null
        ? '$line That\'s $streak in a row!'
        : '$line $san does it.';
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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

  /// Fires [effect] at [square] on the board (its centre when null).
  void _boardFx(
    Square? square,
    void Function(FxScopeState scope, Offset at, double cell) effect,
  ) {
    final ctx = _boardKey.currentContext;
    final size = ctx?.size?.width ?? 0;
    if (ctx == null || size <= 0) return;
    final cell = boardSquareSize(size);
    final local = square == null
        ? Offset(size / 2, size / 2)
        : boardSquareCenter(square, size, _orientation);
    ctx.fx(local, (s, at) => effect(s, at, cell));
  }

  /// A soft ring of light as a new position lands on the board.
  void _arrivalFx() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _boardFx(null, (s, at, cell) {
        s.fx
          ..shockwave(at, Palette.gold, radius: cell * 6.5, width: 4, life: 0.7)
          ..motes(
            at,
            Palette.gold,
            count: 14,
            radius: cell * 3.5,
            size: cell * 0.3,
            rise: 50,
          );
      });
    });
  }

  void _celebrate(
    Square square, {
    required bool milestone,
    required bool perfect,
  }) {
    _pulse(Palette.gold, 1, seconds: milestone ? 4.5 : 3.2);
    // After the piece has landed and the board's own verdict flare.
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _boardFx(square, (s, at, cell) {
        s.fx
          ..flare(at, Palette.gold, size: cell * 5.5, life: 0.9)
          ..stars(at, Palette.gold, count: 26, speed: 340, size: cell * 0.5)
          ..sparks(
            at,
            const Color(0xFFFFE2A8),
            count: 60,
            speed: 560,
            gravity: 520,
            life: 1.1,
          );
      });
      _boardFx(null, (s, at, cell) {
        s.fx
          ..shockwave(
            at,
            Palette.gold,
            radius: cell * 7,
            width: cell * 0.14,
            life: 0.8,
          )
          ..shockwave(
            at,
            Colors.white,
            radius: cell * 4.5,
            width: cell * 0.06,
            delay: 0.12,
          )
          ..motes(
            at,
            Palette.gold,
            count: 22,
            radius: cell * 3.5,
            size: cell * 0.35,
            rise: 70,
          );
      });
      final fx = _fx.currentState;
      if (fx == null) return;
      fx.flash(Palette.gold);
      final size = fx.size;
      if (milestone) {
        fx.fx.confetti(Offset.zero & size, count: 170);
        final rnd = Random();
        for (var i = 0; i < 4; i++) {
          fx.fx.firework(
            Offset(
              size.width * (0.15 + 0.7 * rnd.nextDouble()),
              size.height * (0.1 + 0.3 * rnd.nextDouble()),
            ),
            [
              Palette.gold,
              MoveClass.brilliant.color,
              const Color(0xFFF1D79B),
            ][i % 3],
            delay: 0.3 + i * 0.35,
          );
        }
      } else if (perfect) {
        fx.fx.confetti(
          Offset.zero & size,
          count: 70,
          colors: const [Palette.gold, Color(0xFFF1D79B), Palette.ivory],
        );
      }
    });
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
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final wide =
                    w >= Breakpoints.desktop ||
                    (w >= Breakpoints.tablet && w > h * 1.15);
                if (_phase == _Phase.empty) return _emptyState(compact: !wide);
                return wide ? _buildWide(c) : _buildColumn(c);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Phones and tablets in portrait: everything stacked, nothing scrolls.
  Widget _buildColumn(BoxConstraints c) {
    final tablet = c.maxWidth >= Breakpoints.tablet;
    final width = tablet ? min(c.maxWidth, 760.0) : c.maxWidth;
    final topBar = tablet ? 64.0 : 54.0;
    final actionHeight = tablet ? 72.0 : 62.0;
    final stripHeight = tablet ? 44.0 : 38.0;
    final chatMin = tablet ? 200.0 : 104.0;
    final fixed = topBar + stripHeight + actionHeight;
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
              offset: const Offset(0, -16),
              child: _topBar(compact: !tablet, flame: true),
            ),
            Expanded(
              child: Entrance(
                delay: const Duration(milliseconds: 90),
                offset: const Offset(-24, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 10, 2),
                  child: _coachChat(avatarSize: tablet ? 72 : 54),
                ),
              ),
            ),
            Entrance(
              delay: const Duration(milliseconds: 160),
              offset: Offset.zero,
              scale: 0.92,
              child: _board(boardSize),
            ),
            Entrance(
              delay: const Duration(milliseconds: 240),
              offset: const Offset(0, 12),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tablet ? 24 : 16),
                child: _infoStrip(height: stripHeight),
              ),
            ),
            Entrance(
              delay: const Duration(milliseconds: 320),
              offset: const Offset(0, 24),
              child: _bottomBar(actionHeight),
            ),
          ],
        ),
      ),
    );
  }

  /// Landscape tablets and desktops: the board, and a panel beside it.
  Widget _buildWide(BoxConstraints c) {
    final side = (c.maxWidth * 0.3).clamp(340.0, 440.0);
    const topBar = 64.0;
    final boardSize = min(
      c.maxHeight - topBar - 32,
      c.maxWidth - side - 80,
    ).clamp(280.0, 940.0);
    return Column(
      children: [
        Entrance(
          offset: const Offset(0, -16),
          child: _topBar(compact: false, flame: false),
        ),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Entrance(
                  delay: const Duration(milliseconds: 100),
                  offset: const Offset(-30, 0),
                  scale: 0.94,
                  child: _board(boardSize),
                ),
                const SizedBox(width: 28),
                Entrance(
                  delay: const Duration(milliseconds: 200),
                  offset: const Offset(36, 0),
                  child: SizedBox(
                    width: side,
                    height: boardSize,
                    child: _sidePanel(tall: boardSize >= 460),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidePanel({required bool tall}) {
    final showNext = tall && _done;
    return Panel(
      highlight: _phase == _Phase.solved,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tall) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mistakes ? 'MISTAKE TRAINER' : 'PUZZLE TRAINER',
                        style: Typo.label(size: 10),
                      ),
                      const SizedBox(height: 4),
                      GoldText(
                        widget.title,
                        style: Typo.display(28),
                      ),
                    ],
                  ),
                ),
                _StreakFlame(streak: _streak),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _infoStrip(height: 40, flame: !tall),
          const SizedBox(height: 8),
          Container(
            height: 0.7,
            color: Palette.goldDeep.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Expanded(child: _coachChat(avatarSize: tall ? 76 : 56)),
          if (showNext)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Entrance(
                key: ValueKey('next-$_round'),
                delay: const Duration(milliseconds: 500),
                offset: const Offset(0, 14),
                scale: 0.85,
                child: Shine(
                  child: GoldButton(
                    label: _mistakes ? 'Next position' : 'Next puzzle',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _load,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          _bottomBar(64, includeNext: !showNext),
        ],
      ),
    );
  }

  Widget _topBar({required bool compact, required bool flame}) {
    final puzzle = _puzzle;
    final drill = _drill;
    return TopBar(
      onBack: () => Navigator.of(context).pop(),
      compact: compact,
      title: widget.title,
      titleBadge: _mistakes
          ? (drill == null ? null : '${drill.remaining} to fix')
          : (puzzle == null ? null : 'Puzzle ${puzzle.rating}'),
      subtitle: _statusLine(),
      trailing: flame
          ? Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _StreakFlame(streak: _streak, compact: true),
            )
          : null,
    );
  }

  Widget _statusLine() {
    final side = _position.turn == Side.white ? 'White' : 'Black';
    final total = _puzzle?.solutionMoves ?? 1;
    final (text, color) = switch (_phase) {
      _Phase.loading => ('Setting up…', Palette.muted),
      _Phase.intro => ('Watch their move', Palette.parchment),
      _Phase.solving =>
        _mistakes || total == 1
            ? ('$side to move', Palette.gold)
            : ('$side to move · ${total - _found} to find', Palette.gold),
      _Phase.checking => ('Checking…', Palette.parchment),
      _Phase.wrong => ('Not quite. Try again', MoveClass.blunder.color),
      _Phase.solved => (_mistakes ? 'Fixed!' : 'Solved!', Palette.win),
      _Phase.revealed => ('Solution shown', BoardArrow.best),
      _Phase.empty => ('', Palette.muted),
    };
    final dot = _position.turn == Side.white
        ? Palette.ivory
        : const Color(0xFF2A2520);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(text),
        children: [
          if (_phase == _Phase.solving) ...[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot,
                border: Border.all(color: Palette.goldDeep),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Typo.body(12, color: color, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachChat({required double avatarSize}) {
    final thinking = switch (_phase) {
      _Phase.loading =>
        _mistakes ? 'Finding a moment from your games' : 'Picking one for you',
      _Phase.checking => 'Let me see',
      _ => _explaining ? 'Let me explain' : null,
    };
    return CoachChat(
      avatarSize: avatarSize,
      mood: _mood,
      accent: _accent,
      speaking:
          _explaining ||
          _phase == _Phase.wrong ||
          _phase == _Phase.solved ||
          (_phase == _Phase.solving && _hintLevel > 0),
      lines: [
        for (final m in _chat)
          CoachLine(id: m.id, accent: m.accent, child: _MsgBody(m)),
        if (thinking != null)
          CoachLine(
            id: 'thinking-$_round-$_phase-$_explaining',
            child: CoachThinking(label: thinking),
          ),
      ],
    );
  }

  Widget _infoStrip({required double height, bool flame = false}) {
    final drill = _drill;
    final puzzle = _puzzle;
    final delta = _ratingDelta;
    final children = <Widget>[];
    if (_mistakes) {
      if (drill != null) {
        children.addAll([
          MoveBadge(drill.classification, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Game move ${drill.playedSan}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Typo.body(
                12.5,
                color: Palette.parchment,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ]);
      }
      children
        ..add(const Spacer())
        ..add(_sessionCount('fixed'));
    } else {
      children.addAll([
        _RatingCounter(rating: _rating, delta: delta),
        const SizedBox(width: 8),
        if (delta != null)
          _RatingChip(key: ValueKey('delta-$_round-$delta'), delta: delta),
        const Spacer(),
        if (puzzle != null)
          _Pips(
            total: puzzle.solutionMoves,
            found: _found,
            solved: _phase == _Phase.solved,
          ),
        const Spacer(),
        _sessionCount('solved'),
      ]);
    }
    if (flame) {
      children.addAll([
        const SizedBox(width: 10),
        _StreakFlame(streak: _streak, compact: true),
      ]);
    }
    return SizedBox(
      height: height,
      child: Row(children: children),
    );
  }

  Widget _sessionCount(String verb) {
    return Tooltip(
      message: '$_solvedThisSession $verb this session',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: _solvedThisSession > 0 ? Palette.win : Palette.muted,
          ),
          const SizedBox(width: 4),
          TweenAnimationBuilder<double>(
            key: ValueKey(_solvedThisSession),
            tween: Tween(begin: _solvedThisSession > 0 ? 1.5 : 1, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Text(
              '$_solvedThisSession',
              style: Typo.mono(13, color: Palette.parchment).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(double height, {bool includeNext = true}) {
    final group = switch (_phase) {
      _Phase.wrong => 'wrong',
      _Phase.solved || _Phase.revealed => 'done',
      _ => 'play',
    };
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
        key: ValueKey('actions-$group-$includeNext'),
        child: ActionBar(
          height: height,
          items: _actions(includeNext: includeNext),
        ),
      ),
    );
  }

  List<ActionItem> _actions({required bool includeNext}) {
    final ask = ActionItem(
      label: 'Ask',
      icon: Icons.forum_outlined,
      tooltip: 'Ask me about this position',
      onTap: _phase == _Phase.loading || _phase == _Phase.intro ? null : _ask,
    );
    final skip = ActionItem(
      label: 'Skip',
      icon: Icons.skip_next_rounded,
      tooltip: _mistakes ? 'Skip this position' : 'Skip this puzzle',
      onTap: _phase == _Phase.loading || _phase == _Phase.checking
          ? null
          : _load,
    );
    switch (_phase) {
      case _Phase.wrong:
        return [
          ActionItem(
            label: 'Retry',
            icon: Icons.replay_rounded,
            tooltip: 'Try the position again',
            highlight: true,
            onTap: _retry,
          ),
          if (!_mistakes)
            ActionItem(
              label: 'Why?',
              icon: Icons.help_outline_rounded,
              tooltip: 'Why doesn\'t ${_wrongSan ?? 'it'} work?',
              busy: _explaining,
              onTap: _explanation == null ? _explainMiss : null,
            ),
          ActionItem(
            label: 'Solution',
            icon: Icons.visibility_outlined,
            tooltip: 'Show me the solution',
            onTap: _solution.isEmpty ? null : _showSolution,
          ),
          ask,
          skip,
        ];
      case _Phase.solved || _Phase.revealed:
        return [
          ask,
          if (includeNext)
            ActionItem(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              tooltip: _mistakes ? 'Next position' : 'Next puzzle',
              highlight: true,
              onTap: _load,
            ),
        ];
      default:
        return [
          ActionItem(
            label: _hintLevel == 0 ? 'Hint' : 'More',
            icon: Icons.lightbulb_outline_rounded,
            tooltip: 'A nudge in the right direction',
            highlight: _hintLevel > 0,
            onTap: _phase == _Phase.solving && _hintLevel < 2 ? _hint : null,
          ),
          ask,
          skip,
        ];
    }
  }

  Widget _board(double size) {
    final legal = <Square, Set<Square>>{};
    if (_phase == _Phase.solving) {
      for (final uci in _legal.keys) {
        final m = Move.parse(uci);
        if (m != null) (legal[m.from] ??= {}).add(m.to);
      }
    }
    final delta = _ratingDelta;
    return SizedBox(
      key: _boardKey,
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_phase == _Phase.solved)
            Positioned.fill(
              child: _BoardGlow(
                key: ValueKey('glow-solved-$_round'),
                color: Palette.gold,
                radius: size * 0.04,
                strength: 1,
              ),
            ),
          if (_phase == _Phase.wrong)
            Positioned.fill(
              child: _BoardGlow(
                key: ValueKey('glow-wrong-$_msgId'),
                color: _red,
                radius: size * 0.04,
                strength: 0.8,
              ),
            ),
          ChessBoardView(
            position: _position,
            orientation: _orientation,
            legalMoves: legal,
            lastMove: _lastMove,
            arrows: _arrows,
            badge: _badge,
            inCheck: _inCheck,
            onMove: _onMove,
          ),
          if (_phase == _Phase.loading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(color: Palette.gold),
                ),
              ),
            ),
          if (_phase == _Phase.solved)
            Positioned.fill(
              child: _SolvedBurst(
                key: ValueKey('burst-$_round'),
                size: size,
                title: _milestone
                    ? '$_streak in a row!'
                    : (_mistakes ? 'Fixed!' : 'Solved!'),
                delta: _mistakes ? null : delta,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState({required bool compact}) {
    final error = _error;
    return Column(
      children: [
        _topBar(compact: compact, flame: false),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Entrance(
                  scale: 0.9,
                  child: CoachSays(
                    accent: error == null ? Palette.win : Palette.loss,
                    mood: error == null ? CoachMood.happy : CoachMood.surprised,
                    avatarSize: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error ??
                              (_mistakes
                                  ? 'No mistakes waiting: you\'ve fixed them '
                                        'all! Play a game and I\'ll collect '
                                        'new ones.'
                                  : 'That\'s every puzzle in this set for '
                                        'now. Try another one!'),
                          style: BubbleText.body,
                        ),
                        const SizedBox(height: 14),
                        GoldButton(
                          label: error != null ? 'Try again' : 'Back',
                          icon: error != null
                              ? Icons.replay_rounded
                              : Icons.arrow_back_rounded,
                          compact: true,
                          onPressed: error != null
                              ? _load
                              : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Pieces of the screen

/// The words inside one of the coach's bubbles.
class _MsgBody extends StatelessWidget {
  const _MsgBody(this.msg);

  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (msg.chip case final chip?) ...[
          _InkChip(label: chip, color: msg.chipColor),
          const SizedBox(height: 6),
        ],
        TypewriterText(msg.text, style: BubbleText.body),
        if (msg.themes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final (i, t) in msg.themes.indexed)
                Entrance(
                  delay: Duration(milliseconds: 250 + i * 90),
                  offset: const Offset(0, 6),
                  scale: 0.7,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Palette.gold.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Palette.goldDeep.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      t,
                      style: Typo.body(
                        11.5,
                        color: Palette.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (msg.footnote case final note?) ...[
          const SizedBox(height: 6),
          Text(note, style: BubbleText.small.copyWith(fontSize: 11)),
        ],
      ],
    );
  }
}

/// A small label inside a bubble, e.g. "HINT 1 OF 2".
class _InkChip extends StatelessWidget {
  const _InkChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: Typo.label(
          size: 9.5,
          color: Color.lerp(color, Palette.ink, 0.4)!,
        ).copyWith(letterSpacing: 1.6),
      ),
    );
  }
}

/// The puzzle rating, rolling to its new value.
class _RatingCounter extends StatelessWidget {
  const _RatingCounter({required this.rating, required this.delta});

  final int? rating;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final r = rating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('RATING', style: Typo.label(size: 9)),
        const SizedBox(width: 6),
        if (r == null)
          Text('—', style: Typo.title(22, color: Palette.muted))
        else
          TweenAnimationBuilder<double>(
            tween: Tween(end: r.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) =>
                GoldText('${v.round()}', style: Typo.title(22)),
          ),
      ],
    );
  }
}

/// "+12": pops in with an elastic bounce, a glow and a glint of light.
class _RatingChip extends StatelessWidget {
  const _RatingChip({super.key, required this.delta, this.big = false});

  final int delta;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? Palette.win : Palette.loss;
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: big ? 14 : 8,
        vertical: big ? 5 : 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.25)!,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: big ? 20 : 14,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            up ? '+$delta' : '$delta',
            style: Typo.mono(
              big ? 20 : 13,
              color: Colors.white,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      builder: (context, t, child) {
        final pop = Curves.elasticOut.transform((t / 0.65).clamp(0.0, 1.0));
        final glow = 1 - 0.65 * Curves.easeOut.transform(t);
        return Transform.scale(
          scale: pop,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.75 * glow),
                  blurRadius: (big ? 28 : 16) * glow + 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Shine(period: const Duration(milliseconds: 2600), child: pill),
    );
  }
}

/// One pip per move to find, lit as they are found.
class _Pips extends StatelessWidget {
  const _Pips({required this.total, required this.found, required this.solved});

  final int total;
  final int found;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final n = total.clamp(1, 8);
    return Tooltip(
      message: '$found of $total moves found',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < n; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: i < found ? 18 : 11,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < found
                    ? (solved ? Palette.win : Palette.gold)
                    : Colors.white.withValues(alpha: 0.12),
                boxShadow: [
                  if (i < found)
                    BoxShadow(
                      color: (solved ? Palette.win : Palette.gold).withValues(
                        alpha: 0.6,
                      ),
                      blurRadius: 8,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A glow around the board that flares up and fades.
class _BoardGlow extends StatelessWidget {
  const _BoardGlow({
    super.key,
    required this.color,
    required this.radius,
    required this.strength,
  });

  final Color color;
  final double radius;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        builder: (context, t, _) {
          final a = t < 0.15
              ? t / 0.15
              : 1 -
                    Curves.easeOut.transform(
                      (t - 0.15) / 0.85,
                    );
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55 * strength * a),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "Solved!" in gold over turning rays of light, with the rating change.
class _SolvedBurst extends StatelessWidget {
  const _SolvedBurst({
    super.key,
    required this.size,
    required this.title,
    this.delta,
  });

  final double size;
  final String title;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: SizedBox(
        width: size * 0.92,
        height: size * 0.92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: LightRays(rays: 16, opacity: 0.5, speed: 0.08),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.42,
                    colors: [
                      Palette.onyx.withValues(alpha: 0.72),
                      Palette.onyx.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoldText(
                  title,
                  align: TextAlign.center,
                  style: Typo.display(max(30, size * 0.12)),
                ),
                if (delta case final d?) ...[
                  SizedBox(height: size * 0.025),
                  _RatingChip(delta: d, big: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2700),
        builder: (context, t, child) {
          if (t >= 1) return const SizedBox.shrink();
          // In with a bounce, hold, then rise and fade away.
          final pop = Curves.elasticOut.transform((t / 0.3).clamp(0.0, 1.0));
          final fadeIn = (t / 0.06).clamp(0.0, 1.0);
          final out = t < 0.72 ? 0.0 : (t - 0.72) / 0.28;
          return Opacity(
            opacity: (fadeIn * (1 - out)).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -size * 0.06 * Curves.easeIn.transform(out)),
              child: Transform.scale(
                scale: (0.35 + 0.65 * pop) * (1 + 0.08 * out),
                child: child,
              ),
            ),
          );
        },
        child: content,
      ),
    );
  }
}

class _StreakFlame extends StatelessWidget {
  const _StreakFlame({required this.streak, this.compact = false});

  final int streak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hot = streak > 0;
    const flame = Color(0xFFE8913A);
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        color: hot
            ? flame.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: hot
              ? flame.withValues(alpha: 0.6)
              : Palette.goldDeep.withValues(alpha: 0.3),
        ),
        boxShadow: [
          if (hot)
            BoxShadow(
              color: flame.withValues(alpha: min(0.6, 0.2 + streak * 0.05)),
              blurRadius: 12 + min(streak, 10) * 1.5,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: compact ? 18 : 24,
            color: hot ? const Color(0xFFF2A23A) : Palette.muted,
          ),
          const SizedBox(width: 3),
          Text(
            '$streak',
            style: Typo.title(
              compact ? 17 : 22,
              color: hot ? Palette.ivory : Palette.muted,
            ),
          ),
        ],
      ),
    );
    return Tooltip(
      message: 'Streak: $streak in a row',
      child: TweenAnimationBuilder<double>(
        key: ValueKey(streak),
        tween: Tween(begin: hot ? 1.4 : 1, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: Shine(enabled: streak >= 3, child: box),
      ),
    );
  }
}

/// A nudge for the second hint, by the puzzle's main motif (first match
/// wins, so the most telling motifs come first).
const _themeHints = {
  'smotheredMate':
      'Their king is boxed in by its own pieces. A knight would love that.',
  'backRankMate': 'Their back rank is weak. Who guards it?',
  'doubleCheck': 'Two checks at once can\'t be blocked. Can you arrange that?',
  'fork': 'Look for a move that attacks two things at once.',
  'pin': 'Something is pinned. How can you take advantage?',
  'skewer': 'Attack a big piece that has something behind it.',
  'discoveredAttack': 'Move one piece out of the way to unleash another.',
  'hangingPiece': 'Something of theirs is left undefended.',
  'trappedPiece': 'One of their pieces is running out of squares.',
  'deflection': 'Lure a defender away from its job.',
  'attraction': 'Drag one of their pieces onto a bad square.',
  'capturingDefender': 'Take out the piece that holds everything together.',
  'sacrifice': 'Don\'t be afraid to give something up.',
  'xRayAttack': 'Look through the pieces: what lines up behind them?',
  'intermezzo': 'Before the obvious move, is there an in-between one?',
  'clearance': 'One of your pieces is in the way. Clear the path.',
  'interference': 'Cut the line between two of their pieces.',
  'promotion': 'A pawn is dreaming of becoming a queen.',
  'advancedPawn': 'That far-advanced pawn is the key.',
  'quietMove': 'The best move here is neither a check nor a capture.',
  'defensiveMove': 'First, deal with the danger.',
  'exposedKing': 'Their king is out in the open. Go after it.',
  'kingsideAttack': 'Aim everything at their king.',
  'queensideAttack': 'The action is on the queenside.',
  'mateIn1': 'One move, checkmate. Which check leaves no escape?',
  'mateIn2': 'Mate in two. Start with the most forcing check.',
  'mateIn3': 'Mate in three. Keep checking and close the net.',
  'mateIn4': 'Mate in four. Every move should be forcing.',
};

const _themeNames = {
  'fork': 'Fork',
  'pin': 'Pin',
  'skewer': 'Skewer',
  'discoveredAttack': 'Discovered attack',
  'doubleCheck': 'Double check',
  'hangingPiece': 'Loose piece',
  'trappedPiece': 'Trapped piece',
  'deflection': 'Deflection',
  'attraction': 'Attraction',
  'capturingDefender': 'Remove the defender',
  'sacrifice': 'Sacrifice',
  'xRayAttack': 'X-ray',
  'intermezzo': 'In-between move',
  'clearance': 'Clearance',
  'interference': 'Interference',
  'quietMove': 'Quiet move',
  'defensiveMove': 'Defence',
  'kingsideAttack': 'Kingside attack',
  'queensideAttack': 'Queenside attack',
  'exposedKing': 'Exposed king',
  'advancedPawn': 'Advanced pawn',
  'promotion': 'Promotion',
  'mateIn1': 'Mate in 1',
  'mateIn2': 'Mate in 2',
  'mateIn3': 'Mate in 3',
  'mateIn4': 'Mate in 4',
  'backRankMate': 'Back-rank mate',
  'smotheredMate': 'Smothered mate',
  'endgame': 'Endgame',
  'rookEndgame': 'Rook endgame',
  'pawnEndgame': 'Pawn endgame',
  'bishopEndgame': 'Bishop endgame',
  'knightEndgame': 'Knight endgame',
  'queenEndgame': 'Queen endgame',
  'opening': 'Opening',
  'middlegame': 'Middlegame',
  'crushing': 'Crushing',
  'advantage': 'Advantage',
  'equality': 'Equality',
};
