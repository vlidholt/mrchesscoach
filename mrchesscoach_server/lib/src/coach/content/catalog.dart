import 'package:dartchess/dartchess.dart';

import '../../chess/chess_rules.dart';
import '../../generated/protocol.dart';
import 'content_types.dart';
import 'lessons.dart';
import 'openings.dart';

/// The curated content, converted for the API.
PositionLesson? lessonById(String? id) =>
    id == null ? null : positionLessons.where((l) => l.id == id).firstOrNull;

OpeningCourse? courseById(String? id) =>
    id == null ? null : openingCourses.where((c) => c.id == id).firstOrNull;

PlayerColor colorOf(StudentSide side) =>
    side == StudentSide.white ? PlayerColor.white : PlayerColor.black;

/// The UCI moves of a course's main line.
List<String> courseUciMoves(OpeningCourse course) {
  Position position = Chess.initial;
  final moves = <String>[];
  for (final step in course.moves) {
    final move = position.parseSan(step.san)!;
    moves.add(move.uci);
    position = position.play(move);
  }
  return moves;
}

OpeningSummary courseSummary(
  OpeningCourse course, {
  required int trapCount,
  required bool completed,
}) => OpeningSummary(
  id: course.id,
  name: course.name,
  eco: course.eco,
  side: colorOf(course.side),
  level: course.level,
  tagline: course.tagline,
  plies: course.moves.length,
  finalFen: ReplayedGame.fromMoves(courseUciMoves(course)).position.fen,
  trapCount: trapCount,
  completed: completed,
);

OpeningCourseInfo courseInfo(OpeningCourse course, {required bool completed}) {
  Position position = Chess.initial;
  final steps = <OpeningStep>[];
  final studentWhite = course.side == StudentSide.white;
  for (final step in course.moves) {
    final move = position.parseSan(step.san)!;
    final byStudent = (position.turn == Side.white) == studentWhite;
    final (next, san) = position.makeSan(move);
    position = next;
    steps.add(
      OpeningStep(
        san: san,
        uci: move.uci,
        fen: position.fen,
        comment: step.comment,
        arrows: step.arrows,
        byStudent: byStudent,
      ),
    );
  }
  return OpeningCourseInfo(
    id: course.id,
    name: course.name,
    eco: course.eco,
    side: colorOf(course.side),
    level: course.level,
    tagline: course.tagline,
    summary: course.summary,
    ideas: course.ideas,
    steps: steps,
    family: course.lichessFamily,
    completed: completed,
  );
}

LessonInfo lessonInfo(PositionLesson lesson, {required bool completed}) {
  final turn = positionFromFen(lesson.fen).turn;
  return LessonInfo(
    id: lesson.id,
    category: lesson.category,
    title: lesson.title,
    tagline: lesson.tagline,
    concept: lesson.concept,
    tips: lesson.tips,
    fen: lesson.fen,
    side: turn == Side.white ? PlayerColor.white : PlayerColor.black,
    goal: lesson.goal.name,
    targetMoves: lesson.targetMoves,
    difficulty: lesson.difficulty,
    completed: completed,
  );
}
