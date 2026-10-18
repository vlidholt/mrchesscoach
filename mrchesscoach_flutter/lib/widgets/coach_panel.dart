import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../game/chess_model.dart';
import '../game/game_controller.dart';
import '../theme.dart';
import 'chess_board.dart';
import 'move_badge.dart';

/// The coach's avatar: a white queen in a gold-rimmed medallion.
class CoachAvatar extends StatelessWidget {
  const CoachAvatar({super.key, this.size = 46, this.speaking = false});

  final double size;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF3A3020), Palette.ebony],
        ),
        border: Border.all(color: Palette.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Palette.gold.withValues(alpha: speaking ? 0.45 : 0.15),
            blurRadius: speaking ? 22 : 10,
          ),
        ],
      ),
      child: Image.asset(
        pieceAsset(Side.white, Role.queen),
        filterQuality: FilterQuality.medium,
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
    final ms = min(1600, 220 + text.length * 14);
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
  const CoachThinking({super.key, this.label = 'Coach is thinking'});

  final String label;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: Typo.body(13, color: Palette.muted)),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.gold.withValues(
                      alpha:
                          0.3 +
                          0.7 *
                              (0.5 + 0.5 * sin((_c.value - i * 0.2) * 2 * pi)),
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

/// The coach's corner of the game screen: a speech bubble that reacts to
/// the game, and the coach's tools.
class CoachPanel extends StatelessWidget {
  const CoachPanel({
    super.key,
    required this.controller,
    required this.onAsk,
    this.lessonTips = const [],
    this.compact = false,
  });

  final GameController controller;
  final VoidCallback onAsk;

  /// Tips from a lesson, shown before the first move.
  final List<String> lessonTips;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final bubble = _bubbleContent(c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoachAvatar(
              size: compact ? 38 : 46,
              speaking: c.awaitingDecision || c.hint != null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: CoachBubble(
                    key: ValueKey(bubble.key),
                    accent: bubble.accent,
                    child: bubble.child,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: _hintLabel(c),
                icon: Icons.lightbulb_outline_rounded,
                tooltip: 'Hint: first the idea, then the piece, then the move',
                busy: c.pending == PendingAction.hint,
                onPressed: c.canMove && (c.hint?.level ?? 0) < 3
                    ? c.nextHint
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GhostButton(
                label: 'Threats',
                icon: Icons.warning_amber_rounded,
                tooltip: 'What is my opponent threatening?',
                busy: c.pending == PendingAction.threat,
                onPressed: c.canMove ? c.findThreat : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GhostButton(
                label: 'Ask coach',
                icon: Icons.forum_outlined,
                tooltip: 'Ask the coach about this position',
                onPressed: onAsk,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _hintLabel(GameController c) => switch (c.hint?.level) {
    1 => 'More help',
    2 => 'Show move',
    3 => 'Hint',
    _ => 'Hint',
  };

  ({String key, Color accent, Widget child}) _bubbleContent(GameController c) {
    final text = Typo.body(14, color: Palette.ivory).copyWith(height: 1.45);

    if (c.pending == PendingAction.hint || c.pending == PendingAction.threat) {
      return (
        key: 'thinking',
        accent: Palette.goldDeep,
        child: const CoachThinking(),
      );
    }

    if (c.awaitingDecision && c.playerFeedback != null) {
      return (
        key: 'pause-${c.playerFeedback!.id}',
        accent: c.playerFeedback!.classification.color,
        child: _PauseCard(controller: c),
      );
    }

    if (c.threat case final t?) {
      return (
        key: 'threat-${t.san}-${t.text.hashCode}',
        accent: t.hasThreat ? BoardArrow.threat : Palette.win,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Chip(
              label: t.hasThreat ? 'THREAT: ${t.san ?? 'CHECK'}' : 'NO THREAT',
              color: t.hasThreat ? BoardArrow.threat : Palette.win,
            ),
            const SizedBox(height: 8),
            TypewriterText(t.text, style: text),
          ],
        ),
      );
    }

    if (c.hint case final h?) {
      return (
        key: 'hint-${h.level}',
        accent: BoardArrow.idea,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(label: 'HINT ${h.level} OF 3', color: BoardArrow.idea),
                const SizedBox(width: 8),
                for (var i = 1; i <= 3; i++)
                  Container(
                    margin: const EdgeInsets.only(right: 3),
                    width: 14,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= h.level
                          ? BoardArrow.idea
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TypewriterText(h.text, style: text),
          ],
        ),
      );
    }

    if (c.bestMoveArrow != null) {
      return (
        key: 'best-${c.bestMoveArrow}',
        accent: BoardArrow.best,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Chip(label: 'YOUR TURN AGAIN', color: BoardArrow.best),
            const SizedBox(height: 8),
            Text(
              'The green arrow shows the engine\'s move. Play it, or find '
              'another good move.',
              style: text,
            ),
          ],
        ),
      );
    }

    final feedback = c.playerFeedback;
    final opponent = c.opponentFeedback;
    if (!c.coachOn) {
      return (
        key: 'off',
        accent: Palette.goldDeep,
        child: Text(
          'Coach is off for this game. Play your best. You will get a full '
          'review at the end.',
          style: text,
        ),
      );
    }
    if (feedback == null) {
      return (
        key: 'intro',
        accent: Palette.goldDeep,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypewriterText(
              lessonTips.isNotEmpty
                  ? lessonTips.first
                  : 'Let\'s play! I\'ll grade every move, stop you before '
                        'a blunder costs the game, and explain the key '
                        'moments.',
              style: text,
            ),
            for (final tip in lessonTips.skip(1))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $tip', style: Typo.body(13)),
              ),
          ],
        ),
      );
    }

    final opportunity =
        opponent != null &&
        !c.isOver &&
        opponent.ply > feedback.ply &&
        (opponent.classification == MoveClass.blunder ||
            opponent.classification == MoveClass.mistake);
    return (
      key: 'move-${feedback.id}-${feedback.explanation != null}-$opportunity',
      accent: feedback.classification.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Verdict(controller: c, analysis: feedback),
          if (opportunity) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: MoveClass.brilliant.color.withValues(alpha: 0.12),
                border: Border.all(
                  color: MoveClass.brilliant.color.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: MoveClass.brilliant.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Opportunity! Stockfish just slipped with '
                      '${opponent.san}. Can you find the punishment?',
                      style: Typo.body(13, color: Palette.ivory),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A verdict on one move, with the coach's explanation when there is one.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.controller, required this.analysis});

  final GameController controller;
  final MoveAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final loading = controller.explaining.contains(a.ply);
    final text = Typo.body(14, color: Palette.ivory).copyWith(height: 1.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MoveBadgeLabel(a.classification),
            const SizedBox(width: 8),
            Text(a.san, style: Typo.mono(14, color: Palette.parchment)),
          ],
        ),
        const SizedBox(height: 8),
        if (a.headline != null)
          Text(a.headline!, style: Typo.title(19))
        else if (!loading)
          Text(_quickLine(a), style: text),
        if (a.explanation != null) ...[
          const SizedBox(height: 6),
          TypewriterText(a.explanation!, style: text),
        ],
        if (a.lesson != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.school_outlined, size: 16, color: Palette.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.lesson!,
                  style: Typo.body(
                    13,
                    color: Palette.gold,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
        if (loading) ...[
          const SizedBox(height: 8),
          const CoachThinking(),
        ] else if (a.explanation == null)
          TextButton.icon(
            onPressed: () => controller.explain(a.ply),
            style: TextButton.styleFrom(
              foregroundColor: Palette.gold,
              padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: Text(
              'Why?',
              style: Typo.body(
                13,
                color: Palette.gold,
                weight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  static String _quickLine(MoveAnalysis a) => switch (a.classification) {
    MoveClass.best => '${a.san} is exactly what the engine would play.',
    MoveClass.excellent =>
      'Almost perfect. ${a.san} keeps everything under control.',
    MoveClass.good =>
      'A solid move.${a.bestSan != null && a.bestSan != a.san ? ' ${a.bestSan} was a touch stronger.' : ''}',
    MoveClass.book => '${a.san} is a well-known opening move.',
    _ => '${a.san}: ${a.classification.label.toLowerCase()}.',
  };
}

/// The pause after a mistake: what went wrong and what to do now.
class _PauseCard extends StatelessWidget {
  const _PauseCard({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final a = c.playerFeedback!;
    final busy = c.pending != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Verdict(controller: c, analysis: a),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GoldButton(
              label: 'Try again',
              icon: Icons.replay_rounded,
              compact: true,
              busy: c.pending == PendingAction.retry,
              onPressed: busy ? null : () => c.retry(),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => c.retry(showBest: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: BoardArrow.best,
                side: BorderSide(color: BoardArrow.best.withValues(alpha: 0.7)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(
                'Show best move',
                style: Typo.body(
                  13,
                  color: BoardArrow.best,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: busy ? null : c.playOn,
              style: TextButton.styleFrom(foregroundColor: Palette.muted),
              child: c.pending == PendingAction.playOn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.muted,
                      ),
                    )
                  : Text(
                      'Play on',
                      style: Typo.body(
                        13,
                        color: Palette.muted,
                        weight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class CoachBubble extends StatelessWidget {
  const CoachBubble({super.key, required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Palette.lacquer, accent, 0.10)!,
            Palette.ebony,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
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
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(label, style: Typo.label(color: color, size: 10)),
    );
  }
}

/// The coach's avatar with a speech bubble, for screens other than games.
class CoachSays extends StatelessWidget {
  const CoachSays({
    super.key,
    required this.child,
    this.accent = Palette.goldDeep,
    this.speaking = false,
  });

  final Widget child;
  final Color accent;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachAvatar(speaking: speaking),
        const SizedBox(width: 12),
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
