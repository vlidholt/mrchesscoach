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
import '../../chess/models/game_end_reason.dart' as _ivjkg4d2;
import '../../chess/models/game_status.dart' as _i2ao9ybe;
import '../../chess/models/player_color.dart' as _ivqn4l49;
import '../../coach/models/move_analysis.dart' as _ix39qary;

/// A game of chess between a signed-in player and the computer.
abstract class ChessGame
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ChessGame._({
    this.id,
    this.userId,
    required this.level,
    required this.playerColor,
    required this.moves,
    required this.sanMoves,
    required this.fen,
    required this.status,
    this.endReason,
    this.evalCp,
    this.evalMate,
    this.legalMoves,
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    this.startFen,
    this.lessonId,
    bool? awaitingDecision,
    int? retries,
    this.analysisCache,
    this.lastFeedback,
    this.opponentFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : hintsUsed = hintsUsed ?? 0,
       takebacks = takebacks ?? 0,
       coachEnabled = coachEnabled ?? true,
       awaitingDecision = awaitingDecision ?? false,
       retries = retries ?? 0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ChessGame({
    int? id,
    _is.UuidValue? userId,
    required int level,
    required _ivqn4l49.PlayerColor playerColor,
    required List<String> moves,
    required List<String> sanMoves,
    required String fen,
    required _i2ao9ybe.GameStatus status,
    _ivjkg4d2.GameEndReason? endReason,
    int? evalCp,
    int? evalMate,
    Map<String, String>? legalMoves,
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    String? startFen,
    String? lessonId,
    bool? awaitingDecision,
    int? retries,
    String? analysisCache,
    _ix39qary.MoveAnalysis? lastFeedback,
    _ix39qary.MoveAnalysis? opponentFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ChessGameImpl;

  factory ChessGame.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChessGame(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      level: jsonSerialization['level'] as int,
      playerColor: _ivqn4l49.PlayerColor.fromJson(
        (jsonSerialization['playerColor'] as String),
      ),
      moves: _idwhoq0v.Protocol().deserialize<List<String>>(
        jsonSerialization['moves'],
      ),
      sanMoves: _idwhoq0v.Protocol().deserialize<List<String>>(
        jsonSerialization['sanMoves'],
      ),
      fen: jsonSerialization['fen'] as String,
      status: _i2ao9ybe.GameStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      endReason: jsonSerialization['endReason'] == null
          ? null
          : _ivjkg4d2.GameEndReason.fromJson(
              (jsonSerialization['endReason'] as String),
            ),
      evalCp: jsonSerialization['evalCp'] as int?,
      evalMate: jsonSerialization['evalMate'] as int?,
      legalMoves: jsonSerialization['legalMoves'] == null
          ? null
          : _idwhoq0v.Protocol().deserialize<Map<String, String>>(
              jsonSerialization['legalMoves'],
            ),
      hintsUsed: jsonSerialization['hintsUsed'] as int?,
      takebacks: jsonSerialization['takebacks'] as int?,
      coachEnabled: jsonSerialization['coachEnabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['coachEnabled']),
      startFen: jsonSerialization['startFen'] as String?,
      lessonId: jsonSerialization['lessonId'] as String?,
      awaitingDecision: jsonSerialization['awaitingDecision'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['awaitingDecision'],
            ),
      retries: jsonSerialization['retries'] as int?,
      analysisCache: jsonSerialization['analysisCache'] as String?,
      lastFeedback: jsonSerialization['lastFeedback'] == null
          ? null
          : _idwhoq0v.Protocol().deserialize<_ix39qary.MoveAnalysis>(
              jsonSerialization['lastFeedback'],
            ),
      opponentFeedback: jsonSerialization['opponentFeedback'] == null
          ? null
          : _idwhoq0v.Protocol().deserialize<_ix39qary.MoveAnalysis>(
              jsonSerialization['opponentFeedback'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = ChessGameTable();

  static const db = ChessGameRepository._();

  @override
  int? id;

  /// The auth user who plays this game.
  _is.UuidValue? userId;

  /// Index of the difficulty level, see `ChessLevel`.
  int level;

  /// The side the human plays.
  _ivqn4l49.PlayerColor playerColor;

  /// Moves played from the start position, in UCI notation (e.g. `e2e4`).
  List<String> moves;

  /// The same moves in standard algebraic notation (e.g. `e4`, `Nf3`).
  List<String> sanMoves;

  /// The current position as FEN.
  String fen;

  /// Whether the game is still going, and if not, how it ended.
  _i2ao9ybe.GameStatus status;

  /// Why the game ended; null while it is active.
  _ivjkg4d2.GameEndReason? endReason;

  /// Engine evaluation in centipawns from White's point of view.
  int? evalCp;

  /// Moves to mate from White's point of view (negative: Black mates).
  int? evalMate;

  /// Legal moves for the player when it is their turn, UCI to SAN (e.g.
  /// `g1f3` to `Nf3`). Filled in by the server on every response.
  Map<String, String>? legalMoves;

  /// Number of hints the player asked for.
  int hintsUsed;

  /// Number of moves the player took back.
  int takebacks;

  /// Whether the AI coach is on: live move verdicts and pauses after
  /// mistakes. Every game is analysed for the review either way.
  bool coachEnabled;

  /// The start position when the game did not start from the initial
  /// position (lessons).
  String? startFen;

  /// The opening course or position lesson this game practises, if any.
  String? lessonId;

  /// The coach paused the game after the player's mistake and waits for
  /// the player to retry or play on.
  bool awaitingDecision;

  /// How often the player retried a move after a coach warning.
  int retries;

  /// Engine analysis of recent positions, as JSON.
  String? analysisCache;

  /// The coach's verdict on the player's last move. Filled in by the
  /// server after a move.
  _ix39qary.MoveAnalysis? lastFeedback;

  /// The verdict on the computer's last move. Filled in by the server.
  _ix39qary.MoveAnalysis? opponentFeedback;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ChessGame]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ChessGame copyWith({
    int? id,
    _is.UuidValue? userId = const _is.$UndefinedUuidValue(),
    int? level,
    _ivqn4l49.PlayerColor? playerColor,
    List<String>? moves,
    List<String>? sanMoves,
    String? fen,
    _i2ao9ybe.GameStatus? status,
    _ivjkg4d2.GameEndReason? endReason,
    int? evalCp,
    int? evalMate,
    Map<String, String>? legalMoves = const _is.$UndefinedMap<String, String>(),
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    String? startFen,
    String? lessonId,
    bool? awaitingDecision,
    int? retries,
    String? analysisCache,
    _ix39qary.MoveAnalysis? lastFeedback =
        const _UndefinedChessGame$lastFeedback(),
    _ix39qary.MoveAnalysis? opponentFeedback =
        const _UndefinedChessGame$lastFeedback(),
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChessGame',
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId?.toJson(),
      'level': level,
      'playerColor': playerColor.toJson(),
      'moves': moves.toJson(),
      'sanMoves': sanMoves.toJson(),
      'fen': fen,
      'status': status.toJson(),
      if (endReason != null) 'endReason': endReason?.toJson(),
      if (evalCp != null) 'evalCp': evalCp,
      if (evalMate != null) 'evalMate': evalMate,
      if (legalMoves != null) 'legalMoves': legalMoves?.toJson(),
      'hintsUsed': hintsUsed,
      'takebacks': takebacks,
      'coachEnabled': coachEnabled,
      if (startFen != null) 'startFen': startFen,
      if (lessonId != null) 'lessonId': lessonId,
      'awaitingDecision': awaitingDecision,
      'retries': retries,
      if (analysisCache != null) 'analysisCache': analysisCache,
      if (lastFeedback != null) 'lastFeedback': lastFeedback?.toJson(),
      if (opponentFeedback != null)
        'opponentFeedback': opponentFeedback?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ChessGame',
      if (id != null) 'id': id,
      'level': level,
      'playerColor': playerColor.toJson(),
      'moves': moves.toJson(),
      'sanMoves': sanMoves.toJson(),
      'fen': fen,
      'status': status.toJson(),
      if (endReason != null) 'endReason': endReason?.toJson(),
      if (evalCp != null) 'evalCp': evalCp,
      if (evalMate != null) 'evalMate': evalMate,
      if (legalMoves != null) 'legalMoves': legalMoves?.toJson(),
      'hintsUsed': hintsUsed,
      'takebacks': takebacks,
      'coachEnabled': coachEnabled,
      if (startFen != null) 'startFen': startFen,
      if (lessonId != null) 'lessonId': lessonId,
      'awaitingDecision': awaitingDecision,
      'retries': retries,
      if (lastFeedback != null)
        'lastFeedback': lastFeedback?.toJsonForProtocol(),
      if (opponentFeedback != null)
        'opponentFeedback': opponentFeedback?.toJsonForProtocol(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ChessGameInclude include() {
    return ChessGameInclude._();
  }

  static ChessGameIncludeList includeList({
    _is.WhereExpressionBuilder<ChessGameTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    ChessGameInclude? include,
  }) {
    return ChessGameIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedChessGame$lastFeedback extends _is.UndefinedSentinel
    implements _ix39qary.MoveAnalysis {
  const _UndefinedChessGame$lastFeedback();
}

class _ChessGameImpl extends ChessGame {
  _ChessGameImpl({
    int? id,
    _is.UuidValue? userId,
    required int level,
    required _ivqn4l49.PlayerColor playerColor,
    required List<String> moves,
    required List<String> sanMoves,
    required String fen,
    required _i2ao9ybe.GameStatus status,
    _ivjkg4d2.GameEndReason? endReason,
    int? evalCp,
    int? evalMate,
    Map<String, String>? legalMoves,
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    String? startFen,
    String? lessonId,
    bool? awaitingDecision,
    int? retries,
    String? analysisCache,
    _ix39qary.MoveAnalysis? lastFeedback,
    _ix39qary.MoveAnalysis? opponentFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         level: level,
         playerColor: playerColor,
         moves: moves,
         sanMoves: sanMoves,
         fen: fen,
         status: status,
         endReason: endReason,
         evalCp: evalCp,
         evalMate: evalMate,
         legalMoves: legalMoves,
         hintsUsed: hintsUsed,
         takebacks: takebacks,
         coachEnabled: coachEnabled,
         startFen: startFen,
         lessonId: lessonId,
         awaitingDecision: awaitingDecision,
         retries: retries,
         analysisCache: analysisCache,
         lastFeedback: lastFeedback,
         opponentFeedback: opponentFeedback,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ChessGame]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ChessGame copyWith({
    Object? id = _Undefined,
    _is.UuidValue? userId = const _is.$UndefinedUuidValue(),
    int? level,
    _ivqn4l49.PlayerColor? playerColor,
    List<String>? moves,
    List<String>? sanMoves,
    String? fen,
    _i2ao9ybe.GameStatus? status,
    Object? endReason = _Undefined,
    Object? evalCp = _Undefined,
    Object? evalMate = _Undefined,
    Map<String, String>? legalMoves = const _is.$UndefinedMap<String, String>(),
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    Object? startFen = _Undefined,
    Object? lessonId = _Undefined,
    bool? awaitingDecision,
    int? retries,
    Object? analysisCache = _Undefined,
    _ix39qary.MoveAnalysis? lastFeedback =
        const _UndefinedChessGame$lastFeedback(),
    _ix39qary.MoveAnalysis? opponentFeedback =
        const _UndefinedChessGame$lastFeedback(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChessGame(
      id: id is int? ? id : this.id,
      userId: userId is _is.UndefinedSentinel ? this.userId : userId,
      level: level ?? this.level,
      playerColor: playerColor ?? this.playerColor,
      moves: moves ?? this.moves.map((e0) => e0).toList(),
      sanMoves: sanMoves ?? this.sanMoves.map((e0) => e0).toList(),
      fen: fen ?? this.fen,
      status: status ?? this.status,
      endReason: endReason is _ivjkg4d2.GameEndReason?
          ? endReason
          : this.endReason,
      evalCp: evalCp is int? ? evalCp : this.evalCp,
      evalMate: evalMate is int? ? evalMate : this.evalMate,
      legalMoves: legalMoves is _is.UndefinedSentinel
          ? this.legalMoves?.map(
              (
                key0,
                value0,
              ) => MapEntry(
                key0,
                value0,
              ),
            )
          : legalMoves,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      takebacks: takebacks ?? this.takebacks,
      coachEnabled: coachEnabled ?? this.coachEnabled,
      startFen: startFen is String? ? startFen : this.startFen,
      lessonId: lessonId is String? ? lessonId : this.lessonId,
      awaitingDecision: awaitingDecision ?? this.awaitingDecision,
      retries: retries ?? this.retries,
      analysisCache: analysisCache is String?
          ? analysisCache
          : this.analysisCache,
      lastFeedback: lastFeedback is _is.UndefinedSentinel
          ? this.lastFeedback?.copyWith()
          : lastFeedback,
      opponentFeedback: opponentFeedback is _is.UndefinedSentinel
          ? this.opponentFeedback?.copyWith()
          : opponentFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChessGameUpdateTable extends _is.UpdateTable<ChessGameTable> {
  ChessGameUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<int, int> level(int value) => _is.ColumnValue(
    table.level,
    value,
  );

  _is.ColumnValue<_ivqn4l49.PlayerColor, _ivqn4l49.PlayerColor> playerColor(
    _ivqn4l49.PlayerColor value,
  ) => _is.ColumnValue(
    table.playerColor,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> moves(List<String> value) =>
      _is.ColumnValue(
        table.moves,
        value,
      );

  _is.ColumnValue<List<String>, List<String>> sanMoves(List<String> value) =>
      _is.ColumnValue(
        table.sanMoves,
        value,
      );

  _is.ColumnValue<String, String> fen(String value) => _is.ColumnValue(
    table.fen,
    value,
  );

  _is.ColumnValue<_i2ao9ybe.GameStatus, _i2ao9ybe.GameStatus> status(
    _i2ao9ybe.GameStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_ivjkg4d2.GameEndReason, _ivjkg4d2.GameEndReason> endReason(
    _ivjkg4d2.GameEndReason? value,
  ) => _is.ColumnValue(
    table.endReason,
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

  _is.ColumnValue<int, int> hintsUsed(int value) => _is.ColumnValue(
    table.hintsUsed,
    value,
  );

  _is.ColumnValue<int, int> takebacks(int value) => _is.ColumnValue(
    table.takebacks,
    value,
  );

  _is.ColumnValue<bool, bool> coachEnabled(bool value) => _is.ColumnValue(
    table.coachEnabled,
    value,
  );

  _is.ColumnValue<String, String> startFen(String? value) => _is.ColumnValue(
    table.startFen,
    value,
  );

  _is.ColumnValue<String, String> lessonId(String? value) => _is.ColumnValue(
    table.lessonId,
    value,
  );

  _is.ColumnValue<bool, bool> awaitingDecision(bool value) => _is.ColumnValue(
    table.awaitingDecision,
    value,
  );

  _is.ColumnValue<int, int> retries(int value) => _is.ColumnValue(
    table.retries,
    value,
  );

  _is.ColumnValue<String, String> analysisCache(String? value) =>
      _is.ColumnValue(
        table.analysisCache,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ChessGameTable extends _is.Table<int?> {
  ChessGameTable({super.tableRelation}) : super(tableName: 'chess_game') {
    updateTable = ChessGameUpdateTable(this);
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    level = _is.ColumnInt(
      'level',
      this,
    );
    playerColor = _is.ColumnEnum(
      'playerColor',
      this,
      _is.EnumSerialization.byName,
    );
    moves = _is.ColumnSerializable<List<String>>(
      'moves',
      this,
    );
    sanMoves = _is.ColumnSerializable<List<String>>(
      'sanMoves',
      this,
    );
    fen = _is.ColumnString(
      'fen',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    endReason = _is.ColumnEnum(
      'endReason',
      this,
      _is.EnumSerialization.byName,
    );
    evalCp = _is.ColumnInt(
      'evalCp',
      this,
    );
    evalMate = _is.ColumnInt(
      'evalMate',
      this,
    );
    hintsUsed = _is.ColumnInt(
      'hintsUsed',
      this,
      hasDefault: true,
    );
    takebacks = _is.ColumnInt(
      'takebacks',
      this,
      hasDefault: true,
    );
    coachEnabled = _is.ColumnBool(
      'coachEnabled',
      this,
      hasDefault: true,
    );
    startFen = _is.ColumnString(
      'startFen',
      this,
    );
    lessonId = _is.ColumnString(
      'lessonId',
      this,
    );
    awaitingDecision = _is.ColumnBool(
      'awaitingDecision',
      this,
      hasDefault: true,
    );
    retries = _is.ColumnInt(
      'retries',
      this,
      hasDefault: true,
    );
    analysisCache = _is.ColumnString(
      'analysisCache',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final ChessGameUpdateTable updateTable;

  /// The auth user who plays this game.
  late final _is.ColumnUuid userId;

  /// Index of the difficulty level, see `ChessLevel`.
  late final _is.ColumnInt level;

  /// The side the human plays.
  late final _is.ColumnEnum<_ivqn4l49.PlayerColor> playerColor;

  /// Moves played from the start position, in UCI notation (e.g. `e2e4`).
  late final _is.ColumnSerializable<List<String>> moves;

  /// The same moves in standard algebraic notation (e.g. `e4`, `Nf3`).
  late final _is.ColumnSerializable<List<String>> sanMoves;

  /// The current position as FEN.
  late final _is.ColumnString fen;

  /// Whether the game is still going, and if not, how it ended.
  late final _is.ColumnEnum<_i2ao9ybe.GameStatus> status;

  /// Why the game ended; null while it is active.
  late final _is.ColumnEnum<_ivjkg4d2.GameEndReason> endReason;

  /// Engine evaluation in centipawns from White's point of view.
  late final _is.ColumnInt evalCp;

  /// Moves to mate from White's point of view (negative: Black mates).
  late final _is.ColumnInt evalMate;

  /// Number of hints the player asked for.
  late final _is.ColumnInt hintsUsed;

  /// Number of moves the player took back.
  late final _is.ColumnInt takebacks;

  /// Whether the AI coach is on: live move verdicts and pauses after
  /// mistakes. Every game is analysed for the review either way.
  late final _is.ColumnBool coachEnabled;

  /// The start position when the game did not start from the initial
  /// position (lessons).
  late final _is.ColumnString startFen;

  /// The opening course or position lesson this game practises, if any.
  late final _is.ColumnString lessonId;

  /// The coach paused the game after the player's mistake and waits for
  /// the player to retry or play on.
  late final _is.ColumnBool awaitingDecision;

  /// How often the player retried a move after a coach warning.
  late final _is.ColumnInt retries;

  /// Engine analysis of recent positions, as JSON.
  late final _is.ColumnString analysisCache;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    level,
    playerColor,
    moves,
    sanMoves,
    fen,
    status,
    endReason,
    evalCp,
    evalMate,
    hintsUsed,
    takebacks,
    coachEnabled,
    startFen,
    lessonId,
    awaitingDecision,
    retries,
    analysisCache,
    createdAt,
    updatedAt,
  ];
}

class ChessGameInclude extends _is.IncludeObject {
  ChessGameInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ChessGame.t;
}

class ChessGameIncludeList extends _is.IncludeList {
  ChessGameIncludeList._({
    _is.WhereExpressionBuilder<ChessGameTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ChessGame.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ChessGame.t;
}

class ChessGameRepository {
  const ChessGameRepository._();

  /// Returns a list of [ChessGame]s matching the given query parameters.
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
  Future<List<ChessGame>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChessGameTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ChessGame>(
      where: where?.call(ChessGame.t),
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ChessGame]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ChessGame.t`.
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
  _ida.Stream<List<ChessGame>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChessGameTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ChessGame>(
      where: where?.call(ChessGame.t),
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ChessGame] matching the given query parameters.
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
  Future<ChessGame?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChessGameTable>? where,
    int? offset,
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ChessGame>(
      where: where?.call(ChessGame.t),
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ChessGame] by its [id] or null if no such row exists.
  Future<ChessGame?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ChessGame>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ChessGame]s in the list and returns the inserted rows.
  ///
  /// The returned [ChessGame]s will have their `id` fields set.
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
  Future<List<ChessGame>> insert(
    _is.DatabaseSession session,
    List<ChessGame> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ChessGame>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ChessGame] and returns the inserted row.
  ///
  /// The returned [ChessGame] will have its `id` field set.
  Future<ChessGame> insertRow(
    _is.DatabaseSession session,
    ChessGame row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ChessGame>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ChessGame]s in the list and returns the resulting rows.
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
  /// The returned [ChessGame]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ChessGame>> upsert(
    _is.DatabaseSession session,
    List<ChessGame> rows, {
    required _is.ColumnSelections<ChessGameTable> conflictColumns,
    _is.ColumnSelections<ChessGameTable>? updateColumns,
    _is.WhereExpressionBuilder<ChessGameTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ChessGame>(
      rows,
      conflictColumns: conflictColumns(ChessGame.t),
      updateColumns: updateColumns?.call(ChessGame.t),
      updateWhere: updateWhere?.call(ChessGame.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ChessGame] and returns the resulting row.
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
  /// The returned [ChessGame] will have its `id` field set.
  Future<ChessGame?> upsertRow(
    _is.DatabaseSession session,
    ChessGame row, {
    required _is.ColumnSelections<ChessGameTable> conflictColumns,
    _is.ColumnSelections<ChessGameTable>? updateColumns,
    _is.WhereExpressionBuilder<ChessGameTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ChessGame>(
      row,
      conflictColumns: conflictColumns(ChessGame.t),
      updateColumns: updateColumns?.call(ChessGame.t),
      updateWhere: updateWhere?.call(ChessGame.t),
      transaction: transaction,
    );
  }

  /// Updates all [ChessGame]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ChessGame>> update(
    _is.DatabaseSession session,
    List<ChessGame> rows, {
    _is.ColumnSelections<ChessGameTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ChessGame>(
      rows,
      columns: columns?.call(ChessGame.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ChessGame]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ChessGame> updateRow(
    _is.DatabaseSession session,
    ChessGame row, {
    _is.ColumnSelections<ChessGameTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ChessGame>(
      row,
      columns: columns?.call(ChessGame.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChessGame] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ChessGame?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ChessGameUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ChessGame>(
      id,
      columnValues: columnValues(ChessGame.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ChessGame]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ChessGame>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ChessGameUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ChessGameTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ChessGame>(
      columnValues: columnValues(ChessGame.t.updateTable),
      where: where(ChessGame.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ChessGame]s in the list and returns the deleted rows.
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
  Future<List<ChessGame>> delete(
    _is.DatabaseSession session,
    List<ChessGame> rows, {
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ChessGame>(
      rows,
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ChessGame].
  Future<ChessGame> deleteRow(
    _is.DatabaseSession session,
    ChessGame row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ChessGame>(
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
  Future<List<ChessGame>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ChessGameTable> where,
    _is.OrderByBuilder<ChessGameTable>? orderBy,
    _is.OrderByListBuilder<ChessGameTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ChessGame>(
      where: where(ChessGame.t),
      orderBy: orderBy?.call(ChessGame.t),
      orderByList: orderByList?.call(ChessGame.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChessGameTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ChessGame>(
      where: where?.call(ChessGame.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ChessGame] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ChessGameTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ChessGame>(
      where: where(ChessGame.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
