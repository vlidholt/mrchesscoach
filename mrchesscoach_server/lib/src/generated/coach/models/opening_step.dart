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
import 'package:mrchesscoach_server/src/generated/protocol.dart' as _idwhoq0v;
import 'package:serverpod/serverpod.dart' as _is;

/// One move of an opening course.
abstract class OpeningStep
    implements _is.SerializableModel, _is.ProtocolSerialization {
  OpeningStep._({
    required this.san,
    required this.uci,
    required this.fen,
    required this.comment,
    required this.arrows,
    required this.byStudent,
  });

  factory OpeningStep({
    required String san,
    required String uci,
    required String fen,
    required String comment,
    required List<String> arrows,
    required bool byStudent,
  }) = _OpeningStepImpl;

  factory OpeningStep.fromJson(Map<String, dynamic> jsonSerialization) {
    return OpeningStep(
      san: jsonSerialization['san'] as String,
      uci: jsonSerialization['uci'] as String,
      fen: jsonSerialization['fen'] as String,
      comment: jsonSerialization['comment'] as String,
      arrows: _idwhoq0v.Protocol().deserialize<List<String>>(
        jsonSerialization['arrows'],
      ),
      byStudent: _is.BoolJsonExtension.fromJson(jsonSerialization['byStudent']),
    );
  }

  String san;

  String uci;

  /// The position after the move.
  String fen;

  String comment;

  List<String> arrows;

  /// Whether the student plays this move in the course.
  bool byStudent;

  /// Returns a shallow copy of this [OpeningStep]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OpeningStep copyWith({
    String? san,
    String? uci,
    String? fen,
    String? comment,
    List<String>? arrows,
    bool? byStudent,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OpeningStep',
      'san': san,
      'uci': uci,
      'fen': fen,
      'comment': comment,
      'arrows': arrows.toJson(),
      'byStudent': byStudent,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OpeningStep',
      'san': san,
      'uci': uci,
      'fen': fen,
      'comment': comment,
      'arrows': arrows.toJson(),
      'byStudent': byStudent,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _OpeningStepImpl extends OpeningStep {
  _OpeningStepImpl({
    required String san,
    required String uci,
    required String fen,
    required String comment,
    required List<String> arrows,
    required bool byStudent,
  }) : super._(
         san: san,
         uci: uci,
         fen: fen,
         comment: comment,
         arrows: arrows,
         byStudent: byStudent,
       );

  /// Returns a shallow copy of this [OpeningStep]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OpeningStep copyWith({
    String? san,
    String? uci,
    String? fen,
    String? comment,
    List<String>? arrows,
    bool? byStudent,
  }) {
    return OpeningStep(
      san: san ?? this.san,
      uci: uci ?? this.uci,
      fen: fen ?? this.fen,
      comment: comment ?? this.comment,
      arrows: arrows ?? this.arrows.map((e0) => e0).toList(),
      byStudent: byStudent ?? this.byStudent,
    );
  }
}
