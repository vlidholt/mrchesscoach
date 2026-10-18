import 'package:flutter/material.dart';
import 'package:mrchesscoach_client/mrchesscoach_client.dart';

import '../theme.dart';

/// Colors, names and glyphs of the move verdicts. The colors follow the
/// convention players know from game reviews, so a red "??" reads at once.
extension MoveClassStyle on MoveClass {
  Color get color => switch (this) {
    MoveClass.brilliant => const Color(0xFF26C2A3),
    MoveClass.great => const Color(0xFF5C8BB0),
    MoveClass.best => const Color(0xFF8BC34A),
    MoveClass.excellent => const Color(0xFF8BC34A),
    MoveClass.good => const Color(0xFF9BB28E),
    MoveClass.book => const Color(0xFFB08B62),
    MoveClass.inaccuracy => const Color(0xFFF2C14E),
    MoveClass.mistake => const Color(0xFFE8913A),
    MoveClass.miss => const Color(0xFFEE6B55),
    MoveClass.blunder => const Color(0xFFD9443E),
  };

  String get label => switch (this) {
    MoveClass.brilliant => 'Brilliant',
    MoveClass.great => 'Great move',
    MoveClass.best => 'Best move',
    MoveClass.excellent => 'Excellent',
    MoveClass.good => 'Good',
    MoveClass.book => 'Book move',
    MoveClass.inaccuracy => 'Inaccuracy',
    MoveClass.mistake => 'Mistake',
    MoveClass.miss => 'Missed win',
    MoveClass.blunder => 'Blunder',
  };

  /// The text glyph, or null when an icon is used.
  String? get glyph => switch (this) {
    MoveClass.brilliant => '!!',
    MoveClass.great => '!',
    MoveClass.inaccuracy => '?!',
    MoveClass.mistake => '?',
    MoveClass.blunder => '??',
    _ => null,
  };

  IconData get icon => switch (this) {
    MoveClass.best => Icons.star_rounded,
    MoveClass.excellent => Icons.thumb_up_rounded,
    MoveClass.good => Icons.check_rounded,
    MoveClass.book => Icons.menu_book_rounded,
    MoveClass.miss => Icons.close_rounded,
    _ => Icons.circle,
  };

  /// Verdicts that call for the coach's attention.
  bool get isError =>
      this == MoveClass.inaccuracy ||
      this == MoveClass.mistake ||
      this == MoveClass.miss ||
      this == MoveClass.blunder;

  bool get isHighlight =>
      this == MoveClass.brilliant || this == MoveClass.great;
}

/// A round verdict badge, e.g. a red "??" for a blunder.
class MoveBadge extends StatelessWidget {
  const MoveBadge(this.classification, {super.key, this.size = 22});

  final MoveClass classification;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = classification.glyph;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: classification.color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: size * 0.07,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: glyph != null
          ? Text(
              glyph,
              style: Typo.body(
                size * (glyph.length > 1 ? 0.46 : 0.6),
                color: Colors.white,
                weight: FontWeight.w900,
              ).copyWith(height: 1, letterSpacing: -0.5),
            )
          : Icon(classification.icon, size: size * 0.62, color: Colors.white),
    );
  }
}

/// A badge with its label, e.g. "?? Blunder", for the coach panel.
class MoveBadgeLabel extends StatelessWidget {
  const MoveBadgeLabel(this.classification, {super.key, this.size = 15});

  final MoveClass classification;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MoveBadge(classification, size: size * 1.6),
        const SizedBox(width: 8),
        Text(
          classification.label,
          style: Typo.body(
            size,
            color: classification.color,
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
