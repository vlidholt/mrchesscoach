import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart' show MoveClass;

import '../game/chess_model.dart';
import '../theme.dart';
import 'move_badge.dart';

/// The asset for [piece], e.g. `assets/images/pieces/wn.png`.
String pieceAsset(Side color, Role role) =>
    'assets/images/pieces/${color == Side.white ? 'w' : 'b'}${role.letter}.png';

/// Every piece and board image, for precaching.
Iterable<String> get allBoardAssets => [
  'assets/images/board.png',
  for (final side in Side.values)
    for (final role in Role.values) pieceAsset(side, role),
];

/// Where the 8x8 grid sits inside `board.png`, as fractions of its size.
const _gridLeft = 0.0507;
const _gridTop = 0.0534;
const _gridRight = 0.9520;
const _gridBottom = 0.9528;

const _slide = Duration(milliseconds: 280);

/// An arrow drawn on the board, e.g. a hint or a threat.
class BoardArrow {
  const BoardArrow(this.from, this.to, {this.color = Palette.gold});

  /// An arrow for a UCI move such as `e2e4`; null if it can't be parsed.
  static BoardArrow? fromUci(String? uci, {Color color = Palette.gold}) {
    final move = uci == null ? null : Move.parse(uci);
    return move == null ? null : BoardArrow(move.from, move.to, color: color);
  }

  final Square from;
  final Square to;
  final Color color;

  String get key => '${from.name}${to.name}${color.toARGB32()}';

  static const best = Color(0xFF8BC34A);
  static const threat = Color(0xFFE5533D);
  static const idea = Color(0xFF6FA8DC);
}

/// An interactive chessboard drawn with the glossy board and piece images.
class ChessBoardView extends StatefulWidget {
  const ChessBoardView({
    super.key,
    required this.position,
    required this.orientation,
    required this.legalMoves,
    required this.onMove,
    this.lastMove,
    this.arrows = const [],
    this.inCheck = false,
    this.markedSquare,
    this.badge,
  });

  final BoardState position;

  /// The side shown at the bottom.
  final Side orientation;

  /// Legal destinations for the pieces the user may move. Empty when the
  /// board is read-only.
  final Map<Square, Set<Square>> legalMoves;

  final void Function(Move move) onMove;
  final Move? lastMove;

  /// Whether the side to move is in check.
  final bool inCheck;

  /// Arrows to draw, e.g. a hint, the best move or a threat.
  final List<BoardArrow> arrows;

  /// A square to draw attention to (hint: "this piece").
  final Square? markedSquare;

  /// A verdict badge shown on a square, usually the last move's target.
  final (Square, MoveClass)? badge;

  @override
  State<ChessBoardView> createState() => _ChessBoardViewState();
}

class _ChessBoardViewState extends State<ChessBoardView> {
  var _sprites = <_Sprite>[];
  final _ghosts = <_Sprite>[];
  int _nextId = 0;

  Square? _selected;
  _Drag? _drag;
  _Press? _press;

  /// Sprites that should jump instead of slide (they were dropped by hand).
  final _instant = <int>{};

  /// A pawn move waiting for the user to pick the promotion piece.
  ({Square from, Square to})? _promotion;

  @override
  void initState() {
    super.initState();
    _sprites = [
      for (final MapEntry(key: square, value: piece)
          in widget.position.pieces.entries)
        _Sprite(_nextId++, piece, square),
    ];
  }

  @override
  void didUpdateWidget(ChessBoardView old) {
    super.didUpdateWidget(old);
    if (old.position.placementKey != widget.position.placementKey) {
      _reconcile(widget.position);
    }
    if (widget.legalMoves.isEmpty) {
      _selected = null;
      _drag = null;
      _promotion = null;
    }
  }

