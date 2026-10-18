import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../client.dart';
import '../theme.dart';
import '../widgets/coach_panel.dart';
import '../widgets/move_badge.dart';

/// The body of the "Progress" tab in the lobby (no Scaffold of its own; it is
/// placed inside the lobby's Scaffold/AmbientBackground under a tab header).
///
/// Shows the coach's plan, the headline numbers, the puzzle rating and game
/// accuracy curves, strengths and weaknesses, move quality and the training
/// log. Loads its data itself and refreshes on pull or on the refresh button.
class ProgressView extends StatefulWidget {
  const ProgressView({super.key, required this.onRecommendation});

  /// Called when the user taps a recommendation card.
  final void Function(CoachRecommendation recommendation) onRecommendation;

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

/// The warm orange of the streak flame.
const _flame = Color(0xFFFF9F43);

/// Accuracy below this is "shaky", at or above [_accuracyGreat] "excellent".
const _accuracyGood = 70.0;
const _accuracyGreat = 85.0;

class _ProgressViewState extends State<ProgressView> {
  PlayerProgress? _progress;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_refreshing) return;
    if (_progress != null) {
      setState(() => _refreshing = true);
    } else if (!_loading || _error != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final progress = await client.progress.progress();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      final hadData = _progress != null;
      setState(() {
        _loading = false;
        _refreshing = false;
        if (!hadData) _error = 'Could not load your progress.';
      });
      if (hadData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh. Check your connection.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CoachThinking(label: 'Coach is reviewing your progress'),
      );
    }
    final progress = _progress;
    if (progress == null) {
      return _ErrorState(
        message: _error ?? 'Could not load your progress.',
        onRetry: _load,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return RefreshIndicator(
          color: Palette.gold,
          backgroundColor: Palette.smoke,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: wide
                ? const EdgeInsets.fromLTRB(48, 12, 48, 48)
                : const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1280 : 720),
                child: _dashboard(progress, wide: wide),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dashboard(PlayerProgress p, {required bool wide}) {
    const gap = SizedBox(height: 20);
    final rating = _RatingPanel(
      history: p.puzzleRatingHistory,
      rating: p.puzzleRating,
    );
    final accuracy = _AccuracyPanel(
      values: p.recentAccuracy,
      average: p.averageAccuracy,
    );
    final themes = _ThemesPanel(stats: p.themeStats);
    final motifs = _MotifsPanel(stats: p.motifStats);
    final quality = _MoveQualityPanel(totals: p.classTotals);
    final learning = _LearningPanel(
      progress: p,
      onReview: () => widget.onRecommendation(
        CoachRecommendation(
          kind: 'mistakes',
          title: 'Review your mistakes',
          body:
              'Replay the positions where you went wrong and find the '
              'better move.',
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Entrance(
          index: 0,
          child: _Intro(
            progress: p,
            refreshing: _refreshing,
            onRefresh: _load,
          ),
        ),
        const SizedBox(height: 14),
        _Entrance(
          index: 1,
          child: _PlanPanel(
            recommendations: p.recommendations,
            onTap: widget.onRecommendation,
            wide: wide,
          ),
        ),
        gap,
        _Entrance(index: 2, child: _StatTiles(progress: p)),
        gap,
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Entrance(index: 3, child: rating),
                    gap,
                    _Entrance(index: 5, child: themes),
                    gap,
                    _Entrance(index: 7, child: quality),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Entrance(index: 4, child: accuracy),
                    gap,
                    _Entrance(index: 6, child: motifs),
                    gap,
                    _Entrance(index: 8, child: learning),
                  ],
                ),
              ),
            ],
          )
        else ...[
          _Entrance(index: 3, child: rating),
          gap,
          _Entrance(index: 4, child: accuracy),
          gap,
          _Entrance(index: 5, child: themes),
          gap,
          _Entrance(index: 6, child: motifs),
          gap,
          _Entrance(index: 7, child: quality),
          gap,
          _Entrance(index: 8, child: learning),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header and coach's plan
// ---------------------------------------------------------------------------

class _Intro extends StatelessWidget {
  const _Intro({
    required this.progress,
    required this.refreshing,
    required this.onRefresh,
  });

  final PlayerProgress progress;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR PROGRESS', style: Typo.label()),
              const SizedBox(height: 4),
              Text(_motto(progress), style: Typo.body(14)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          onPressed: refreshing ? null : onRefresh,
          hoverColor: Palette.gold.withValues(alpha: 0.12),
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Palette.gold,
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Palette.muted),
        ),
      ],
    );
  }

  static String _motto(PlayerProgress p) {
    if (p.dayStreak > 0) {
      return '${p.dayStreak}-day streak. A little training every day keeps '
          'it alive.';
    }
    if (p.gamesPlayed == 0 && p.puzzlesSolved + p.puzzlesFailed == 0) {
      return 'Every master was once a beginner. Your first game or puzzle '
          'starts the story.';
    }
    return 'Train today to start a new streak.';
  }
}

