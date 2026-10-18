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

  PuzzleInfo? _puzzle;
  MistakeDrill? _drill;
  List<String> _solution = const [];
  String? _wrongSan;

  int? _rating;
  int? _ratingDelta;
  int _streak = 0;
  int _solvedThisSession = 0;

  String _coachText = '';
  Color _coachAccent = Palette.goldDeep;
  String? _explanation;
  bool _explaining = false;
  (Square, MoveClass)? _badge;
  List<BoardArrow> _arrows = const [];

  bool get _mistakes => widget.setKey == mistakesSetKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
      _badge = null;
      _arrows = const [];
      _explanation = null;
      _wrongSan = null;
      _ratingDelta = null;
    });
    try {
      if (_mistakes) {
        await _loadMistake();
      } else {
        await _loadPuzzle();
      }
    } on ChessGameException catch (e) {
      setState(() {
        _error = e.message;
        _phase = _Phase.empty;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server.';
        _phase = _Phase.empty;
      });
    }
  }

  Future<void> _loadPuzzle() async {
    final puzzle = await client.learn.nextPuzzle(widget.setKey);
    final start = BoardState.fromFen(puzzle.fen);
    setState(() {
      _puzzle = puzzle;
      _rating ??= puzzle.playerRating;
      _position = start;
      _lastMove = null;
      _orientation = start.turn.opposite;
      _legal = const {};
      _phase = _Phase.intro;
      _coachText = 'Watch your opponent\'s move…';
      _coachAccent = Palette.goldDeep;
    });
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted || _puzzle?.id != puzzle.id) return;
    final setup = Move.parse(puzzle.setupMove)!;
    setState(() {
      _position = _position.play(setup);
      _lastMove = setup;
      _legal = puzzle.legalMoves;
      _phase = _Phase.solving;
      final side = _orientation == Side.white ? 'White' : 'Black';
      _coachText = puzzle.solutionMoves > 1
          ? 'Your turn. Find the best move for $side. It takes '
                '${puzzle.solutionMoves} moves.'
          : 'Your turn. Find the best move for $side.';
    });
  }

  Future<void> _loadMistake() async {
    final drill = await client.learn.nextMistake();
    if (drill == null) {
      setState(() {
        _drill = null;
        _phase = _Phase.empty;
      });
      return;
    }
    final position = BoardState.fromFen(drill.fen);
    setState(() {
      _drill = drill;
      _position = position;
      _lastMove = null;
      _orientation = position.turn;
      _legal = drill.legalMoves;
      _phase = _Phase.solving;
      _coachText =
          'In your game you played ${drill.playedSan} here: '
          '${drill.classification.label.toLowerCase()}. Find a stronger '
          'move.';
      _coachAccent = drill.classification.color;
    });
  }

  Future<void> _onMove(Move move) async {
    if (_phase != _Phase.solving) return;
    final san = _legal[move.uci];
    if (san == null) return;
    setState(() {
      _before = _position;
      _lastMoveBefore = _lastMove;
      _position = _position.play(move);
      _lastMove = move;
      _legal = const {};
      _arrows = const [];
      _phase = _Phase.checking;
    });
    try {
      if (_mistakes) {
        await _checkMistake(move, san);
      } else {
        await _checkPuzzle(move, san);
      }
    } catch (_) {
      setState(() {
        _position = _before!;
        _lastMove = _lastMoveBefore;
        _phase = _Phase.solving;
        _legal = _puzzle?.legalMoves ?? _drill?.legalMoves ?? const {};
      });
      _snack('Could not reach the server. Try again.');
    }
  }

  Future<void> _checkPuzzle(Move move, String san) async {
    final puzzle = _puzzle!;
    final result = await client.learn.puzzleMove(puzzle.id, move.uci);
    if (!mounted) return;
    final delta = result.ratingAfter - result.ratingBefore;
    if (result.correct) {
      setState(() {
        _badge = (move.to, result.solved ? MoveClass.best : MoveClass.great);
        _streak = result.streak;
      });
      if (result.solved) {
        setState(() {
          _phase = _Phase.solved;
          _solvedThisSession++;
          if (delta != 0) {
            _ratingDelta = delta;
            _rating = result.ratingAfter;
          }
          _coachText = _praise(san);
          _coachAccent = Palette.win;
        });
        return;
      }
      setState(() => _coachText = 'Good! Keep going.');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final reply = Move.parse(result.replyUci!)!;
      setState(() {
        _badge = null;
        _position = _position.play(reply);
        _lastMove = reply;
        _legal = result.legalMoves ?? const {};
        _phase = _Phase.solving;
      });
      return;
    }
    setState(() {
      _badge = (move.to, MoveClass.blunder);
      _phase = _Phase.wrong;
      _wrongSan = san;
      _solution = result.solution ?? const [];
      _streak = 0;
      if (delta != 0) {
        _ratingDelta = delta;
        _rating = result.ratingAfter;
      }
      _coachText =
          'Not quite. $san doesn\'t work here. Try again, or ask me why.';
      _coachAccent = MoveClass.blunder.color;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _phase != _Phase.wrong) return;
    setState(() {
      _position = _before!;
      _lastMove = _lastMoveBefore;
      _badge = null;
      _legal = result.legalMoves ?? const {};
    });
  }

  Future<void> _checkMistake(Move move, String san) async {
    final drill = _drill!;
    final result = await client.learn.mistakeMove(drill.analysisId, move.uci);
    if (!mounted) return;
    if (result.correct) {
      setState(() {
        _badge = (move.to, MoveClass.best);
        _phase = _Phase.solved;
        _solvedThisSession++;
        _coachText = san == result.bestSan
            ? 'Exactly! $san is the move you missed in the game.'
            : 'Good! $san is just as strong as the engine\'s ${result.bestSan}.';
        _coachAccent = Palette.win;
        _explanation = result.explanation.isEmpty ? null : result.explanation;
      });
      return;
    }
    setState(() {
      _badge = (move.to, MoveClass.mistake);
      _phase = _Phase.revealed;
      _coachText = 'Not this time. The strongest move was ${result.bestSan}.';
      _coachAccent = MoveClass.mistake.color;
      _explanation = result.explanation.isEmpty ? null : result.explanation;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _position = _before!;
      _lastMove = _lastMoveBefore;
      _badge = null;
      _arrows = [?BoardArrow.fromUci(result.bestUci, color: BoardArrow.best)];
    });
  }

  void _retry() {
    setState(() {
      _phase = _Phase.solving;
      _badge = null;
      _coachText = 'Take your time. Look at checks, captures and threats.';
      _coachAccent = Palette.goldDeep;
    });
  }

  Future<void> _explainMiss() async {
    final puzzle = _puzzle;
    if (puzzle == null || _explaining) return;
    setState(() => _explaining = true);
    try {
      final text = await client.learn.explainPuzzle(puzzle.id);
      if (mounted) setState(() => _explanation = text);
    } catch (_) {
      _snack('The coach could not be reached.');
    } finally {
      if (mounted) setState(() => _explaining = false);
    }
  }

  Future<void> _showSolution() async {
    final moves = _solution;
    if (moves.isEmpty) return;
    setState(() {
      _phase = _Phase.revealed;
      _legal = const {};
      _coachText = 'Here is the solution. Watch the idea unfold.';
      _coachAccent = BoardArrow.best;
    });
    for (final (i, uci) in moves.indexed) {
      final move = Move.parse(uci)!;
      setState(() {
        _arrows = [BoardArrow(move.from, move.to, color: BoardArrow.best)];
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _position = _position.play(move);
        _lastMove = move;
        _arrows = const [];
        if (i.isEven) _badge = (move.to, MoveClass.best);
      });
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
    }
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

  String _praise(String san) {
    const lines = [
      'Brilliant! That\'s the one.',
      'Correct! Nicely calculated.',
      'Spot on!',
      'Excellent, that wins.',
      'Yes! Clean and precise.',
    ];
    final themes = _puzzle?.themes
        .where((t) => _themeNames.containsKey(t))
        .map((t) => _themeNames[t]!)
        .take(2)
        .toList();
    final line = lines[Random().nextInt(lines.length)];
    return themes == null || themes.isEmpty
        ? '$line $san solves it.'
        : '$line $san: ${themes.join(' and ').toLowerCase()}.';
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
                    title: widget.title,
                    compact: !wide,
                  ),
                  Expanded(
                    child: _phase == _Phase.empty
                        ? _emptyState()
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
    final boardSize = min(c.maxHeight - 110, c.maxWidth - 520).clamp(
      300.0,
      820.0,
    );
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _board(boardSize),
          const SizedBox(width: 36),
          SizedBox(
            width: 400,
            height: boardSize,
            child: Panel(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: SingleChildScrollView(child: _sidePanel()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrow(BoxConstraints c) {
    final boardSize = min(c.maxWidth - 32, c.maxHeight - 260).clamp(
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
              _sidePanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board(double size) {
    final legal = <Square, Set<Square>>{};
    if (_phase == _Phase.solving) {
      for (final uci in _legal.keys) {
        final m = Move.parse(uci);
        if (m != null) (legal[m.from] ??= {}).add(m.to);
      }
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ChessBoardView(
            position: _position,
            orientation: _orientation,
            legalMoves: legal,
            lastMove: _lastMove,
            arrows: _arrows,
            badge: _badge,
            onMove: _onMove,
          ),
          if (_phase == _Phase.loading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Palette.gold),
              ),
            ),
          if (_phase == _Phase.solved)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, t, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.win.withValues(alpha: 0.35 * (1 - t)),
                          blurRadius: 40,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sidePanel() {
    final puzzle = _puzzle;
    // Themes are a clue, so they stay hidden until the puzzle is over.
    final done = _phase == _Phase.solved || _phase == _Phase.revealed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _mistakes ? 'MISTAKE TRAINER' : 'PUZZLE TRAINER',
          style: Typo.label(),
        ),
        const SizedBox(height: 6),
        Text(widget.title, style: Typo.display(32)),
        const SizedBox(height: 14),
        if (!_mistakes) _ratingRow(),
        if (_mistakes && _drill != null)
          Text(
            '${_drill!.remaining} position${_drill!.remaining == 1 ? '' : 's'} '
            'from your games to fix',
            style: Typo.body(13, color: Palette.muted),
          ),
        const SizedBox(height: 16),
        CoachSays(
          accent: _coachAccent,
          speaking: _phase == _Phase.wrong || _phase == _Phase.solved,
          child: Column(
            key: ValueKey('$_coachText$_explanation$_explaining'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypewriterText(
                _coachText,
                style: Typo.body(
                  14,
                  color: Palette.ivory,
                ).copyWith(height: 1.45),
              ),
              if (_explanation != null) ...[
                const SizedBox(height: 8),
                TypewriterText(
                  _explanation!,
                  style: Typo.body(13).copyWith(height: 1.45),
                ),
              ],
              if (_explaining) ...[
                const SizedBox(height: 8),
                const CoachThinking(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_phase == _Phase.wrong)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GoldButton(
                label: 'Try again',
                icon: Icons.replay_rounded,
                compact: true,
                onPressed: _retry,
              ),
              if (_explanation == null)
                OutlinedButton.icon(
                  onPressed: _explaining ? null : _explainMiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.gold,
                    side: const BorderSide(color: Palette.goldDeep),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: Text(
                    'Why not $_wrongSan?',
                    style: Typo.body(
                      13,
                      color: Palette.gold,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              TextButton(
                onPressed: _showSolution,
                child: Text(
                  'Show solution',
                  style: Typo.body(
                    13,
                    color: Palette.muted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        if (_phase == _Phase.solved || _phase == _Phase.revealed)
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: _mistakes ? 'Next position' : 'Next puzzle',
              icon: Icons.arrow_forward_rounded,
              onPressed: _load,
            ),
          ),
        if (done && puzzle != null) ...[
          const SizedBox(height: 18),
          Text('THEMES', style: Typo.label(size: 10)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in puzzle.themes)
                if (_themeNames.containsKey(t))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: Palette.goldDeep.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _themeNames[t]!,
                      style: Typo.body(12, color: Palette.parchment),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Puzzle rating ${puzzle.rating} · from the Lichess puzzle database',
            style: Typo.body(11, color: Palette.muted),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Ask coach',
                icon: Icons.forum_outlined,
                onPressed: _phase == _Phase.loading ? null : _ask,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GhostButton(
                label: 'Skip',
                icon: Icons.skip_next_rounded,
                onPressed: _phase == _Phase.loading || _phase == _Phase.checking
                    ? null
                    : _load,
              ),
            ),
          ],
        ),
        if (_solvedThisSession > 0) ...[
          const SizedBox(height: 14),
          Text(
            '$_solvedThisSession solved this session',
            style: Typo.body(12, color: Palette.muted),
          ),
        ],
      ],
    );
  }

  Widget _ratingRow() {
    final delta = _ratingDelta;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR RATING', style: Typo.label(size: 10)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: (_rating ?? 0).toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) =>
                      Text('${v.round()}', style: Typo.title(34)),
                ),
                const SizedBox(width: 8),
                if (delta != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('delta-$delta-${_puzzle?.id}'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) => Opacity(
                        opacity: t.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - t)),
                          child: child,
                        ),
                      ),
                      child: Text(
                        delta > 0 ? '+$delta' : '$delta',
                        style: Typo.mono(
                          16,
                          color: delta > 0 ? Palette.win : Palette.loss,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _StreakFlame(streak: _streak),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: CoachSays(
            accent: _error == null ? Palette.win : Palette.loss,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error ??
                      (_mistakes
                          ? 'No mistakes waiting. Every position from your '
                                'games has been fixed. Play a game and I\'ll '
                                'collect new ones.'
                          : 'No puzzles in this set right now.'),
                  style: Typo.body(14, color: Palette.ivory),
                ),
                const SizedBox(height: 14),
                GoldButton(
                  label: _error != null ? 'Try again' : 'Back',
                  compact: true,
                  onPressed: _error != null
                      ? _load
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakFlame extends StatelessWidget {
  const _StreakFlame({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final hot = streak > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: hot
            ? const Color(0xFFE8913A).withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: hot
              ? const Color(0xFFE8913A).withValues(alpha: 0.6)
              : Palette.goldDeep.withValues(alpha: 0.3),
        ),
        boxShadow: [
          if (hot)
            BoxShadow(
              color: const Color(0xFFE8913A).withValues(alpha: 0.25),
              blurRadius: 16,
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: hot ? const Color(0xFFF2A23A) : Palette.muted,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: Typo.title(22, color: hot ? Palette.ivory : Palette.muted),
          ),
        ],
      ),
    );
  }
}

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
