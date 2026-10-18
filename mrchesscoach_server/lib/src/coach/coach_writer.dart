import 'package:dartchess/dartchess.dart';
import 'package:serverpod/serverpod.dart';

import '../chess/chess_rules.dart';
import '../generated/protocol.dart';
import 'coach_ai.dart';
import 'move_classifier.dart';
import 'position_facts.dart';

/// Themes the coach tags explanations with. The progress screen counts them
/// to find the player's weak spots.
const coachMotifs = {
  'hangingPiece': 'Loose pieces',
  'fork': 'Forks',
  'pin': 'Pins',
  'skewer': 'Skewers',
  'discoveredAttack': 'Discovered attacks',
  'backRank': 'Back-rank weakness',
  'mateThreat': 'Mating attacks',
  'kingSafety': 'King safety',
  'trappedPiece': 'Trapped pieces',
  'overloadedPiece': 'Overloaded defenders',
  'missedCapture': 'Missed captures',
  'development': 'Development',
  'centerControl': 'The centre',
  'pawnStructure': 'Pawn structure',
  'pieceActivity': 'Piece activity',
  'endgameTechnique': 'Endgame technique',
  'trade': 'Trades',
  'other': 'Other',
};

/// How the coach should pitch its explanations.
String audienceFor(int rating) {
  if (rating < 900) {
    return 'a beginner (about $rating). Use plain words, name pieces and '
        'squares, avoid jargon, and explain one idea at a time';
  }
  if (rating < 1500) {
    return 'a club player (about $rating). Name tactics and plans '
        'by their usual names and keep it practical';
  }
  return 'a strong player (about $rating). Be precise and concise, and '
      'mention the concrete line';
}

String _system(String audience) =>
    '''
You are "Coach", the friendly, sharp chess coach in the app Mr. Chess Coach.
You talk directly to your student ("you"). The student is $audience.

Rules you always follow:
- Use ONLY the facts in the brief: the engine lines, evaluations, piece lists and computed facts. Never invent moves, pieces, squares or tactics that are not supported by the brief.
- Write moves in SAN exactly as they appear in the brief.
- Be concrete: name the piece, the square and the idea. Prefer one sharp point over several vague ones.
- Plain sentences only: no headings, no lists unless asked, no emojis.
- Be encouraging but honest. A blunder is a blunder; say what it allows.''';

/// The facts about one move that every prompt shares.
class _MoveBrief {
  _MoveBrief(this.analysis) : before = positionFromFen(analysis.fenBefore) {
    final move = Move.parse(analysis.uci);
    after = move != null && before.isLegal(move) ? before.play(move) : before;
    mover = before.turn;
  }

  final MoveAnalysis analysis;
  final Position before;
  late final Position after;
  late final Side mover;

  String describe({required bool byStudent}) {
    final a = analysis;
    final who = byStudent ? 'The student' : 'The opponent (the computer)';
    final buffer = StringBuffer()
      ..writeln('Position before the move (${sideName(mover)} to move):')
      ..writeln(pieceList(before))
      ..writeln('FEN: ${a.fenBefore}')
      ..writeln('Game phase: ${gamePhase(before, a.ply)}.')
      ..writeln()
      ..writeln(
        '$who, playing ${sideName(mover)}, played ${a.san}. '
        'Engine verdict: ${classPhrase(a.classification)}.',
      )
      ..writeln(
        '${sideName(mover)}\'s winning chances: ${a.winBefore.round()}% with '
        'best play, ${a.winAfter.round()}% after ${a.san}.',
      );
    if (a.bestSan != null && a.bestSan != a.san) {
      buffer.writeln(
        'The engine\'s best move was ${a.bestSan}. Best line: '
        '${numberedLine(before, a.bestLine)}.',
      );
    } else if (a.bestLine.isNotEmpty) {
      buffer.writeln(
        '${a.san} is the engine\'s top choice. Main line: '
        '${numberedLine(before, a.bestLine)}.',
      );
    }
    if (a.replyLine.isNotEmpty) {
      buffer.writeln(
        'Best continuation after ${a.san}: '
        '${numberedLine(after, a.replyLine)}.',
      );
    }
    final looseAfter = loosePieces(after, mover);
    final looseBefore = loosePieces(before, mover);
    final newlyLoose = looseAfter.where((p) => !looseBefore.contains(p));
    if (newlyLoose.isNotEmpty) {
      buffer.writeln(
        'After ${a.san}, these ${sideName(mover)} pieces can be won: '
        '${newlyLoose.join(', ')}.',
      );
    }
    final targets = loosePieces(before, mover.opposite);
    if (targets.isNotEmpty) {
      buffer.writeln(
        'Before the move, these ${sideName(mover.opposite)} pieces were '
        'loose: ${targets.join(', ')}.',
      );
    }
    if (after.isCheck) buffer.writeln('${a.san} gives check.');
    return buffer.toString();
  }
}

