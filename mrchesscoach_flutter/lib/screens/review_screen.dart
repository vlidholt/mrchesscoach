import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../theme.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
import '../widgets/game_panels.dart';
import '../widgets/move_badge.dart';
import 'game_screen.dart' show TextAction, TopBar, reasonText;

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

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

  GameReview? _review;
  ChessGame? _game;
  String? _error;

  /// Positions by index: 0 is the start, `i + 1` is the board after move i.
  List<BoardState> _positions = const [];
  List<Move?> _moves = const [];
  Map<int, MoveClass> _verdicts = const {};

  /// Indexes (into the move list) of the key moments, in game order.
  List<int> _keyIndexes = const [];
  int _startMove = 1;
  bool _blackFirst = false;

  /// The selected move; -1 is the starting position.
  int _selected = -1;

  /// Shows the position before an error with the engine's move drawn on it.
  bool _showBest = false;
  Side _orientation = Side.white;

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
              'The coach could not reach the server. Check your connection '
              'and try again.',
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
      _verdicts = {
        for (final (i, a) in review.moves.indexed) i: a.classification,
      };
      _keyIndexes = keys;
      _blackFirst = fields.length > 1 && fields[1] == 'b';
      _startMove = fields.length > 5 ? int.tryParse(fields[5]) ?? 1 : 1;
      _orientation = _playerSide;
      _selected = -1;
      _showBest = false;
    });
    // Have the first key moment ready by the time the user gets there.
    if (keys.isNotEmpty) _maybeExplain(keys.first);
    _focus.requestFocus();
  }

  Side get _playerSide =>
      _game?.playerColor == PlayerColor.black ? Side.black : Side.white;

  MoveAnalysis _analysis(int i) => _explained[i] ?? _review!.moves[i];

  /// "12." for White's move, "12…" for Black's.
  String _moveNumber(int i) {
    final k = i + (_blackFirst ? 1 : 0);
    final number = _startMove + k ~/ 2;
    return k.isEven ? '$number.' : '$number…';
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
  // Navigation

  void _select(int i) {
    final review = _review;
    if (review == null) return;
    if (!_focus.hasFocus) _focus.requestFocus();
    final next = i.clamp(-1, review.moves.length - 1);
    if (next == _selected) return;
    setState(() {
      _fresh.remove(_selected);
      _selected = next;
      _showBest = false;
    });
    _maybeExplain(next);
  }

  void _step(int delta) => _select(_selected + delta);

  /// Jumps to the next move with verdict [cls] by the player or Stockfish.
  void _jumpToClass(MoveClass cls, {required bool byPlayer}) {
    final moves = _review!.moves;
    final n = moves.length;
    for (var k = 1; k <= n; k++) {
      final i = (_selected + k) % n;
      if (moves[i].classification == cls && moves[i].byPlayer == byPlayer) {
        _select(i);
        return;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  _step(-1),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  _step(1),
              const SingleActivator(LogicalKeyboardKey.home): () => _select(-1),
              const SingleActivator(LogicalKeyboardKey.end): () =>
                  _select(1 << 20),
            },
            child: Focus(
              focusNode: _focus,
              autofocus: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1000;
                  return Column(
                    children: [
                      TopBar(
                        onBack: () => Navigator.of(context).pop(),
                        title: 'Game review',
                        compact: !wide,
                        trailing: _review == null
                            ? null
                            : IconButton(
                                tooltip: 'Flip the board',
                                onPressed: () => setState(
                                  () => _orientation = _orientation.opposite,
                                ),
                                icon: const Icon(
                                  Icons.swap_vert_rounded,
                                  color: Palette.parchment,
                                ),
                              ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          switchInCurve: Curves.easeOutCubic,
                          child: _body(wide),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool wide) {
    if (_error case final message?) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: message,
        onRetry: _retry,
        onBack: () => Navigator.of(context).pop(),
      );
    }
    if (_review == null || _game == null) {
      return const _LoadingView(key: ValueKey('loading'));
    }
    return wide ? _buildWide() : _buildNarrow();
  }

  // ---------------------------------------------------------------------------
  // Layouts

  Widget _buildWide() {
    return LayoutBuilder(
      key: const ValueKey('wide'),
      builder: (context, c) {
        const panelWidth = 420.0;
        const barWidth = 18.0;
        const gap = 12.0;
        const navHeight = 48.0;
        const graphHeight = 96.0;
        const chrome = 14 + navHeight + 16 + _graphHeader + graphHeight;
        final boardSize = min(
          c.maxHeight - 28 - chrome,
          c.maxWidth - panelWidth - barWidth - gap - 36 - 72,
        ).clamp(260.0, 860.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: barWidth + gap + boardSize,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(height: boardSize, child: _winBar(barWidth)),
                          const SizedBox(width: gap),
                          _board(boardSize),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(height: navHeight, child: _navigation()),
                      const SizedBox(height: 16),
                      _graphSection(graphHeight),
                    ],
                  ),
                ),
                const SizedBox(width: 36),
                SizedBox(
                  width: panelWidth,
                  height: boardSize + chrome,
                  child: _sidePanel(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrow() {
    final summary = _review!.summary;
    return LayoutBuilder(
      key: const ValueKey('narrow'),
      builder: (context, c) {
        final width = min(c.maxWidth - 32, 640.0);
        const barWidth = 12.0;
        const gap = 8.0;
        final boardSize = width - barWidth - gap;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Reveal(
                    child: Panel(
                      radius: 20,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          _accuracy(92),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Reveal(
                    delay: 120,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: boardSize,
                              child: _winBar(barWidth),
                            ),
                            const SizedBox(width: gap),
                            _board(boardSize),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(height: 46, child: _navigation()),
                        const SizedBox(height: 14),
                        _graphSection(80),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Reveal(delay: 220, child: _coachComment(compact: true)),
                  const SizedBox(height: 16),
                  _Reveal(
                    delay: 280,
                    child: Panel(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: _keyMoments(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Reveal(
                    delay: 320,
                    child: Panel(
                      radius: 16,
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text('MOVES', style: Typo.label()),
                          ),
                          const SizedBox(height: 6),
                          _moveList(compact: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Reveal(
                    delay: 360,
                    child: Panel(
                      radius: 18,
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                      child: _table(),
                    ),
                  ),
                  if (summary != null && summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Reveal(delay: 400, child: _SummaryCard(text: summary)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sidePanel() {
    final summary = _review!.summary;
    return Panel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(child: _header()),
              const SizedBox(height: 20),
              _Reveal(delay: 80, child: _accuracy(104)),
              const _Divider(),
              _Reveal(delay: 160, child: _coachComment(compact: false)),
              const _Divider(),
              _Reveal(delay: 220, child: _keyMoments()),
              const _Divider(),
              _Reveal(
                delay: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MOVES', style: Typo.label()),
                    const SizedBox(height: 6),
                    SizedBox(height: 240, child: _moveList(compact: false)),
                  ],
                ),
              ),
              const _Divider(),
              _Reveal(delay: 300, child: _table()),
              if (summary != null && summary.trim().isNotEmpty) ...[
                const _Divider(),
                _Reveal(delay: 340, child: _SummaryCard(text: summary)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections

  Widget _header() {
    final game = _game!;
    final review = _review!;
    final goal = game.endReason == GameEndReason.goalReached;
    final (title, accent) = switch (game.status) {
      _ when goal => ('Lesson complete', Palette.win),
      GameStatus.playerWon => ('Victory', Palette.win),
      GameStatus.computerWon => ('Defeat', Palette.loss),
      GameStatus.draw => ('Draw', Palette.draw),
      GameStatus.abandoned => ('Abandoned', Palette.muted),
      GameStatus.active => ('In progress', Palette.gold),
    };
    final reason = reasonText(game.endReason);
    final level = widget.levels.where((l) => l.index == game.level).firstOrNull;
    final fullMoves = (review.moves.length + 1) ~/ 2;
    final details = [
      if (reason.isNotEmpty) reason[0].toUpperCase() + reason.substring(1),
      '$fullMoves ${fullMoves == 1 ? 'move' : 'moves'}',
      level == null ? 'vs Stockfish' : 'vs ${level.name} · ≈${level.rating}',
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
          child: Text(title, style: Typo.display(46)),
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
    final level = widget.levels
        .where((l) => l.index == _game!.level)
        .firstOrNull;
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
            name: 'Stockfish',
            subtitle: level == null ? 'Computer' : '≈${level.rating}',
            side: side.opposite,
            computer: true,
            color: Palette.parchment,
            size: size,
            delay: 160,
          ),
        ),
      ],
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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChessBoardView(
            position: position,
            orientation: _orientation,
            legalMoves: const {},
            onMove: (_) {},
            lastMove: lastMove,
            arrows: arrows,
            inCheck: check,
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
        ],
      ),
    );
  }

  Widget _navigation() {
    final n = _review!.moves.length;
    final i = _selected;
    final a = i >= 0 ? _analysis(i) : null;
    final best = _showBest && a != null && a.classification.isError;
    final title = a == null
        ? 'Start'
        : best
        ? 'Best: ${a.bestSan ?? '—'}'
        : '${_moveNumber(i)} ${a.san}';
    final subtitle = a == null
        ? 'Starting position'
        : '${i + 1} of $n  ·  ${a.byPlayer ? 'You' : 'Stockfish'}';
    return Row(
      children: [
        _NavButton(
          icon: Icons.first_page_rounded,
          tooltip: 'Start (Home)',
          onTap: i > -1 ? () => _select(-1) : null,
        ),
        const SizedBox(width: 8),
        _NavButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous move (←)',
          onTap: i > -1 ? () => _step(-1) : null,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Column(
              key: ValueKey('$i-$best'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.mono(
                    15,
                    color: best ? BoardArrow.best : Palette.ivory,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(11, color: Palette.muted),
                ),
              ],
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next move (→)',
          primary: true,
          onTap: i < n - 1 ? () => _step(1) : null,
        ),
        const SizedBox(width: 8),
        _NavButton(
          icon: Icons.last_page_rounded,
          tooltip: 'Last move (End)',
          onTap: i < n - 1 ? () => _select(n - 1) : null,
        ),
      ],
    );
  }

  static const _graphHeader = 26.0;

  Widget _graphSection(double height) {
    final review = _review!;
    final values = review.winGraph;
    final index = values.isEmpty
        ? 0
        : (_selected + 1).clamp(0, values.length - 1);
    final white = values.isEmpty ? 50.0 : values[index];
    final mine = _playerSide == Side.white ? white : 100 - white;
    return Column(
      children: [
        SizedBox(
          height: _graphHeader,
          child: Row(
            children: [
              Text('WINNING CHANCES', style: Typo.label(size: 10)),
              const Spacer(),
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
            values: values,
            selected: index,
            whiteAtBottom: _orientation == Side.white,
            marks: [
              for (final k in _keyIndexes)
                (k + 1, review.moves[k].classification.color),
            ],
            onSelect: (index) => _select(index - 1),
          ),
        ),
      ],
    );
  }

  Widget _coachComment({required bool compact}) {
    final i = _selected;
    final accent = i < 0 ? Palette.goldDeep : _analysis(i).classification.color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachAvatar(
          size: compact ? 38 : 46,
          speaking: _explaining.contains(i) || _fresh.contains(i),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: _Bubble(
                key: ValueKey('bubble-$i'),
                accent: accent,
                child: i < 0 ? _introComment() : _moveComment(i),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static final _speech = Typo.body(
    14,
    color: Palette.ivory,
  ).copyWith(height: 1.45);

  Widget _say(String text, {required bool fresh}) =>
      fresh ? TypewriterText(text, style: _speech) : Text(text, style: _speech);

  Widget _introComment() {
    final n = _keyIndexes.length;
    final text = n == 0
        ? 'Let\'s walk through your game together. Step through it with the '
              'arrows, or drag across the graph to jump around.'
        : 'Let\'s walk through your game together. I marked $n key '
              'moment${n == 1 ? '' : 's'} on the graph. Start with those, or '
              'step through every move with the arrows.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Tag(label: 'STARTING POSITION', color: Palette.gold),
        const SizedBox(height: 10),
        _say(text, fresh: _fresh.contains(-1)),
      ],
    );
  }

  Widget _moveComment(int i) {
    final a = _analysis(i);
    final cls = a.classification;
    final loading = _explaining.contains(i);
    final failed = _failed.contains(i);
    final explanation = a.explanation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MoveBadgeLabel(cls),
            Text(
              '${_moveNumber(i)} ${a.san}',
              style: Typo.mono(14, color: Palette.parchment),
            ),
            _Tag(
              label: a.byPlayer ? 'YOU' : 'STOCKFISH',
              color: a.byPlayer ? Palette.gold : Palette.muted,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ChanceShift(
          before: a.winBefore,
          after: a.winAfter,
          byPlayer: a.byPlayer,
        ),
        const SizedBox(height: 10),
        if (a.headline case final headline?) ...[
          Text(headline, style: Typo.title(19)),
          const SizedBox(height: 6),
        ],
        if (explanation != null)
          _say(explanation, fresh: _fresh.contains(i))
        else if (!loading)
          Text(_quickLine(a), style: _speech),
        if (a.lesson case final lesson?) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: Palette.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lesson,
                  style: Typo.body(
                    13,
                    color: Palette.gold,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
        if (loading) ...[
          const SizedBox(height: 10),
          const CoachThinking(label: 'Coach is studying this move'),
        ] else if (explanation == null) ...[
          const SizedBox(height: 4),
          _WhyButton(
            label: failed ? 'Ask again' : 'Why?',
            onTap: () => _explain(i),
          ),
        ],
        if (cls.isError && a.bestUci != null && a.bestSan != null) ...[
          const SizedBox(height: 12),
          _BestMoveBlock(
            analysis: a,
            active: _showBest,
            onToggle: () => setState(() => _showBest = !_showBest),
          ),
        ],
      ],
    );
  }

  static String _quickLine(MoveAnalysis a) {
    final who = a.byPlayer ? 'You' : 'Stockfish';
    final best = a.bestSan;
    final better = best != null && best != a.san;
    return switch (a.classification) {
      MoveClass.brilliant =>
        'A brilliant find! ${a.san} gives something up for much more.',
      MoveClass.great => '$who found the only move that keeps the balance.',
      MoveClass.best => '${a.san} is exactly what the engine would play.',
      MoveClass.excellent =>
        'Almost perfect. ${a.san} keeps everything under control.',
      MoveClass.good =>
        'A solid move.${better ? ' $best was a touch stronger.' : ''}',
      MoveClass.book => '${a.san} is a well-known opening move.',
      MoveClass.inaccuracy =>
        'Not the most precise.${better ? ' $best was better.' : ''}',
      MoveClass.mistake =>
        '${a.san} lets the advantage slip.${better ? ' $best was the move.' : ''}',
      MoveClass.miss =>
        'A missed chance!${better ? ' $best would have been much stronger.' : ''}',
      MoveClass.blunder =>
        '${a.san} is a serious error.${better ? ' $best was needed.' : ''}',
    };
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
                  onTap: () => _select(k),
                ),
            ],
          ),
      ],
    );
  }

  Widget _moveList({required bool compact}) {
    return MoveList(
      sanMoves: [for (final a in _review!.moves) a.san],
      verdicts: _verdicts,
      selectedPly: _selected,
      onTap: _select,
      plyOffset: (_startMove - 1) * 2,
      compact: compact,
    );
  }

  Widget _table() {
    final review = _review!;
    final side = _playerSide;
    Widget header(Side side, Role role, String name) => SizedBox(
      width: _ClassRow.countWidth,
      child: Column(
        children: [
          Image.asset(
            pieceAsset(side, role),
            width: 28,
            height: 28,
            filterQuality: FilterQuality.medium,
          ),
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
            header(side, Role.king, 'You'),
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
            header(side.opposite, Role.knight, 'Stockfish'),
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
  const _LoadingView({super.key});

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  static const _lines = [
    'Grading every move',
    'Finding the turning points',
    'Measuring your accuracy',
    'Writing your summary',
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
                dimension: 136,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _spin,
                        builder: (context, _) => CustomPaint(
                          painter: _OrbitPainter(_spin.value),
                        ),
                      ),
                    ),
                    const CoachAvatar(size: 86, speaking: true),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'The coach is reviewing your game…',
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
                'Every move gets a verdict. Long games can take a few seconds.',
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
    super.key,
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
          child: Panel(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.loss.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Palette.loss.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Palette.loss,
                    size: 30,
                  ),
                ),
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
                TextAction(label: 'Back to the game', onTap: onBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Building blocks

/// Fades and lifts its child in once, after [delay] milliseconds.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final total = 560 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        height: 0.7,
        color: Palette.goldDeep.withValues(alpha: 0.4),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(label, style: Typo.label(color: color, size: 10)),
    );
  }
}

/// The coach's speech bubble, tinted with the verdict's colour.
class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(Palette.lacquer, accent, 0.10)!, Palette.ebony],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "Your chances 62% → 31%".
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
        ? Palette.loss
        : delta >= 4
        ? Palette.win
        : Palette.parchment;
    return Row(
      children: [
        Flexible(
          child: Text(
            byPlayer ? 'Your chances' : 'Stockfish\'s chances',
            overflow: TextOverflow.ellipsis,
            style: Typo.body(12, color: Palette.muted),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${before.round()}%',
          style: Typo.mono(12, color: Palette.parchment),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_right_alt_rounded, size: 16, color: color),
        ),
        Text(
          '${after.round()}%',
          style: Typo.mono(12, color: color).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WhyButton extends StatelessWidget {
  const _WhyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Palette.gold,
        padding: const EdgeInsets.symmetric(horizontal: 0),
      ),
      icon: const Icon(Icons.help_outline_rounded, size: 16),
      label: Text(
        label,
        style: Typo.body(13, color: Palette.gold, weight: FontWeight.w700),
      ),
    );
  }
}

/// What the engine wanted instead, with a toggle to see it on the board.
class _BestMoveBlock extends StatelessWidget {
  const _BestMoveBlock({
    required this.analysis,
    required this.active,
    required this.onToggle,
  });

  final MoveAnalysis analysis;
  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    const green = BoardArrow.best;
    final line = a.bestLine.take(6).join(' ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: green.withValues(alpha: active ? 0.14 : 0.07),
        border: Border.all(
          color: green.withValues(alpha: active ? 0.8 : 0.35),
          width: active ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 17, color: green),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Best was ',
                        style: Typo.body(13, color: Palette.parchment),
                      ),
                      TextSpan(
                        text: a.bestSan,
                        style: Typo.mono(
                          14,
                          color: green,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (a.bestLine.length > 1) ...[
            const SizedBox(height: 4),
            Text(
              line,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Typo.mono(12, color: Palette.muted),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onToggle,
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              backgroundColor: active ? green.withValues(alpha: 0.16) : null,
              side: BorderSide(color: green.withValues(alpha: 0.7)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: Icon(
              active ? Icons.undo_rounded : Icons.visibility_outlined,
              size: 17,
            ),
            label: Text(
              active ? 'Back to the game move' : 'Show best move',
              style: Typo.body(13, color: green, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
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

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool primary;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final lit = enabled && (_hover || widget.primary);
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onTap!();
                }
              : null,
          child: AnimatedScale(
            scale: _down ? 0.92 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hover && enabled
                    ? Palette.gold.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: lit
                      ? Palette.gold.withValues(alpha: _hover ? 1 : 0.7)
                      : Palette.goldDeep.withValues(
                          alpha: enabled ? 0.45 : 0.2,
                        ),
                  width: 0.9,
                ),
                boxShadow: [
                  if (lit && _hover)
                    const BoxShadow(color: Palette.goldGlow, blurRadius: 16),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: enabled
                    ? (lit ? Palette.gold : Palette.ivory)
                    : Palette.muted.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
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
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
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

/// The coach's written summary: a paragraph, then up to three lessons.
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Palette.gold.withValues(alpha: 0.13),
            Palette.gold.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Palette.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CoachAvatar(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COACH\'S VERDICT', style: Typo.label(size: 10)),
                    const SizedBox(height: 4),
                    Text('Summary', style: Typo.title(22)),
                  ],
                ),
              ),
            ],
          ),
          if (paragraph.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              paragraph,
              style: Typo.body(14, color: Palette.ivory).copyWith(height: 1.5),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('TAKE AWAY', style: Typo.label(size: 10)),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 12),
                      child: Transform.rotate(
                        angle: pi / 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          color: Palette.gold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: Typo.body(13.5).copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
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
    this.computer = false,
    this.size = 100,
    this.delay = 0,
  });

  final double value;
  final String name;
  final String subtitle;
  final Side side;
  final Color color;
  final bool computer;
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
            Image.asset(
              pieceAsset(side, computer ? Role.knight : Role.king),
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
    canvas.drawCircle(
      center + Offset(cos(end), sin(end)) * radius,
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
  });

  /// White's winning chances (0-100) before the first move and after each.
  final List<double> values;

  /// The selected index into [values].
  final int selected;
  final bool whiteAtBottom;

  /// Dots on the curve: index into [values] and colour.
  final List<(int, Color)> marks;
  final ValueChanged<int> onSelect;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void pick(Offset p) => widget.onSelect(_indexAt(p.dx, width));
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Palette.goldDeep.withValues(alpha: 0.6),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
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
  });

  final List<double> values;
  final int selected;
  final int? hover;
  final List<(int, Color)> marks;
  final bool whiteAtBottom;
  final double progress;

  static const _light = [Color(0xFFFFF8E8), Color(0xFFE2D5B8)];
  static const _dark = [Color(0xFF2A2620), Color(0xFF100E0C)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = values.length;
    final bounds = Offset.zero & size;

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
          ..strokeWidth = 1.3
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.gold.withValues(alpha: 0.75),
      );
      canvas.restore();
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
        5.2,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      canvas.drawCircle(p, 4, Paint()..color = color);
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
        ..strokeWidth = 2,
    );
    final dot = Offset(x, point(s).dy);
    canvas.drawCircle(dot, 5.5, Paint()..color = Palette.onyx);
    canvas.drawCircle(dot, 4, Paint()..color = Palette.gold);
  }

  @override
  bool shouldRepaint(_WinGraphPainter old) =>
      old.values != values ||
      old.selected != selected ||
      old.hover != hover ||
      old.whiteAtBottom != whiteAtBottom ||
      old.progress != progress ||
      old.marks.length != marks.length;
}
