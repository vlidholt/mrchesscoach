/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mrchesscoach_client/src/protocol/protocol.dart' as _iqtjiupe;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../coach/models/move_class.dart' as _iua1gast;

/// The engine's verdict on one move of a game, plus the coach's explanation.
abstract class MoveAnalysis
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MoveAnalysis._({
    this.id,
    required this.gameId,
    required this.ply,
    required this.uci,
    required this.san,
    required this.byPlayer,
    required this.classification,
    required this.winBefore,
    required this.winAfter,
    required this.accuracy,
    this.evalCp,
    this.evalMate,
    this.bestUci,
    this.bestSan,
    required this.bestLine,
    required this.replyLine,
    this.replyUci,
    required this.fenBefore,
    this.headline,
    this.explanation,
    this.lesson,
    this.motif,
    bool? retracted,
    int? drillAttempts,
    int? drillSuccesses,
    DateTime? createdAt,
  }) : retracted = retracted ?? false,
       drillAttempts = drillAttempts ?? 0,
       drillSuccesses = drillSuccesses ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory MoveAnalysis({
    int? id,
    required int gameId,
    required int ply,
    required String uci,
    required String san,
    required bool byPlayer,
    required _iua1gast.MoveClass classification,
    required double winBefore,
    required double winAfter,
    required double accuracy,
    int? evalCp,
    int? evalMate,
    String? bestUci,
    String? bestSan,
    required List<String> bestLine,
    required List<String> replyLine,
    String? replyUci,
    required String fenBefore,
    String? headline,
    String? explanation,
    String? lesson,
    String? motif,
    bool? retracted,
    int? drillAttempts,
    int? drillSuccesses,
    DateTime? createdAt,
  }) = _MoveAnalysisImpl;

  factory MoveAnalysis.fromJson(Map<String, dynamic> jsonSerialization) {
    return MoveAnalysis(
      id: jsonSerialization['id'] as int?,
      gameId: jsonSerialization['gameId'] as int,
      ply: jsonSerialization['ply'] as int,
      uci: jsonSerialization['uci'] as String,
      san: jsonSerialization['san'] as String,
      byPlayer: _isc.BoolJsonExtension.fromJson(jsonSerialization['byPlayer']),
      classification: _iua1gast.MoveClass.fromJson(
        (jsonSerialization['classification'] as String),
      ),
      winBefore: (jsonSerialization['winBefore'] as num).toDouble(),
      winAfter: (jsonSerialization['winAfter'] as num).toDouble(),
      accuracy: (jsonSerialization['accuracy'] as num).toDouble(),
      evalCp: jsonSerialization['evalCp'] as int?,
      evalMate: jsonSerialization['evalMate'] as int?,
      bestUci: jsonSerialization['bestUci'] as String?,
      bestSan: jsonSerialization['bestSan'] as String?,
      bestLine: _iqtjiupe.Protocol().deserialize<List<String>>(
        jsonSerialization['bestLine'],
      ),
      replyLine: _iqtjiupe.Protocol().deserialize<List<String>>(
        jsonSerialization['replyLine'],
      ),
      replyUci: jsonSerialization['replyUci'] as String?,
      fenBefore: jsonSerialization['fenBefore'] as String,
      headline: jsonSerialization['headline'] as String?,
      explanation: jsonSerialization['explanation'] as String?,
      lesson: jsonSerialization['lesson'] as String?,
      motif: jsonSerialization['motif'] as String?,
      retracted: jsonSerialization['retracted'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['retracted']),
      drillAttempts: jsonSerialization['drillAttempts'] as int?,
      drillSuccesses: jsonSerialization['drillSuccesses'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int gameId;

  /// Index of the move in the game's move list.
  int ply;

  String uci;

  String san;

  /// Whether the human played this move (otherwise the computer did).
  bool byPlayer;

  _iua1gast.MoveClass classification;

  /// The mover's winning chances (0-100) with best play before the move.
  double winBefore;

  /// The mover's winning chances (0-100) after the move.
  double winAfter;

  /// Move accuracy (0-100), as in game reviews.
  double accuracy;

  /// Evaluation after the move, from White's point of view.
  int? evalCp;

  int? evalMate;

  /// The engine's best move in the position before the move.
  String? bestUci;

  String? bestSan;

  /// The engine's main line from the position before the move (SAN).
  List<String> bestLine;

  /// The best continuation after the played move (SAN).
  List<String> replyLine;

  /// The first move of that continuation (UCI), for drawing an arrow.
  String? replyUci;

  /// The position before the move.
  String fenBefore;

  /// The coach's short verdict, e.g. "Hangs the knight". Null until asked.
  String? headline;

  /// The coach's explanation. Null until asked.
  String? explanation;

  /// What to remember from this move, as one sentence.
  String? lesson;

  /// The tactical or positional theme behind the verdict.
  String? motif;

  /// The player took the move back after the coach's warning. Kept for
  /// the mistake trainer; not part of the game any more.
  bool retracted;

  /// Practice attempts on this position in the mistake trainer.
  int drillAttempts;

  int drillSuccesses;

  DateTime createdAt;

  /// Returns a shallow copy of this [MoveAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MoveAnalysis copyWith({
    int? id,
    int? gameId,
    int? ply,
    String? uci,
    String? san,
    bool? byPlayer,
    _iua1gast.MoveClass? classification,
    double? winBefore,
    double? winAfter,
    double? accuracy,
    int? evalCp,
    int? evalMate,
    String? bestUci,
    String? bestSan,
    List<String>? bestLine,
    List<String>? replyLine,
    String? replyUci,
    String? fenBefore,
    String? headline,
    String? explanation,
    String? lesson,
    String? motif,
    bool? retracted,
    int? drillAttempts,
    int? drillSuccesses,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MoveAnalysis',
      if (id != null) 'id': id,
      'gameId': gameId,
      'ply': ply,
      'uci': uci,
      'san': san,
      'byPlayer': byPlayer,
      'classification': classification.toJson(),
      'winBefore': winBefore,
      'winAfter': winAfter,
      'accuracy': accuracy,
      if (evalCp != null) 'evalCp': evalCp,
      if (evalMate != null) 'evalMate': evalMate,
      if (bestUci != null) 'bestUci': bestUci,
      if (bestSan != null) 'bestSan': bestSan,
      'bestLine': bestLine.toJson(),
      'replyLine': replyLine.toJson(),
      if (replyUci != null) 'replyUci': replyUci,
      'fenBefore': fenBefore,
      if (headline != null) 'headline': headline,
      if (explanation != null) 'explanation': explanation,
      if (lesson != null) 'lesson': lesson,
      if (motif != null) 'motif': motif,
      'retracted': retracted,
      'drillAttempts': drillAttempts,
      'drillSuccesses': drillSuccesses,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MoveAnalysis',
      if (id != null) 'id': id,
      'gameId': gameId,
      'ply': ply,
      'uci': uci,
      'san': san,
      'byPlayer': byPlayer,
      'classification': classification.toJson(),
      'winBefore': winBefore,
      'winAfter': winAfter,
      'accuracy': accuracy,
      if (evalCp != null) 'evalCp': evalCp,
      if (evalMate != null) 'evalMate': evalMate,
      if (bestUci != null) 'bestUci': bestUci,
      if (bestSan != null) 'bestSan': bestSan,
      'bestLine': bestLine.toJson(),
      'replyLine': replyLine.toJson(),
      if (replyUci != null) 'replyUci': replyUci,
      'fenBefore': fenBefore,
      if (headline != null) 'headline': headline,
      if (explanation != null) 'explanation': explanation,
      if (lesson != null) 'lesson': lesson,
      if (motif != null) 'motif': motif,
      'retracted': retracted,
      'drillAttempts': drillAttempts,
      'drillSuccesses': drillSuccesses,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MoveAnalysisImpl extends MoveAnalysis {
  _MoveAnalysisImpl({
    int? id,
    required int gameId,
    required int ply,
    required String uci,
    required String san,
    required bool byPlayer,
    required _iua1gast.MoveClass classification,
    required double winBefore,
    required double winAfter,
    required double accuracy,
    int? evalCp,
    int? evalMate,
    String? bestUci,
    String? bestSan,
    required List<String> bestLine,
    required List<String> replyLine,
    String? replyUci,
    required String fenBefore,
    String? headline,
    String? explanation,
    String? lesson,
    String? motif,
    bool? retracted,
    int? drillAttempts,
    int? drillSuccesses,
    DateTime? createdAt,
  }) : super._(
         id: id,
         gameId: gameId,
         ply: ply,
         uci: uci,
         san: san,
         byPlayer: byPlayer,
         classification: classification,
         winBefore: winBefore,
         winAfter: winAfter,
         accuracy: accuracy,
         evalCp: evalCp,
         evalMate: evalMate,
         bestUci: bestUci,
         bestSan: bestSan,
         bestLine: bestLine,
         replyLine: replyLine,
         replyUci: replyUci,
         fenBefore: fenBefore,
         headline: headline,
         explanation: explanation,
         lesson: lesson,
         motif: motif,
         retracted: retracted,
         drillAttempts: drillAttempts,
         drillSuccesses: drillSuccesses,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MoveAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MoveAnalysis copyWith({
    Object? id = _Undefined,
    int? gameId,
    int? ply,
    String? uci,
    String? san,
    bool? byPlayer,
    _iua1gast.MoveClass? classification,
    double? winBefore,
    double? winAfter,
    double? accuracy,
    Object? evalCp = _Undefined,
    Object? evalMate = _Undefined,
    Object? bestUci = _Undefined,
    Object? bestSan = _Undefined,
    List<String>? bestLine,
    List<String>? replyLine,
    Object? replyUci = _Undefined,
    String? fenBefore,
    Object? headline = _Undefined,
    Object? explanation = _Undefined,
    Object? lesson = _Undefined,
    Object? motif = _Undefined,
    bool? retracted,
    int? drillAttempts,
    int? drillSuccesses,
    DateTime? createdAt,
  }) {
    return MoveAnalysis(
      id: id is int? ? id : this.id,
      gameId: gameId ?? this.gameId,
      ply: ply ?? this.ply,
      uci: uci ?? this.uci,
      san: san ?? this.san,
      byPlayer: byPlayer ?? this.byPlayer,
      classification: classification ?? this.classification,
      winBefore: winBefore ?? this.winBefore,
      winAfter: winAfter ?? this.winAfter,
      accuracy: accuracy ?? this.accuracy,
      evalCp: evalCp is int? ? evalCp : this.evalCp,
      evalMate: evalMate is int? ? evalMate : this.evalMate,
      bestUci: bestUci is String? ? bestUci : this.bestUci,
      bestSan: bestSan is String? ? bestSan : this.bestSan,
      bestLine: bestLine ?? this.bestLine.map((e0) => e0).toList(),
      replyLine: replyLine ?? this.replyLine.map((e0) => e0).toList(),
      replyUci: replyUci is String? ? replyUci : this.replyUci,
      fenBefore: fenBefore ?? this.fenBefore,
      headline: headline is String? ? headline : this.headline,
      explanation: explanation is String? ? explanation : this.explanation,
      lesson: lesson is String? ? lesson : this.lesson,
      motif: motif is String? ? motif : this.motif,
      retracted: retracted ?? this.retracted,
      drillAttempts: drillAttempts ?? this.drillAttempts,
      drillSuccesses: drillSuccesses ?? this.drillSuccesses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
