import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

// =============================================================================
// Particles
//
// One [FxScope] per screen holds a particle layer above its content. Widgets
// anywhere below it call `FxScope.of(context)` and fire effects at points in
// their own coordinates, so sparks can fly out of the board and across the
// screen. Particles are drawn with `drawAtlas` from a small sprite sheet,
// which stays cheap on the web and on phones.

final _rnd = Random();

double _range(double a, double b) => a + _rnd.nextDouble() * (b - a);

enum _Shape { glow, star, rect, shard, streak }

class _Particle {
  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
    required this.shape,
    this.gravity = 0,
    this.drag = 0,
    this.spin = 0,
    this.angle = 0,
    this.additive = true,
    this.grow = 0,
    this.delay = 0,
    this.wobble = 0,
  });

  Offset pos;
  Offset vel;
  double age = 0;
  final double life;
  final double size;
  final Color color;
  final _Shape shape;
  final double gravity;
  final double drag;
  final double spin;
  double angle;
  final bool additive;

  /// Relative size growth over the particle's life.
  final double grow;

  /// Seconds before the particle appears.
  double delay;

  /// Sideways flutter (confetti).
  final double wobble;

  double get t => (age / life).clamp(0.0, 1.0);
}

class _Ring {
  _Ring({
    required this.center,
    required this.radius,
    required this.color,
    required this.life,
    required this.width,
    this.delay = 0,
  });

  final Offset center;
  final double radius;
  final Color color;
  final double life;
  final double width;
  double delay;
  double age = 0;
}

/// The particles of one [FxScope].
class FxController extends ChangeNotifier {
  final _particles = <_Particle>[];
  final _rings = <_Ring>[];
  final _timers = <Timer>{};
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  /// Runs [f] after [delay], unless this controller is disposed first.
  void _after(double seconds, VoidCallback f) {
    late final Timer timer;
    timer = Timer(Duration(milliseconds: (seconds * 1000).round()), () {
      _timers.remove(timer);
      if (!_disposed) f();
    });
    _timers.add(timer);
  }

  bool get isIdle => _particles.isEmpty && _rings.isEmpty;

  void _add(Iterable<_Particle> ps) {
    if (_disposed) return;
    // Keep phones and old laptops smooth when effects pile up.
    if (_particles.length > 900) _particles.removeRange(0, 300);
    _particles.addAll(ps);
    notifyListeners();
  }

  void _step(double dt) {
    for (final p in _particles) {
      if (p.delay > 0) {
        p.delay -= dt;
        continue;
      }
      p.age += dt;
      final damp = pow(1 - p.drag, dt * 60).toDouble();
      p.vel = Offset(p.vel.dx * damp, p.vel.dy * damp + p.gravity * dt);
      var dx = p.vel.dx * dt;
      if (p.wobble != 0) dx += sin(p.age * 9 + p.size) * p.wobble * dt;
      p.pos = p.pos.translate(dx, p.vel.dy * dt);
      p.angle += p.spin * dt;
    }
    _particles.removeWhere((p) => p.age >= p.life);
    for (final r in _rings) {
      if (r.delay > 0) {
        r.delay -= dt;
      } else {
        r.age += dt;
      }
    }
    _rings.removeWhere((r) => r.age >= r.life);
  }

  // ---------------------------------------------------------------------------
  // Presets

  /// Hot sparks thrown out in all directions, falling under gravity.
  void sparks(
    Offset at,
    Color color, {
    int count = 28,
    double speed = 420,
    double size = 3,
    double gravity = 700,
    double spread = 2 * pi,
    double direction = -pi / 2,
    double life = 0.9,
  }) {
    _add([
      for (var i = 0; i < count; i++)
        () {
          final a = direction + _range(-spread / 2, spread / 2);
          final v = _range(0.25, 1) * speed;
          return _Particle(
            pos: at,
            vel: Offset(cos(a) * v, sin(a) * v),
            life: _range(0.5, 1) * life,
            size: _range(0.6, 1.3) * size,
            color: Color.lerp(color, Colors.white, _range(0, 0.6))!,
            shape: _Shape.streak,
            gravity: gravity,
            drag: 0.035,
          );
        }(),
    ]);
  }

