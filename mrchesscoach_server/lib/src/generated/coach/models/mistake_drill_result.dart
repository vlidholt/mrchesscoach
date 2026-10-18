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
import 'package:serverpod/serverpod.dart' as _is;

/// The result of trying a mistake drill.
abstract class MistakeDrillResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MistakeDrillResult._({
    required this.correct,
    required this.bestUci,
    required this.bestSan,
    required this.explanation,
  });

  factory MistakeDrillResult({
    required bool correct,
    required String bestUci,
    required String bestSan,
    required String explanation,
  }) = _MistakeDrillResultImpl;

  factory MistakeDrillResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return MistakeDrillResult(
      correct: _is.BoolJsonExtension.fromJson(jsonSerialization['correct']),
      bestUci: jsonSerialization['bestUci'] as String,
      bestSan: jsonSerialization['bestSan'] as String,
      explanation: jsonSerialization['explanation'] as String,
    );
  }

  bool correct;

  /// The engine's best move.
  String bestUci;

  String bestSan;

  /// The coach's explanation of the position.
  String explanation;

  /// Returns a shallow copy of this [MistakeDrillResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MistakeDrillResult copyWith({
    bool? correct,
    String? bestUci,
    String? bestSan,
    String? explanation,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MistakeDrillResult',
      'correct': correct,
      'bestUci': bestUci,
      'bestSan': bestSan,
      'explanation': explanation,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MistakeDrillResult',
      'correct': correct,
      'bestUci': bestUci,
      'bestSan': bestSan,
      'explanation': explanation,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _MistakeDrillResultImpl extends MistakeDrillResult {
  _MistakeDrillResultImpl({
    required bool correct,
    required String bestUci,
    required String bestSan,
    required String explanation,
  }) : super._(
         correct: correct,
         bestUci: bestUci,
         bestSan: bestSan,
         explanation: explanation,
       );

  /// Returns a shallow copy of this [MistakeDrillResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MistakeDrillResult copyWith({
    bool? correct,
    String? bestUci,
    String? bestSan,
    String? explanation,
  }) {
    return MistakeDrillResult(
      correct: correct ?? this.correct,
      bestUci: bestUci ?? this.bestUci,
      bestSan: bestSan ?? this.bestSan,
      explanation: explanation ?? this.explanation,
    );
  }
}