  /// Matches the new board against the current sprites so that moved pieces
  /// keep their identity and slide, and captured ones fade out.
  void _reconcile(BoardState board) {
    final remaining = [..._sprites];
    final next = <_Sprite>[];
    final added = <(Square, Piece)>[];

    for (final MapEntry(key: square, value: piece) in board.pieces.entries) {
      final same = remaining.where(
        (s) => s.square == square && s.piece == piece,
      );
      if (same.isNotEmpty) {
        next.add(same.first);
        remaining.remove(same.first);
      } else {
        added.add((square, piece));
      }
    }

    for (final (square, piece) in added) {
      // A piece of the same kind that left its square moved here; a pawn
      // that vanished from the 7th rank may have been promoted.
      var candidates = remaining.where((s) => s.piece == piece).toList();
      if (candidates.isEmpty && (square.rank == 0 || square.rank == 7)) {
        candidates = remaining
            .where(
              (s) => s.piece.color == piece.color && s.piece.role == Role.pawn,
            )
            .toList();
      }
      if (candidates.isNotEmpty) {
        candidates.sort(
          (a, b) => _distance(
            a.square,
            square,
          ).compareTo(_distance(b.square, square)),
        );
        final moved = candidates.first;
        remaining.remove(moved);
        next.add(_Sprite(moved.id, piece, square));
      } else {
        next.add(_Sprite(_nextId++, piece, square));
      }
    }

    // Whatever is left was captured.
    for (final ghost in remaining) {
      _ghosts.add(ghost);
      Timer(_slide + const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _ghosts.remove(ghost));
      });
    }
    _sprites = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _instant.isNotEmpty) setState(_instant.clear);
    });
  }

  static int _distance(Square a, Square b) =>
      max((a.file - b.file).abs(), (a.rank - b.rank).abs());

  bool _isPromotion(Square from, Square to) {
    final piece = widget.position.pieceAt(from);
    return piece?.role == Role.pawn && (to.rank == 0 || to.rank == 7);
  }

  void _attempt(Square from, Square to, {bool dropped = false}) {
    if (!(widget.legalMoves[from]?.contains(to) ?? false)) return;
    if (dropped) {
      final sprite = _sprites.where((s) => s.square == from).firstOrNull;
      if (sprite != null) _instant.add(sprite.id);
    }
    setState(() => _selected = null);
    if (_isPromotion(from, to)) {
      setState(() => _promotion = (from: from, to: to));
      return;
    }
    widget.onMove(Move(from, to));
  }

  void _promote(Role role) {
    final p = _promotion;
    if (p == null) return;
    setState(() => _promotion = null);
    widget.onMove(Move(p.from, p.to, role));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final g = _Geometry(constraints.maxWidth, widget.orientation);
          return _buildBoard(g);
        },
      ),
    );
  }

  Widget _buildBoard(_Geometry g) {
    final interactive = widget.legalMoves.isNotEmpty;
    final focus = _drag?.from ?? _selected;
    final targets = focus == null
        ? const <Square>{}
        : widget.legalMoves[focus] ?? const {};
    final checkedKing = widget.inCheck
        ? widget.position.kingOf(widget.position.turn)
        : null;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      // Raw pointer events rather than tap and pan recognizers: a press on a
      // piece selects it, and the release decides between tap and drop.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: interactive
            ? (e) => _pointerDown(g, e.localPosition)
            : null,
        onPointerMove: interactive
            ? (e) => _pointerMove(e.localPosition)
            : null,
        onPointerUp: interactive ? (e) => _pointerUp(g, e.localPosition) : null,
        onPointerCancel: (_) => setState(() {
          _press = null;
          _drag = null;
        }),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Shadow cast by the board onto the table.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(g.size * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.75),
                      blurRadius: g.size * 0.08,
                      offset: Offset(0, g.size * 0.035),
                    ),
                    BoxShadow(
                      color: Palette.gold.withValues(alpha: 0.10),
                      blurRadius: g.size * 0.12,
                      spreadRadius: -g.size * 0.02,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                'assets/images/board.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (widget.lastMove case final m?) ...[
              _tint(g, m.from, Palette.gold.withValues(alpha: 0.30)),
              _tint(g, m.to, Palette.gold.withValues(alpha: 0.42)),
            ],
            if (focus != null)
              _tint(g, focus, Palette.gold.withValues(alpha: 0.55), glow: true),
            if (checkedKing != null) _checkGlow(g, checkedKing),
            ..._coordinates(g),
            for (final t in targets)
              _target(g, t, widget.position.pieceAt(t) != null),
            for (final ghost in _ghosts) _ghost(g, ghost),
            for (final s in _sprites) _piece(g, s),
            if (widget.markedSquare case final m?) _marker(g, m),
            for (final h in widget.arrows)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(h.key),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => CustomPaint(
                      painter: _ArrowPainter(
                        g.center(h.from),
                        g.center(h.to),
                        g.square,
                        t,
                        h.color,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.badge case (final square, final cls))
              _badge(g, square, cls),
            if (_drag case final d?) _dragged(g, d),
            if (_promotion case final p?) _promotionPicker(g, p.to),
          ],
        ),
      ),
    );
  }

  Widget _marker(_Geometry g, Square square) {
    return Positioned.fromRect(
      rect: g.rect(square),
      child: IgnorePointer(
        child: _PulsingRing(size: g.square),
      ),
    );
  }

  Widget _badge(_Geometry g, Square square, MoveClass cls) {
    final r = g.rect(square);
    final size = max(16.0, g.square * 0.38);
    return Positioned(
      key: ValueKey('badge-${square.name}-${cls.name}'),
      left: r.right - size * 0.72,
      top: r.top - size * 0.28,
      width: size,
      height: size,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.elasticOut,
          builder: (context, t, child) =>
              Transform.scale(scale: t.clamp(0, 1.3), child: child),
          child: MoveBadge(cls, size: size),
        ),
      ),
    );
  }

  void _pointerDown(_Geometry g, Offset local) {
    if (_promotion != null) return;
    final square = g.squareAt(local);
    final selected = _selected;
    if (square == null) {
      setState(() => _selected = null);
      return;
    }
    // Tap-to-move: the second press lands on a legal target.
    if (selected != null &&
        (widget.legalMoves[selected]?.contains(square) ?? false)) {
      _attempt(selected, square);
      return;
    }
    if (widget.legalMoves.containsKey(square)) {
      setState(() {
        _selected = square;
        _press = _Press(square, local, wasSelected: selected == square);
      });
    } else {
      setState(() => _selected = null);
    }
  }

  void _pointerMove(Offset local) {
    final press = _press;
    if (press == null) return;
    if (_drag == null && (local - press.start).distance < 6) return;
    final piece = widget.position.pieceAt(press.square);
    if (piece == null) return;
    setState(() => _drag = _Drag(press.square, piece, local));
  }

  void _pointerUp(_Geometry g, Offset local) {
    final press = _press;
    final dragged = _drag != null;
    setState(() {
      _press = null;
      _drag = null;
    });
    if (press == null) return;
    final target = g.squareAt(local);
    if (target != null &&
        target != press.square &&
        (widget.legalMoves[press.square]?.contains(target) ?? false)) {
      _attempt(press.square, target, dropped: dragged);
    } else if (!dragged && press.wasSelected) {
      // A second click on the selected piece puts it back down.
      setState(() => _selected = null);
    }
  }

  Widget _tint(_Geometry g, Square square, Color color, {bool glow = false}) {
    final r = g.rect(square).deflate(g.square * 0.035);
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(g.square * 0.06),
            border: glow
                ? Border.all(
                    color: Palette.gold,
                    width: max(1.5, g.square * 0.03),
                  )
                : null,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: Palette.goldGlow,
                      blurRadius: g.square * 0.3,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _checkGlow(_Geometry g, Square king) {
    return Positioned.fromRect(
      rect: g.rect(king),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFF5A3C).withValues(alpha: 0.95),
                const Color(0xFFE0391E).withValues(alpha: 0.45),
                Colors.transparent,
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ),
    );
  }

  Iterable<Widget> _coordinates(_Geometry g) sync* {
    // Too small to read on preview boards.
    if (g.square < 24) return;
    final fontSize = max(8.0, g.square * 0.15);
    for (var i = 0; i < 8; i++) {
      // Files along the bottom row, ranks along the left column.
      final fileSquare = g.squareAtGrid(i, 7);
      final rankSquare = g.squareAtGrid(0, i);
      for (final (square, text, align) in [
        (fileSquare, fileSquare.fileName, Alignment.bottomRight),
        (rankSquare, rankSquare.rankName, Alignment.topLeft),
      ]) {
        final light = square.isLight;
        yield Positioned.fromRect(
          rect: g.rect(square).deflate(g.square * 0.07),
          child: IgnorePointer(
            child: Align(
              alignment: align,
              child: Text(
                text,
                style: Typo.body(
                  fontSize,
                  weight: FontWeight.w800,
                  color: light
                      ? const Color(0xFF8A7650)
                      : const Color(0xFFB59A62),
                ).copyWith(height: 1),
              ),
            ),
          ),
        );
      }
    }
  }

  Widget _target(_Geometry g, Square square, bool capture) {
    final r = g.rect(square);
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: capture
                ? Container(
                    width: g.square * 0.9,
                    height: g.square * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Palette.gold.withValues(alpha: 0.85),
                        width: g.square * 0.07,
                      ),
                    ),
                  )
                : Container(
                    width: g.square * 0.28,
                    height: g.square * 0.28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFF6DDA0),
                          Palette.gold,
                          Color(0xFF8E6C30),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _piece(_Geometry g, _Sprite s) {
    final dragging = _drag?.from == s.square;
    return AnimatedPositioned.fromRect(
      key: ValueKey(s.id),
      rect: g.rect(s.square),
      duration: _instant.contains(s.id) ? Duration.zero : _slide,
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: dragging ? 0.3 : 1,
          duration: const Duration(milliseconds: 120),
          child: _PieceImage(piece: s.piece, size: g.square),
        ),
      ),
    );
  }

  Widget _ghost(_Geometry g, _Sprite s) {
    return Positioned.fromRect(
      key: ValueKey('ghost-${s.id}'),
      rect: g.rect(s.square),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: _slide,
          curve: Curves.easeIn,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
          child: _PieceImage(piece: s.piece, size: g.square),
        ),
      ),
    );
  }

  Widget _dragged(_Geometry g, _Drag d) {
    final size = g.square * 1.3;
    return Positioned(
      left: d.pointer.dx - size / 2,
      top: d.pointer.dy - size * 0.62,
      width: size,
      height: size,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: size * 0.25,
                offset: Offset(0, size * 0.2),
              ),
            ],
          ),
          child: _PieceImage(piece: d.piece, size: size, shadow: false),
        ),
      ),
    );
  }

  Widget _promotionPicker(_Geometry g, Square to) {
    final color = widget.position.turn;
    final roles = [Role.queen, Role.knight, Role.rook, Role.bishop];
    final topRect = g.rect(to);
    // The picker grows from the promotion square towards the centre.
    final downwards = topRect.top < g.size / 2;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _promotion = null),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Stack(
            children: [
              for (final (i, role) in roles.indexed)
                Positioned.fromRect(
                  rect: topRect.shift(
                    Offset(0, (downwards ? 1 : -1) * i * g.square),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 200 + i * 60),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) =>
                        Transform.scale(scale: t, child: child),
                    child: _PromotionChoice(
                      piece: Piece(color, role),
                      size: g.square,
                      onTap: () => _promote(role),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionChoice extends StatefulWidget {
  const _PromotionChoice({
    required this.piece,
    required this.size,
    required this.onTap,
  });

  final Piece piece;
  final double size;
  final VoidCallback onTap;

  @override
  State<_PromotionChoice> createState() => _PromotionChoiceState();
}

class _PromotionChoiceState extends State<_PromotionChoice> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.all(widget.size * 0.04),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: _hover
                  ? [const Color(0xFF5A4A2C), Palette.lacquer]
                  : [Palette.smoke, Palette.ebony],
            ),
            border: Border.all(color: Palette.gold, width: _hover ? 2 : 1),
            boxShadow: [
              BoxShadow(color: Palette.goldGlow, blurRadius: _hover ? 18 : 8),
            ],
          ),
          child: _PieceImage(
            piece: widget.piece,
            size: widget.size,
            shadow: false,
          ),
        ),
      ),
    );
  }
}