class _PlanPanel extends StatelessWidget {
  const _PlanPanel({
    required this.recommendations,
    required this.onTap,
    required this.wide,
  });

  final List<CoachRecommendation> recommendations;
  final void Function(CoachRecommendation recommendation) onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final recs = recommendations;
    return Panel(
      highlight: true,
      padding: EdgeInsets.all(wide ? 26 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CoachAvatar(size: wide ? 56 : 48, speaking: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COACH\'S PLAN FOR YOU', style: Typo.label()),
                    const SizedBox(height: 6),
                    Text(
                      recs.isEmpty
                          ? 'Let\'s get to know your game'
                          : 'Here is what to work on next',
                      style: Typo.display(wide ? 40 : 30),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recs.isEmpty)
            Text(
              'Play a game or solve a few puzzles, and I will put together a '
              'plan made for you.',
              style: Typo.display(20, color: Palette.muted),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final n = recs.length;
                final columns = w >= 860
                    ? (n <= 3 ? n : (n == 4 ? 2 : 3))
                    : w >= 540
                    ? min(2, n)
                    : 1;
                return _Grid(
                  columns: columns,
                  gap: 12,
                  children: [
                    for (final (i, rec) in recs.indexed)
                      _Entrance(
                        index: 2 + i,
                        child: _RecommendationCard(
                          recommendation: rec,
                          primary: i == 0,
                          onTap: () => onTap(rec),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

({IconData icon, String label, String cta}) _kindStyle(String kind) =>
    switch (kind) {
      'puzzles' => (
        icon: Icons.extension_rounded,
        label: 'PUZZLES',
        cta: 'Solve puzzles',
      ),
      'lesson' => (
        icon: Icons.school_rounded,
        label: 'LESSON',
        cta: 'Start the lesson',
      ),
      'opening' => (
        icon: Icons.menu_book_rounded,
        label: 'OPENING',
        cta: 'Study the opening',
      ),
      'mistakes' => (
        icon: Icons.replay_rounded,
        label: 'REVIEW',
        cta: 'Review mistakes',
      ),
      'play' => (
        icon: Icons.sports_esports_rounded,
        label: 'PLAY',
        cta: 'Play a game',
      ),
      _ => (icon: Icons.auto_awesome_rounded, label: 'PRACTICE', cta: 'Begin'),
    };

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.primary,
    required this.onTap,
  });

  final CoachRecommendation recommendation;
  final bool primary;
  final VoidCallback onTap;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final style = _kindStyle(rec.kind);
    final primary = widget.primary;
    final lit = primary || _hover;
    return Semantics(
      button: true,
      label: rec.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) {
            setState(() => _down = false);
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _down ? 0.98 : (_hover ? 1.015 : 1),
            duration: const Duration(milliseconds: 160),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: primary
                      ? [const Color(0xFF3A2F1C), const Color(0xFF1C1710)]
                      : [
                          Colors.white.withValues(alpha: _hover ? 0.06 : 0.03),
                          Colors.white.withValues(alpha: 0.01),
                        ],
                ),
                border: Border.all(
                  color: lit
                      ? Palette.gold
                      : Palette.goldDeep.withValues(alpha: 0.35),
                  width: primary ? 1.3 : 0.8,
                ),
                boxShadow: [
                  if (lit)
                    BoxShadow(
                      color: Palette.goldGlow,
                      blurRadius: _hover ? 28 : 20,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hover ? Palette.gold : null,
                          gradient: _hover
                              ? null
                              : const RadialGradient(
                                  colors: [Color(0xFF3A3020), Palette.ebony],
                                ),
                          border: Border.all(color: Palette.gold, width: 1.2),
                        ),
                        child: Icon(
                          style.icon,
                          size: 22,
                          color: _hover ? Palette.onyx : Palette.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          style.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Typo.label(size: 10),
                        ),
                      ),
                      if (primary)
                        const _Tag(label: 'START HERE', color: Palette.gold),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(rec.title, style: Typo.title(23)),
                  const SizedBox(height: 6),
                  Text(rec.body, style: Typo.body(13)),
                  const SizedBox(height: 14),
                  const Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          style.cta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Typo.body(
                            13,
                            color: Palette.gold,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(left: _hover ? 10 : 6),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Palette.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat tiles
// ---------------------------------------------------------------------------

class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final history = p.puzzleRatingHistory;
    final delta = history.length >= 2 ? history.last - history.first : null;
    final avg = p.averageAccuracy;
    final personalBest =
        p.puzzleStreak > 0 && p.puzzleStreak >= p.bestPuzzleStreak;

    final tiles = <Widget>[
      _StatTile(
        icon: const Icon(
          Icons.extension_rounded,
          size: 18,
          color: Palette.gold,
        ),
        label: 'PUZZLE RATING',
        value: _CountUp(
          p.puzzleRating.toDouble(),
          style: Typo.display(46, color: Palette.gold),
        ),
        footer: delta != null
            ? _DeltaChip(delta: delta)
            : Text(
                'Solve rated puzzles to move it',
                style: Typo.body(12, color: Palette.muted),
              ),
      ),
      _StatTile(
        icon: _Flame(active: p.dayStreak > 0),
        label: 'DAY STREAK',
        glow: p.dayStreak > 0 ? _flame : null,
        value: _CountUp(p.dayStreak.toDouble(), style: Typo.display(46)),
        unit: p.dayStreak == 1 ? 'day' : 'days',
        footer: Text(
          p.dayStreak > 0 ? 'Keep the fire going' : 'Train today to start one',
          style: Typo.body(
            12,
            color: p.dayStreak > 0 ? _flame : Palette.muted,
            weight: FontWeight.w700,
          ),
        ),
      ),
      _StatTile(
        icon: const Icon(Icons.bolt_rounded, size: 20, color: Palette.gold),
        label: 'PUZZLE STREAK',
        value: _CountUp(p.puzzleStreak.toDouble(), style: Typo.display(46)),
        unit: 'in a row',
        footer: Text(
          personalBest ? 'Personal best!' : 'Best ${p.bestPuzzleStreak}',
          style: Typo.body(
            12,
            color: personalBest ? Palette.gold : Palette.muted,
            weight: FontWeight.w700,
          ),
        ),
      ),
      _StatTile(
        icon: const Icon(
          Icons.emoji_events_rounded,
          size: 18,
          color: Palette.gold,
        ),
        label: 'GAMES',
        value: _CountUp(p.gamesPlayed.toDouble(), style: Typo.display(46)),
        unit: 'played',
        footer: _WinDrawLoss(wins: p.wins, draws: p.draws, losses: p.losses),
      ),
      _StatTile(
        icon: const Icon(
          Icons.track_changes_rounded,
          size: 18,
          color: Palette.gold,
        ),
        label: 'ACCURACY',
        value: avg == null
            ? Text('—', style: Typo.display(46, color: Palette.muted))
            : _CountUp(avg, decimals: 1, style: Typo.display(46)),
        unit: avg == null ? null : '%',
        footer: Text(
          avg == null ? 'Finish a reviewed game' : _accuracyWord(avg),
          style: Typo.body(
            12,
            color: avg == null ? Palette.muted : _accuracyColor(avg),
            weight: FontWeight.w700,
          ),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 900 ? 5 : (w >= 560 ? 3 : 2);
        return _Grid(columns: columns, gap: 12, children: tiles);
      },
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.footer,
    this.unit,
    this.glow,
  });

  final Widget icon;
  final String label;
  final Widget value;
  final String? unit;
  final Widget footer;

  /// A colour the tile is softly lit with, e.g. the streak flame.
  final Color? glow;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.glow;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glow != null
                  ? Color.lerp(const Color(0xE6221E18), glow, 0.10)!
                  : const Color(0xE6221E18),
              const Color(0xE6120F0C),
            ],
          ),
          border: Border.all(
            color: _hover
                ? Palette.gold.withValues(alpha: 0.85)
                : (glow?.withValues(alpha: 0.45) ??
                      Palette.goldDeep.withValues(alpha: 0.4)),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: _hover ? 26 : 18,
              offset: Offset(0, _hover ? 14 : 10),
            ),
            if (_hover || glow != null)
              BoxShadow(
                color: (glow ?? Palette.gold).withValues(
                  alpha: _hover ? 0.28 : 0.14,
                ),
                blurRadius: 22,
                spreadRadius: -6,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(child: widget.icon),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: Typo.label(size: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  widget.value,
                  if (widget.unit != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.unit!,
                      style: Typo.body(13, color: Palette.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Spacer(),
            widget.footer,
          ],
        ),
      ),
    );
  }
}

class _WinDrawLoss extends StatelessWidget {
  const _WinDrawLoss({
    required this.wins,
    required this.draws,
    required this.losses,
  });

  final int wins;
  final int draws;
  final int losses;

  @override
  Widget build(BuildContext context) {
    final total = wins + draws + losses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$wins W',
                  style: Typo.mono(12, color: Palette.win),
                ),
                TextSpan(
                  text: '  ·  ',
                  style: Typo.mono(12, color: Palette.muted),
                ),
                TextSpan(
                  text: '$draws D',
                  style: Typo.mono(12, color: Palette.draw),
                ),
                TextSpan(
                  text: '  ·  ',
                  style: Typo.mono(12, color: Palette.muted),
                ),
                TextSpan(
                  text: '$losses L',
                  style: Typo.mono(12, color: Palette.loss),
                ),
              ],
            ),
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  if (wins > 0)
                    Expanded(
                      flex: wins,
                      child: const ColoredBox(color: Palette.win),
                    ),
                  if (draws > 0)
                    Expanded(
                      flex: draws,
                      child: const ColoredBox(color: Palette.draw),
                    ),
                  if (losses > 0)
                    Expanded(
                      flex: losses,
                      child: const ColoredBox(color: Palette.loss),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The streak flame, breathing with a warm glow while the streak is alive.
class _Flame extends StatefulWidget {
  const _Flame({required this.active});

  final bool active;

  @override
  State<_Flame> createState() => _FlameState();
}

class _FlameState extends State<_Flame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Flame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const Icon(
        Icons.local_fire_department_outlined,
        size: 20,
        color: Palette.muted,
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _flame.withValues(alpha: 0.22 + 0.33 * t),
                blurRadius: 10 + 10 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: Transform.scale(scale: 1 + 0.1 * t, child: child),
        );
      },
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFE5532D), _flame, Color(0xFFFFD36E)],
        ).createShader(rect),
        child: const Icon(
          Icons.local_fire_department_rounded,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final color = delta > 0
        ? Palette.win
        : (delta < 0 ? Palette.loss : Palette.draw);
    final icon = delta > 0
        ? Icons.trending_up_rounded
        : (delta < 0
              ? Icons.trending_down_rounded
              : Icons.trending_flat_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            delta > 0 ? '+$delta' : '$delta',
            style: Typo.mono(12, color: color).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({required this.history, required this.rating});

  final List<int> history;
  final int rating;

  @override
  Widget build(BuildContext context) {
    final enough = history.length >= 2;
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            label: 'PUZZLE RATING',
            title: 'Your rating curve',
            trailing: enough
                ? _DeltaChip(delta: history.last - history.first)
                : null,
          ),
          const SizedBox(height: 18),
          if (!enough)
            const _EmptyChart(
              icon: Icons.show_chart_rounded,
              text: 'Solve a few rated puzzles to see your rating curve',
            )
          else ...[
            SizedBox(
              height: 170,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1300),
                curve: Curves.easeInOutCubic,
                builder: (context, t, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _RatingChartPainter(
                    values: history,
                    progress: t,
                    maxStyle: Typo.mono(11, color: Palette.gold),
                    minStyle: Typo.mono(11, color: Palette.muted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last ${history.length} rated puzzles',
                    style: Typo.body(12, color: Palette.muted),
                  ),
                ),
                Text(
                  'Now $rating',
                  style: Typo.mono(12, color: Palette.parchment),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingChartPainter extends CustomPainter {
  _RatingChartPainter({
    required this.values,
    required this.progress,
    required this.maxStyle,
    required this.minStyle,
  });

  final List<int> values;
  final double progress;
  final TextStyle maxStyle;
  final TextStyle minStyle;

  static const _gutter = 46.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= _gutter) return;
    final chart = Rect.fromLTRB(4, 12, size.width - _gutter, size.height - 12);

    final hi = values.reduce(max);
    final lo = values.reduce(min);
    var top = hi.toDouble();
    var bottom = lo.toDouble();
    if (top - bottom < 20) {
      final mid = (top + bottom) / 2;
      top = mid + 10;
      bottom = mid - 10;
    }
    final pad = (top - bottom) * 0.1;
    top += pad;
    bottom -= pad;

    double y(num v) =>
        chart.bottom - (v - bottom) / (top - bottom) * chart.height;
    Offset point(int i) => Offset(
      chart.left + chart.width * i / (values.length - 1),
      y(values[i]),
    );
    final points = [for (var i = 0; i < values.length; i++) point(i)];

    // Guides at the best and lowest rating, labelled in the right gutter.
    final guide = Paint()
      ..color = Palette.goldDeep.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    for (final (value, style) in [
      (hi, maxStyle),
      if (lo != hi) (lo, minStyle),
    ]) {
      final gy = y(value);
      _dashedLine(canvas, gy, chart.left, chart.right, guide);
      final tp = TextPainter(
        text: TextSpan(text: '$value', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chart.right + 8, gy - tp.height / 2));
      tp.dispose();
    }

    // A smooth line with horizontal tangents, so it never overshoots.
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final cx = (a.dx + b.dx) / 2;
      line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, chart.bottom)
      ..lineTo(points.first.dx, chart.bottom)
      ..close();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, chart.left + chart.width * progress + 6, size.height),
    );
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.gold.withValues(alpha: 0.34),
            Palette.gold.withValues(alpha: 0.0),
          ],
        ).createShader(chart),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          colors: [Palette.goldDeep, Palette.gold, Color(0xFFF1D79B)],
        ).createShader(chart),
    );

    // Mark the peak and the low point.
    final hiIndex = values.indexOf(hi);
    final loIndex = values.indexOf(lo);
    for (final i in {hiIndex, loIndex}) {
      if (i == values.length - 1) continue;
      canvas.drawCircle(points[i], 3.4, Paint()..color = Palette.ebony);
      canvas.drawCircle(
        points[i],
        3.4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = i == hiIndex ? Palette.gold : Palette.muted,
      );
    }
    canvas.restore();

    // The current rating: a lit dot that appears as the line arrives.
    final dot = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    if (dot > 0) {
      final last = points.last;
      canvas.drawCircle(
        last,
        10 * dot,
        Paint()
          ..color = Palette.gold.withValues(alpha: 0.35 * dot)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        last,
        4.2 * dot,
        Paint()..color = Palette.ivory.withValues(alpha: dot),
      );
      canvas.drawCircle(
        last,
        4.2 * dot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Palette.gold.withValues(alpha: dot),
      );
    }
  }

  @override
  bool shouldRepaint(_RatingChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

class _AccuracyPanel extends StatelessWidget {
  const _AccuracyPanel({required this.values, required this.average});

  final List<double> values;
  final double? average;

  static const _maxBars = 24;
  static const _height = 160.0;

  @override
  Widget build(BuildContext context) {
    final shown = values.length > _maxBars
        ? values.sublist(values.length - _maxBars)
        : values;
    final offset = values.length - shown.length;
    final latest = shown.isEmpty ? null : shown.last;
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            label: 'GAME ACCURACY',
            title: 'How precisely you play',
            trailing: latest == null
                ? null
                : _Tag(
                    label: 'LAST ${latest.round()}%',
                    color: _accuracyColor(latest),
                  ),
          ),
          const SizedBox(height: 18),
          if (shown.isEmpty)
            const _EmptyChart(
              icon: Icons.bar_chart_rounded,
              text: 'Finish a game with the coach to see your accuracy',
            )
          else ...[
            SizedBox(
              height: _height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AccuracyGuidesPainter(
                        style: Typo.mono(10, color: Palette.muted),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: _AccuracyGuidesPainter.gutter,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, v) in shown.indexed)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: shown.length > 16 ? 1.5 : 3,
                              ),
                              child: _AccuracyBar(
                                value: v,
                                index: i,
                                label: 'Game ${offset + i + 1}',
                              ),
                            ),
                          ),
                        // Few games: keep bars slim rather than stretched.
                        if (shown.length < 8) Spacer(flex: 8 - shown.length),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _LegendDot(color: Palette.win, label: '85+ excellent'),
                const _LegendDot(color: Palette.gold, label: '70–85 solid'),
                _LegendDot(
                  color: MoveClass.mistake.color,
                  label: 'under 70 shaky',
                ),
                if (average != null)
                  Text(
                    'Average ${average!.toStringAsFixed(1)}%',
                    style: Typo.mono(12, color: Palette.parchment),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccuracyBar extends StatefulWidget {
  const _AccuracyBar({
    required this.value,
    required this.index,
    required this.label,
  });

  final double value;
  final int index;
  final String label;

  @override
  State<_AccuracyBar> createState() => _AccuracyBarState();
}

class _AccuracyBarState extends State<_AccuracyBar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.value.clamp(0.0, 100.0);
    final color = _accuracyColor(v);
    return Tooltip(
      message: '${widget.label} · ${v.toStringAsFixed(1)}%',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v / 100),
          duration: Duration(
            milliseconds: min(1500, 650 + widget.index * 40),
          ),
          curve: Curves.easeOutCubic,
          builder: (context, f, _) => Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: max(f, 0.015),
              widthFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                    bottom: Radius.circular(2),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: _hover ? 1 : 0.9),
                      color.withValues(alpha: _hover ? 0.7 : 0.4),
                    ],
                  ),
                  boxShadow: [
                    if (_hover)
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint reference lines at 70 % and 85 % behind the accuracy bars.
class _AccuracyGuidesPainter extends CustomPainter {
  _AccuracyGuidesPainter({required this.style});

  final TextStyle style;

  static const gutter = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final right = size.width - gutter;
    final base = Paint()
      ..color = Palette.goldDeep.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(0, size.height - 0.4),
      Offset(right, size.height - 0.4),
      base,
    );
    for (final (level, color) in [
      (100.0, Palette.muted),
      (_accuracyGreat, Palette.win),
      (_accuracyGood, Palette.gold),
    ]) {
      final y = size.height * (1 - level / 100);
      _dashedLine(
        canvas,
        y,
        0,
        right,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..strokeWidth = 0.8,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: level.round().toString(),
          style: style.copyWith(color: color.withValues(alpha: 0.85)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          right + 8,
          (y - tp.height / 2).clamp(0, size.height - tp.height),
        ),
      );
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_AccuracyGuidesPainter oldDelegate) =>
      oldDelegate.style != style;
}

