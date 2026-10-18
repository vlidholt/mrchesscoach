import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../theme.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_panel.dart';
import 'game_screen.dart';
import 'opening_screen.dart';
import 'puzzle_screen.dart';

// -----------------------------------------------------------------------------
// Navigation helpers, shared with the lobby's recommendations.

Future<void> openPuzzles(BuildContext context, String key, String title) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleScreen(setKey: key, title: title),
      ),
    );

Future<void> openOpening(
  BuildContext context,
  String id,
  List<ChessLevel> levels,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => OpeningScreen(openingId: id, levels: levels),
  ),
);

String lessonGoalText(LessonInfo lesson) => switch (lesson.goal) {
  'draw' => 'Goal: hold the draw for ${lesson.targetMoves} moves',
  'keepAdvantage' =>
    'Goal: keep your advantage for ${lesson.targetMoves} moves',
  _ => 'Goal: win the position',
};

/// Shows a lesson's concept and starts it on request.
Future<void> openLesson(
  BuildContext context,
  LessonInfo lesson,
  List<ChessLevel> levels,
) async {
  final start = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => _LessonDialog(lesson: lesson),
  );
  if (start != true || !context.mounted) return;
  try {
    final game = await client.learn.startLesson(lesson.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          game: game,
          levels: levels,
          lesson: GameLesson(
            title: lesson.title,
            goal: lessonGoalText(lesson),
            tips: lesson.tips,
          ),
        ),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start the lesson.')),
      );
    }
  }
}

// -----------------------------------------------------------------------------

/// The "Learn" tab: openings, puzzles, lessons and the mistake trainer.
class LearnView extends StatefulWidget {
  const LearnView({super.key, required this.levels});

  final List<ChessLevel> levels;

  @override
  State<LearnView> createState() => _LearnViewState();
}

