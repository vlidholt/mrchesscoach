import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../game/chess_model.dart';
import '../theme.dart';
import '../widgets/chess_board.dart';
import '../widgets/coach_avatar.dart';
import '../widgets/fx.dart';
import '../widgets/recent_games.dart';
import 'game_screen.dart';
import 'learn_view.dart';
import 'progress_screen.dart';
import 'puzzle_screen.dart';
import 'review_screen.dart';

/// The menu: continue a game or start one, learn, and see your progress.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

/// The side the player picks; null in [PlayerColor] terms means random.
enum ColorChoice { white, random, black }

/// The settings picked in the new game sheet.
typedef NewGameChoice = ({
  int level,
  ColorChoice color,
  bool coach,
  Offset? origin,
});

class _LobbyScreenState extends State<LobbyScreen> {
  List<ChessLevel> _levels = [];
  ChessGame? _active;
  List<ChessGame> _history = [];
  bool _loading = true;
  bool _starting = false;
  String? _error;

  int _level = 2;
  ColorChoice _color = ColorChoice.white;
  bool _coach = true;

  /// 0 = Play, 1 = Learn, 2 = Progress.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in [...allBoardAssets, ...coachAssets]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  Future<void> _load({bool pickLevel = true}) async {
    setState(() {
      _loading = _levels.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        client.game.levels(),
        client.game.activeGame(),
        client.game.finishedGames(),
      ]);
      if (!mounted) return;
      setState(() {
        _levels = results[0] as List<ChessLevel>;
        _active = results[1] as ChessGame?;
        _history = results[2] as List<ChessGame>;
        final recent = _active ?? _history.firstOrNull;
        if (pickLevel && recent != null) _level = recent.level;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'I can\'t reach the club right now.';
      });
    }
  }

  Future<void> _newGame(BuildContext buttonContext) async {
    if (_levels.isEmpty) return;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    final sheet = NewGameSheet(
      levels: _levels,
      level: _level,
      color: _color,
      coach: _coach,
      abandons: _active != null,
    );
    final choice = wide
        ? await showDialog<NewGameChoice>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.65),
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: sheet,
              ),
            ),
          )
        : await showModalBottomSheet<NewGameChoice>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.65),
            builder: (_) => sheet,
          );
    if (choice == null || !mounted) return;
    setState(() {
      _level = choice.level;
      _color = choice.color;
      _coach = choice.coach;
    });
    await _start(choice.origin);
  }

  Future<void> _start(Offset? origin) async {
    setState(() => _starting = true);
    try {
      final game = await client.game.startGame(
        _level,
        switch (_color) {
          ColorChoice.white => PlayerColor.white,
          ColorChoice.black => PlayerColor.black,
          ColorChoice.random => null,
        },
        _coach,
      );
      await _open(game, origin: origin);
    } on ChessGameException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not start the game. Try again.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// The lesson a resumed game belongs to, so its banner and tips return.
  Future<GameLesson?> _lessonOf(ChessGame game) async {
    final id = game.lessonId;
    if (id == null) return null;
    try {
      if (game.startFen != null) {
        final lessons = await client.learn.lessons();
        final l = lessons.where((l) => l.id == id).firstOrNull;
        return l == null
            ? null
            : GameLesson(
                title: l.title,
                goal: lessonGoalText(l),
                tips: l.tips,
              );
      }
      final course = await client.learn.opening(id);
      return GameLesson(
        title: course.name,
        goal: 'Play on from the main line and use its ideas',
        tips: course.ideas.take(3).toList(),
        openingPlies: course.steps.length,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _open(ChessGame game, {Offset? origin}) async {
    if (!mounted) return;
    final lesson = await _lessonOf(game);
    if (!mounted) return;
    await Navigator.of(context).push(
      FxPageRoute<void>(
        origin: origin,
        builder: (_) => GameScreen(game: game, levels: _levels, lesson: lesson),
      ),
    );
    if (mounted) await _load(pickLevel: false);
  }

  Future<void> _review(ChessGame game) async {
    await Navigator.of(context).push(
      FxPageRoute<void>(
        builder: (_) => ReviewScreen(gameId: game.id!, levels: _levels),
      ),
    );
  }

  /// Follows one of the coach's suggestions from the progress page.
  Future<void> _recommendation(CoachRecommendation r) async {
    switch (r.kind) {
      case 'mistakes':
        await openPuzzles(context, mistakesSetKey, 'Your mistakes');
      case 'puzzles':
        await openPuzzles(
          context,
          r.ref ?? 'mixed',
          r.title.replaceFirst(RegExp(r'^(Train|Strengthen): '), ''),
        );
      case 'opening' when r.ref != null:
        await openOpening(context, r.ref!, _levels);
      case 'lesson' when r.ref != null:
        try {
          final lessons = await client.learn.lessons();
          final lesson = lessons.where((l) => l.id == r.ref).firstOrNull;
          if (lesson != null && mounted) {
            await openLesson(context, lesson, _levels);
          }
        } catch (_) {
          _snack('Could not open the lesson.');
        }
      default:
        setState(() => _tab = 0);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setTab(int t) {
    setState(() => _tab = t);
    if (t != 1) _load(pickLevel: false);
  }

  ChessLevel? _levelOf(ChessGame game) =>
      _levels.where((l) => l.index == game.level).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FxScope(
        child: AmbientBackground(
          spotlight: const Alignment(-0.1, -0.55),
          intensity: _tab == 0 ? 0.55 : 0.3,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= Breakpoints.tablet;
                final content = _loading
                    ? const Center(
                        child: CoachThinking(label: 'Setting up the board'),
                      )
                    : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : switch (_tab) {
                        1 => LearnView(levels: _levels),
                        2 => ProgressView(
                          onRecommendation: _recommendation,
                          recentGames: RecentGamesPanel(
                            games: _history,
                            levelOf: _levelOf,
                            onOpen: _review,
                          ),
                        ),
                        _ => PlayHome(
                          active: _active,
                          activeLevel: _active == null
                              ? null
                              : _levelOf(_active!),
                          starting: _starting,
                          wide: wide,
                          onContinue: (origin) =>
                              _open(_active!, origin: origin),
                          onNewGame: _newGame,
                          onPuzzles: () =>
                              openPuzzles(context, 'mixed', 'Rated puzzles'),
                        ),
                      };
                return Column(
                  children: [
                    _Header(wide: wide, tab: _tab, onTab: _setTab),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: content,
                        ),
                      ),
                    ),
                    if (!wide) _BottomTabs(tab: _tab, onTab: _setTab),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Play tab

/// The splash of the Play tab: the coach in his armchair, and two big
/// buttons.
class PlayHome extends StatelessWidget {
  const PlayHome({
    super.key,
    required this.active,
    required this.activeLevel,
    required this.starting,
    required this.wide,
    required this.onContinue,
    required this.onNewGame,
    required this.onPuzzles,
  });

  final ChessGame? active;
  final ChessLevel? activeLevel;
  final bool starting;
  final bool wide;
  final void Function(Offset? origin) onContinue;
  final void Function(BuildContext buttonContext) onNewGame;
  final VoidCallback onPuzzles;

  @override
  Widget build(BuildContext context) {
    final buttons = _buttons(context);
    if (!wide) {
      return Column(
        children: [
          const Expanded(child: CoachHero()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: buttons,
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final big = c.maxWidth >= Breakpoints.desktop;
        return Padding(
          padding: EdgeInsets.fromLTRB(big ? 48 : 24, 0, big ? 64 : 32, 24),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: const CoachHero(big: true),
              ),
              SizedBox(width: big ? 48 : 24),
              Expanded(
                flex: 5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Entrance(
                          delay: const Duration(milliseconds: 150),
                          child: Text('PLAY THE COACH', style: Typo.label()),
                        ),
                        const SizedBox(height: 10),
                        Entrance(
                          delay: const Duration(milliseconds: 250),
                          child: Shine(
                            period: const Duration(milliseconds: 5000),
                            child: GoldText(
                              'Your move.',
                              style: Typo.display(big ? 104 : 76),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Entrance(
                          delay: const Duration(milliseconds: 350),
                          child: Text(
                            'Eight strengths, one friendly opponent who grades '
                            'every move and stops you before a blunder.',
                            style: Typo.body(big ? 17 : 15),
                          ),
                        ),
                        const SizedBox(height: 32),
                        buttons,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buttons(BuildContext context) {
    final game = active;
    final secondary = game == null
        ? Builder(
            builder: (context) => _BigButton(
              icon: Icons.extension_rounded,
              title: 'Puzzles',
              subtitle: 'Rated tactics, matched to you',
              primary: false,
              onTap: onPuzzles,
            ),
          )
        : Builder(
            builder: (context) => _BigButton(
              icon: Icons.add_rounded,
              title: 'New game',
              subtitle: 'Pick my strength and your colour',
              primary: false,
              onTap: () => onNewGame(context),
            ),
          );
    final primary = game == null
        ? Builder(
            builder: (context) => _BigButton(
              icon: Icons.play_arrow_rounded,
              title: 'New game',
              subtitle: 'Pick my strength and your colour',
              busy: starting,
              onTap: () => onNewGame(context),
            ),
          )
        : Builder(
            builder: (context) => _BigButton(
              icon: Icons.play_arrow_rounded,
              title: 'Continue game',
              subtitle:
                  'vs ${activeLevel?.name ?? 'Coach'} · move ${game.moves.length ~/ 2 + 1}',
              busy: starting,
              onTap: () => onContinue(_center(context)),
            ),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Entrance(delay: const Duration(milliseconds: 300), child: primary),
        const SizedBox(height: 12),
        Entrance(delay: const Duration(milliseconds: 420), child: secondary),
      ],
    );
  }

  static Offset? _center(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box?.localToGlobal(box.size.center(Offset.zero));
  }
}

/// The coach in his armchair, lit from above.
class CoachHero extends StatelessWidget {
  const CoachHero({super.key, this.big = false});

  final bool big;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = min(c.maxWidth, c.maxHeight);
        final image = side * (big ? 0.86 : 0.9);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // A halo of slowly turning rays behind the coach.
            Positioned(
              top: c.maxHeight / 2 - side * 0.72,
              width: side * 1.3,
              height: side * 1.3,
              child: const LightRays(opacity: 0.22, rays: 16, speed: 0.025),
            ),
            // A pool of light on the floor.
            Positioned(
              bottom: c.maxHeight / 2 - image * 0.5,
              child: Container(
                width: image * 0.9,
                height: image * 0.14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(image, image * 0.14),
                  ),
                  gradient: RadialGradient(
                    colors: [
                      Palette.gold.withValues(alpha: 0.22),
                      Palette.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Entrance(
              duration: const Duration(milliseconds: 1100),
              offset: const Offset(0, 40),
              scale: 0.92,
              child: _Floating(
                child: Image.asset(
                  'assets/images/coach/armchair.webp',
                  width: image,
                  height: image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A gentle up-and-down drift.
class _Floating extends StatefulWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(_c.value * 2 * pi) * 5),
        child: child,
      ),
    );
  }
}

/// A large two-line button: gold for the main action, glass for the other.
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = true,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Palette.onyx : Palette.ivory;
    final button = Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: primary
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6E2AE), Palette.gold, Color(0xFFA9823F)],
                stops: [0, 0.45, 1],
              )
            : const LinearGradient(
                colors: [Color(0xCC26211A), Color(0xCC15120E)],
              ),
        border: primary
            ? null
            : Border.all(color: Palette.goldDeep.withValues(alpha: 0.7)),
        boxShadow: [
          if (primary)
            BoxShadow(
              color: Palette.gold.withValues(alpha: 0.38),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary
                  ? Palette.onyx.withValues(alpha: 0.12)
                  : Palette.gold.withValues(alpha: 0.12),
            ),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Icon(icon, color: primary ? Palette.onyx : Palette.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Typo.body(17, color: fg, weight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(
                    12.5,
                    color: primary
                        ? Palette.onyx.withValues(alpha: 0.7)
                        : Palette.muted,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: primary ? Palette.onyx : Palette.gold,
          ),
        ],
      ),
    );
    return Pressable(
      onTap: busy ? null : onTap,
      scale: 0.96,
      child: primary
          ? Shine(period: const Duration(milliseconds: 4200), child: button)
          : button,
    );
  }
}

// =============================================================================
// New game sheet

/// Pick the coach's strength, your colour and whether he coaches you.
class NewGameSheet extends StatefulWidget {
  const NewGameSheet({
    super.key,
    required this.levels,
    required this.level,
    required this.color,
    required this.coach,
    this.abandons = false,
  });

  final List<ChessLevel> levels;
  final int level;
  final ColorChoice color;
  final bool coach;

  /// Starting abandons the unfinished game.
  final bool abandons;

  @override
  State<NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends State<NewGameSheet> {
  late int _level = widget.level.clamp(0, widget.levels.length - 1);
  late ColorChoice _color = widget.color;
  late bool _coach = widget.coach;
  late final _pages = PageController(
    viewportFraction: 0.6,
    initialPage: _level,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.levels;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(28),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241F18), Color(0xFF110F0C)],
        ),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Palette.gold.withValues(alpha: 0.15),
            blurRadius: 40,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.goldDeep.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text('NEW GAME', style: Typo.label()),
            const SizedBox(height: 4),
            GoldText('How strong should I play?', style: Typo.display(30)),
            const SizedBox(height: 14),
            SizedBox(
              height: 176,
              child: Row(
                children: [
                  StepArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: _level > 0 ? () => _go(_level - 1) : null,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: levels.length,
                      onPageChanged: (i) => setState(() => _level = i),
                      itemBuilder: (context, i) => AnimatedBuilder(
                        animation: _pages,
                        builder: (context, child) {
                          final page =
                              _pages.hasClients &&
                                  _pages.position.haveDimensions
                              ? _pages.page ?? _level.toDouble()
                              : _level.toDouble();
                          final d = (page - i).abs().clamp(0.0, 1.0);
                          return Opacity(
                            opacity: 1 - d * 0.55,
                            child: Transform.scale(
                              scale: 1 - d * 0.14,
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () => _go(i),
                          child: _LevelCard(
                            level: levels[i],
                            count: levels.length,
                            selected: i == _level,
                          ),
                        ),
                      ),
                    ),
                  ),
                  StepArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: _level < levels.length - 1
                        ? () => _go(_level + 1)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final choice in ColorChoice.values) ...[
                        Expanded(
                          child: _ColorTile(
                            choice: choice,
                            selected: _color == choice,
                            onTap: () => setState(() => _color = choice),
                          ),
                        ),
                        if (choice != ColorChoice.values.last)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CoachToggle(
                    value: _coach,
                    onChanged: (v) => setState(() => _coach = v),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => SizedBox(
                      width: double.infinity,
                      child: Shine(
                        child: GoldButton(
                          label: 'Let\'s play',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            final box =
                                context.findRenderObject() as RenderBox?;
                            Navigator.of(context).pop<NewGameChoice>((
                              level: levels[_level].index,
                              color: _color,
                              coach: _coach,
                              origin: box?.localToGlobal(
                                box.size.center(Offset.zero),
                              ),
                            ));
                          },
                        ),
                      ),
                    ),
                  ),
                  if (widget.abandons) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Your unfinished game will be abandoned.',
                      style: Typo.body(12, color: Palette.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ‹ or › arrow beside a carousel.
class StepArrow extends StatelessWidget {
  const StepArrow({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.8,
      child: SizedBox(
        width: 36,
        height: 64,
        child: Icon(
          icon,
          size: 34,
          color: onTap == null
              ? Palette.muted.withValues(alpha: 0.3)
              : Palette.gold,
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.count,
    required this.selected,
  });

  final ChessLevel level;
  final int count;
  final bool selected;

  CoachMood get _mood => switch (level.index) {
    0 || 1 => CoachMood.happy,
    2 || 3 => CoachMood.neutral,
    _ => CoachMood.thoughtful,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [const Color(0xFF41341F), const Color(0xFF1C1710)]
              : [const Color(0xFF221E18), const Color(0xFF15120E)],
        ),
        border: Border.all(
          color: selected
              ? Palette.gold
              : Palette.goldDeep.withValues(alpha: 0.35),
          width: selected ? 1.4 : 0.8,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: Palette.gold.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: -4,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoachAvatar(size: 40, mood: _mood),
              const Spacer(),
              StrengthMeter(value: level.index + 1, max: count, lit: selected),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(level.name, maxLines: 1, style: Typo.title(26)),
          ),
          Text(
            '≈ ${level.rating} Elo',
            style: Typo.body(
              12,
              color: selected ? Palette.gold : Palette.muted,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            level.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Typo.body(12, color: Palette.parchment),
          ),
        ],
      ),
    );
  }
}

/// Bars of rising height, lit up to [value].
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({
    super.key,
    required this.value,
    required this.max,
    required this.lit,
  });

  final int value;
  final int max;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < max; i++)
          AnimatedContainer(
            duration: Duration(milliseconds: 200 + i * 40),
            margin: const EdgeInsets.only(left: 2),
            width: 3.5,
            height: 5 + i * 2.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i < value
                  ? (lit
                        ? Palette.gold
                        : Palette.parchment.withValues(alpha: 0.55))
                  : Colors.white.withValues(alpha: 0.08),
              boxShadow: [
                if (lit && i < value)
                  BoxShadow(
                    color: Palette.gold.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final ColorChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (choice) {
      ColorChoice.white => 'White',
      ColorChoice.random => 'Random',
      ColorChoice.black => 'Black',
    };
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? const Color(0xFF2E2617)
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? Palette.gold
                : Palette.goldDeep.withValues(alpha: 0.3),
            width: selected ? 1.3 : 0.8,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Palette.goldGlow,
                blurRadius: 18,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 46,
              child: switch (choice) {
                ColorChoice.white => Image.asset(
                  pieceAsset(Side.white, Role.king),
                ),
                ColorChoice.black => Image.asset(
                  pieceAsset(Side.black, Role.king),
                ),
                ColorChoice.random => Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Transform.rotate(
                        angle: -0.15,
                        child: Image.asset(
                          pieceAsset(Side.white, Role.king),
                          height: 42,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(10, 3),
                      child: Transform.rotate(
                        angle: 0.15,
                        child: Image.asset(
                          pieceAsset(Side.black, Role.king),
                          height: 42,
                        ),
                      ),
                    ),
                  ],
                ),
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Typo.body(
                13,
                color: selected ? Palette.ivory : Palette.muted,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachToggle extends StatelessWidget {
  const _CoachToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => onChanged(!value),
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value
              ? Palette.gold.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: value
                ? Palette.gold.withValues(alpha: 0.6)
                : Palette.goldDeep.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: value ? 1 : 0.5,
              child: CoachAvatar(
                size: 38,
                mood: value ? CoachMood.happy : CoachMood.neutral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value ? 'Coach me while we play' : 'No help this time',
                    style: Typo.body(
                      14,
                      color: Palette.ivory,
                      weight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    value
                        ? 'I grade your moves and stop you before a blunder.'
                        : 'A real game. We review it together afterwards.',
                    style: Typo.body(12, color: Palette.muted),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Palette.onyx,
              activeTrackColor: Palette.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Header and tabs

class _Header extends StatelessWidget {
  const _Header({required this.wide, required this.tab, required this.onTab});

  final bool wide;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: wide ? 36 : 30,
          height: wide ? 36 : 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Palette.gold, width: 1),
            boxShadow: [BoxShadow(color: Palette.goldGlow, blurRadius: 12)],
          ),
          padding: const EdgeInsets.all(2),
          child: Image.asset(pieceAsset(Side.white, Role.knight)),
        ),
        const SizedBox(width: 10),
        GoldText('Mr. Chess Coach', style: Typo.display(wide ? 28 : 24)),
      ],
    );
    final signOut = IconButton(
      tooltip: 'Sign out',
      onPressed: () => client.auth.signOutDevice(),
      icon: const Icon(Icons.logout_rounded, color: Palette.muted),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? 32 : 18,
        wide ? 18 : 8,
        wide ? 24 : 6,
        6,
      ),
      child: Row(
        children: [
          logo,
          const Spacer(),
          if (wide) ...[_Tabs(tab: tab, onTab: onTab), const Spacer()],
          signOut,
        ],
      ),
    );
  }
}

const _tabItems = [
  ('Play', Icons.sports_esports_rounded),
  ('Learn', Icons.school_rounded),
  ('Progress', Icons.insights_rounded),
];

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (label, icon)) in _tabItems.indexed)
            Pressable(
              onTap: () => onTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: i == tab
                      ? const LinearGradient(
                          colors: [Color(0xFFF1D79B), Palette.gold],
                        )
                      : null,
                  boxShadow: [
                    if (i == tab)
                      BoxShadow(
                        color: Palette.gold.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color: i == tab ? Palette.onyx : Palette.parchment,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: Typo.body(
                        14,
                        color: i == tab ? Palette.onyx : Palette.parchment,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The phone's tab bar, with a glowing light that slides to the open tab.
class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.onyx.withValues(alpha: 0.4),
            Palette.onyx.withValues(alpha: 0.92),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Palette.goldDeep.withValues(alpha: 0.4),
            width: 0.7,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / _tabItems.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                left: w * tab + w * 0.2,
                width: w * 0.6,
                top: 0,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Palette.gold,
                    boxShadow: [
                      BoxShadow(
                        color: Palette.gold.withValues(alpha: 0.8),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (i, (label, icon)) in _tabItems.indexed)
                    Expanded(
                      child: Pressable(
                        onTap: () => onTab(i),
                        scale: 0.88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: i == tab ? 1.15 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                icon,
                                size: 24,
                                color: i == tab ? Palette.gold : Palette.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              label,
                              style: Typo.body(
                                11.5,
                                color: i == tab ? Palette.gold : Palette.muted,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
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
            const CoachAvatar(size: 90, mood: CoachMood.surprised),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Typo.display(30),
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
