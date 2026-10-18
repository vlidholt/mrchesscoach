/// Plain Dart types for the curated learning content. The content files are
/// hand-written; the server validates every move and position at startup
/// (see `test/unit/content_test.dart`).
library;

/// Which side the student plays in a lesson.
enum StudentSide { white, black }

/// One move of an opening line, written in standard algebraic notation.
class OpeningMove {
  const OpeningMove(this.san, this.comment, {this.arrows = const []});

  /// The move in SAN, e.g. `Nf3`, `O-O`, `exd5`.
  final String san;

  /// One or two sentences on why the move is played. Explains the idea,
  /// not just the name of the move.
  final String comment;

  /// Optional arrows drawn while this move is shown, as square pairs in UCI
  /// form (e.g. `f3e5`), pointing at the plan or threat the comment talks
  /// about.
  final List<String> arrows;
}

/// A named opening taught as a main line with commentary.
class OpeningCourse {
  const OpeningCourse({
    required this.id,
    required this.name,
    required this.eco,
    required this.side,
    required this.level,
    required this.tagline,
    required this.summary,
    required this.ideas,
    required this.moves,
    required this.lichessFamily,
  });

  /// Stable id, e.g. `italian-game`.
  final String id;
  final String name;

  /// ECO code of the main line, e.g. `C50`.
  final String eco;

  /// The side the course teaches (whose moves the student drills).
  final StudentSide side;

  /// `Beginner`, `Intermediate` or `Advanced`.
  final String level;

  /// A short hook for the catalog card (max ~60 characters).
  final String tagline;

  /// One paragraph on what the opening is about and who it suits.
  final String summary;

  /// Three to five reasons the opening is good, each a short sentence:
  /// structure, piece activity, typical plans, practical value.
  final List<String> ideas;

  /// The main line from the starting position, both sides' moves.
  final List<OpeningMove> moves;

  /// The first Lichess opening tag of this family (for trap puzzles), e.g.
  /// `Italian_Game`.
  final String lichessFamily;
}

/// What the student has to achieve in a position lesson.
enum LessonGoal {
  /// Win the game (checkmate the engine).
  win,

  /// Avoid losing for [PositionLesson.targetMoves] moves.
  draw,

  /// Still be clearly better (about +0.7 or more) after
  /// [PositionLesson.targetMoves] moves: convert or press an advantage.
  keepAdvantage,
}

/// A position to play out against the engine, teaching one technique.
class PositionLesson {
  const PositionLesson({
    required this.id,
    required this.category,
    required this.title,
    required this.tagline,
    required this.concept,
    required this.tips,
    required this.fen,
    required this.goal,
    this.targetMoves = 0,
    required this.difficulty,
  });

  /// Stable id, e.g. `lucena-position`.
  final String id;

  /// `endgame` or `middlegame`.
  final String category;
  final String title;

  /// A short hook for the catalog card (max ~60 characters).
  final String tagline;

  /// One or two paragraphs explaining the technique.
  final String concept;

  /// Two to four concrete, actionable tips shown during play.
  final List<String> tips;

  /// The starting position. The side to move is the student.
  final String fen;
  final LessonGoal goal;

  /// For [LessonGoal.draw] and [LessonGoal.keepAdvantage]: how many of the
  /// student's moves the goal must hold for.
  final int targetMoves;

  /// 1 (easy) to 3 (hard).
  final int difficulty;
}