class _LearnViewState extends State<LearnView> {
  List<OpeningSummary> _openings = [];
  List<PuzzleTheme> _sets = [];
  List<LessonInfo> _lessons = [];
  int _mistakes = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _openings.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        client.learn.openings(),
        client.learn.puzzleSets(),
        client.learn.lessons(),
        client.learn.nextMistake(),
      ]);
      if (!mounted) return;
      setState(() {
        _openings = results[0] as List<OpeningSummary>;
        _sets = results[1] as List<PuzzleTheme>;
        _lessons = results[2] as List<LessonInfo>;
        _mistakes = (results[3] as MistakeDrill?)?.remaining ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the training area.';
      });
    }
  }

  Future<void> _then(Future<void> navigation) async {
    await navigation;
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Palette.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: Typo.display(26)),
            const SizedBox(height: 16),
            GoldButton(label: 'Try again', onPressed: _load),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final pad = wide ? 48.0 : 16.0;
        return RefreshIndicator(
          color: Palette.gold,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mistakes > 0) ...[
                      _MistakesBanner(
                        count: _mistakes,
                        onTap: () => _then(
                          openPuzzles(context, mistakesSetKey, 'Your mistakes'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    _SectionHeader(
                      label: 'OPENING EXPLORER',
                      title: 'Learn an opening',
                      subtitle:
                          'Walk through the main line, learn why every move '
                          'is played, then drill it and play it out.',
                    ),
                    const SizedBox(height: 16),
                    _grid(
                      c.maxWidth - 2 * pad,
                      minTile: 270,
                      children: [
                        for (final o in _openings)
                          _OpeningCard(
                            opening: o,
                            onTap: () => _then(
                              openOpening(context, o.id, widget.levels),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _SectionHeader(
                      label: 'TACTICS TRAINER',
                      title: 'Sharpen your eye',
                      subtitle:
                          'Thousands of real positions from the Lichess puzzle '
                          'database, matched to your rating.',
                    ),
                    const SizedBox(height: 16),
                    ..._puzzleSections(c.maxWidth - 2 * pad),
                    const SizedBox(height: 40),
                    _SectionHeader(
                      label: 'ENDGAME SCHOOL',
                      title: 'Technique wins games',
                      subtitle:
                          'Classic positions every player should know. Play '
                          'them out against full-strength Stockfish.',
                    ),
                    const SizedBox(height: 16),
                    _lessonGrid(c.maxWidth - 2 * pad, 'endgame'),
                    const SizedBox(height: 40),
                    _SectionHeader(
                      label: 'MIDDLEGAME PLANS',
                      title: 'Think like a master',
                      subtitle:
                          'Strategic ideas from real openings: outposts, '
                          'pawn storms and converting an advantage.',
                    ),
                    const SizedBox(height: 16),
                    _lessonGrid(c.maxWidth - 2 * pad, 'middlegame'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _puzzleSections(double width) {
    final mixed = _sets.where((s) => s.key == 'mixed').firstOrNull;
    final groups = {
      'tactics': 'Tactical motifs',
      'mates': 'Checkmate patterns',
      'endgames': 'Endgame puzzles',
      'openings': 'Opening traps',
    };
    return [
      if (mixed != null)
        _RatedCard(
          set: mixed,
          onTap: () => _then(openPuzzles(context, mixed.key, mixed.name)),
        ),
      for (final g in groups.entries) ...[
        const SizedBox(height: 22),
        Text(g.value.toUpperCase(), style: Typo.label(size: 10)),
        const SizedBox(height: 10),
        _grid(
          width,
          minTile: 220,
          children: [
            for (final s in _sets.where(
              (s) => s.category == g.key && s.key != 'mixed' && s.count > 0,
            ))
              _ThemeTile(
                set: s,
                onTap: () => _then(openPuzzles(context, s.key, s.name)),
              ),
          ],
        ),
      ],
    ];
  }

  Widget _lessonGrid(double width, String category) => _grid(
    width,
    minTile: 300,
    children: [
      for (final l in _lessons.where((l) => l.category == category))
        _LessonCard(
          lesson: l,
          onTap: () => _then(openLesson(context, l, widget.levels)),
        ),
    ],
  );

  static Widget _grid(
    double width, {
    required double minTile,
    required List<Widget> children,
  }) {
    const gap = 14.0;
    final columns = (width / (minTile + gap)).floor().clamp(1, 6);
    final tile = (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final (i, child) in children.indexed)
          SizedBox(
            width: tile,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (i % 12) * 50),
              curve: Curves.easeOutCubic,
              builder: (context, t, c) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - t)),
                  child: c,
                ),
              ),
              child: child,
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Typo.label()),
        const SizedBox(height: 4),
        Text(title, style: Typo.display(40)),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(subtitle, style: Typo.body(14, color: Palette.muted)),
        ),
      ],
    );
  }
}

/// A card that lifts and glows on hover.
class _HoverCard extends StatefulWidget {
  const _HoverCard({
    required this.child,
    required this.onTap,
    this.highlight = false,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback onTap;
  final bool highlight;
  final EdgeInsets padding;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final lit = _hover || widget.highlight;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(Palette.lacquer, Palette.gold, lit ? 0.08 : 0.02)!,
                Palette.ebony,
              ],
            ),
            border: Border.all(
              color: lit
                  ? Palette.gold.withValues(alpha: 0.8)
                  : Palette.goldDeep.withValues(alpha: 0.35),
              width: lit ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: _hover ? 26 : 14,
                offset: Offset(0, _hover ? 12 : 6),
              ),
              if (_hover)
                BoxShadow(
                  color: Palette.goldGlow,
                  blurRadius: 22,
                  spreadRadius: -8,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MistakesBanner extends StatelessWidget {
  const _MistakesBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      onTap: onTap,
      highlight: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          const CoachAvatar(size: 52, speaking: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR MISTAKES', style: Typo.label()),
                const SizedBox(height: 4),
                Text(
                  '$count position${count == 1 ? '' : 's'} from your games '
                  '${count == 1 ? 'deserves' : 'deserve'} a second look',
                  style: Typo.title(22),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find the move you missed. It\'s the fastest way to stop '
                  'repeating the same mistakes.',
                  style: Typo.body(13, color: Palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, color: Palette.gold),
        ],
      ),
    );
  }
}