  /// Soft glowing motes that drift and fade, e.g. around a selected piece.
  void motes(
    Offset at,
    Color color, {
    int count = 10,
    double radius = 20,
    double size = 10,
    double rise = 40,
    double life = 1.4,
  }) {
    _add([
      for (var i = 0; i < count; i++)
        _Particle(
          pos: at.translate(_range(-radius, radius), _range(-radius, radius)),
          vel: Offset(_range(-12, 12), -_range(0.4, 1) * rise),
          life: _range(0.6, 1) * life,
          size: _range(0.5, 1.2) * size,
          color: color,
          shape: _Shape.glow,
          delay: _range(0, 0.3),
        ),
    ]);
  }

  /// A bright four-pointed flare with a halo.
  void flare(Offset at, Color color, {double size = 140, double life = 0.7}) {
    _add([
      _Particle(
        pos: at,
        vel: Offset.zero,
        life: life,
        size: size,
        color: color,
        shape: _Shape.star,
        spin: 1.4,
        grow: 0.4,
      ),
      _Particle(
        pos: at,
        vel: Offset.zero,
        life: life * 0.8,
        size: size * 0.9,
        color: Color.lerp(color, Colors.white, 0.4)!,
        shape: _Shape.glow,
        grow: 0.6,
      ),
    ]);
  }

  /// Little stars that twinkle out of a point.
  void stars(
    Offset at,
    Color color, {
    int count = 14,
    double speed = 200,
    double size = 22,
    double life = 1.1,
  }) {
    _add([
      for (var i = 0; i < count; i++)
        () {
          final a = _range(0, 2 * pi);
          final v = _range(0.3, 1) * speed;
          return _Particle(
            pos: at,
            vel: Offset(cos(a) * v, sin(a) * v),
            life: _range(0.6, 1) * life,
            size: _range(0.5, 1) * size,
            color: Color.lerp(color, Colors.white, _range(0.1, 0.5))!,
            shape: _Shape.star,
            drag: 0.06,
            spin: _range(-4, 4),
            gravity: 60,
          );
        }(),
    ]);
  }

  /// A piece breaking apart: shards that spin away and fall.
  void shatter(Offset at, Color color, {double size = 60, int count = 18}) {
    _add([
      for (var i = 0; i < count; i++)
        () {
          final a = _range(0, 2 * pi);
          final v = _range(80, 380);
          return _Particle(
            pos: at.translate(
              _range(-size / 4, size / 4),
              _range(-size / 3, 0),
            ),
            vel: Offset(cos(a) * v, sin(a) * v - 180),
            life: _range(0.6, 1.1),
            size: _range(0.12, 0.3) * size,
            color: Color.lerp(color, Colors.black, _range(0, 0.35))!,
            shape: _Shape.shard,
            gravity: 1100,
            drag: 0.02,
            spin: _range(-12, 12),
            angle: _range(0, 2 * pi),
            additive: false,
          );
        }(),
      for (var i = 0; i < 8; i++)
        _Particle(
          pos: at.translate(_range(-size / 4, size / 4), _range(-size / 4, 0)),
          vel: Offset(_range(-40, 40), _range(-70, -20)),
          life: _range(0.6, 1),
          size: _range(0.4, 0.7) * size,
          color: Colors.black.withValues(alpha: 0.35),
          shape: _Shape.glow,
          additive: false,
          grow: 1.2,
        ),
    ]);
  }

  /// Dark smoke rising, e.g. from a blunder.
  void smoke(Offset at, {double size = 50, int count = 12, Color? color}) {
    _add([
      for (var i = 0; i < count; i++)
        _Particle(
          pos: at.translate(_range(-size / 3, size / 3), _range(-size / 4, 0)),
          vel: Offset(_range(-25, 25), _range(-90, -40)),
          life: _range(0.9, 1.6),
          size: _range(0.5, 1) * size,
          color: (color ?? const Color(0xFF1A1512)).withValues(alpha: 0.55),
          shape: _Shape.glow,
          additive: false,
          grow: 1.6,
          delay: _range(0, 0.25),
        ),
    ]);
  }

  /// Confetti raining across [area].
  void confetti(Rect area, {int count = 140, List<Color>? colors}) {
    final palette =
        colors ??
        const [
          Palette.gold,
          Color(0xFFF1D79B),
          Palette.ivory,
          Color(0xFF26C2A3),
          Color(0xFFE5533D),
          Color(0xFF6FA8DC),
        ];
    _add([
      for (var i = 0; i < count; i++)
        _Particle(
          pos: Offset(
            _range(area.left, area.right),
            area.top - _range(0, area.height * 0.25),
          ),
          vel: Offset(_range(-60, 60), _range(120, 320)),
          life: _range(2.4, 4),
          size: _range(9, 15),
          color: palette[_rnd.nextInt(palette.length)],
          shape: _Shape.rect,
          gravity: 90,
          drag: 0.01,
          spin: _range(-7, 7),
          angle: _range(0, 2 * pi),
          additive: false,
          delay: _range(0, 1.2),
          wobble: _range(40, 110),
        ),
    ]);
  }