class _PieceImage extends StatelessWidget {
  const _PieceImage({
    required this.piece,
    required this.size,
    this.shadow = true,
  });

  final Piece piece;
  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      pieceAsset(piece.color, piece.role),
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    if (!shadow) return image;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Contact shadow under the base.
        Positioned(
          left: size * 0.2,
          right: size * 0.2,
          top: size * 0.86,
          height: size * 0.12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.elliptical(size, size * 0.12),
              ),
              gradient: RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        image,
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.from, this.to, this.square, this.progress, this.color);

  final Color color;

  final Offset from;
  final Offset to;
  final double square;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dir = to - from;
    final length = dir.distance;
    if (length == 0) return;
    final unit = dir / length;
    final start = from + unit * square * 0.25;
    final fullEnd = to - unit * square * 0.1;
    final end = Offset.lerp(start, fullEnd, progress)!;
    final width = square * 0.17;
    final headLength = square * 0.42;
    final shaftEnd = end - unit * headLength * 0.8;
    final normal = Offset(-unit.dy, unit.dx);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, square * 0.12);

    final path = Path()
      ..moveTo(
        start.dx + normal.dx * width / 2,
        start.dy + normal.dy * width / 2,
      )
      ..lineTo(
        shaftEnd.dx + normal.dx * width / 2,
        shaftEnd.dy + normal.dy * width / 2,
      )
      ..lineTo(
        shaftEnd.dx + normal.dx * width * 1.6,
        shaftEnd.dy + normal.dy * width * 1.6,
      )
      ..lineTo(end.dx, end.dy)
      ..lineTo(
        shaftEnd.dx - normal.dx * width * 1.6,
        shaftEnd.dy - normal.dy * width * 1.6,
      )
      ..lineTo(
        shaftEnd.dx - normal.dx * width / 2,
        shaftEnd.dy - normal.dy * width / 2,
      )
      ..lineTo(
        start.dx - normal.dx * width / 2,
        start.dy - normal.dy * width / 2,
      )
      ..close();
    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color ||
      old.from != from ||
      old.to != to ||
      old.progress != progress ||
      old.square != square;
}

