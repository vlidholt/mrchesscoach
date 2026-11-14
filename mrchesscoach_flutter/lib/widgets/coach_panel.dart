import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../game/game_controller.dart';
import '../theme.dart';
import 'chess_board.dart';
import 'coach_avatar.dart';
import 'fx.dart';
import 'move_badge.dart';

export 'coach_avatar.dart';

/// The coach's expression for the state of a game.
CoachMood gameMood(GameController c) {
  if (c.isOver) {
    return switch (c.game.status) {
      GameStatus.playerWon => CoachMood.happy,
      GameStatus.computerWon => CoachMood.happy,
      _ => CoachMood.neutral,
    };
  }
  final feedback = c.playerFeedback;
  if (c.pending == PendingAction.hint || c.pending == PendingAction.threat) {
    return CoachMood.thoughtful;
  }
  if (c.awaitingDecision && feedback != null) {
    return switch (feedback.classification) {
      MoveClass.blunder || MoveClass.miss => CoachMood.surprised,
      _ => CoachMood.thoughtful,
    };
  }
  if (c.threat case final t?) {
    return t.hasThreat ? CoachMood.surprised : CoachMood.happy;
  }
  if (c.hint != null) return CoachMood.thoughtful;
  if (c.bestMoveArrow != null) return CoachMood.happy;
  if (c.thinking) return CoachMood.thoughtful;
  if (feedback == null) return CoachMood.happy;
  return switch (feedback.classification) {
    MoveClass.brilliant => CoachMood.surprised,
    MoveClass.great || MoveClass.best || MoveClass.excellent => CoachMood.happy,
    MoveClass.good || MoveClass.book => CoachMood.neutral,
    _ => CoachMood.thoughtful,
  };
}

/// The colour the coach's halo and bubbles glow in.
Color gameAccent(GameController c) {
  if (c.awaitingDecision && c.playerFeedback != null) {
    return c.playerFeedback!.classification.color;
  }
  if (c.threat case final t?) {
    return t.hasThreat ? BoardArrow.threat : Palette.win;
  }
  if (c.hint != null) return BoardArrow.idea;
  if (c.bestMoveArrow != null) return BoardArrow.best;
  return c.playerFeedback?.classification.color ?? Palette.gold;
}

/// The coach's avatar and speech bubbles during a game.
class GameCoachChat extends StatelessWidget {
  const GameCoachChat({
    super.key,
    required this.controller,
    this.lessonTips = const [],
    this.avatarSize = 56,
  });

  final GameController controller;
  final List<String> lessonTips;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return CoachChat(
      lines: _lines(c),
      mood: gameMood(c),
      accent: gameAccent(c),
      avatarSize: avatarSize,
      lively: true,
      speaking:
          c.awaitingDecision ||
          c.hint != null ||
          c.threat != null ||
          c.isExplainingAny,
    );
  }

  List<CoachLine> _lines(GameController c) {
    final feedback = c.playerFeedback;

    if (c.awaitingDecision && feedback != null) {
      return [
        CoachLine(
          id: 'pause-${feedback.id}-${feedback.explanation != null}',
          accent: feedback.classification.color,
          child: _Verdict(controller: c, analysis: feedback, paused: true),
        ),
      ];
    }

    final lines = <CoachLine>[];
    if (!c.coachOn && !c.isOver) {
      lines.add(
        const CoachLine(
          id: 'off',
          child: Text(
            'No help this time: just you and me. We\'ll go through the game '
            'together afterwards.',
          ),
        ),
      );
    } else if (feedback == null &&
        !c.isOver &&
        lessonTips.isEmpty &&
        c.verdicts.values.any((v) => v.byPlayer)) {
      // After a retry or a takeback: not the greeting again.
      if (c.bestMoveArrow == null) {
        lines.add(
          CoachLine(
            id: 'again-${c.sanMoves.length}',
            child: TypewriterText(
              'Your move again. Take a fresh look at the position.',
              style: BubbleText.body,
            ),
          ),
        );
      }
    } else if (feedback == null && !c.isOver) {
      lines.add(
        CoachLine(
          id: 'intro',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypewriterText(
                lessonTips.isNotEmpty
                    ? lessonTips.first
                    : 'Let\'s play! I\'ll grade your moves and stop you '
                          'before a blunder.',
                style: BubbleText.body,
              ),
              for (final tip in lessonTips.skip(1))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('• $tip', style: BubbleText.small),
                ),
            ],
          ),
        ),
      );
    } else if (feedback != null && c.coachOn) {
      lines.add(
        CoachLine(
          id: 'move-${feedback.id}-${feedback.explanation != null}',
          accent: feedback.classification.color,
          child: _Verdict(controller: c, analysis: feedback),
        ),
      );
    }

    if (c.pending == PendingAction.hint || c.pending == PendingAction.threat) {
      lines.add(
        CoachLine(
          id: 'thinking-${c.pending}',
          child: CoachThinking(
            label: c.pending == PendingAction.hint
                ? 'Let me find you a hint'
                : 'Let me see what I\'m up to',
          ),
        ),
      );
    } else if (c.threat case final t?) {
      final color = t.hasThreat ? BoardArrow.threat : Palette.win;
      lines.add(
        CoachLine(
          id: 'threat-${t.san}-${t.text.hashCode}',
          accent: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Chip(
                label: t.hasThreat
                    ? 'MY THREAT: ${t.san ?? 'CHECK'}'
                    : 'NO THREAT',
                color: color,
              ),
              const SizedBox(height: 6),
              TypewriterText(t.text, style: BubbleText.body),
            ],
          ),
        ),
      );
    } else if (c.hint case final h?) {
      lines.add(
        CoachLine(
          id: 'hint-${h.level}',
          accent: BoardArrow.idea,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(label: 'HINT ${h.level} OF 3', color: BoardArrow.idea),
                  const SizedBox(width: 8),
                  for (var i = 1; i <= 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 3),
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= h.level
                            ? BoardArrow.idea
                            : Palette.ink.withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TypewriterText(h.text, style: BubbleText.body),
            ],
          ),
        ),
      );
    } else if (c.bestMoveArrow != null) {
      lines.add(
        CoachLine(
          id: 'best-${c.bestMoveArrow}',
          accent: BoardArrow.best,
          child: Text(
            'The green arrow is what I would play. Go for it, or find another '
            'good move.',
            style: BubbleText.body,
          ),
        ),
      );
    }

    if (c.isOver) {
      final (text, accent) = switch (c.game.status) {
        GameStatus.playerWon => (
          'Well played! You got me this time.',
          Palette.win,
        ),
        GameStatus.computerWon => (
          'Good game! Shall we look at it together?',
          Palette.gold,
        ),
        GameStatus.draw => ('A draw. Well fought!', Palette.draw),
        _ => ('Let\'s play again soon.', Palette.gold),
      };
      lines.add(
        CoachLine(
          id: 'over-${c.game.status}',
          accent: accent,
          child: TypewriterText(text, style: BubbleText.body),
        ),
      );
    }
    return lines;
  }
}

