import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
}

/// Text styles. Cormorant for display, Manrope for UI, Plex Mono for moves.
abstract final class Typo {
  static TextStyle display(double size, {Color color = Palette.ivory}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 0.95,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle title(double size, {Color color = Palette.ivory}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
        color: color,
      );

  static TextStyle body(
    double size, {
    Color color = Palette.parchment,
    FontWeight weight = FontWeight.w500,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.35,
  );

  /// Small capitals used for labels: "NEW GAME", "LEVEL".
  static TextStyle label({Color color = Palette.gold, double size = 11}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.6,
        color: color,
      );

  static TextStyle mono(double size, {Color color = Palette.parchment}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
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
    textTheme: GoogleFonts.manropeTextTheme(
      base.textTheme,
    ).apply(bodyColor: Palette.ivory, displayColor: Palette.ivory),
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

/// The room the game is played in: a dark lacquered surface lit by a single
/// warm lamp, with a faint diagonal inlay and film grain.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.spotlight = const Alignment(0, -0.35),
  });

  final Widget child;

  /// Where the lamp hangs.
  final Alignment spotlight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Palette.onyx),
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: spotlight,
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
        child,
      ],
    );
  }
}

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