class _Sprite {
  _Sprite(this.id, this.piece, this.square);

  final int id;
  final Piece piece;
  final Square square;
}

class _Press {
  _Press(this.square, this.start, {required this.wasSelected});

  final Square square;
  final Offset start;
  final bool wasSelected;
}

class _Drag {
  _Drag(this.from, this.piece, this.pointer);

  final Square from;
  final Piece piece;
  final Offset pointer;

  _Drag copyWith(Offset pointer) => _Drag(from, piece, pointer);
}

/// Maps squares to pixels for a board of [size] seen from [orientation].
class _Geometry {
  _Geometry(this.size, this.orientation)
    : grid = Rect.fromLTRB(
        size * _gridLeft,
        size * _gridTop,
        size * _gridRight,
        size * _gridBottom,
      );

  final double size;
  final Side orientation;
  final Rect grid;

  double get square => grid.width / 8;
  double get _squareHeight => grid.height / 8;

  /// The square at grid column [col] and row [row], counted from the top
  /// left as the user sees it.
  Square squareAtGrid(int col, int row) {
    final white = orientation == Side.white;
    return Square.fromCoords(white ? col : 7 - col, white ? 7 - row : row);
  }

  Rect rect(Square s) {
    final white = orientation == Side.white;
    final col = white ? s.file : 7 - s.file;
    final row = white ? 7 - s.rank : s.rank;
    return Rect.fromLTWH(
      grid.left + col * square,
      grid.top + row * _squareHeight,
      square,
      _squareHeight,
    );
  }

  Offset center(Square s) => rect(s).center;

  Square? squareAt(Offset p) {
    if (!grid.contains(p)) return null;
    final col = ((p.dx - grid.left) / square).floor().clamp(0, 7);
    final row = ((p.dy - grid.top) / _squareHeight).floor().clamp(0, 7);
    return squareAtGrid(col, row);
  }
}

/// A soft, breathing ring that draws the eye to a square.
class _PulsingRing extends StatefulWidget {
  const _PulsingRing({required this.size});

  final double size;

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Center(
          child: Container(
            width: widget.size * (0.82 + 0.12 * t),
            height: widget.size * (0.82 + 0.12 * t),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: BoardArrow.idea.withValues(alpha: 0.6 + 0.4 * t),
                width: widget.size * 0.06,
              ),
              boxShadow: [
                BoxShadow(
                  color: BoardArrow.idea.withValues(alpha: 0.5 * t),
                  blurRadius: widget.size * 0.3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