const _explainSchema = {
  'type': 'object',
  'properties': {
    'headline': {
      'type': 'string',
      'description': 'At most 7 words, e.g. "Hangs the bishop on c4".',
    },
    'explanation': {
      'type': 'string',
      'description': '2-3 sentences, at most 60 words.',
    },
    'lesson': {
      'type': 'string',
      'description': 'One general takeaway, at most 18 words.',
    },
    'motif': {
      'type': 'string',
      'enum': [
        'hangingPiece',
        'fork',
        'pin',
        'skewer',
        'discoveredAttack',
        'backRank',
        'mateThreat',
        'kingSafety',
        'trappedPiece',
        'overloadedPiece',
        'missedCapture',
        'development',
        'centerControl',
        'pawnStructure',
        'pieceActivity',
        'endgameTechnique',
        'trade',
        'other',
      ],
    },
  },
  'required': ['headline', 'explanation', 'lesson', 'motif'],
};

/// Writes the coach's texts. Every method falls back to a template when the
/// language model is unavailable.
class CoachWriter {
  CoachWriter(this.session, {required this.rating, this.allowModel = true});

  final Session session;
  final int rating;

  /// Whether the language model may be called; templates are used if not.
  final bool allowModel;

  Future<Map<String, dynamic>?> _json({
    required String system,
    required String prompt,
    required Map<String, Object?> schema,
  }) async => allowModel
      ? CoachAi.json(session, system: system, prompt: prompt, schema: schema)
      : null;

  Future<String?> _text({
    required String system,
    required String prompt,
    List<CoachChatTurn> history = const [],
  }) async => allowModel
      ? CoachAi.text(session, system: system, prompt: prompt, history: history)
      : null;

  String get _systemPrompt => _system(audienceFor(rating));

  /// Fills in headline, explanation, lesson and motif for [analysis].
  Future<MoveAnalysis> explainMove(MoveAnalysis analysis) async {
    final brief = _MoveBrief(analysis);
    final good =
        !keyClasses.contains(analysis.classification) ||
        analysis.classification == MoveClass.brilliant ||
        analysis.classification == MoveClass.great;
    final task = analysis.byPlayer
        ? (good
              ? 'Explain why ${analysis.san} is ${classPhrase(analysis.classification)}: what it achieves and what idea it follows.'
              : 'Explain why ${analysis.san} is ${classPhrase(analysis.classification)}: what concretely goes wrong (use the continuation), and what the better move ${analysis.bestSan ?? ''} would have achieved.')
        : 'Explain the opponent\'s move ${analysis.san} (${classPhrase(analysis.classification)}) to the student: what it does, and if it is a mistake, how the student can punish it (use the continuation).';
    final json = await _json(
      system: _systemPrompt,
      prompt: '${brief.describe(byStudent: analysis.byPlayer)}\nTask: $task',
      schema: _explainSchema,
    );
    if (json != null) {
      return analysis.copyWith(
        headline: _clip(json['headline'] as String?, 80),
        explanation: _clip(json['explanation'] as String?, 600),
        lesson: _clip(json['lesson'] as String?, 200),
        motif: coachMotifs.containsKey(json['motif']) ? json['motif'] : 'other',
      );
    }
    return analysis.copyWith(
      headline: _fallbackHeadline(analysis),
      explanation: _fallbackExplanation(brief),
      lesson: _fallbackLesson(analysis),
      motif: _fallbackMotif(brief),
    );
  }

