import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'widgets/fx.dart';

/// The palette: onyx lacquer, ivory and brushed gold, taken from the board.
abstract final class Palette {
  static const onyx = Color(0xFF0B0A09);
  static const ebony = Color(0xFF15130F);
  static const lacquer = Color(0xFF1E1B16);
  static const smoke = Color(0xFF2A261F);
  static const ivory = Color(0xFFF3EAD7);
  static const parchment = Color(0xFFCFC3AA);
  static const muted = Color(0xFF8C8270);
  static const gold = Color(0xFFD4AF6A);
  static const goldDeep = Color(0xFF9C7A3C);
  static const goldGlow = Color(0x66D4AF6A);
  static const win = Color(0xFF8FBF7A);
  static const loss = Color(0xFFD9745F);
  static const draw = Color(0xFFB9AE98);

  /// Speech bubbles: ivory paper with dark ink.
  static const paper = Color(0xFFFBF4E4);
  static const paperShade = Color(0xFFEFE2C6);
  static const ink = Color(0xFF2A2219);
  static const inkMuted = Color(0xFF7A6C58);
}

/// Text styles. Cormorant for display, Manrope for UI, Plex Mono for moves.
///
/// The fonts are bundled (see `fonts:` in pubspec.yaml) as static weights
/// subset to Latin: Manrope 400–800, Cormorant Garamond 700 and 600 italic,
/// Plex Mono 500 and 700. A weight that is not bundled renders with the
/// nearest one, so add the file before using a new weight.
abstract final class Typo {
  static const serif = 'Cormorant Garamond';
  static const sans = 'Manrope';
  static const monospace = 'IBM Plex Mono';

  static TextStyle display(double size, {Color color = Palette.ivory}) =>
      TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 0.95,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle title(double size, {Color color = Palette.ivory}) =>
      TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
        color: color,
      );

  static TextStyle body(
    double size, {
    Color color = Palette.parchment,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: sans,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.35,
  );

  /// Small capitals used for labels: "NEW GAME", "LEVEL".
  static TextStyle label({Color color = Palette.gold, double size = 11}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.6,
        color: color,
      );

  static TextStyle mono(double size, {Color color = Palette.parchment}) =>
      TextStyle(
        fontFamily: monospace,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    fontFamily: Typo.sans,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Palette.gold,
      onPrimary: Palette.onyx,
      secondary: Palette.ivory,
      surface: Palette.lacquer,
      onSurface: Palette.ivory,
      error: Palette.loss,
    ),
    scaffoldBackgroundColor: Palette.onyx,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: Typo.sans,
      bodyColor: Palette.ivory,
      displayColor: Palette.ivory,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: Typo.sans),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.smoke,
      contentTextStyle: Typo.body(14, color: Palette.ivory),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Palette.goldDeep, width: 0.6),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Palette.smoke,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.goldDeep, width: 0.6),
      ),
      textStyle: Typo.body(12, color: Palette.ivory),
    ),
  );
}

/// Layout breakpoints shared by every screen.
abstract final class Breakpoints {
  /// Below this width the phone layouts are used.
  static const tablet = 700.0;

  /// From this width the board and the side panel sit side by side.
  static const desktop = 1000.0;
}

/// The room the game is played in: a dark lacquered surface lit by a single
/// warm lamp, with slow light shafts (a fragment shader) and rising embers.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.spotlight = const Alignment(0, -0.35),
    this.tint = Palette.gold,
    this.intensity = 0.3,
    this.embers = true,
  });

  final Widget child;

  /// Where the lamp hangs.
  final Alignment spotlight;

  /// The colour of the light; it eases to a new tint, e.g. red after a
  /// blunder.
  final Color tint;

  /// 0..1, how strongly the light shafts glow.
  final double intensity;

  final bool embers;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram?>? _program;

  static Future<ui.FragmentProgram?> _load() async {
    try {
      return await ui.FragmentProgram.fromAsset('shaders/ambient.frag');
    } catch (e) {
      debugPrint('Ambient shader unavailable: $e');
      return null;
    }
  }

  ui.FragmentShader? _shader;
  late final Ticker _ticker = createTicker((elapsed) {
    _time.value = elapsed.inMicroseconds / 1e6;
  });
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    (_program ??= _load()).then((program) {
      if (!mounted || program == null) return;
      setState(() => _shader = program.fragmentShader());
      _ticker.start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    _ticker.muted = still;
    final light = Offset(
      (widget.spotlight.x + 1) / 2,
      (widget.spotlight.y + 1) / 2,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Palette.onyx),
        if (_shader case final shader?)
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: widget.tint),
            duration: const Duration(milliseconds: 900),
            builder: (context, tint, _) => TweenAnimationBuilder<double>(
              tween: Tween(end: widget.intensity),
              duration: const Duration(milliseconds: 900),
              builder: (context, intensity, _) => RepaintBoundary(
                child: CustomPaint(
                  painter: _AmbientShaderPainter(
                    shader,
                    _time,
                    light,
                    tint ?? Palette.gold,
                    intensity,
                  ),
                ),
              ),
            ),
          )
        else ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: widget.spotlight,
                radius: 1.15,
                colors: const [
                  Color(0xFF2B251B),
                  Color(0xFF16130F),
                  Palette.onyx,
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          const RepaintBoundary(child: CustomPaint(painter: _InlayPainter())),
        ],
        if (widget.embers && !still)
          IgnorePointer(child: EmberField(color: widget.tint)),
        widget.child,
      ],
    );
  }
}

