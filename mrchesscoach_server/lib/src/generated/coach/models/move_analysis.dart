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
import 'dart:async' as _ida;
import 'package:mrchesscoach_server/src/generated/protocol.dart' as _idwhoq0v;
import 'package:serverpod/serverpod.dart' as _is;
import '../../coach/models/move_class.dart' as _iua1gast;

/// The engine's verdict on one move of a game, plus the coach's explanation.
abstract class MoveAnalysis
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MoveAnalysis._({
    this.id,
    required this.gameId,
    this.userId,
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
    _is.UuidValue? userId,
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
      userId: jsonSerialization['userId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      ply: jsonSerialization['ply'] as int,
      uci: jsonSerialization['uci'] as String,
      san: jsonSerialization['san'] as String,
      byPlayer: _is.BoolJsonExtension.fromJson(jsonSerialization['byPlayer']),
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
      bestLine: _idwhoq0v.Protocol().deserialize<List<String>>(
        jsonSerialization['bestLine'],
      ),
      replyLine: _idwhoq0v.Protocol().deserialize<List<String>>(
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
          : _is.BoolJsonExtension.fromJson(jsonSerialization['retracted']),
      drillAttempts: jsonSerialization['drillAttempts'] as int?,
      drillSuccesses: jsonSerialization['drillSuccesses'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = MoveAnalysisTable();

  static const db = MoveAnalysisRepository._();

  @override
  int? id;

  int gameId;

  _is.UuidValue? userId;

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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MoveAnalysis]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MoveAnalysis copyWith({
    int? id,
    int? gameId,
    _is.UuidValue? userId = const _is.$UndefinedUuidValue(),
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
      if (userId != null) 'userId': userId?.toJson(),
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

  static MoveAnalysisInclude include() {
    return MoveAnalysisInclude._();
  }

  static MoveAnalysisIncludeList includeList({
    _is.WhereExpressionBuilder<MoveAnalysisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    MoveAnalysisInclude? include,
  }) {
    return MoveAnalysisIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MoveAnalysisImpl extends MoveAnalysis {
  _MoveAnalysisImpl({
    int? id,
    required int gameId,
    _is.UuidValue? userId,
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
         userId: userId,
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
  @_is.useResult
  @override
  MoveAnalysis copyWith({
    Object? id = _Undefined,
    int? gameId,
    _is.UuidValue? userId = const _is.$UndefinedUuidValue(),
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
      userId: userId is _is.UndefinedSentinel ? this.userId : userId,
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

class MoveAnalysisUpdateTable extends _is.UpdateTable<MoveAnalysisTable> {
  MoveAnalysisUpdateTable(super.table);

  _is.ColumnValue<int, int> gameId(int value) => _is.ColumnValue(
    table.gameId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<int, int> ply(int value) => _is.ColumnValue(
    table.ply,
    value,
  );

  _is.ColumnValue<String, String> uci(String value) => _is.ColumnValue(
    table.uci,
    value,
  );

  _is.ColumnValue<String, String> san(String value) => _is.ColumnValue(
    table.san,
    value,
  );

  _is.ColumnValue<bool, bool> byPlayer(bool value) => _is.ColumnValue(
    table.byPlayer,
    value,
  );

  _is.ColumnValue<_iua1gast.MoveClass, _iua1gast.MoveClass> classification(
    _iua1gast.MoveClass value,
  ) => _is.ColumnValue(
    table.classification,
    value,
  );

  _is.ColumnValue<double, double> winBefore(double value) => _is.ColumnValue(
    table.winBefore,
    value,
  );

  _is.ColumnValue<double, double> winAfter(double value) => _is.ColumnValue(
    table.winAfter,
    value,
  );

  _is.ColumnValue<double, double> accuracy(double value) => _is.ColumnValue(
    table.accuracy,
    value,
  );

  _is.ColumnValue<int, int> evalCp(int? value) => _is.ColumnValue(
    table.evalCp,
    value,
  );

  _is.ColumnValue<int, int> evalMate(int? value) => _is.ColumnValue(
    table.evalMate,
    value,
  );

  _is.ColumnValue<String, String> bestUci(String? value) => _is.ColumnValue(
    table.bestUci,
    value,
  );

  _is.ColumnValue<String, String> bestSan(String? value) => _is.ColumnValue(
    table.bestSan,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> bestLine(List<String> value) =>
      _is.ColumnValue(
        table.bestLine,
        value,
      );

  _is.ColumnValue<List<String>, List<String>> replyLine(List<String> value) =>
      _is.ColumnValue(
        table.replyLine,
        value,
      );

  _is.ColumnValue<String, String> replyUci(String? value) => _is.ColumnValue(
    table.replyUci,
    value,
  );

  _is.ColumnValue<String, String> fenBefore(String value) => _is.ColumnValue(
    table.fenBefore,
    value,
  );

  _is.ColumnValue<String, String> headline(String? value) => _is.ColumnValue(
    table.headline,
    value,
  );

  _is.ColumnValue<String, String> explanation(String? value) => _is.ColumnValue(
    table.explanation,
    value,
  );

  _is.ColumnValue<String, String> lesson(String? value) => _is.ColumnValue(
    table.lesson,
    value,
  );

  _is.ColumnValue<String, String> motif(String? value) => _is.ColumnValue(
    table.motif,
    value,
  );

  _is.ColumnValue<bool, bool> retracted(bool value) => _is.ColumnValue(
    table.retracted,
    value,
  );

  _is.ColumnValue<int, int> drillAttempts(int value) => _is.ColumnValue(
    table.drillAttempts,
    value,
  );

  _is.ColumnValue<int, int> drillSuccesses(int value) => _is.ColumnValue(
    table.drillSuccesses,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class MoveAnalysisTable extends _is.Table<int?> {
  MoveAnalysisTable({super.tableRelation}) : super(tableName: 'move_analysis') {
    updateTable = MoveAnalysisUpdateTable(this);
    gameId = _is.ColumnInt(
      'gameId',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    ply = _is.ColumnInt(
      'ply',
      this,
    );
    uci = _is.ColumnString(
      'uci',
      this,
    );
    san = _is.ColumnString(
      'san',
      this,
    );
    byPlayer = _is.ColumnBool(
      'byPlayer',
      this,
    );
    classification = _is.ColumnEnum(
      'classification',
      this,
      _is.EnumSerialization.byName,
    );
    winBefore = _is.ColumnDouble(
      'winBefore',
      this,
    );
    winAfter = _is.ColumnDouble(
      'winAfter',
      this,
    );
    accuracy = _is.ColumnDouble(
      'accuracy',
      this,
    );
    evalCp = _is.ColumnInt(
      'evalCp',
      this,
    );
    evalMate = _is.ColumnInt(
      'evalMate',
      this,
    );
    bestUci = _is.ColumnString(
      'bestUci',
      this,
    );
    bestSan = _is.ColumnString(
      'bestSan',
      this,
    );
    bestLine = _is.ColumnSerializable<List<String>>(
      'bestLine',
      this,
    );
    replyLine = _is.ColumnSerializable<List<String>>(
      'replyLine',
      this,
    );
    replyUci = _is.ColumnString(
      'replyUci',
      this,
    );
    fenBefore = _is.ColumnString(
      'fenBefore',
      this,
    );
    headline = _is.ColumnString(
      'headline',
      this,
    );
    explanation = _is.ColumnString(
      'explanation',
      this,
    );
    lesson = _is.ColumnString(
      'lesson',
      this,
    );
    motif = _is.ColumnString(
      'motif',
      this,
    );
    retracted = _is.ColumnBool(
      'retracted',
      this,
      hasDefault: true,
    );
    drillAttempts = _is.ColumnInt(
      'drillAttempts',
      this,
      hasDefault: true,
    );
    drillSuccesses = _is.ColumnInt(
      'drillSuccesses',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final MoveAnalysisUpdateTable updateTable;

  late final _is.ColumnInt gameId;

  late final _is.ColumnUuid userId;

  /// Index of the move in the game's move list.
  late final _is.ColumnInt ply;

  late final _is.ColumnString uci;

  late final _is.ColumnString san;

  /// Whether the human played this move (otherwise the computer did).
  late final _is.ColumnBool byPlayer;

  late final _is.ColumnEnum<_iua1gast.MoveClass> classification;

  /// The mover's winning chances (0-100) with best play before the move.
  late final _is.ColumnDouble winBefore;

  /// The mover's winning chances (0-100) after the move.
  late final _is.ColumnDouble winAfter;

  /// Move accuracy (0-100), as in game reviews.
  late final _is.ColumnDouble accuracy;

  /// Evaluation after the move, from White's point of view.
  late final _is.ColumnInt evalCp;

  late final _is.ColumnInt evalMate;

  /// The engine's best move in the position before the move.
  late final _is.ColumnString bestUci;

  late final _is.ColumnString bestSan;

  /// The engine's main line from the position before the move (SAN).
  late final _is.ColumnSerializable<List<String>> bestLine;

  /// The best continuation after the played move (SAN).
  late final _is.ColumnSerializable<List<String>> replyLine;

  /// The first move of that continuation (UCI), for drawing an arrow.
  late final _is.ColumnString replyUci;

  /// The position before the move.
  late final _is.ColumnString fenBefore;

  /// The coach's short verdict, e.g. "Hangs the knight". Null until asked.
  late final _is.ColumnString headline;

  /// The coach's explanation. Null until asked.
  late final _is.ColumnString explanation;

  /// What to remember from this move, as one sentence.
  late final _is.ColumnString lesson;

  /// The tactical or positional theme behind the verdict.
  late final _is.ColumnString motif;

  /// The player took the move back after the coach's warning. Kept for
  /// the mistake trainer; not part of the game any more.
  late final _is.ColumnBool retracted;

  /// Practice attempts on this position in the mistake trainer.
  late final _is.ColumnInt drillAttempts;

  late final _is.ColumnInt drillSuccesses;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    gameId,
    userId,
    ply,
    uci,
    san,
    byPlayer,
    classification,
    winBefore,
    winAfter,
    accuracy,
    evalCp,
    evalMate,
    bestUci,
    bestSan,
    bestLine,
    replyLine,
    replyUci,
    fenBefore,
    headline,
    explanation,
    lesson,
    motif,
    retracted,
    drillAttempts,
    drillSuccesses,
    createdAt,
  ];
}

class MoveAnalysisInclude extends _is.IncludeObject {
  MoveAnalysisInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MoveAnalysis.t;
}

class MoveAnalysisIncludeList extends _is.IncludeList {
  MoveAnalysisIncludeList._({
    _is.WhereExpressionBuilder<MoveAnalysisTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MoveAnalysis.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MoveAnalysis.t;
}

class MoveAnalysisRepository {
  const MoveAnalysisRepository._();

  /// Returns a list of [MoveAnalysis]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<MoveAnalysis>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MoveAnalysisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MoveAnalysis>(
      where: where?.call(MoveAnalysis.t),
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [MoveAnalysis]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `MoveAnalysis.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<MoveAnalysis>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MoveAnalysisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<MoveAnalysis>(
      where: where?.call(MoveAnalysis.t),
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [MoveAnalysis] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<MoveAnalysis?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MoveAnalysisTable>? where,
    int? offset,
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MoveAnalysis>(
      where: where?.call(MoveAnalysis.t),
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MoveAnalysis] by its [id] or null if no such row exists.
  Future<MoveAnalysis?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MoveAnalysis>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MoveAnalysis]s in the list and returns the inserted rows.
  ///
  /// The returned [MoveAnalysis]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MoveAnalysis>> insert(
    _is.DatabaseSession session,
    List<MoveAnalysis> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MoveAnalysis>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MoveAnalysis] and returns the inserted row.
  ///
  /// The returned [MoveAnalysis] will have its `id` field set.
  Future<MoveAnalysis> insertRow(
    _is.DatabaseSession session,
    MoveAnalysis row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MoveAnalysis>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MoveAnalysis]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [MoveAnalysis]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MoveAnalysis>> upsert(
    _is.DatabaseSession session,
    List<MoveAnalysis> rows, {
    required _is.ColumnSelections<MoveAnalysisTable> conflictColumns,
    _is.ColumnSelections<MoveAnalysisTable>? updateColumns,
    _is.WhereExpressionBuilder<MoveAnalysisTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MoveAnalysis>(
      rows,
      conflictColumns: conflictColumns(MoveAnalysis.t),
      updateColumns: updateColumns?.call(MoveAnalysis.t),
      updateWhere: updateWhere?.call(MoveAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MoveAnalysis] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [MoveAnalysis] will have its `id` field set.
  Future<MoveAnalysis?> upsertRow(
    _is.DatabaseSession session,
    MoveAnalysis row, {
    required _is.ColumnSelections<MoveAnalysisTable> conflictColumns,
    _is.ColumnSelections<MoveAnalysisTable>? updateColumns,
    _is.WhereExpressionBuilder<MoveAnalysisTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MoveAnalysis>(
      row,
      conflictColumns: conflictColumns(MoveAnalysis.t),
      updateColumns: updateColumns?.call(MoveAnalysis.t),
      updateWhere: updateWhere?.call(MoveAnalysis.t),
      transaction: transaction,
    );
  }

  /// Updates all [MoveAnalysis]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MoveAnalysis>> update(
    _is.DatabaseSession session,
    List<MoveAnalysis> rows, {
    _is.ColumnSelections<MoveAnalysisTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MoveAnalysis>(
      rows,
      columns: columns?.call(MoveAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MoveAnalysis]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MoveAnalysis> updateRow(
    _is.DatabaseSession session,
    MoveAnalysis row, {
    _is.ColumnSelections<MoveAnalysisTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MoveAnalysis>(
      row,
      columns: columns?.call(MoveAnalysis.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MoveAnalysis] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MoveAnalysis?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MoveAnalysisUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MoveAnalysis>(
      id,
      columnValues: columnValues(MoveAnalysis.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MoveAnalysis]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MoveAnalysis>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MoveAnalysisUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MoveAnalysisTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MoveAnalysis>(
      columnValues: columnValues(MoveAnalysis.t.updateTable),
      where: where(MoveAnalysis.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MoveAnalysis]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MoveAnalysis>> delete(
    _is.DatabaseSession session,
    List<MoveAnalysis> rows, {
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MoveAnalysis>(
      rows,
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MoveAnalysis].
  Future<MoveAnalysis> deleteRow(
    _is.DatabaseSession session,
    MoveAnalysis row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MoveAnalysis>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MoveAnalysis>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MoveAnalysisTable> where,
    _is.OrderByBuilder<MoveAnalysisTable>? orderBy,
    _is.OrderByListBuilder<MoveAnalysisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MoveAnalysis>(
      where: where(MoveAnalysis.t),
      orderBy: orderBy?.call(MoveAnalysis.t),
      orderByList: orderByList?.call(MoveAnalysis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MoveAnalysisTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MoveAnalysis>(
      where: where?.call(MoveAnalysis.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MoveAnalysis] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MoveAnalysisTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MoveAnalysis>(
      where: where(MoveAnalysis.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
