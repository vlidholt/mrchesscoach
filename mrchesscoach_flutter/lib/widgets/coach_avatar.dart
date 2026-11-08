import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme.dart';
import 'fx.dart';

/// The coach's facial expression.
enum CoachMood {
  neutral,
  happy,
  thoughtful,
  surprised;

  String get asset => 'assets/images/coach/$name.webp';
}

/// Every coach image, for precaching.
Iterable<String> get coachAssets => [
  for (final m in CoachMood.values) m.asset,
  'assets/images/coach/armchair.webp',
];

/// Text styles for words written in a speech bubble (dark ink on paper).
abstract final class BubbleText {
  static TextStyle get body => Typo.body(
    14.5,
    color: Palette.ink,
    weight: FontWeight.w600,
  ).copyWith(height: 1.4);

  static TextStyle get small =>
      Typo.body(13, color: Palette.inkMuted, weight: FontWeight.w600);

  static TextStyle get headline =>
      Typo.title(20, color: Palette.ink).copyWith(height: 1.1);

  static TextStyle get move =>
      Typo.mono(14, color: Palette.ink).copyWith(fontWeight: FontWeight.w700);
}

/// The coach's head in a gold medallion. Changing [mood] swaps the
/// expression with a little pop and a reaction ("!", "…", sparkles).
class CoachAvatar extends StatefulWidget {
  const CoachAvatar({
    super.key,
    this.size = 46,
    this.speaking = false,
    this.mood = CoachMood.neutral,
    this.accent = Palette.gold,
    this.lively = false,
  });

  final double size;
  final bool speaking;
  final CoachMood mood;

  /// The colour of the halo, e.g. the verdict colour.
  final Color accent;

  /// Breathes and bobs while speaking, as across the board in a game.
  /// Elsewhere the head stays still.
  final bool lively;

  @override
  State<CoachAvatar> createState() => _CoachAvatarState();
}

class _CoachAvatarState extends State<CoachAvatar>
    with SingleTickerProviderStateMixin {
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  )..repeat();

  /// Bumped on every mood change, to replay the reaction.
  int _reaction = 0;

  @override
  void didUpdateWidget(CoachAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _reaction++;
      if (widget.mood == CoachMood.happy && widget.size >= 40) {
        final c = Offset(widget.size / 2, widget.size / 2);
        context.fx(c, (s, at) {
          s.fx.stars(at, Palette.gold, count: 8, speed: 120, size: 16);
        });
      }
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final still = MediaQuery.of(context).disableAnimations;
    final medallion = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(0, -0.3),
          colors: [Color(0xFFFFF3D6), Color(0xFFE2C48A), Color(0xFF9C7A3C)],
          stops: [0, 0.6, 1],
        ),
        border: Border.all(
          color: Color.lerp(Palette.gold, widget.accent, 0.5)!,
          width: max(1.5, size * 0.035),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(
              alpha: widget.speaking ? 0.55 : 0.25,
            ),
            blurRadius: widget.speaking ? size * 0.5 : size * 0.25,
            spreadRadius: widget.speaking ? size * 0.02 : 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipOval(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: TweenSequence([
                TweenSequenceItem(
                  tween: Tween(begin: 0.9, end: 1.07),
                  weight: 60,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.07, end: 1.0),
                  weight: 40,
                ),
              ]).animate(a),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
          child: Transform.scale(
            key: ValueKey(widget.mood),
            scale: 1.12,
            alignment: const Alignment(0, -0.2),
            child: Image.asset(
              widget.mood.asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.5),
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _idle,
            child: medallion,
            builder: (context, child) {
              if (still || !widget.lively) return child!;
              final t = _idle.value * 2 * pi;
              final bob = widget.speaking
                  ? -(sin(t * 9).abs()) * size * 0.025
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, bob),
                child: Transform.rotate(
                  angle: sin(t) * 0.025,
                  child: Transform.scale(
                    scale: 1 + sin(t * 2) * 0.012,
                    child: child,
                  ),
                ),
              );
            },
          ),
          if (size >= 34)
            Positioned(
              right: -size * 0.12,
              top: -size * 0.18,
              child: IgnorePointer(
                child: _Reaction(
                  key: ValueKey(_reaction),
                  mood: _reaction == 0 ? null : widget.mood,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A glyph that pops out of the coach's head and floats away.
class _Reaction extends StatelessWidget {
  const _Reaction({super.key, required this.mood, required this.size});

  final CoachMood? mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (glyph, color) = switch (mood) {
      CoachMood.surprised => ('!', const Color(0xFFE5533D)),
      CoachMood.thoughtful => ('…', const Color(0xFF6FA8DC)),
      // An icon, not '✦': the bundled fonts have no such glyph.
      CoachMood.happy => ('', Palette.gold),
      _ => (null, Palette.gold),
    };
    if (glyph == null) return const SizedBox.shrink();
    final s = max(16.0, size * 0.36);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, t, child) {
        final pop = Curves.elasticOut.transform((t / 0.45).clamp(0, 1));
        final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
        return Opacity(
          opacity: fade.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -t * size * 0.25),
            child: Transform.scale(scale: pop, child: child),
          ),
        );
      },
      child: Container(
        width: s,
        height: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Palette.paper,
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: s * 0.6),
          ],
        ),
        child: glyph.isEmpty
            ? Icon(Icons.auto_awesome, size: s * 0.6, color: color)
            : Text(
                glyph,
                style: Typo.body(
                  s * 0.62,
                  color: color,
                  weight: FontWeight.w800,
                ).copyWith(height: 1),
              ),
      ),
    );
  }
}