  /// A firework: a rising trail that bursts into sparks and stars.
  void firework(Offset at, Color color, {double delay = 0}) {
    _after(delay, () {
      sparks(at, color, count: 46, speed: 360, gravity: 260, life: 1.3);
      stars(at, color, count: 10, speed: 160, size: 18);
      flare(at, color, size: 120, life: 0.5);
    });
  }

  /// An expanding ring of light.
  void shockwave(
    Offset at,
    Color color, {
    double radius = 120,
    double life = 0.6,
    double width = 6,
    double delay = 0,
  }) {
    if (_disposed) return;
    _rings.add(
      _Ring(
        center: at,
        radius: radius,
        color: color,
        life: life,
        width: width,
        delay: delay,
      ),
    );
    notifyListeners();
  }
}

/// A sprite sheet of white shapes, tinted per particle.
abstract final class _Sprites {
  static const cell = 64.0;
  static ui.Image? image;
  static Future<void>? _loading;

  static Future<void> ensure() => _loading ??= _build();

  static Rect rect(_Shape s) => Rect.fromLTWH(cell * s.index, 0, cell, cell);

  static Future<void> _build() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(cell / 2, cell / 2);
    // Glow.
    canvas.drawCircle(
      c,
      cell / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          cell / 2,
          [
            Colors.white,
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0),
          ],
          [0, 0.3, 1],
        ),
    );
    // Star: four rays and a hot core.
    canvas.save();
    canvas.translate(cell, 0);
    for (final (w, h) in [(5.0, 62.0), (62.0, 5.0), (3.0, 40.0), (40.0, 3.0)]) {
      canvas.save();
      if (w == 3 || h == 3) {
        canvas.translate(c.dx, c.dy);
        canvas.rotate(pi / 4);
        canvas.translate(-c.dx, -c.dy);
      }
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w, height: h),
        Paint()
          ..shader = ui.Gradient.radial(c, max(w, h) / 2, [
            Colors.white,
            Colors.white.withValues(alpha: 0),
          ]),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      10,
      Paint()
        ..shader = ui.Gradient.radial(c, 10, [
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ]),
    );
    canvas.restore();
    // Confetti.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c.translate(cell * 2, 0),
          width: 40,
          height: 24,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white,
    );
    // Shard: a faceted triangle.
    final o = Offset(cell * 3, 0);
    final shard = Path()
      ..moveTo(o.dx + 32, o.dy + 4)
      ..lineTo(o.dx + 60, o.dy + 58)
      ..lineTo(o.dx + 6, o.dy + 46)
      ..close();
    canvas.drawPath(
      shard,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(o.dx + 10, o.dy + 4),
          Offset(o.dx + 56, o.dy + 58),
          [Colors.white, const Color(0xFFBDBDBD)],
        ),
    );
    final picture = recorder.endRecording();
    image = await picture.toImage((cell * 5).toInt(), cell.toInt());
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.fx, Listenable repaint) : super(repaint: repaint);

  final FxController fx;

  @override
  void paint(Canvas canvas, Size size) {
    final sprites = _Sprites.image;
    final streak = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;
    final normal = <(RSTransform, Rect, Color)>[];
    final additive = <(RSTransform, Rect, Color)>[];

    for (final p in fx._particles) {
      if (p.delay > 0) continue;
      final t = p.t;
      final fadeIn = (p.age / 0.06).clamp(0.0, 1.0);
      final alpha = fadeIn * pow(1 - t, p.shape == _Shape.rect ? 0.4 : 1.4);
      final color = p.color.withValues(alpha: p.color.a * alpha);
      if (p.shape == _Shape.streak) {
        final tail = p.vel * 0.035;
        streak
          ..color = color
          ..strokeWidth = p.size * (1 - t * 0.5);
        canvas.drawLine(p.pos, p.pos - tail, streak);
        continue;
      }
      if (sprites == null) continue;
      final scale = p.size * (1 + p.grow * t) / _Sprites.cell;
      final transform = RSTransform.fromComponents(
        rotation: p.angle,
        scale: scale,
        anchorX: _Sprites.cell / 2,
        anchorY: _Sprites.cell / 2,
        translateX: p.pos.dx,
        translateY: p.pos.dy,
      );
      (p.additive ? additive : normal).add((
        transform,
        _Sprites.rect(p.shape),
        color,
      ));
    }

    void draw(List<(RSTransform, Rect, Color)> items, BlendMode mode) {
      if (items.isEmpty || sprites == null) return;
      canvas.drawAtlas(
        sprites,
        [for (final i in items) i.$1],
        [for (final i in items) i.$2],
        [for (final i in items) i.$3],
        BlendMode.modulate,
        null,
        Paint()
          ..blendMode = mode
          ..filterQuality = FilterQuality.low,
      );
    }

    draw(normal, BlendMode.srcOver);
    draw(additive, BlendMode.plus);

    for (final r in fx._rings) {
      if (r.delay > 0) continue;
      final t = Curves.easeOutCubic.transform((r.age / r.life).clamp(0, 1));
      final radius = r.radius * (0.15 + 0.85 * t);
      final a = (1 - t);
      canvas.drawCircle(
        r.center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.width * (1 - t * 0.6) * 2.4
          ..color = r.color.withValues(alpha: 0.25 * a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width),
      );
      canvas.drawCircle(
        r.center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.width * (1 - t * 0.6)
          ..blendMode = BlendMode.plus
          ..color = r.color.withValues(alpha: 0.8 * a),
      );
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => false;
}

/// Hosts a particle layer, screen shake and color flashes over [child].
class FxScope extends StatefulWidget {
  const FxScope({super.key, required this.child});

  final Widget child;

  /// The nearest scope, or null (effects are then silently skipped).
  static FxScopeState? of(BuildContext context) =>
      context.findAncestorStateOfType<FxScopeState>();

  @override
  State<FxScope> createState() => FxScopeState();
}

class FxScopeState extends State<FxScope> with TickerProviderStateMixin {
  final fx = FxController();
  final _frame = ValueNotifier<int>(0);
  final _layerKey = GlobalKey();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  double _shakeStrength = 0;

  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Color _flashColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _Sprites.ensure().then((_) {
      if (mounted) _frame.value++;
    });
    fx.addListener(_wake);
  }

  void _wake() {
    if (!_ticker.isActive && !fx.isIdle) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    fx._step(dt);
    _frame.value++;
    if (fx.isIdle) _ticker.stop();
  }

  @override
  void dispose() {
    fx.removeListener(_wake);
    _ticker.dispose();
    _shake.dispose();
    _flash.dispose();
    _frame.dispose();
    fx.dispose();
    super.dispose();
  }

  /// Converts [local] in [context]'s box to this scope's coordinates.
  Offset? toScope(BuildContext context, Offset local) {
    final from = context.findRenderObject() as RenderBox?;
    final to = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (from == null || to == null || !from.attached || !to.attached) {
      return null;
    }
    return to.globalToLocal(from.localToGlobal(local));
  }

  Size get size =>
      (_layerKey.currentContext?.findRenderObject() as RenderBox?)?.size ??
      Size.zero;

  /// Shakes the whole screen; [strength] is the peak offset in pixels.
  void shake([double strength = 10]) {
    if (MediaQuery.of(context).disableAnimations) return;
    _shakeStrength = strength;
    _shake.forward(from: 0);
  }

  /// Washes the screen with [color] for a moment.
  void flash(Color color) {
    _flashColor = color;
    _flash.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            if (!_shake.isAnimating) return child!;
            final t = _shake.value;
            final decay = pow(1 - t, 2).toDouble();
            final s = _shakeStrength * decay;
            return Transform.translate(
              offset: Offset(
                sin(t * 70) * s,
                cos(t * 53 + 1) * s * 0.6,
              ),
              child: Transform.rotate(
                angle: sin(t * 37) * s * 0.0012,
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: _layerKey,
                painter: _FxPainter(fx, _frame),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _flash,
              builder: (context, _) {
                if (!_flash.isAnimating) return const SizedBox.shrink();
                final a = sin(_flash.value * pi) * 0.9;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.1,
                      colors: [
                        _flashColor.withValues(alpha: 0.06 * a),
                        _flashColor.withValues(alpha: 0.42 * a),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Fires effects at a point inside the widget that owns [context].
extension FxContext on BuildContext {
  /// Runs [effect] with this widget's [local] point in scope coordinates.
  void fx(Offset local, void Function(FxScopeState scope, Offset at) effect) {
    final scope = FxScope.of(this);
    if (scope == null) return;
    final at = scope.toScope(this, local);
    if (at != null) effect(scope, at);
  }
}

// =============================================================================
// Ambient embers

/// Slowly rising embers and dust, lit by the lamp.
class EmberField extends StatefulWidget {
  const EmberField({super.key, this.density = 1, this.color = Palette.gold});

  final double density;
  final Color color;

  @override
  State<EmberField> createState() => _EmberFieldState();
}

class _Ember {
  _Ember(Size s, {bool anywhere = false}) {
    reset(s, anywhere: anywhere);
  }

  late Offset pos;
  late double speed;
  late double size;
  late double phase;
  late double drift;
  late double glow;

  void reset(Size s, {bool anywhere = false}) {
    pos = Offset(
      _range(0, s.width),
      anywhere ? _range(0, s.height) : s.height + _range(0, 40),
    );
    speed = _range(8, 26);
    size = _range(1.2, 3.4);
    phase = _range(0, 2 * pi);
    drift = _range(6, 22);
    glow = _range(0.25, 0.9);
  }
}

class _EmberFieldState extends State<EmberField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<int>(0);
  final _embers = <_Ember>[];
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _Sprites.ensure();
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;
    if (_size.isEmpty) return;
    final target = (_size.width * _size.height / 26000 * widget.density)
        .clamp(8, 70)
        .round();
    while (_embers.length < target) {
      _embers.add(_Ember(_size, anywhere: true));
    }
    if (_embers.length > target) _embers.removeRange(target, _embers.length);
    for (final e in _embers) {
      e.pos = e.pos.translate(
        sin(_time * 0.6 + e.phase) * e.drift * dt,
        -e.speed * dt,
      );
      if (e.pos.dy < -10) e.reset(_size);
    }
    _frame.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      _ticker.muted = true;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return RepaintBoundary(
          child: CustomPaint(
            size: constraints.biggest,
            painter: _EmberPainter(this, _frame),
          ),
        );
      },
    );
  }
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.state, Listenable repaint) : super(repaint: repaint);

  final _EmberFieldState state;

  @override
  void paint(Canvas canvas, Size size) {
    final sprites = _Sprites.image;
    if (sprites == null || state._embers.isEmpty) return;
    final h = size.height;
    canvas.drawAtlas(
      sprites,
      [
        for (final e in state._embers)
          RSTransform.fromComponents(
            rotation: 0,
            scale: e.size * 3.2 / _Sprites.cell,
            anchorX: _Sprites.cell / 2,
            anchorY: _Sprites.cell / 2,
            translateX: e.pos.dx,
            translateY: e.pos.dy,
          ),
      ],
      [for (final _ in state._embers) _Sprites.rect(_Shape.glow)],
      [
        for (final e in state._embers)
          state.widget.color.withValues(
            alpha:
                e.glow *
                (0.55 + 0.45 * sin(state._time * 2.2 + e.phase)) *
                // Fade in from the bottom and out near the top.
                (e.pos.dy / h).clamp(0.0, 1.0) *
                ((h - e.pos.dy) / 60).clamp(0.0, 1.0),
          ),
      ],
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(_EmberPainter old) => false;
}

// =============================================================================
// Light and shine

/// Slowly turning rays of light, e.g. behind a trophy or the coach.
class LightRays extends StatefulWidget {
  const LightRays({
    super.key,
    this.color = Palette.gold,
    this.rays = 14,
    this.opacity = 0.35,
    this.speed = 0.05,
  });

  final Color color;
  final int rays;
  final double opacity;

  /// Turns per second.
  final double speed;

  @override
  State<LightRays> createState() => _LightRaysState();
}

class _LightRaysState extends State<LightRays>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();
  double _turns = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final now = _c.lastElapsedDuration ?? Duration.zero;
      final dt = (now - _last).inMicroseconds / 1e6;
      _last = now;
      if (dt > 0 && dt < 0.1) _turns += dt * widget.speed;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _RaysPainter(
              widget.color,
              widget.rays,
              widget.opacity,
              _turns * 2 * pi,
            ),
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color, this.rays, this.opacity, this.angle);

  final Color color;
  final int rays;
  final double opacity;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        c,
        r,
        [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.4),
          color.withValues(alpha: 0),
        ],
        [0, 0.4, 1],
      );
    final path = Path();
    for (var i = 0; i < rays; i++) {
      final a = angle + i * 2 * pi / rays;
      final w = (i.isEven ? 0.09 : 0.05) * pi;
      path
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - w) * r, c.dy + sin(a - w) * r)
        ..lineTo(c.dx + cos(a + w) * r, c.dy + sin(a + w) * r)
        ..close();
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      c,
      r * 0.55,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(c, r * 0.55, [
          color.withValues(alpha: opacity * 0.6),
          color.withValues(alpha: 0),
        ]),
    );
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.angle != angle || old.color != color || old.opacity != opacity;
}

