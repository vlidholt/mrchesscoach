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
import '../../chess/models/game_end_reason.dart' as _ivjkg4d2;
import '../../chess/models/game_status.dart' as _i2ao9ybe;
import '../../chess/models/player_color.dart' as _ivqn4l49;
import '../../coach/models/move_analysis.dart' as _ix39qary;

/// A game of chess between a signed-in player and the computer.
abstract class ChessGame
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ChessGame._({
    this.id,
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
    _ix39qary.MoveAnalysis? lastFeedback,
    _ix39qary.MoveAnalysis? opponentFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ChessGameImpl;

  factory ChessGame.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChessGame(
      id: jsonSerialization['id'] as int?,
      level: jsonSerialization['level'] as int,
      playerColor: _ivqn4l49.PlayerColor.fromJson(
        (jsonSerialization['playerColor'] as String),
      ),
      moves: _iqtjiupe.Protocol().deserialize<List<String>>(
        jsonSerialization['moves'],
      ),
      sanMoves: _iqtjiupe.Protocol().deserialize<List<String>>(
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
          : _iqtjiupe.Protocol().deserialize<Map<String, String>>(
              jsonSerialization['legalMoves'],
            ),
      hintsUsed: jsonSerialization['hintsUsed'] as int?,
      takebacks: jsonSerialization['takebacks'] as int?,
      coachEnabled: jsonSerialization['coachEnabled'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['coachEnabled']),
      startFen: jsonSerialization['startFen'] as String?,
      lessonId: jsonSerialization['lessonId'] as String?,
      awaitingDecision: jsonSerialization['awaitingDecision'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['awaitingDecision'],
            ),
      retries: jsonSerialization['retries'] as int?,
      lastFeedback: jsonSerialization['lastFeedback'] == null
          ? null
          : _iqtjiupe.Protocol().deserialize<_ix39qary.MoveAnalysis>(
              jsonSerialization['lastFeedback'],
            ),
      opponentFeedback: jsonSerialization['opponentFeedback'] == null
          ? null
          : _iqtjiupe.Protocol().deserialize<_ix39qary.MoveAnalysis>(
              jsonSerialization['opponentFeedback'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

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

  /// The coach's verdict on the player's last move. Filled in by the
  /// server after a move.
  _ix39qary.MoveAnalysis? lastFeedback;

  /// The verdict on the computer's last move. Filled in by the server.
  _ix39qary.MoveAnalysis? opponentFeedback;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ChessGame]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ChessGame copyWith({
    int? id,
    int? level,
    _ivqn4l49.PlayerColor? playerColor,
    List<String>? moves,
    List<String>? sanMoves,
    String? fen,
    _i2ao9ybe.GameStatus? status,
    _ivjkg4d2.GameEndReason? endReason,
    int? evalCp,
    int? evalMate,
    Map<String, String>? legalMoves =
        const _isc.$UndefinedMap<String, String>(),
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    String? startFen,
    String? lessonId,
    bool? awaitingDecision,
    int? retries,
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedChessGame$lastFeedback extends _isc.UndefinedSentinel
    implements _ix39qary.MoveAnalysis {
  const _UndefinedChessGame$lastFeedback();
}

class _ChessGameImpl extends ChessGame {
  _ChessGameImpl({
    int? id,
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
    _ix39qary.MoveAnalysis? lastFeedback,
    _ix39qary.MoveAnalysis? opponentFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
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
         lastFeedback: lastFeedback,
         opponentFeedback: opponentFeedback,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ChessGame]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ChessGame copyWith({
    Object? id = _Undefined,
    int? level,
    _ivqn4l49.PlayerColor? playerColor,
    List<String>? moves,
    List<String>? sanMoves,
    String? fen,
    _i2ao9ybe.GameStatus? status,
    Object? endReason = _Undefined,
    Object? evalCp = _Undefined,
    Object? evalMate = _Undefined,
    Map<String, String>? legalMoves =
        const _isc.$UndefinedMap<String, String>(),
    int? hintsUsed,
    int? takebacks,
    bool? coachEnabled,
    Object? startFen = _Undefined,
    Object? lessonId = _Undefined,
    bool? awaitingDecision,
    int? retries,
    _ix39qary.MoveAnalysis? lastFeedback =
        const _UndefinedChessGame$lastFeedback(),
    _ix39qary.MoveAnalysis? opponentFeedback =
        const _UndefinedChessGame$lastFeedback(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChessGame(
      id: id is int? ? id : this.id,
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
      legalMoves: legalMoves is _isc.UndefinedSentinel
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
      lastFeedback: lastFeedback is _isc.UndefinedSentinel
          ? this.lastFeedback?.copyWith()
          : lastFeedback,
      opponentFeedback: opponentFeedback is _isc.UndefinedSentinel
          ? this.opponentFeedback?.copyWith()
          : opponentFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
