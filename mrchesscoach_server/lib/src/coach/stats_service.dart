import 'dart:math';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Reads and updates a user's training stats.
abstract final class StatsService {
  /// The user's stats, created on first use.
  static Future<PlayerStats> load(Session session, UuidValue userId) async {
    final stats = await PlayerStats.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (stats != null) return stats;
    try {
      return await PlayerStats.db.insertRow(
        session,
        PlayerStats(userId: userId),
      );
    } catch (_) {
      // Created by a concurrent request.
      return (await PlayerStats.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userId),
      ))!;
    }
  }

  /// Records activity today and updates the day streak.
  static Future<PlayerStats> touch(Session session, UuidValue userId) async {
    final stats = await load(session, userId);
    final updated = _touched(stats);
    if (identical(updated, stats)) return stats;
    return PlayerStats.db.updateRow(session, updated);
  }

  static PlayerStats _touched(PlayerStats stats) {
    final today = _day(DateTime.now().toUtc());
    if (stats.lastActiveDay == today) return stats;
    final yesterday = _day(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    return stats.copyWith(
      lastActiveDay: today,
      dayStreak: stats.lastActiveDay == yesterday ? stats.dayStreak + 1 : 1,
    );
  }

  /// The day streak as of today: zero if the last activity was before
  /// yesterday.
  static int currentDayStreak(PlayerStats stats) {
    final now = DateTime.now().toUtc();
    final today = _day(now);
    final yesterday = _day(now.subtract(const Duration(days: 1)));
    return stats.lastActiveDay == today || stats.lastActiveDay == yesterday
        ? stats.dayStreak
        : 0;
  }

  /// Applies a rated puzzle result and returns the updated stats.
  static Future<PlayerStats> ratePuzzle(
    Session session,
    UuidValue userId, {
    required String puzzleId,
    required int puzzleRating,
    required String themes,
    required bool solved,
  }) async {
    final stats = _touched(await load(session, userId));
    final attempts = stats.puzzlesSolved + stats.puzzlesFailed;
    // Larger steps while the rating is still settling.
    final k = attempts < 20 ? 48 : (attempts < 100 ? 32 : 20);
    final expected =
        1 / (1 + pow(10, (puzzleRating - stats.puzzleRating) / 400));
    final rating = (stats.puzzleRating + k * ((solved ? 1 : 0) - expected))
        .round()
        .clamp(400, 3200);
    final streak = solved ? stats.puzzleStreak + 1 : 0;
    final updated = await PlayerStats.db.updateRow(
      session,
      stats.copyWith(
        puzzleRating: rating,
        puzzleStreak: streak,
        bestPuzzleStreak: max(stats.bestPuzzleStreak, streak),
        puzzlesSolved: stats.puzzlesSolved + (solved ? 1 : 0),
        puzzlesFailed: stats.puzzlesFailed + (solved ? 0 : 1),
      ),
    );
    await PuzzleAttempt.db.insertRow(
      session,
      PuzzleAttempt(
        userId: userId,
        puzzleId: puzzleId,
        solved: solved,
        puzzleRating: puzzleRating,
        ratingAfter: rating,
        themes: themes,
      ),
    );
    return updated;
  }

  /// Marks a lesson or opening as attempted or completed.
  static Future<void> lessonProgress(
    Session session,
    UuidValue userId, {
    required String lessonId,
    required String kind,
    bool completed = false,
  }) async {
    final existing = await LessonProgress.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.lessonId.equals(lessonId),
    );
    if (existing == null) {
      await LessonProgress.db.insertRow(
        session,
        LessonProgress(
          userId: userId,
          lessonId: lessonId,
          kind: kind,
          completed: completed,
          attempts: completed ? 0 : 1,
        ),
      );
      return;
    }
    await LessonProgress.db.updateRow(
      session,
      existing.copyWith(
        completed: existing.completed || completed,
        attempts: existing.attempts + (completed ? 0 : 1),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Ids of the lessons and openings the user completed.
  static Future<Set<String>> completedLessons(
    Session session,
    UuidValue userId,
  ) async {
    final rows = await LessonProgress.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.completed.equals(true),
    );
    return {for (final r in rows) r.lessonId};
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