/// A bright band of light that sweeps across [child] every few seconds,
/// like light catching polished metal.
class Shine extends StatefulWidget {
  const Shine({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3600),
    this.color = Colors.white,
    this.enabled = true,
  });

  final Widget child;
  final Duration period;
  final Color color;
  final bool enabled;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period)
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // The sweep takes the first 35% of the period, then rests.
        final t = (_c.value / 0.35).clamp(0.0, 1.0);
        final x = -1.6 + 3.2 * Curves.easeInOutSine.transform(t);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.5, -0.4),
            end: Alignment(x + 0.5, 0.4),
            colors: [
              widget.color.withValues(alpha: 0),
              widget.color.withValues(alpha: 0.55),
              widget.color.withValues(alpha: 0),
            ],
            stops: const [0.3, 0.5, 0.7],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Text painted with a polished gold gradient.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, required this.style, this.align});

  final String text;
  final TextStyle style;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF1C9),
          Color(0xFFE9C981),
          Palette.gold,
          Color(0xFF9C7A3C),
        ],
        stops: [0, 0.35, 0.6, 1],
      ).createShader(rect),
      child: Text(text, style: style, textAlign: align),
    );
  }
}

/// Scales [child] down while pressed and springs back, for anything tappable.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.94,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Duration(milliseconds: _down ? 90 : 380),
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Slides and fades [child] in after [delay], for staggered entrances.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 24),
    this.duration = const Duration(milliseconds: 700),
    this.scale = 1,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  /// The starting scale.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final total = delay + duration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, v, child) {
        final t = Curves.easeOutCubic.transform(
          ((v - start) / (1 - start)).clamp(0.0, 1.0),
        );
        final s = scale + (1 - scale) * Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: offset * (1 - t),
            child: Transform.scale(scale: s, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

// =============================================================================
// Page transition

/// A circular reveal that grows from [origin] with a ring of gold light at its
/// edge, while the new page settles from a slight zoom.
class FxPageRoute<T> extends PageRouteBuilder<T> {
  FxPageRoute({required WidgetBuilder builder, this.origin})
    : super(
        transitionDuration: const Duration(milliseconds: 780),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, _, _) => builder(context),
      );

  /// Where the reveal starts, in global coordinates; the centre if null.
  final Offset? origin;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return FadeTransition(opacity: animation, child: child);
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final o = origin ?? size.center(Offset.zero);
        final reverse = animation.status == AnimationStatus.reverse;
        final t = (reverse ? Curves.easeInCubic : Curves.easeInOutCubic)
            .transform(animation.value);
        final far = [
          Offset.zero,
          Offset(size.width, 0),
          Offset(0, size.height),
          Offset(size.width, size.height),
        ].map((c) => (c - o).distance).reduce(max);
        final radius = far * t;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
              clipper: _CircleClipper(o, radius),
              child: Transform.scale(
                scale:
                    1.08 -
                    0.08 * Curves.easeOutCubic.transform(animation.value),
                child: child,
              ),
            ),
            if (t > 0 && t < 1)
              IgnorePointer(
                child: CustomPaint(painter: _RevealRingPainter(o, radius, t)),
              ),
          ],
        );
      },
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.radius != radius || old.center != center;
}

class _RevealRingPainter extends CustomPainter {
  _RevealRingPainter(this.center, this.radius, this.t);

  final Offset center;
  final double radius;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final a = sin(t * pi);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..color = Palette.gold.withValues(alpha: 0.35 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..blendMode = BlendMode.plus
        ..color = const Color(0xFFFFE7B0).withValues(alpha: 0.9 * a),
    );
  }

  @override
  bool shouldRepaint(_RevealRingPainter old) => true;
}

/// Pushes [builder] with the circular reveal, starting at the widget that
/// owns [context] (usually the button that was tapped).
Future<T?> pushFx<T>(BuildContext context, WidgetBuilder builder) {
  Offset? origin;
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.attached) {
    origin = box.localToGlobal(box.size.center(Offset.zero));
  }
  return Navigator.of(
    context,
  ).push<T>(FxPageRoute<T>(builder: builder, origin: origin));
}
