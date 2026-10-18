import 'package:dartchess/dartchess.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../chess/chess_engine.dart';
import '../chess/chess_rules.dart';
import '../chess/game_endpoint.dart';
import '../chess/levels.dart';
import '../generated/protocol.dart';
import 'coach_writer.dart';
import 'content/catalog.dart';
import 'content/lessons.dart';
import 'content/openings.dart';
import 'move_classifier.dart';
import 'position_facts.dart';
import 'puzzles.dart';
import 'stats_service.dart';

/// The puzzle a user is solving right now.
class _ActivePuzzle {
  _ActivePuzzle(this.puzzle, this.position);

  final Puzzle puzzle;

  /// The position the solver has to move in.
  Position position;

  /// Index in [Puzzle.moves] of the solver's next move.
  int step = 1;

  /// The first wrong move was made (the attempt is rated as a failure).
  bool failed = false;
  bool rated = false;

  /// The last wrong move and the position it was played in.
  ({Position position, String uci})? lastWrong;
}

/// Openings, lessons, puzzles and the mistake trainer.
class LearnEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static final _active = <UuidValue, _ActivePuzzle>{};

  // ---------------------------------------------------------------------------
  // Openings

  /// The opening courses.
  Future<List<OpeningSummary>> openings(Session session) async {
    final done = await StatsService.completedLessons(session, _user(session));
    final catalog = PuzzleCatalog.instance;
    return [
      for (final c in openingCourses)
        courseSummary(
          c,
          trapCount: catalog.countFor('opening:${c.lichessFamily}'),
          completed: done.contains(c.id),
        ),
    ];
  }

  /// One opening course with its moves and commentary.
  Future<OpeningCourseInfo> opening(Session session, String id) async {
    final course = courseById(id);
    if (course == null) {
      throw ChessGameException(message: 'Unknown opening: $id');
    }
    final done = await StatsService.completedLessons(session, _user(session));
    return courseInfo(course, completed: done.contains(id));
  }

  /// Marks an opening's drill as completed.
  Future<void> completeOpening(Session session, String id) async {
    if (courseById(id) == null) return;
    await StatsService.lessonProgress(
      session,
      _user(session),
      lessonId: id,
      kind: 'opening',
      completed: true,
    );
    await StatsService.touch(session, _user(session));
  }

  /// The legal moves in [fen], UCI to SAN (the app has no move generator).
  Future<Map<String, String>> legalMoves(Session session, String fen) async {
    try {
      return legalMovesOf(positionFromFen(fen));
    } catch (_) {
      throw ChessGameException(message: 'That position is not valid.');
    }
  }

  /// Starts a coached game from the end of an opening's main line.
  Future<ChessGame> startOpeningGame(
    Session session,
    String id,
    int level,
  ) async {
    final course = courseById(id);
    if (course == null) {
      throw ChessGameException(message: 'Unknown opening: $id');
    }
    return GameEndpoint.createGame(
      session,
      level: level.clamp(0, levelSpecs.length - 1),
      color: colorOf(course.side),
      moves: courseUciMoves(course),
      lessonId: id,
    );
  }

  // ---------------------------------------------------------------------------
  // Position lessons

  /// The endgame and middlegame lessons.
  Future<List<LessonInfo>> lessons(Session session) async {
    final done = await StatsService.completedLessons(session, _user(session));
    return [
      for (final l in positionLessons)
        lessonInfo(l, completed: done.contains(l.id)),
    ];
  }

  /// Starts a lesson: a game from the lesson's position against
  /// full-strength Stockfish.
  Future<ChessGame> startLesson(Session session, String id) async {
    final lesson = lessonById(id);
    if (lesson == null) {
      throw ChessGameException(message: 'Unknown lesson: $id');
    }
    final turn = positionFromFen(lesson.fen).turn;
    await StatsService.lessonProgress(
      session,
      _user(session),
      lessonId: id,
      kind: 'lesson',
    );
    return GameEndpoint.createGame(
      session,
      level: levelSpecs.length - 1,
      color: turn == Side.white ? PlayerColor.white : PlayerColor.black,
      startFen: lesson.fen,
      lessonId: id,
    );
  }

  // ---------------------------------------------------------------------------
  // Puzzles

  /// The puzzle sets, with the player's results on each.
  Future<List<PuzzleTheme>> puzzleSets(Session session) async {
    final attempts = await PuzzleAttempt.db.find(
      session,
      where: (t) => t.userId.equals(_user(session)),
      orderBy: (t) => t.createdAt.desc(),
      limit: 2000,
    );
    final catalog = PuzzleCatalog.instance;
    PuzzleTheme theme(String key, String name, String desc, String category) {
      final matching = key == 'mixed'
          ? attempts
          : key.startsWith('opening:')
          ? attempts.where((a) {
              final p = catalog.byId(a.puzzleId);
              return p != null && p.openingTags.firstOrNull == key.substring(8);
            }).toList()
          : attempts.where((a) => a.themes.split(' ').contains(key)).toList();
      return PuzzleTheme(
        key: key,
        name: name,
        description: desc,
        category: category,
        count: catalog.countFor(key),
        attempts: matching.length,
        successes: matching.where((a) => a.solved).length,
      );
    }

    return [
      for (final s in puzzleSetCatalog)
        theme(s.key, s.name, s.description, s.category),
      for (final c in openingCourses)
        theme(
          'opening:${c.lichessFamily}',
          '${c.name} traps',
          'Tactics that arise from the ${c.name}.',
          'openings',
        ),
    ];
  }

  /// The next puzzle from [setKey], matched to the player's rating.
  Future<PuzzleInfo> nextPuzzle(Session session, String setKey) async {
    final userId = _user(session);
    final stats = await StatsService.load(session, userId);
    final recentAttempts = await PuzzleAttempt.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt.desc(),
      limit: 500,
    );
    final recent = {for (final a in recentAttempts) a.puzzleId};
    final active = _active[userId];
    if (active != null) recent.add(active.puzzle.id);
    final puzzle = PuzzleCatalog.instance.pick(
      setKey,
      stats.puzzleRating,
      recent,
    );
    if (puzzle == null) {
      throw ChessGameException(message: 'No puzzles in this set.');
    }
    final start = positionFromFen(puzzle.fen);
    final afterSetup = start.play(Move.parse(puzzle.moves.first)!);
    _active[userId] = _ActivePuzzle(puzzle, afterSetup);
    final set = puzzleSetCatalog.where((s) => s.key == setKey).firstOrNull;
    final course = setKey.startsWith('opening:')
        ? openingCourses
              .where((c) => c.lichessFamily == setKey.substring(8))
              .firstOrNull
        : null;
    return PuzzleInfo(
      id: puzzle.id,
      fen: puzzle.fen,
      setupMove: puzzle.moves.first,
      rating: puzzle.rating,
      themes: puzzle.themes,
      solutionMoves: puzzle.solverMoves,
      legalMoves: legalMovesOf(afterSetup),
      playerRating: stats.puzzleRating,
      setName: set?.name ?? (course == null ? null : '${course.name} traps'),
    );
  }

  /// Checks the solver's move in the current puzzle.
  Future<PuzzleMoveResult> puzzleMove(
    Session session,
    String puzzleId,
    String uci,
  ) async {
    final userId = _user(session);
    final active = _active[userId];
    if (active == null || active.puzzle.id != puzzleId) {
      throw ChessGameException(message: 'This puzzle has expired.');
    }
    final puzzle = active.puzzle;
    final move = Move.parse(uci);
    if (move == null || !active.position.isLegal(move)) {
      throw ChessGameException(message: 'Illegal move.');
    }
    final after = active.position.play(move);
    final expected = puzzle.moves[active.step];
    final correct = move.uci == expected || after.isCheckmate;
    var stats = await StatsService.load(session, userId);
    final ratingBefore = stats.puzzleRating;

    if (!correct) {
      active.lastWrong = (position: active.position, uci: move.uci);
      if (!active.failed) {
        active.failed = true;
        active.rated = true;
        stats = await StatsService.ratePuzzle(
          session,
          userId,
          puzzleId: puzzle.id,
          puzzleRating: puzzle.rating,
          themes: puzzle.themes.join(' '),
          solved: false,
        );
      }
      return PuzzleMoveResult(
        correct: false,
        solved: false,
        solution: puzzle.moves.sublist(active.step),
        legalMoves: legalMovesOf(active.position),
        ratingBefore: ratingBefore,
        ratingAfter: stats.puzzleRating,
        streak: stats.puzzleStreak,
      );
    }

    final replyIndex = active.step + 1;
    if (replyIndex >= puzzle.moves.length || after.isCheckmate) {
      if (!active.rated) {
        active.rated = true;
        stats = await StatsService.ratePuzzle(
          session,
          userId,
          puzzleId: puzzle.id,
          puzzleRating: puzzle.rating,
          themes: puzzle.themes.join(' '),
          solved: true,
        );
      }
      active.position = after;
      return PuzzleMoveResult(
        correct: true,
        solved: true,
        ratingBefore: ratingBefore,
        ratingAfter: stats.puzzleRating,
        streak: stats.puzzleStreak,
      );
    }
    final reply = puzzle.moves[replyIndex];
    active.position = after.play(Move.parse(reply)!);
    active.step += 2;
    return PuzzleMoveResult(
      correct: true,
      solved: false,
      replyUci: reply,
      legalMoves: legalMovesOf(active.position),
      ratingBefore: ratingBefore,
      ratingAfter: stats.puzzleRating,
      streak: stats.puzzleStreak,
    );
  }

  /// The coach explains why the last wrong move in the puzzle fails.
  Future<String> explainPuzzle(Session session, String puzzleId) async {
    final userId = _user(session);
    final active = _active[userId];
    final wrong = active?.lastWrong;
    if (active == null || active.puzzle.id != puzzleId || wrong == null) {
      throw ChessGameException(message: 'Nothing to explain yet.');
    }
    final position = wrong.position;
    final after = position.play(Move.parse(wrong.uci)!);
    final refutation = after.isGameOver
        ? const PositionAnalysis([])
        : await ChessEngine.instance.analyse([], startFen: after.fen);
    final stepIndex = active.step;
    final solution = active.puzzle.moves.sublist(stepIndex);
    final solutionSan = uciLineToSan(position, solution);
    final writer = CoachWriter(
      session,
      rating: (await StatsService.load(session, userId)).puzzleRating,
    );
    return writer.puzzleMiss(
      position: position,
      wrongSan: uciLineToSan(position, [wrong.uci]).first,
      refutation: refutation.best == null
          ? []
          : uciLineToSan(after, refutation.best!.pv.take(5)),
      solutionSan: solutionSan.firstOrNull ?? '',
      solutionLine: solutionSan,
      themes: [
        for (final t in active.puzzle.themes)
          puzzleSetCatalog.where((s) => s.key == t).firstOrNull?.name ?? t,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mistake trainer

  /// The next position from the player's games where they went wrong.
  Future<MistakeDrill?> nextMistake(Session session) async {
    final userId = _user(session);
    Expression where(MoveAnalysisTable t) =>
        t.userId.equals(userId) &
        t.byPlayer.equals(true) &
        t.classification.inSet(pausingClasses) &
        t.drillSuccesses.equals(0);
    final remaining = await MoveAnalysis.db.count(session, where: where);
    final rows = await MoveAnalysis.db.find(
      session,
      where: where,
      orderByList: (t) => [t.drillAttempts.asc(), t.createdAt.desc()],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return null;
    final position = positionFromFen(row.fenBefore);
    return MistakeDrill(
      analysisId: row.id!,
      fen: row.fenBefore,
      side: position.turn == Side.white ? PlayerColor.white : PlayerColor.black,
      playedSan: row.san,
      classification: row.classification,
      legalMoves: legalMovesOf(position),
      remaining: remaining,
      playedAt: row.createdAt,
    );
  }

  /// Checks a move in a mistake drill. Any move about as good as the
  /// engine's best counts.
  Future<MistakeDrillResult> mistakeMove(
    Session session,
    int analysisId,
    String uci,
  ) async {
    final userId = _user(session);
    var row = await MoveAnalysis.db.findById(session, analysisId);
    if (row == null || row.userId != userId) {
      throw ChessGameException(message: 'Drill not found.');
    }
    final position = positionFromFen(row.fenBefore);
    final move = Move.parse(uci);
    if (move == null || !position.isLegal(move)) {
      throw ChessGameException(message: 'Illegal move.');
    }
    var correct = move.uci == row.bestUci;
    if (!correct) {
      final after = position.play(move);
      if (after.isCheckmate) {
        correct = true;
      } else if (!after.isGameOver) {
        final analysis = await ChessEngine.instance.analyse(
          [],
          startFen: after.fen,
        );
        final best = analysis.best;
        if (best != null) {
          final win = moverChance(
            whiteWinChance(cp: best.cp, mate: best.mate),
            whiteMoved: position.turn == Side.white,
          );
          correct = row.winBefore - win <= 3;
        }
      }
    }
    if (row.explanation == null) {
      final writer = CoachWriter(
        session,
        rating: (await StatsService.load(session, userId)).puzzleRating,
      );
      row = await writer.explainMove(row);
    }
    row = await MoveAnalysis.db.updateRow(
      session,
      row.copyWith(
        drillAttempts: row.drillAttempts + 1,
        drillSuccesses: row.drillSuccesses + (correct ? 1 : 0),
      ),
    );
    await StatsService.touch(session, userId);
    return MistakeDrillResult(
      correct: correct,
      bestUci: row.bestUci ?? uci,
      bestSan: row.bestSan ?? '',
      explanation: [
        if (row.explanation != null) row.explanation!,
        if (row.lesson != null) row.lesson!,
      ].join('\n\n'),
    );
  }

  static UuidValue _user(Session session) => session.authenticated!.authUserId;
}