class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.opening, required this.onTap});

  final OpeningSummary opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = opening;
    final side = o.side == PlayerColor.white ? Side.white : Side.black;
    return _HoverCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: IgnorePointer(
              child: ChessBoardView(
                position: BoardState.fromFen(o.finalFen),
                orientation: side,
                legalMoves: const {},
                onMove: (_) {},
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(o.eco, style: Typo.mono(11, color: Palette.muted)),
                    const SizedBox(width: 8),
                    Image.asset(pieceAsset(side, Role.king), height: 16),
                    const Spacer(),
                    if (o.completed)
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: Palette.win,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  o.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.title(20),
                ),
                const SizedBox(height: 4),
                Text(
                  o.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(12, color: Palette.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Tag(o.level),
                    const SizedBox(width: 6),
                    if (o.trapCount > 0) _Tag('${o.trapCount} traps'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Palette.gold.withValues(alpha: 0.1),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: Typo.body(11, color: Palette.gold)),
    );
  }
}

class _RatedCard extends StatelessWidget {
  const _RatedCard({required this.set, required this.onTap});

  final PuzzleTheme set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = set.attempts == 0 ? null : set.successes / set.attempts;
    return _HoverCard(
      onTap: onTap,
      highlight: true,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF4A3B22), Palette.ebony],
              ),
              border: Border.all(color: Palette.gold),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Palette.gold,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rated puzzles', style: Typo.display(32)),
                Text(
                  rate == null
                      ? 'Your rating rises with every puzzle you solve.'
                      : '${set.attempts} solved attempts · '
                            '${(rate * 100).round()}% success',
                  style: Typo.body(13, color: Palette.muted),
                ),
              ],
            ),
          ),
          GoldButton(label: 'Start', compact: true, onPressed: onTap),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.set, required this.onTap});

  final PuzzleTheme set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = set.attempts == 0 ? null : set.successes / set.attempts;
    final color = rate == null
        ? Palette.goldDeep
        : Color.lerp(Palette.loss, Palette.win, rate)!;
    return _HoverCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(set.name, style: Typo.title(18))),
              Text('${set.count}', style: Typo.mono(11, color: Palette.muted)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            set.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Typo.body(12, color: Palette.muted),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: rate ?? 0,
              minHeight: 4,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rate == null
                ? 'Not tried yet'
                : '${set.successes}/${set.attempts} solved',
            style: Typo.body(11, color: Palette.muted),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final LessonInfo lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final side = l.side == PlayerColor.white ? Side.white : Side.black;
    return _HoverCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: IgnorePointer(
              child: ChessBoardView(
                position: BoardState.fromFen(l.fen),
                orientation: side,
                legalMoves: const {},
                onMove: (_) {},
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                          color: i < l.difficulty
                              ? Palette.gold
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    const Spacer(),
                    if (l.completed)
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: Palette.win,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l.title, style: Typo.title(19)),
                const SizedBox(height: 2),
                Text(
                  l.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(12, color: Palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonDialog extends StatelessWidget {
  const _LessonDialog({required this.lesson});

  final LessonInfo lesson;

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final side = l.side == PlayerColor.white ? Side.white : Side.black;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.88,
        ),
        child: Panel(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.category == 'endgame'
                      ? 'ENDGAME SCHOOL'
                      : 'MIDDLEGAME PLAN',
                  style: Typo.label(),
                ),
                const SizedBox(height: 6),
                Text(l.title, style: Typo.display(36)),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: IgnorePointer(
                      child: ChessBoardView(
                        position: BoardState.fromFen(l.fen),
                        orientation: side,
                        legalMoves: const {},
                        onMove: (_) {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.concept,
                  style: Typo.body(
                    14,
                    color: Palette.ivory,
                  ).copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                Text('KEY POINTS', style: Typo.label(size: 10)),
                const SizedBox(height: 6),
                for (final tip in l.tips)
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
                        Expanded(child: Text(tip, style: Typo.body(13))),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Palette.gold.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Palette.goldDeep.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Palette.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${lessonGoalText(l)}, playing '
                          '${side == Side.white ? 'White' : 'Black'} against '
                          'full-strength Stockfish.',
                          style: Typo.body(13, color: Palette.ivory),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextAction(
                      label: 'Not now',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 8),
                    GoldButton(
                      label: l.completed ? 'Play again' : 'Start lesson',
                      icon: Icons.play_arrow_rounded,
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