// ---------------------------------------------------------------------------
// Strengths and weaknesses
// ---------------------------------------------------------------------------

class _ThemesPanel extends StatefulWidget {
  const _ThemesPanel({required this.stats});

  final List<ThemeStat> stats;

  @override
  State<_ThemesPanel> createState() => _ThemesPanelState();
}

class _ThemesPanelState extends State<_ThemesPanel> {
  static const _collapsed = 7;
  bool _all = false;

  static double _rate(ThemeStat s) =>
      s.attempts == 0 ? 0 : s.successes / s.attempts;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats.where((s) => s.attempts > 0).toList()
      ..sort((a, b) {
        final byRate = _rate(b).compareTo(_rate(a));
        return byRate != 0 ? byRate : b.attempts.compareTo(a.attempts);
      });
    final shown = _all ? stats : stats.take(_collapsed).toList();
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            label: 'PUZZLE THEMES',
            title: 'Strengths & weaknesses',
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            const _EmptyNote(
              icon: Icons.extension_rounded,
              text: 'Solve some puzzles to discover your strongest themes.',
            )
          else ...[
            if (stats.length >= 2) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    icon: Icons.trending_up_rounded,
                    color: Palette.win,
                    text: 'Strongest · ${stats.first.name}',
                  ),
                  _Pill(
                    icon: Icons.flag_rounded,
                    color: Palette.loss,
                    text: 'Work on · ${stats.last.name}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            for (final (i, s) in shown.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RateBar(
                  name: s.name,
                  detail: '${s.successes}/${s.attempts}',
                  tooltip:
                      '${s.successes} solved of ${s.attempts} '
                      '${s.attempts == 1 ? 'attempt' : 'attempts'}',
                  fraction: _rate(s),
                  color: _rateColor(_rate(s)),
                  trailing: '${(_rate(s) * 100).round()}%',
                  index: i,
                ),
              ),
            if (stats.length > _collapsed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _all = !_all),
                  style: TextButton.styleFrom(
                    foregroundColor: Palette.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  icon: Icon(
                    _all
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _all ? 'Show fewer' : 'Show all ${stats.length} themes',
                    style: Typo.body(
                      13,
                      color: Palette.gold,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MotifsPanel extends StatelessWidget {
  const _MotifsPanel({required this.stats});

  final List<ThemeStat> stats;

  static const _bars = 5;

  @override
  Widget build(BuildContext context) {
    final sorted = stats.where((s) => s.attempts > 0).toList()
      ..sort((a, b) => b.attempts.compareTo(a.attempts));
    final top = sorted.take(_bars).toList();
    final rest = sorted.skip(_bars).toList();
    final most = sorted.isEmpty ? 1 : sorted.first.attempts;
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            label: 'IN YOUR GAMES',
            title: 'What costs you in games',
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            const _EmptyNote(
              icon: Icons.verified_rounded,
              text:
                  'No recurring mistakes spotted yet. Play a few games with '
                  'the coach and I will find your patterns.',
            )
          else ...[
            for (final (i, s) in top.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RateBar(
                  name: s.name,
                  tooltip:
                      'Flagged ${s.attempts} '
                      '${s.attempts == 1 ? 'time' : 'times'} in your games',
                  fraction: s.attempts / most,
                  color: Color.lerp(
                    Palette.loss,
                    MoveClass.inaccuracy.color,
                    top.length == 1 ? 0 : i / (top.length - 1) * 0.8,
                  )!,
                  trailing: '×${s.attempts}',
                  index: i,
                ),
              ),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in rest)
                    _CountChip(name: s.name, count: s.attempts),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Counted from the moves the coach flagged in your games.',
              style: Typo.body(12, color: Palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A labelled horizontal bar that grows in when it appears.
class _RateBar extends StatelessWidget {
  const _RateBar({
    required this.name,
    required this.fraction,
    required this.color,
    required this.trailing,
    required this.tooltip,
    required this.index,
    this.detail,
  });

  final String name;
  final String? detail;
  final double fraction;
  final Color color;
  final String trailing;
  final String tooltip;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(
                    13,
                    color: Palette.ivory,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: 8),
                Text(detail!, style: Typo.mono(11, color: Palette.muted)),
              ],
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 38),
                child: Text(
                  trailing,
                  textAlign: TextAlign.right,
                  style: Typo.mono(12, color: color).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
              duration: Duration(milliseconds: min(1400, 700 + index * 70)),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: f,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.55), color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: -2,
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
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Palette.loss.withValues(alpha: 0.07),
        border: Border.all(
          color: Palette.loss.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Typo.body(12, color: Palette.parchment),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Palette.loss.withValues(alpha: 0.2),
            ),
            child: Text(
              '$count',
              style: Typo.mono(11, color: Palette.loss).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Move quality
// ---------------------------------------------------------------------------

class _MoveQualityPanel extends StatelessWidget {
  const _MoveQualityPanel({required this.totals});

  final Map<String, int> totals;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final mc in MoveClass.values)
        if ((totals[mc.name] ?? 0) > 0) (mc, totals[mc.name]!),
    ];
    final total = entries.fold(0, (sum, e) => sum + e.$2);
    final good = entries
        .where((e) => !e.$1.isError)
        .fold(0, (sum, e) => sum + e.$2);
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            label: 'MOVE QUALITY',
            title: 'Every move, graded',
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const _EmptyNote(
              icon: Icons.star_outline_rounded,
              text:
                  'Finish a game with the coach and your move verdicts will '
                  'show up here.',
            )
          else ...[
            // The whole distribution at a glance.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: t,
                  child: child,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (final (mc, count) in entries)
                        Expanded(
                          flex: count,
                          child: Tooltip(
                            message: '${mc.label}: ${_percent(count, total)}',
                            child: ColoredBox(color: mc.color),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _percent(good, total),
                    style: Typo.body(
                      14,
                      color: Palette.gold,
                      weight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' of your $total moves were good or better.',
                    style: Typo.body(14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 112).floor().clamp(
                  2,
                  5,
                );
                return _Grid(
                  columns: columns,
                  gap: 10,
                  fillLastRow: false,
                  children: [
                    for (final (mc, count) in entries)
                      _MoveClassTile(
                        classification: mc,
                        count: count,
                        share: _percent(count, total),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  static String _percent(int part, int total) =>
      total == 0 ? '0%' : '${(part / total * 100).round()}%';
}

class _MoveClassTile extends StatefulWidget {
  const _MoveClassTile({
    required this.classification,
    required this.count,
    required this.share,
  });

  final MoveClass classification;
  final int count;
  final String share;

  @override
  State<_MoveClassTile> createState() => _MoveClassTileState();
}

class _MoveClassTileState extends State<_MoveClassTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final mc = widget.classification;
    return Tooltip(
      message: '${mc.label}: ${widget.share} of your moves',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: mc.color.withValues(alpha: _hover ? 0.13 : 0.06),
            border: Border.all(
              color: mc.color.withValues(alpha: _hover ? 0.85 : 0.32),
              width: 0.8,
            ),
            boxShadow: [
              if (_hover)
                BoxShadow(
                  color: mc.color.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: _hover ? 1.1 : 1,
                duration: const Duration(milliseconds: 200),
                child: MoveBadge(mc, size: 30),
              ),
              const SizedBox(height: 8),
              _CountUp(
                widget.count.toDouble(),
                style: Typo.title(24, color: Palette.ivory),
              ),
              const SizedBox(height: 2),
              Text(
                mc.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Typo.body(11, color: mc.color, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Learning log
// ---------------------------------------------------------------------------

class _LearningPanel extends StatelessWidget {
  const _LearningPanel({required this.progress, required this.onReview});

  final PlayerProgress progress;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final attempts = p.puzzlesSolved + p.puzzlesFailed;
    final review = p.mistakesToReview;
    final items = [
      _LogItem(
        icon: Icons.school_rounded,
        value: p.lessonsCompleted,
        label: p.lessonsCompleted == 1
            ? 'Lesson completed'
            : 'Lessons completed',
      ),
      _LogItem(
        icon: Icons.menu_book_rounded,
        value: p.openingsCompleted,
        label: p.openingsCompleted == 1
            ? 'Opening completed'
            : 'Openings completed',
      ),
      _LogItem(
        icon: Icons.extension_rounded,
        value: p.puzzlesSolved,
        label: p.puzzlesSolved == 1 ? 'Puzzle solved' : 'Puzzles solved',
        note: attempts == 0
            ? null
            : '${(p.puzzlesSolved / attempts * 100).round()}% success',
      ),
      _LogItem(
        icon: Icons.replay_rounded,
        value: review,
        label: 'Mistakes to review',
        accent: review > 0 ? Palette.loss : Palette.win,
        note: review > 0 ? 'Review now' : 'All caught up',
        onTap: review > 0 ? onReview : null,
      ),
    ];
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(label: 'LEARNING', title: 'Your training log'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => _Grid(
              columns: constraints.maxWidth >= 300 ? 2 : 1,
              gap: 10,
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatefulWidget {
  const _LogItem({
    required this.icon,
    required this.value,
    required this.label,
    this.note,
    this.accent = Palette.gold,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final String? note;
  final Color accent;
  final VoidCallback? onTap;

  @override
  State<_LogItem> createState() => _LogItemState();
}

class _LogItemState extends State<_LogItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final accent = widget.accent;
    final lit = _hover && tappable;
    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: lit
                ? accent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: _hover ? 0.05 : 0.025),
            border: Border.all(
              color: lit
                  ? accent
                  : (tappable
                        ? accent.withValues(alpha: 0.45)
                        : Palette.goldDeep.withValues(alpha: 0.3)),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Icon(widget.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CountUp(widget.value.toDouble(), style: Typo.title(26)),
                    Text(
                      widget.label,
                      style: Typo.body(12, color: Palette.muted),
                    ),
                    if (widget.note != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Typo.body(
                                12,
                                color: tappable || widget.accent != Palette.gold
                                    ? accent
                                    : Palette.parchment,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (tappable)
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.only(left: lit ? 8 : 4),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: accent,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// Fades and lifts [child] in, a little after the items before it.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = min(index, 10) * 80;
    final total = 480 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Rows of equally wide, equally tall cells.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.columns,
    required this.children,
    this.gap = 12,
    this.fillLastRow = true,
  });

  final int columns;
  final List<Widget> children;
  final double gap;

  /// Whether a short last row stretches to the full width.
  final bool fillLastRow;

  @override
  Widget build(BuildContext context) {
    final cols = max(1, columns);
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += cols) {
      final row = children.sublist(start, min(start + cols, children.length));
      final slots = fillLastRow ? row.length : cols;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < slots; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: j < row.length ? row[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          row,
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.title,
    this.trailing,
  });

  final String label;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Typo.label()),
              const SizedBox(height: 6),
              Text(title, style: Typo.display(30)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// A number that counts up to [value] when it appears or changes.
class _CountUp extends StatelessWidget {
  const _CountUp(this.value, {required this.style, this.decimals = 0});

  final double value;
  final TextStyle style;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(v.toStringAsFixed(decimals), style: style),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Typo.body(
                12,
                color: Palette.ivory,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Typo.body(12, color: Palette.muted)),
      ],
    );
  }
}

/// The placeholder where a chart will be once there is data.
class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: Palette.goldDeep.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Palette.goldDeep),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Typo.display(21, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A friendly line for a section without data yet.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 22, color: Palette.goldDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Typo.display(20, color: Palette.muted)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: Palette.goldDeep,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Typo.display(30),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: Typo.body(14, color: Palette.muted),
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Red for a weak success rate, gold for middling, green for strong.
Color _rateColor(double rate) => rate < 0.5
    ? Color.lerp(Palette.loss, Palette.gold, rate / 0.5)!
    : Color.lerp(Palette.gold, Palette.win, (rate - 0.5) / 0.5)!;

Color _accuracyColor(double accuracy) => accuracy >= _accuracyGreat
    ? Palette.win
    : accuracy >= _accuracyGood
    ? Palette.gold
    : accuracy >= 55
    ? MoveClass.mistake.color
    : Palette.loss;

String _accuracyWord(double accuracy) => accuracy >= _accuracyGreat
    ? 'Excellent precision'
    : accuracy >= _accuracyGood
    ? 'Solid play'
    : 'Room to grow';

void _dashedLine(Canvas canvas, double y, double x0, double x1, Paint paint) {
  const dash = 4.0;
  const space = 4.0;
  for (var x = x0; x < x1; x += dash + space) {
    canvas.drawLine(Offset(x, y), Offset(min(x + dash, x1), y), paint);
  }
}