  /// A nudge for the hint ladder. [level] 1 gives the idea, 2 names the
  /// piece, 3 names the move.
  Future<CoachHint> hint({
    required Position position,
    required String bestUci,
    required List<String> bestLine,
    required int level,
  }) async {
    final move = Move.parse(bestUci) as NormalMove;
    final san = position.makeSan(move).$2;
    final square = move.from.name;
    final piece = pieceOn(position, square);
    final brief = StringBuffer()
      ..writeln('Position (${sideName(position.turn)} to move, the student):')
      ..writeln(pieceList(position))
      ..writeln(
        'Best move (SECRET): $san. Best line: ${numberedLine(position, bestLine)}.',
      )
      ..writeln(
        materialStory(
          position,
          uciLineFromSan(position, bestLine),
          position.turn,
        ),
      );
    final targets = loosePieces(position, position.turn.opposite);
    if (targets.isNotEmpty) {
      brief.writeln('Loose opponent pieces: ${targets.join(', ')}.');
    }
    final task = switch (level) {
      1 =>
        'Give a hint of one or two sentences that points the student towards the idea behind the best move WITHOUT naming the move, the moving piece or its destination square. Mention the target, weakness or theme instead.',
      2 =>
        'In one or two sentences, tell the student that $piece is the piece to move and hint at what it should aim for, without giving the destination square.',
      _ => 'In one or two sentences, explain why $san is the best move here.',
    };
    final json = await _json(
      system: _systemPrompt,
      prompt: '$brief\nTask: $task',
      schema: const {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
        },
        'required': ['text'],
      },
    );
    var text = _clip(json?['text'] as String?, 400);
    if (text != null && level == 1 && text.contains(san.replaceAll('+', ''))) {
      text = null; // Gave the move away; use the template instead.
    }
    text ??= switch (level) {
      1 => _fallbackIdea(position, san, targets),
      2 => 'Look at $piece. That is the piece to move.',
      _ =>
        'Play $san. It is the engine\'s top choice: ${numberedLine(position, bestLine)}.',
    };
    return CoachHint(
      level: level,
      text: text,
      square: level >= 2 ? square : null,
      uci: level >= 3 ? bestUci : null,
      san: level >= 3 ? san : null,
    );
  }

  /// Explains the opponent's [threatSan], found by letting them move twice.
  Future<String> threat({
    required Position position,
    required Position nullMovePosition,
    required String threatSan,
    required List<String> threatLine,
    required double gain,
    String? defenceSan,
  }) async {
    final opponent = position.turn.opposite;
    final brief = StringBuffer()
      ..writeln('Position (${sideName(position.turn)} to move, the student):')
      ..writeln(pieceList(position))
      ..writeln(
        'If it were ${sideName(opponent)}\'s move, they would play $threatSan '
        '(line: ${numberedLine(nullMovePosition, threatLine)}), improving '
        'their winning chances by about ${gain.round()} points.',
      )
      ..writeln(
        materialStory(
          nullMovePosition,
          uciLineFromSan(nullMovePosition, threatLine),
          opponent,
        ),
      );
    if (defenceSan != null) {
      brief.writeln(
        'The engine\'s recommended move for the student now: $defenceSan.',
      );
    }
    final text = await _text(
      system: _systemPrompt,
      prompt:
          '$brief\nTask: In two sentences, explain what ${sideName(opponent)} is threatening with $threatSan and what the student should keep in mind to deal with it. Do not reveal the recommended move.',
    );
    return text ??
        '${sideName(opponent)} is threatening $threatSan. '
            '${materialStory(nullMovePosition, uciLineFromSan(nullMovePosition, threatLine), opponent)}';
  }

  /// Answers a question about [position].
  Future<String> answer({
    required Position position,
    required List<String> recentSan,
    required List<({String san, int? cp, int? mate, List<String> line})> lines,
    required String question,
    required List<CoachChatTurn> history,
    Side? studentSide,
  }) async {
    final brief = StringBuffer()
      ..writeln('Current position (${sideName(position.turn)} to move):')
      ..writeln(pieceList(position))
      ..writeln('FEN: ${position.fen}')
      ..writeln('Game phase: ${gamePhase(position, recentSan.length)}.');
    if (studentSide != null) {
      brief.writeln('The student plays ${sideName(studentSide)}.');
    }
    if (recentSan.isNotEmpty) {
      brief.writeln(
        'Most recent moves: ${recentSan.skip(recentSan.length > 12 ? recentSan.length - 12 : 0).join(' ')}.',
      );
    }
    for (final (i, l) in lines.indexed) {
      final eval = l.mate != null
          ? 'mate in ${l.mate!.abs()} for ${l.mate! > 0 ? 'White' : 'Black'}'
          : '${((l.cp ?? 0) / 100).toStringAsFixed(1)} pawns (White\'s view)';
      brief.writeln(
        'Engine line ${i + 1}: ${numberedLine(position, l.line)} — $eval.',
      );
    }
    final looseWhite = loosePieces(position, Side.white);
    final looseBlack = loosePieces(position, Side.black);
    if (looseWhite.isNotEmpty) {
      brief.writeln('Loose White pieces: ${looseWhite.join(', ')}.');
    }
    if (looseBlack.isNotEmpty) {
      brief.writeln('Loose Black pieces: ${looseBlack.join(', ')}.');
    }
    final text = await _text(
      system:
          '$_systemPrompt\n- Answer the student\'s question about the position in at most 120 words. If the question is not about chess, steer back to the game kindly.\n\nBrief:\n$brief',
      prompt: question,
      history: history,
    );
    return text ??
        'I can\'t reach my analysis notes right now. The engine likes '
            '${lines.firstOrNull?.san ?? 'the position'} here. Try asking again in a moment.';
  }

  /// A short written review of a finished game.
  Future<String?> summarize({
    required List<MoveAnalysis> moves,
    required Side studentSide,
    required String result,
    required double playerAccuracy,
    required double opponentAccuracy,
    String? openingName,
  }) async {
    final lines = <String>[];
    for (final m in moves) {
      final moveNo = '${m.ply ~/ 2 + 1}${m.ply.isEven ? '.' : '...'}';
      final tag = keyClasses.contains(m.classification)
          ? ' (${m.classification.name}; best was ${m.bestSan})'
          : '';
      lines.add('$moveNo ${m.san}$tag');
    }
    final brief =
        '''
The student played ${sideName(studentSide)}. Result: $result.
Opening: ${openingName ?? 'unknown'}.
Accuracy: student ${playerAccuracy.round()}%, computer ${opponentAccuracy.round()}%.
Moves (key moments tagged with the engine verdict and best move):
${lines.join(' ')}''';
    final json = await _json(
      system: _systemPrompt,
      prompt:
          '$brief\n\nTask: Write a short game summary (at most 70 words) describing how the game went and its turning point, then exactly three concrete lessons for the student (each at most 16 words).',
      schema: const {
        'type': 'object',
        'properties': {
          'summary': {'type': 'string'},
          'lessons': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['summary', 'lessons'],
      },
    );
    if (json == null) return null;
    final lessons = (json['lessons'] as List? ?? []).cast<String>().take(3);
    return [
      json['summary'] as String? ?? '',
      for (final l in lessons) '• $l',
    ].join('\n');
  }

  /// Explains why [wrongSan] fails in a puzzle and what the solution does.
  Future<String> puzzleMiss({
    required Position position,
    required String wrongSan,
    required List<String> refutation,
    required String solutionSan,
    required List<String> solutionLine,
    required List<String> themes,
  }) async {
    final after = playLine(position, uciLineFromSan(position, [wrongSan]));
    final brief = StringBuffer()
      ..writeln(
        'Puzzle position (${sideName(position.turn)} to move, the student):',
      )
      ..writeln(pieceList(position))
      ..writeln('Puzzle themes: ${themes.join(', ')}.')
      ..writeln('The student tried $wrongSan.')
      ..writeln(
        refutation.isEmpty
            ? ''
            : 'Best answer to $wrongSan: ${numberedLine(after, refutation)}.',
      )
      ..writeln(
        'The solution is $solutionSan: ${numberedLine(position, solutionLine)}.',
      );
    final text = await _text(
      system: _systemPrompt,
      prompt:
          '$brief\nTask: In at most three sentences, explain why $wrongSan does not work and what idea the solution $solutionSan uses.',
    );
    return text ??
        '$wrongSan doesn\'t work here. The key move is $solutionSan: '
            '${numberedLine(position, solutionLine)}.';
  }

  // ---------------------------------------------------------------------------
  // Templates

  static String? _clip(String? s, int max) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    return t.length <= max ? t : '${t.substring(0, max - 1)}…';
  }

  static String _fallbackHeadline(MoveAnalysis a) => switch (a.classification) {
    MoveClass.brilliant => 'A brilliant sacrifice!',
    MoveClass.great => 'The only good move',
    MoveClass.best => 'The engine\'s top choice',
    MoveClass.excellent => 'Excellent, nearly perfect',
    MoveClass.good => 'A solid move',
    MoveClass.book => 'A known opening move',
    MoveClass.inaccuracy => 'A little imprecise',
    MoveClass.mistake => 'This lets the advantage slip',
    MoveClass.miss => 'A chance was missed',
    MoveClass.blunder => 'This loses a lot',
  };

  static String _fallbackExplanation(_MoveBrief brief) {
    final a = brief.analysis;
    final parts = <String>[
      '${a.san} is ${classPhrase(a.classification)}.',
    ];
    if (a.bestSan != null && a.bestSan != a.san) {
      parts.add('The engine preferred ${a.bestSan}.');
    }
    if (a.replyLine.isNotEmpty && keyClasses.contains(a.classification)) {
      parts.add(
        'After ${a.san}, the critical line is '
        '${numberedLine(brief.after, a.replyLine.take(4).toList())}.',
      );
      parts.add(
        materialStory(
          brief.after,
          uciLineFromSan(brief.after, a.replyLine),
          brief.mover,
        ),
      );
    }
    return parts.join(' ');
  }

  static String _fallbackLesson(MoveAnalysis a) => switch (a.classification) {
    MoveClass.blunder || MoveClass.mistake =>
      'Before every move, check what your opponent can capture or attack.',
    MoveClass.miss => 'When your opponent errs, look for forcing moves first.',
    MoveClass.brilliant ||
    MoveClass.great => 'Look for forcing moves even when they cost material.',
    _ => 'Keep developing pieces towards the centre.',
  };

  static String _fallbackMotif(_MoveBrief brief) {
    final a = brief.analysis;
    if (loosePieces(brief.after, brief.mover).length >
        loosePieces(brief.before, brief.mover).length) {
      return 'hangingPiece';
    }
    if (loosePieces(brief.before, brief.mover.opposite).isNotEmpty &&
        (a.bestSan?.contains('x') ?? false)) {
      return 'missedCapture';
    }
    return 'other';
  }

  static String _fallbackIdea(Position p, String san, List<String> targets) {
    if (san.contains('#')) {
      return 'There is a checkmate on the board. Look at every check.';
    }
    if (san.contains('+')) {
      return 'Look at forcing moves. A check is the key here.';
    }
    if (san.contains('x') && targets.isNotEmpty) {
      return 'Something is undefended: ${targets.first} looks vulnerable.';
    }
    if (san.contains('x')) {
      return 'There is material to win. Look at the captures.';
    }
    return 'Improve your worst-placed piece, or find a move that creates a threat.';
  }
}

/// Converts a SAN line back to UCI (for material counting).
List<String> uciLineFromSan(Position start, List<String> sanLine) {
  final uci = <String>[];
  var position = start;
  for (final san in sanLine) {
    final move = position.parseSan(san);
    if (move == null) break;
    uci.add(move.uci);
    position = position.play(move);
  }
  return uci;
}
