import 'dart:math';

import '../game/chess_model.dart';
import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../theme.dart';
import '../widgets/chess_board.dart';
import 'game_screen.dart';
import 'learn_view.dart';
import 'progress_screen.dart';
import 'puzzle_screen.dart';
import 'review_screen.dart';

/// Pick a level and a side, continue a game, or look back at past games.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

/// The side the player picks; null in [PlayerColor] terms means random.
enum _ColorChoice { white, random, black }

class _LobbyScreenState extends State<LobbyScreen> {
  List<ChessLevel> _levels = [];
  ChessGame? _active;
  List<ChessGame> _history = [];
  bool _loading = true;
  bool _starting = false;
  String? _error;

  int _level = 2;
  _ColorChoice _color = _ColorChoice.white;
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
    for (final asset in allBoardAssets) {
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
        _error = 'Could not reach the server.';
      });
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final game = await client.game.startGame(
        _level,
        switch (_color) {
          _ColorChoice.white => PlayerColor.white,
          _ColorChoice.black => PlayerColor.black,
          _ColorChoice.random => null,
        },
        _coach,
      );
      await _open(game);
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

  Future<void> _open(ChessGame game) async {
    if (!mounted) return;
    final lesson = await _lessonOf(game);
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) =>
            GameScreen(game: game, levels: _levels, lesson: lesson),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.04, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (mounted) await _load(pickLevel: false);
  }

  Future<void> _review(ChessGame game) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        spotlight: const Alignment(-0.55, -0.6),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final content = _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Palette.gold),
                    )
                  : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : switch (_tab) {
                      1 => LearnView(levels: _levels),
                      2 => ProgressView(onRecommendation: _recommendation),
                      _ => wide ? _buildWide() : _buildNarrow(),
                    };
              return Column(
                children: [
                  _Header(
                    compact: !wide,
                    tab: _tab,
                    onTab: (t) {
                      setState(() => _tab = t);
                      if (t == 0) _load(pickLevel: false);
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: content,
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

  Widget _buildWide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 12, 48, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    const _Hero(),
                    const SizedBox(height: 36),
                    if (_active != null) ...[
                      _ContinueCard(
                        game: _active!,
                        level: _levelOf(_active!),
                        onTap: () => _open(_active!),
                      ),
                      const SizedBox(height: 28),
                    ],
                    _HistoryPanel(
                      games: _history,
                      levelOf: _levelOf,
                      onOpen: _review,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(flex: 6, child: _newGamePanel(columns: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Hero(compact: true),
              const SizedBox(height: 24),
              if (_active != null) ...[
                _ContinueCard(
                  game: _active!,
                  level: _levelOf(_active!),
                  onTap: () => _open(_active!),
                ),
                const SizedBox(height: 20),
              ],
              _newGamePanel(columns: 2),
              const SizedBox(height: 20),
              _HistoryPanel(
                games: _history,
                levelOf: _levelOf,
                onOpen: _review,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChessLevel? _levelOf(ChessGame game) =>
      _levels.where((l) => l.index == game.level).firstOrNull;

  Widget _newGamePanel({required int columns}) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEW GAME', style: Typo.label()),
          const SizedBox(height: 6),
          Text('Choose your opponent', style: Typo.display(36)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final level in _levels)
                    SizedBox(
                      width: width,
                      child: _LevelTile(
                        level: level,
                        count: _levels.length,
                        selected: level.index == _level,
                        onTap: () => setState(() => _level = level.index),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Text('PLAY AS', style: Typo.label()),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final choice in _ColorChoice.values) ...[
                Expanded(
                  child: _ColorTile(
                    choice: choice,
                    selected: _color == choice,
                    onTap: () => setState(() => _color = choice),
                  ),
                ),
                if (choice != _ColorChoice.values.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 22),
          _CoachToggle(
            value: _coach,
            onChanged: (v) => setState(() => _coach = v),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: _active == null ? 'Start game' : 'Start a new game',
              icon: Icons.play_arrow_rounded,
              busy: _starting,
              onPressed: _levels.isEmpty ? null : _start,
            ),
          ),
          if (_active != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Your unfinished game will be abandoned.',
                style: Typo.body(12, color: Palette.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.compact,
    required this.tab,
    required this.onTab,
  });

  final bool compact;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Palette.gold, width: 1),
          ),
          padding: const EdgeInsets.all(2),
          child: Image.asset(pieceAsset(Side.white, Role.knight)),
        ),
        const SizedBox(width: 12),
        Text('Mr. Chess Coach', style: Typo.display(26, color: Palette.gold)),
      ],
    );
    final signOut = IconButton(
      tooltip: 'Sign out',
      onPressed: () => client.auth.signOutDevice(),
      icon: const Icon(Icons.logout_rounded, color: Palette.muted),
    );
    final tabs = _Tabs(tab: tab, onTab: onTab);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 12 : 24,
        compact ? 8 : 40,
        compact ? 8 : 12,
      ),
      child: compact
          ? Column(
              children: [
                Row(children: [logo, const Spacer(), signOut]),
                const SizedBox(height: 10),
                tabs,
              ],
            )
          : Row(
              children: [
                logo,
                const Spacer(),
                tabs,
                const Spacer(),
                signOut,
              ],
            ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  static const _items = [
    ('Play', Icons.sports_esports_rounded),
    ('Learn', Icons.school_rounded),
    ('Progress', Icons.insights_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: Palette.goldDeep.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (label, icon)) in _items.indexed)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onTab(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
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
                          color: Palette.gold.withValues(alpha: 0.3),
                          blurRadius: 14,
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
            ),
        ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: value ? Palette.gold : Palette.goldDeep,
                  ),
                ),
                child: Opacity(
                  opacity: value ? 1 : 0.4,
                  child: Image.asset(pieceAsset(Side.white, Role.queen)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value ? 'Coach is on' : 'Coach is off',
                      style: Typo.body(
                        14,
                        color: Palette.ivory,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      value
                          ? 'Grades every move, stops you before blunders and '
                                'explains the key moments.'
                          : 'A real game without help. You still get a full '
                                'review afterwards.',
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
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final headline = compact ? 64.0 : 112.0;
    // The headline sizes the hero; the knight leans in from the right edge,
    // just behind the end of "move.".
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 190 : 300),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // A great ivory knight leaning into the light.
          Positioned(
            right: compact ? -12 : -40,
            top: compact ? 0 : 6,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(40 * (1 - t), 0),
                  child: Transform.rotate(angle: -0.12 * t, child: child),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Palette.gold.withValues(alpha: 0.18),
                      blurRadius: 90,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Image.asset(
                  pieceAsset(Side.white, Role.knight),
                  width: compact ? 118 : 250,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: compact ? 18 : 30),
              Text('Your', style: Typo.display(headline)),
              Padding(
                padding: EdgeInsets.only(left: compact ? 36 : 70),
                child: Text(
                  'move.',
                  style: Typo.display(headline, color: Palette.gold),
                ),
              ),
              SizedBox(height: compact ? 10 : 18),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 220 : 420),
                child: Text(
                  'Eight opponents, one engine. From first steps to full-strength Stockfish.',
                  style: Typo.body(compact ? 13 : 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatefulWidget {
  const _LevelTile({
    required this.level,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final ChessLevel level;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.level;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [const Color(0xFF3A2F1C), const Color(0xFF1C1710)]
                  : [
                      Colors.white.withValues(alpha: _hover ? 0.06 : 0.03),
                      Colors.white.withValues(alpha: 0.01),
                    ],
            ),
            border: Border.all(
              color: selected
                  ? Palette.gold
                  : Palette.goldDeep.withValues(alpha: _hover ? 0.7 : 0.3),
              width: selected ? 1.3 : 0.8,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: Palette.goldGlow,
                  blurRadius: 22,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    (l.index + 1).toString().padLeft(2, '0'),
                    style: Typo.mono(
                      12,
                      color: selected ? Palette.gold : Palette.muted,
                    ),
                  ),
                  const Spacer(),
                  _StrengthMeter(
                    value: l.index + 1,
                    max: widget.count,
                    lit: selected,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  l.name,
                  maxLines: 1,
                  style: Typo.title(
                    24,
                    color: selected ? Palette.ivory : Palette.parchment,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '≈ ${l.rating} Elo',
                style: Typo.body(
                  12,
                  color: selected ? Palette.gold : Palette.muted,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Typo.body(12, color: Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({
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
            duration: Duration(milliseconds: 200 + i * 30),
            margin: const EdgeInsets.only(left: 2),
            width: 3,
            height: 4 + i * 1.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i < value
                  ? (lit
                        ? Palette.gold
                        : Palette.parchment.withValues(alpha: 0.55))
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}

class _ColorTile extends StatefulWidget {
  const _ColorTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _ColorChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<_ColorTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final label = switch (widget.choice) {
      _ColorChoice.white => 'White',
      _ColorChoice.random => 'Random',
      _ColorChoice.black => 'Black',
    };
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? const Color(0xFF2E2617)
                : Colors.white.withValues(alpha: _hover ? 0.05 : 0.025),
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
                height: 64,
                child: switch (widget.choice) {
                  _ColorChoice.white => Image.asset(
                    pieceAsset(Side.white, Role.king),
                  ),
                  _ColorChoice.black => Image.asset(
                    pieceAsset(Side.black, Role.king),
                  ),
                  _ColorChoice.random => Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(-12, 0),
                        child: Transform.rotate(
                          angle: -0.15,
                          child: Image.asset(
                            pieceAsset(Side.white, Role.king),
                            height: 58,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(12, 4),
                        child: Transform.rotate(
                          angle: 0.15,
                          child: Image.asset(
                            pieceAsset(Side.black, Role.king),
                            height: 58,
                          ),
                        ),
                      ),
                    ],
                  ),
                },
              ),
              const SizedBox(height: 6),
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
      ),
    );
  }
}

class _ContinueCard extends StatefulWidget {
  const _ContinueCard({
    required this.game,
    required this.level,
    required this.onTap,
  });

  final ChessGame game;
  final ChessLevel? level;
  final VoidCallback onTap;

  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final side = g.playerColor == PlayerColor.white ? Side.white : Side.black;
    final moveNumber = g.moves.length ~/ 2 + 1;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.01 : 1,
          duration: const Duration(milliseconds: 180),
          child: Panel(
            highlight: true,
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.asset(pieceAsset(side, Role.queen)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GAME IN PROGRESS', style: Typo.label()),
                      const SizedBox(height: 4),
                      Text(
                        'vs ${widget.level?.name ?? 'Stockfish'}',
                        style: Typo.title(26),
                      ),
                      Text(
                        'Move $moveNumber · playing ${side == Side.white ? 'White' : 'Black'}',
                        style: Typo.body(13, color: Palette.muted),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hover ? Palette.gold : Colors.transparent,
                    border: Border.all(color: Palette.gold),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _hover ? Palette.onyx : Palette.gold,
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

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.games,
    required this.levelOf,
    required this.onOpen,
  });

  final List<ChessGame> games;
  final ChessLevel? Function(ChessGame) levelOf;
  final void Function(ChessGame) onOpen;

  @override
  Widget build(BuildContext context) {
    final wins = games.where((g) => g.status == GameStatus.playerWon).length;
    final losses = games
        .where((g) => g.status == GameStatus.computerWon)
        .length;
    final draws = games.where((g) => g.status == GameStatus.draw).length;
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('RECENT GAMES', style: Typo.label()),
              const Spacer(),
              if (games.isNotEmpty)
                Text.rich(
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
            ],
          ),
          const SizedBox(height: 10),
          if (games.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No finished games yet. Your story starts with the first move.',
                style: Typo.display(20, color: Palette.muted),
              ),
            )
          else
            for (final (i, game) in games.take(8).indexed)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + min(i, 8) * 70),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - t)),
                    child: child,
                  ),
                ),
                child: _HistoryRow(
                  game: game,
                  level: levelOf(game),
                  onTap: () => onOpen(game),
                ),
              ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.game,
    required this.level,
    required this.onTap,
  });

  final ChessGame game;
  final ChessLevel? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (letter, color) = switch (game.status) {
      GameStatus.playerWon => ('W', Palette.win),
      GameStatus.computerWon => ('L', Palette.loss),
      _ => ('D', Palette.draw),
    };
    final side = game.playerColor == PlayerColor.white ? 'White' : 'Black';
    final moves = (game.moves.length + 1) ~/ 2;
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Palette.goldDeep.withValues(alpha: 0.18),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.8), width: 1),
            ),
            child: Text(
              letter,
              style: Typo.mono(
                12,
                color: color,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs ${level?.name ?? 'Stockfish'}', style: Typo.title(19)),
                Text(
                  '$moves moves · as $side${_reasonShort(game.endReason)}',
                  style: Typo.body(12, color: Palette.muted),
                ),
              ],
            ),
          ),
          Text(
            _ago(game.updatedAt),
            style: Typo.body(12, color: Palette.muted),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.insights_rounded,
            size: 18,
            color: Palette.goldDeep,
          ),
        ],
      ),
    );
    return Tooltip(
      message: 'Review this game',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }

  static String _reasonShort(GameEndReason? reason) => switch (reason) {
    GameEndReason.checkmate => ' · checkmate',
    GameEndReason.resignation => ' · resigned',
    GameEndReason.stalemate => ' · stalemate',
    GameEndReason.insufficientMaterial => ' · insufficient material',
    GameEndReason.threefoldRepetition => ' · repetition',
    GameEndReason.fiftyMoveRule => ' · fifty moves',
    _ => '',
  };

  static String _ago(DateTime time) {
    final d = DateTime.now().toUtc().difference(time.toUtc());
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${time.toLocal().day}/${time.toLocal().month}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Typo.display(30)),
          const SizedBox(height: 20),
          GoldButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