/// A verdict on the player's move, with the coach's explanation.
class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.controller,
    required this.analysis,
    this.paused = false,
  });

  final GameController controller;
  final MoveAnalysis analysis;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final loading = controller.isExplaining(a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MoveBadge(a.classification, size: 22),
            const SizedBox(width: 7),
            Text(
              a.classification.label,
              style: Typo.body(
                13.5,
                color: Color.lerp(a.classification.color, Palette.ink, 0.3)!,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(a.san, style: BubbleText.move),
          ],
        ),
        const SizedBox(height: 5),
        if (a.headline != null)
          Text(a.headline!, style: BubbleText.headline)
        else if (!loading)
          Text(_quickLine(a), style: BubbleText.body),
        if (a.explanation != null) ...[
          const SizedBox(height: 4),
          TypewriterText(a.explanation!, style: BubbleText.body),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: CoachThinking(label: 'Let me explain'),
          )
        else if (a.explanation == null)
          _WhyLink(onTap: () => controller.explain(a.ply)),
        if (paused) ...[
          const SizedBox(height: 6),
          Text(
            'Want to take it back and try again?',
            style: BubbleText.small.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }

  static String _quickLine(MoveAnalysis a) => switch (a.classification) {
    MoveClass.brilliant => 'Wow. I did not see that coming!',
    MoveClass.great => 'The only good move, and you found it.',
    MoveClass.best => 'Exactly what I would have played.',
    MoveClass.excellent => 'Excellent. Everything under control.',
    MoveClass.good =>
      'A solid move.${a.bestSan != null && a.bestSan != a.san ? ' ${a.bestSan} was a touch stronger.' : ''}',
    MoveClass.book => 'Straight out of the opening books.',
    MoveClass.inaccuracy => 'A little imprecise.',
    MoveClass.mistake => 'Careful, that one lets me back in.',
    MoveClass.miss => 'You had a chance there!',
    MoveClass.blunder => 'Ouch. That gives a lot away.',
  };
}

class _WhyLink extends StatelessWidget {
  const _WhyLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Pressable(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              FluentIcons.question_circle_24_regular,
              size: 15,
              color: Palette.goldDeep,
            ),
            const SizedBox(width: 4),
            Text(
              'Why?',
              style: Typo.body(
                13,
                color: Palette.goldDeep,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// After a mistake: try again, see the best move, or play on. Replaces the
/// action bar while the game is paused.
class PauseBar extends StatelessWidget {
  const PauseBar({super.key, required this.controller, this.height = 62});

  final GameController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final busy = c.pending != null;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: GoldButton(
              label: 'Try again',
              icon: FluentIcons.arrow_counterclockwise_24_regular,
              compact: true,
              busy: c.pending == PendingAction.retry,
              onPressed: busy ? null : () => c.retry(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: _OutlinePill(
              label: 'Show best',
              icon: FluentIcons.eye_24_regular,
              color: BoardArrow.best,
              onTap: busy ? null : () => c.retry(showBest: true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: _OutlinePill(
              label: 'Play on',
              color: Palette.muted,
              busy: c.pending == PendingAction.playOn,
              onTap: busy ? null : c.playOn,
              outline: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.busy = false,
    this.outline = true,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;
  final bool busy;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null && !busy ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: outline
                ? Border.all(color: color.withValues(alpha: 0.8), width: 1.3)
                : null,
            color: outline ? color.withValues(alpha: 0.08) : null,
          ),
          child: busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.body(
                          13.5,
                          color: color,
                          weight: FontWeight.w800,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Text(
        label,
        style: Typo.label(
          color: Color.lerp(color, Palette.ink, 0.35)!,
          size: 10,
        ),
      ),
    );
  }
}
