import 'dart:io';
import 'dart:math';

import 'package:stockfish_dart/stockfish_dart.dart';
import 'package:synchronized/synchronized.dart';

import 'levels.dart';

/// An engine evaluation from White's point of view. Exactly one of
/// [centipawns] and [mateIn] is set, or neither if the engine gave no score.
typedef Evaluation = ({int? centipawns, int? mateIn});

/// One line of a multi-PV analysis. Scores are from White's point of view.
class EngineLine {
  const EngineLine({required this.pv, this.cp, this.mate});

  factory EngineLine.fromJson(Map<String, dynamic> json) => EngineLine(
    pv: (json['pv'] as List).cast<String>(),
    cp: json['cp'] as int?,
    mate: json['mate'] as int?,
  );

  /// The principal variation in UCI, starting with the line's move.
  final List<String> pv;
  final int? cp;
  final int? mate;

  String get move => pv.first;

  Map<String, dynamic> toJson() => {'pv': pv, 'cp': cp, 'mate': mate};
}

/// The engine's view of one position: its best lines, best first.
class PositionAnalysis {
  const PositionAnalysis(this.lines);

  factory PositionAnalysis.fromJson(Map<String, dynamic> json) =>
      PositionAnalysis([
        for (final l in json['lines'] as List)
          EngineLine.fromJson((l as Map).cast<String, dynamic>()),
      ]);

  final List<EngineLine> lines;

  EngineLine? get best => lines.firstOrNull;

  Map<String, dynamic> toJson() => {
    'lines': [for (final l in lines) l.toJson()],
  };
}

/// The shared Stockfish engine.
///
/// Only one embedded Stockfish can run per process, so every game shares
/// this instance. A lock makes each request's option changes and search
/// atomic.
class ChessEngine {
  ChessEngine._();

  static final instance = ChessEngine._();

  final _lock = Lock();
  Stockfish? _engine;

  static const _hintLimits = SearchLimits(
    moveTime: Duration(milliseconds: 800),
  );

  /// Analysis depth for coaching: deep enough to see two- and three-move
  /// tactics, quick enough to run after every move.
  static const coachLimits = SearchLimits(
    depth: 18,
    moveTime: Duration(milliseconds: 450),
  );

  /// Picks the computer's move after [moves] at [level].
  Future<String> bestMove(
    List<String> moves,
    LevelSpec level, {
    String? startFen,
  }) => _lock.synchronized(() async {
    final engine = await _ensureStarted();
    await engine.setOptions(const StockfishOptions(multiPv: 1));
    await engine.setOptions(StockfishOptions.strength(level.strength));
    final result = await engine.bestMove(
      _position(startFen, moves),
      limits: level.limits,
    );
    final move = result.bestMove;
    if (move == null) {
      throw StateError('The engine found no move after $moves');
    }
    return move.value;
  });

  /// The best move after [moves] at full strength.
  Future<String?> hint(List<String> moves, {String? startFen}) =>
      _lock.synchronized(() async {
        final engine = await _ensureStarted();
        await _fullStrength(engine, multiPv: 1);
        final result = await engine.bestMove(
          _position(startFen, moves),
          limits: _hintLimits,
        );
        return result.bestMove?.value;
      });

  /// Analyses the position after [moves] at full strength and returns the
  /// [multiPv] best lines with White-relative scores.
  Future<PositionAnalysis> analyse(
    List<String> moves, {
    String? startFen,
    int multiPv = 1,
    SearchLimits limits = coachLimits,
  }) => _lock.synchronized(() async {
    final engine = await _ensureStarted();
    await _fullStrength(engine, multiPv: multiPv);
    final result = await engine.bestMove(
      _position(startFen, moves),
      limits: limits,
    );
    final whiteToMove = _whiteToMove(startFen, moves.length);
    return PositionAnalysis([
      for (final line in result.lines)
        if (line.pv.isNotEmpty)
          _line(line, whiteToMove ? Side.white : Side.black),
    ]);
  });

  /// Evaluates the position after [moves] at full strength.
  Future<Evaluation> evaluate(List<String> moves, {String? startFen}) async {
    final analysis = await analyse(moves, startFen: startFen);
    final best = analysis.best;
    return (centipawns: best?.cp, mateIn: best?.mate);
  }

  static EngineLine _line(SearchInfo info, Side sideToMove) {
    final score = info.score?.fromWhitePerspective(sideToMove);
    return EngineLine(
      pv: [for (final m in info.pv) m.value],
      cp: score is CentipawnScore ? score.centipawns : null,
      mate: score is MateScore ? score.moves : null,
    );
  }

  Future<void> _fullStrength(Stockfish engine, {required int multiPv}) =>
      engine.setOptions(
        StockfishOptions(
          limitStrength: false,
          skillLevel: 20,
          multiPv: multiPv,
        ),
      );

  /// Stops the engine. The next request starts it again. Used by tests,
  /// since only one embedded engine can run per process.
  Future<void> shutdown() => _lock.synchronized(() async {
    final engine = _engine;
    _engine = null;
    await engine?.dispose();
  });

  Future<Stockfish> _ensureStarted() async {
    return _engine ??= await Stockfish.start(
      options: StockfishOptions(
        threads: max(1, min(4, Platform.numberOfProcessors ~/ 2)),
        hashMb: 64,
      ),
    );
  }

  static bool _whiteToMove(String? startFen, int plies) {
    final whiteStarts = startFen == null || startFen.split(' ')[1] == 'w';
    return whiteStarts == plies.isEven;
  }

  static Position _position(String? startFen, List<String> moves) {
    final uciMoves = [for (final m in moves) UciMove(m)];
    return startFen == null
        ? Position.startpos(moves: uciMoves)
        : Position.fromFen(startFen, moves: uciMoves);
  }
}