class _AmbientShaderPainter extends CustomPainter {
  _AmbientShaderPainter(
    this.shader,
    this.time,
    this.light,
    this.tint,
    this.intensity,
  ) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueListenable<double> time;
  final Offset light;
  final Color tint;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time.value)
      ..setFloat(3, light.dx)
      ..setFloat(4, light.dy)
      ..setFloat(5, intensity)
      ..setFloat(6, tint.r)
      ..setFloat(7, tint.g)
      ..setFloat(8, tint.b);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AmbientShaderPainter old) =>
      old.light != light || old.tint != tint || old.intensity != intensity;
}

/// Diagonal pinstripes and film grain, used when shaders are unavailable.
class _InlayPainter extends CustomPainter {
  const _InlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Diagonal pinstripes, fading out towards the bottom.
    final stripe = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Palette.gold.withValues(alpha: 0.035),
          Palette.gold.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 1;
    const gap = 46.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        stripe,
      );
    }
    // Film grain.
    final rnd = Random(7);
    final grain = Paint();
    final count = (size.width * size.height / 900).clamp(0, 4000).toInt();
    for (var i = 0; i < count; i++) {
      grain.color = (rnd.nextBool() ? Colors.white : Colors.black).withValues(
        alpha: 0.025 + rnd.nextDouble() * 0.03,
      );
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 0.9 + 0.3,
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(_InlayPainter oldDelegate) => false;
}

/// A dark glass panel with a hairline gold edge.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE6221E18), Color(0xE6120F0C)],
        ),
        border: Border.all(
          color: highlight
              ? Palette.gold
              : Palette.goldDeep.withValues(alpha: 0.45),
          width: highlight ? 1.2 : 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          if (highlight)
            BoxShadow(
              color: Palette.goldGlow,
              blurRadius: 24,
              spreadRadius: -6,
            ),
        ],
      ),
      child: child,
    );
  }
}

/// The primary call to action: a brushed-gold pill.
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool compact;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : (_hover ? 1.02 : 1),
          duration: const Duration(milliseconds: 140),
          child: AnimatedOpacity(
            opacity: enabled || widget.busy ? 1 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 18 : 28,
                vertical: widget.compact ? 12 : 18,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF1D79B), Palette.gold, Color(0xFFA9823F)],
                  stops: [0, 0.45, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Palette.gold.withValues(alpha: _hover ? 0.45 : 0.25),
                    blurRadius: _hover ? 28 : 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.onyx,
                      ),
                    )
                  else if (widget.icon != null)
                    Icon(widget.icon, size: 20, color: Palette.onyx),
                  if (widget.busy || widget.icon != null)
                    const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: Typo.body(
                      widget.compact ? 14 : 16,
                      color: Palette.onyx,
                      weight: FontWeight.w800,
                    ).copyWith(letterSpacing: 0.4),
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

/// A quiet outlined button for secondary actions.
class GhostButton extends StatefulWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool busy;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final color = enabled
        ? Palette.ivory
        : Palette.muted.withValues(alpha: 0.6);
    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _hover && enabled
                ? Palette.gold.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: _hover && enabled
                  ? Palette.gold
                  : Palette.goldDeep.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.gold,
                      ),
                    )
                  : Icon(widget.icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: Typo.body(12, color: color, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}
