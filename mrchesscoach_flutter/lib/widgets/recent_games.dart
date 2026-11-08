import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../theme.dart';

/// The latest finished games with the win/draw/loss tally; tap one to
/// review it.
class RecentGamesPanel extends StatelessWidget {
  const RecentGamesPanel({
    super.key,
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
                Text('vs ${level?.name ?? 'Coach'}', style: Typo.title(19)),
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
