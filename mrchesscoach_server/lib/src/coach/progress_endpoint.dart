import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import 'coach_writer.dart';
import 'content/lessons.dart';
import 'content/openings.dart';
import 'move_classifier.dart';
import 'puzzles.dart';
import 'stats_service.dart';

/// The puzzle set that trains each mistake motif.
const _motifPractice = {
  'hangingPiece': 'hangingPiece',
  'missedCapture': 'hangingPiece',
  'fork': 'fork',
  'pin': 'pin',
  'skewer': 'skewer',
  'discoveredAttack': 'discoveredAttack',
  'backRank': 'backRankMate',
  'mateThreat': 'mateIn2',
  'kingSafety': 'kingsideAttack',
  'trappedPiece': 'trappedPiece',
  'overloadedPiece': 'deflection',
  'endgameTechnique': 'endgame',
};

/// The player's progress and the coach's suggestions.
class ProgressEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<PlayerProgress> progress(Session session) async {
    final userId = session.authenticated!.authUserId;
    final stats = await StatsService.load(session, userId);

    final games = await ChessGame.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.status.notInSet({GameStatus.active, GameStatus.abandoned}) &
          t.lessonId.equals(null),
      orderBy: (t) => t.updatedAt.desc(),
      limit: 200,
    );
    final wins = games.where((g) => g.status == GameStatus.playerWon).length;
    final draws = games.where((g) => g.status == GameStatus.draw).length;

    final playerMoves = await MoveAnalysis.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.byPlayer.equals(true) &
          t.retracted.equals(false),
      orderBy: (t) => t.createdAt.desc(),
      limit: 3000,
    );
    final recentGames = games.take(15).toList().reversed;
    final recentAccuracy = <double>[];
    for (final g in recentGames) {
      final moves = playerMoves.where((m) => m.gameId == g.id).toList();
      if (moves.length >= 3) {
        recentAccuracy.add(gameAccuracy(moves.map((m) => m.accuracy)));
      }
    }

    final classTotals = {
      for (final c in MoveClass.values)
        c.name: playerMoves.where((m) => m.classification == c).length,
    };

    // Mistakes from games, including the ones taken back.
    final mistakes = await MoveAnalysis.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.byPlayer.equals(true) &
          t.classification.inSet(pausingClasses),
      orderBy: (t) => t.createdAt.desc(),
      limit: 500,
    );
    final motifCounts = <String, int>{};
    for (final m in mistakes) {
      final motif = m.motif;
      if (motif == null || motif == 'other') continue;
      motifCounts[motif] = (motifCounts[motif] ?? 0) + 1;
    }
    final motifStats = [
      for (final e in motifCounts.entries)
        ThemeStat(
          key: e.key,
          name: coachMotifs[e.key] ?? e.key,
          attempts: e.value,
          successes: 0,
        ),
    ]..sort((a, b) => b.attempts.compareTo(a.attempts));
    final mistakesToReview = mistakes
        .where((m) => m.drillSuccesses == 0)
        .length;

    final attempts = await PuzzleAttempt.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt.desc(),
      limit: 2000,
    );
    final themeStats = <ThemeStat>[];
    for (final set in puzzleSetCatalog) {
      if (set.key == 'mixed') continue;
      final matching = attempts.where(
        (a) => a.themes.split(' ').contains(set.key),
      );
      if (matching.isEmpty) continue;
      themeStats.add(
        ThemeStat(
          key: set.key,
          name: set.name,
          attempts: matching.length,
          successes: matching.where((a) => a.solved).length,
        ),
      );
    }
    themeStats.sort((a, b) => b.attempts.compareTo(a.attempts));

    final progressRows = await LessonProgress.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.completed.equals(true),
    );
    final completed = {for (final r in progressRows) r.lessonId};

    final average = recentAccuracy.isEmpty
        ? null
        : recentAccuracy.reduce((a, b) => a + b) / recentAccuracy.length;

    return PlayerProgress(
      gamesPlayed: games.length,
      wins: wins,
      draws: draws,
      losses: games.length - wins - draws,
      recentAccuracy: recentAccuracy,
      averageAccuracy: average,
      puzzleRating: stats.puzzleRating,
      puzzleRatingHistory: [
        for (final a in attempts.take(40).toList().reversed) a.ratingAfter,
      ],
      puzzlesSolved: stats.puzzlesSolved,
      puzzlesFailed: stats.puzzlesFailed,
      puzzleStreak: stats.puzzleStreak,
      bestPuzzleStreak: stats.bestPuzzleStreak,
      dayStreak: StatsService.currentDayStreak(stats),
      themeStats: themeStats,
      motifStats: motifStats,
      classTotals: classTotals,
      lessonsCompleted: progressRows.where((r) => r.kind == 'lesson').length,
      openingsCompleted: progressRows.where((r) => r.kind == 'opening').length,
      mistakesToReview: mistakesToReview,
      recommendations: _recommend(
        mistakesToReview: mistakesToReview,
        motifStats: motifStats,
        themeStats: themeStats,
        completed: completed,
        averageAccuracy: average,
        gamesPlayed: games.length,
        puzzleAttempts: attempts.length,
      ),
    );
  }

  static List<CoachRecommendation> _recommend({
    required int mistakesToReview,
    required List<ThemeStat> motifStats,
    required List<ThemeStat> themeStats,
    required Set<String> completed,
    required double? averageAccuracy,
    required int gamesPlayed,
    required int puzzleAttempts,
  }) {
    final result = <CoachRecommendation>[];
    if (mistakesToReview > 0) {
      result.add(
        CoachRecommendation(
          kind: 'mistakes',
          title: 'Fix your own mistakes',
          body:
              '$mistakesToReview position${mistakesToReview == 1 ? '' : 's'} '
              'from your games where a better move was waiting. Find it this '
              'time.',
        ),
      );
    }
    final motif = motifStats.firstOrNull;
    final practice = motif == null ? null : _motifPractice[motif.key];
    if (motif != null && practice != null && motif.attempts >= 2) {
      final set = puzzleSetCatalog.where((s) => s.key == practice).firstOrNull;
      result.add(
        CoachRecommendation(
          kind: 'puzzles',
          ref: practice,
          title: 'Train: ${set?.name ?? motif.name}',
          body:
              '${motif.name} cost you ${motif.attempts} times in your games. '
              'A few puzzles a day will sharpen your eye.',
        ),
      );
    }
    final weak =
        themeStats
            .where((t) => t.attempts >= 4 && t.successes / t.attempts < 0.6)
            .toList()
          ..sort(
            (a, b) =>
                (a.successes / a.attempts).compareTo(b.successes / b.attempts),
          );
    if (weak.isNotEmpty && weak.first.key != practice) {
      final w = weak.first;
      result.add(
        CoachRecommendation(
          kind: 'puzzles',
          ref: w.key,
          title: 'Strengthen: ${w.name}',
          body:
              'You solve ${(100 * w.successes / w.attempts).round()}% of '
              '${w.name.toLowerCase()} puzzles. This is your biggest room for '
              'growth.',
        ),
      );
    }
    final opening = openingCourses
        .where((c) => !completed.contains(c.id))
        .firstOrNull;
    if (opening != null && result.length < 4) {
      result.add(
        CoachRecommendation(
          kind: 'opening',
          ref: opening.id,
          title: 'Learn the ${opening.name}',
          body: opening.tagline,
        ),
      );
    }
    final lesson = positionLessons
        .where((l) => !completed.contains(l.id))
        .firstOrNull;
    if (lesson != null && result.length < 4) {
      result.add(
        CoachRecommendation(
          kind: 'lesson',
          ref: lesson.id,
          title: lesson.title,
          body: lesson.tagline,
        ),
      );
    }
    if (puzzleAttempts < 10 && result.length < 4) {
      result.add(
        CoachRecommendation(
          kind: 'puzzles',
          ref: 'mixed',
          title: 'Find your puzzle rating',
          body: 'Solve ten rated puzzles and I can tailor training to you.',
        ),
      );
    }
    if (gamesPlayed >= 3 &&
        averageAccuracy != null &&
        averageAccuracy > 85 &&
        result.length < 4) {
      result.add(
        CoachRecommendation(
          kind: 'play',
          title: 'Time to level up',
          body:
              'Your accuracy is ${averageAccuracy.round()}%. Try the next '
              'level up.',
        ),
      );
    }
    return result.take(4).toList();
  }
}
