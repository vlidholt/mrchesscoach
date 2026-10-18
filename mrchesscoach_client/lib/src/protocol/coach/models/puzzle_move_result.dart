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

/// The result of one move in a puzzle.
abstract class PuzzleMoveResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PuzzleMoveResult._({
    required this.correct,
    required this.solved,
    this.replyUci,
    this.solution,
    this.legalMoves,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.streak,
  });

  factory PuzzleMoveResult({
    required bool correct,
    required bool solved,
    String? replyUci,
    List<String>? solution,
    Map<String, String>? legalMoves,
    required int ratingBefore,
    required int ratingAfter,
    required int streak,
  }) = _PuzzleMoveResultImpl;

  factory PuzzleMoveResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return PuzzleMoveResult(
      correct: _isc.BoolJsonExtension.fromJson(jsonSerialization['correct']),
      solved: _isc.BoolJsonExtension.fromJson(jsonSerialization['solved']),
      replyUci: jsonSerialization['replyUci'] as String?,
      solution: jsonSerialization['solution'] == null
          ? null
          : _iqtjiupe.Protocol().deserialize<List<String>>(
              jsonSerialization['solution'],
            ),
      legalMoves: jsonSerialization['legalMoves'] == null
          ? null
          : _iqtjiupe.Protocol().deserialize<Map<String, String>>(
              jsonSerialization['legalMoves'],
            ),
      ratingBefore: jsonSerialization['ratingBefore'] as int,
      ratingAfter: jsonSerialization['ratingAfter'] as int,
      streak: jsonSerialization['streak'] as int,
    );
  }

  bool correct;

  /// The puzzle is complete.
  bool solved;

  /// The opponent's reply (UCI), when the puzzle continues.
  String? replyUci;

  /// The full solution (UCI), revealed after a wrong move.
  List<String>? solution;

  /// Legal moves in the new position, UCI to SAN.
  Map<String, String>? legalMoves;

  int ratingBefore;

  int ratingAfter;

  int streak;

  /// Returns a shallow copy of this [PuzzleMoveResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PuzzleMoveResult copyWith({
    bool? correct,
    bool? solved,
    String? replyUci,
    List<String>? solution = const _isc.$UndefinedList<String>(),
    Map<String, String>? legalMoves =
        const _isc.$UndefinedMap<String, String>(),
    int? ratingBefore,
    int? ratingAfter,
    int? streak,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PuzzleMoveResult',
      'correct': correct,
      'solved': solved,
      if (replyUci != null) 'replyUci': replyUci,
      if (solution != null) 'solution': solution?.toJson(),
      if (legalMoves != null) 'legalMoves': legalMoves?.toJson(),
      'ratingBefore': ratingBefore,
      'ratingAfter': ratingAfter,
      'streak': streak,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PuzzleMoveResult',
      'correct': correct,
      'solved': solved,
      if (replyUci != null) 'replyUci': replyUci,
      if (solution != null) 'solution': solution?.toJson(),
      if (legalMoves != null) 'legalMoves': legalMoves?.toJson(),
      'ratingBefore': ratingBefore,
      'ratingAfter': ratingAfter,
      'streak': streak,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PuzzleMoveResultImpl extends PuzzleMoveResult {
  _PuzzleMoveResultImpl({
    required bool correct,
    required bool solved,
    String? replyUci,
    List<String>? solution,
    Map<String, String>? legalMoves,
    required int ratingBefore,
    required int ratingAfter,
    required int streak,
  }) : super._(
         correct: correct,
         solved: solved,
         replyUci: replyUci,
         solution: solution,
         legalMoves: legalMoves,
         ratingBefore: ratingBefore,
         ratingAfter: ratingAfter,
         streak: streak,
       );

  /// Returns a shallow copy of this [PuzzleMoveResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PuzzleMoveResult copyWith({
    bool? correct,
    bool? solved,
    Object? replyUci = _Undefined,
    List<String>? solution = const _isc.$UndefinedList<String>(),
    Map<String, String>? legalMoves =
        const _isc.$UndefinedMap<String, String>(),
    int? ratingBefore,
    int? ratingAfter,
    int? streak,
  }) {
    return PuzzleMoveResult(
      correct: correct ?? this.correct,
      solved: solved ?? this.solved,
      replyUci: replyUci is String? ? replyUci : this.replyUci,
      solution: solution is _isc.UndefinedSentinel
          ? this.solution?.map((e0) => e0).toList()
          : solution,
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
      ratingBefore: ratingBefore ?? this.ratingBefore,
      ratingAfter: ratingAfter ?? this.ratingAfter,
      streak: streak ?? this.streak,
    );
  }
}
