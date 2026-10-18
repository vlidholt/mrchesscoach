import 'dart:math';

import '../game/chess_model.dart';
import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../game/game_controller.dart';
import '../theme.dart';
import 'chess_board.dart';
import 'move_badge.dart';

/// White's share of the evaluation bar, from 0 (Black winning) to 1.
double whiteShare(ChessGame game) {
  final playerWhite = game.playerColor == PlayerColor.white;
  switch (game.status) {
    case GameStatus.playerWon:
      return playerWhite ? 1 : 0;
    case GameStatus.computerWon:
      return playerWhite ? 0 : 1;
    case GameStatus.draw:
      return 0.5;
    case GameStatus.active:
    case GameStatus.abandoned:
      break;
  }
  if (game.evalMate case final mate?) {
    return mate > 0 ? 1 : (mate < 0 ? 0 : 0.5);
  }
  final cp = game.evalCp ?? 0;
  // Win probability curve used by Lichess.
  return 1 / (1 + exp(-0.00368208 * cp));
}

/// The evaluation as text: "+1.4", "M3", "1-0".
String evalLabel(ChessGame game) {
  final playerWhite = game.playerColor == PlayerColor.white;
  switch (game.status) {
    case GameStatus.playerWon:
      return playerWhite ? '1-0' : '0-1';
    case GameStatus.computerWon:
      return playerWhite ? '0-1' : '1-0';
    case GameStatus.draw:
      return '½-½';
    case GameStatus.active:
    case GameStatus.abandoned:
      break;
  }
  if (game.evalMate case final mate?) return 'M${mate.abs()}';
  final pawns = (game.evalCp ?? 0) / 100;
  return '${pawns >= 0 ? '+' : '−'}${pawns.abs().toStringAsFixed(1)}';
}

/// A vertical ivory/onyx bar showing who is ahead.
class EvalBar extends StatelessWidget {
  const EvalBar({
    super.key,
    required this.game,
    required this.orientation,
    this.width = 22,
  });

  final ChessGame game;
  final Side orientation;
  final double width;