/// Reveals [text] like it is being typed, once per distinct text.
class TypewriterText extends StatelessWidget {
  const TypewriterText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final ms = min(1500, 200 + text.length * 13);
    return TweenAnimationBuilder<int>(
      key: ValueKey(text),
      tween: IntTween(begin: 0, end: text.length),
      duration: Duration(milliseconds: ms),
      builder: (context, n, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text.substring(0, n)),
            // Reserve the space of the rest so the layout doesn't jump.
            TextSpan(
              text: text.substring(n),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// Three dots while the coach is thinking.
class CoachThinking extends StatefulWidget {
  const CoachThinking({
    super.key,
    this.label = 'Let me think',
    this.color,
  });

  final String label;

  /// The label colour; defaults to the surrounding text colour, muted.
  final Color? color;

  @override
  State<CoachThinking> createState() => _CoachThinkingState();
}

class _CoachThinkingState extends State<CoachThinking>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        (DefaultTextStyle.of(context).style.color ?? Palette.muted).withValues(
          alpha: 0.7,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: Typo.body(13, color: color, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(
                    0,
                    -3 * max(0, sin((_c.value - i * 0.18) * 2 * pi)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.goldDeep.withValues(
                        alpha:
                            0.4 +
                            0.6 *
                                (0.5 +
                                    0.5 * sin((_c.value - i * 0.2) * 2 * pi)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A speech bubble: ivory paper with a tail towards the coach and a glow in
/// the colour of what it is about.
class CoachBubble extends StatelessWidget {
  const CoachBubble({
    super.key,
    required this.child,
    this.accent = Palette.gold,
    this.tail = true,
    this.padding = const EdgeInsets.fromLTRB(14, 11, 14, 12),
  });

  final Widget child;
  final Color accent;
  final bool tail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tail ? 5 : 16),
          topRight: const Radius.circular(16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.paper, Palette.paperShade],
        ),
        border: Border.all(
          color: Color.lerp(Palette.gold, accent, 0.7)!.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(style: BubbleText.body, child: child),
    );
    if (!tail) return bubble;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          left: -7,
          top: 9,
          child: CustomPaint(
            size: const Size(9, 12),
            painter: _TailPainter(
              Color.lerp(Palette.gold, accent, 0.7)!.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.border);

  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width + 1, 0)
      ..lineTo(0, size.height * 0.35)
      ..lineTo(size.width + 1, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Palette.paper);
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height * 0.35)
        ..lineTo(size.width, size.height),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.border != border;
}

/// One thing the coach says: a bubble in the chat.
class CoachLine {
  const CoachLine({
    required this.id,
    required this.child,
    this.accent = Palette.gold,
  });

  /// Identifies the message; a new id animates a new bubble in.
  final Object id;
  final Widget child;
  final Color accent;
}

/// The coach's corner: the avatar and a column of speech bubbles that
/// scrolls inside its own area, newest at the bottom.
class CoachChat extends StatefulWidget {
  const CoachChat({
    super.key,
    required this.lines,
    this.mood = CoachMood.neutral,
    this.speaking = false,
    this.avatarSize = 56,
    this.accent = Palette.gold,
    this.name,
    this.lively = false,
  });

  final List<CoachLine> lines;
  final CoachMood mood;
  final bool speaking;
  final double avatarSize;
  final Color accent;

  /// See [CoachAvatar.lively].
  final bool lively;

  /// Shown under the avatar; null to hide.
  final String? name;

  @override
  State<CoachChat> createState() => _CoachChatState();
}

class _CoachChatState extends State<CoachChat> {
  final _scroll = ScrollController();

  /// One key per message, to find the newest bubble.
  final _keys = <Object, GlobalKey>{};

  @override
  void didUpdateWidget(CoachChat old) {
    super.didUpdateWidget(old);
    final before = old.lines.map((l) => l.id).join('|');
    final after = widget.lines.map((l) => l.id).join('|');
    if (before != after) {
      final ids = widget.lines.map((l) => l.id).toSet();
      _keys.removeWhere((id, _) => !ids.contains(id));
      _toEnd();
    }
  }

  void _toEnd() {
    // Twice: once the bubble is laid out, and once it has grown in.
    for (final delay in const [Duration.zero, Duration(milliseconds: 420)]) {
      Future<void>.delayed(delay, () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll.hasClients) return;
          final position = _scroll.position;
          var target = position.maxScrollExtent;
          // A bubble taller than the chat is shown from its top, so the
          // start of a long message is not scrolled away.
          final newest = widget.lines.lastOrNull?.id;
          final box =
              _keys[newest]?.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final tall = box.size.height > position.viewportDimension - 16;
            if (tall) {
              final viewport = RenderAbstractViewport.of(box);
              target = viewport.getOffsetToReveal(box, 0).offset - 6;
            }
          }
          _scroll.animateTo(
            target.clamp(0.0, position.maxScrollExtent),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoachAvatar(
              size: widget.avatarSize,
              mood: widget.mood,
              speaking: widget.speaking,
              accent: widget.accent,
              lively: widget.lively,
            ),
            if (widget.name case final name?) ...[
              const SizedBox(height: 4),
              Text(name, style: Typo.label(size: 9.5)),
            ],
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black, Colors.black],
              stops: [0, 0.07, 1],
            ).createShader(rect),
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 10),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, line) in widget.lines.indexed) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _BubbleIn(
                        // A repeated id (a caller's slip) must not share a
                        // global key.
                        key:
                            widget.lines.indexWhere((l) => l.id == line.id) == i
                            ? _keys.putIfAbsent(line.id, GlobalKey.new)
                            : ValueKey('$i-${line.id}'),
                        child: CoachBubble(
                          accent: line.accent,
                          tail: i == 0,
                          child: line.child,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pops a bubble out of the coach's mouth.
class _BubbleIn extends StatelessWidget {
  const _BubbleIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      builder: (context, t, child) {
        final s = Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.scale(
            scale: 0.7 + 0.3 * s,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The coach's avatar with a single speech bubble, for screens other than
/// games.
class CoachSays extends StatelessWidget {
  const CoachSays({
    super.key,
    required this.child,
    this.accent = Palette.gold,
    this.speaking = false,
    this.mood = CoachMood.neutral,
    this.avatarSize = 52,
  });

  final Widget child;
  final Color accent;
  final bool speaking;
  final CoachMood mood;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachAvatar(
          size: avatarSize,
          speaking: speaking,
          mood: mood,
          accent: accent,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: CoachBubble(
                key: ValueKey(child.key ?? child.hashCode),
                accent: accent,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