  @override
  Widget build(BuildContext context) {
    final share = whiteShare(game);
    final whiteAhead = share >= 0.5;
    final whiteAtBottom = orientation == Side.white;
    return Tooltip(
      message: 'Stockfish evaluation',
      child: Container(
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
            tween: Tween(end: share),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final whiteHeight = h * value;
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
                        height: whiteHeight,
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
                      // Midline.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: h / 2 - 0.5,
                        height: 1,
                        child: ColoredBox(
                          color: Palette.gold.withValues(alpha: 0.7),
                        ),
                      ),
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
                              evalLabel(game),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: Typo.mono(
                                width < 20 ? 8 : 9,
                                color: whiteAhead
                                    ? Palette.onyx
                                    : Palette.ivory,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Name, avatar, captured pieces and turn indicator for one side.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.name,
    required this.subtitle,
    required this.side,
    required this.balance,
    required this.active,
    this.thinking = false,
    this.isComputer = false,
  });

  final String name;
  final String subtitle;
  final Side side;
  final MaterialBalance balance;
  final bool active;
  final bool thinking;
  final bool isComputer;

  @override
  Widget build(BuildContext context) {
    final captured = balance.capturedBy(side);
    final lead = balance.advantage(side);
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Palette.smoke, Palette.ebony],
            ),
            border: Border.all(
              color: active
                  ? Palette.gold
                  : Palette.goldDeep.withValues(alpha: 0.4),
              width: active ? 2 : 1,
            ),
            boxShadow: [
              if (active) BoxShadow(color: Palette.goldGlow, blurRadius: 16),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            pieceAsset(side, isComputer ? Role.knight : Role.king),
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.title(20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: thinking
                        ? const _ThinkingDots(key: ValueKey('t'))
                        : const SizedBox.shrink(key: ValueKey('n')),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: Typo.body(12, color: Palette.muted),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CapturedPieces(roles: captured, color: side.opposite),
                  if (lead > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '+$lead',
                      style: Typo.mono(12, color: Palette.gold),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapturedPieces extends StatelessWidget {
  const _CapturedPieces({required this.roles, required this.color});

  final List<Role> roles;
  final Side color;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();
    const size = 20.0;
    const overlap = 9.0;
    final groups = <List<Role>>[];
    for (final role in roles) {
      if (groups.isNotEmpty && groups.last.first == role) {
        groups.last.add(role);
      } else {
        groups.add([role]);
      }
    }
    return Flexible(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final group in groups)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SizedBox(
                  width: size + (group.length - 1) * overlap,
                  height: size,
                  child: Stack(
                    children: [
                      for (final (i, role) in group.indexed)
                        Positioned(
                          left: i * overlap,
                          child: Image.asset(
                            pieceAsset(color, role),
                            width: size,
                            height: size,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots({super.key});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.gold.withValues(
                  alpha:
                      0.25 +
                      0.75 *
                          (0.5 +
                              0.5 *
                                  sin(
                                    (_controller.value - i * 0.18) * 2 * pi,
                                  )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The game's moves in pairs: "1. e4 e5".
class MoveList extends StatefulWidget {
  const MoveList({
    super.key,
    required this.sanMoves,
    this.compact = false,
    this.verdicts = const {},
    this.selectedPly,
    this.onTap,
    this.plyOffset = 0,
  });

  final List<String> sanMoves;

  /// Verdict badges by ply.
  final Map<int, MoveClass> verdicts;

  /// The highlighted move; defaults to the last one.
  final int? selectedPly;

  final void Function(int ply)? onTap;

  /// The move number of the first ply is 1 + plyOffset // 2 (for games that
  /// start from a position).
  final int plyOffset;

  /// A single horizontal strip, for phones.
  final bool compact;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final _scroll = ScrollController();

  Widget _chip(int ply) => _MoveChip(
    san: widget.sanMoves[ply],
    latest: ply == (widget.selectedPly ?? widget.sanMoves.length - 1),
    verdict: widget.verdicts[ply],
    onTap: widget.onTap == null ? null : () => widget.onTap!(ply),
  );

  @override
  void didUpdateWidget(MoveList old) {
    super.didUpdateWidget(old);
    if (old.sanMoves.length != widget.sanMoves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
    final moves = widget.sanMoves;
    if (moves.isEmpty) {
      return Center(
        child: Text(
          'The board is set. Your opening move.',
          textAlign: TextAlign.center,
          style: Typo.display(20, color: Palette.muted),
        ),
      );
    }
    final rows = (moves.length + 1) ~/ 2;
    if (widget.compact) {
      return SizedBox(
        height: 40,
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          itemCount: moves.length,
          itemBuilder: (context, i) => Row(
            children: [
              if (i.isEven)
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  child: Text(
                    '${(i + widget.plyOffset) ~/ 2 + 1}.',
                    style: Typo.mono(13, color: Palette.muted),
                  ),
                ),
              _chip(i),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: rows,
      itemBuilder: (context, row) {
        final white = row * 2;
        final black = white + 1;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            color: row.isOdd ? Colors.white.withValues(alpha: 0.025) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '${row + 1 + widget.plyOffset ~/ 2}.',
                  style: Typo.mono(13, color: Palette.muted),
                ),
              ),
              Expanded(
                child: _chip(white),
              ),
              Expanded(
                child: black < moves.length
                    ? _chip(black)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({
    required this.san,
    required this.latest,
    this.verdict,
    this.onTap,
  });

  final String san;
  final bool latest;
  final MoveClass? verdict;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = verdict;
    final showBadge =
        v != null && v != MoveClass.good && v != MoveClass.excellent;
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: latest ? Palette.gold.withValues(alpha: 0.18) : null,
        borderRadius: BorderRadius.circular(6),
        border: latest
            ? Border.all(
                color: Palette.gold.withValues(alpha: 0.6),
                width: 0.8,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBadge) ...[
            MoveBadge(v, size: 15),
            const SizedBox(width: 5),
          ],
          Text(
            san,
            style:
                Typo.mono(
                  14,
                  color: latest
                      ? Palette.ivory
                      : (v != null && v.isError ? v.color : Palette.parchment),
                ).copyWith(
                  fontWeight: latest ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: onTap == null
          ? chip
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onTap, child: chip),
            ),
    );
  }
}
