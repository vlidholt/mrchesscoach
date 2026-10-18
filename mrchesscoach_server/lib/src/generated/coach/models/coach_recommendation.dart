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

/// Something the coach suggests practising next.
abstract class CoachRecommendation
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CoachRecommendation._({
    required this.kind,
    this.ref,
    required this.title,
    required this.body,
  });

  factory CoachRecommendation({
    required String kind,
    String? ref,
    required String title,
    required String body,
  }) = _CoachRecommendationImpl;

  factory CoachRecommendation.fromJson(Map<String, dynamic> jsonSerialization) {
    return CoachRecommendation(
      kind: jsonSerialization['kind'] as String,
      ref: jsonSerialization['ref'] as String?,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String,
    );
  }

  /// `puzzles`, `lesson`, `opening`, `mistakes` or `play`.
  String kind;

  /// A puzzle theme key, lesson id or opening id, depending on the kind.
  String? ref;

  String title;

  String body;

  /// Returns a shallow copy of this [CoachRecommendation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CoachRecommendation copyWith({
    String? kind,
    String? ref,
    String? title,
    String? body,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CoachRecommendation',
      'kind': kind,
      if (ref != null) 'ref': ref,
      'title': title,
      'body': body,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CoachRecommendation',
      'kind': kind,
      if (ref != null) 'ref': ref,
      'title': title,
      'body': body,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CoachRecommendationImpl extends CoachRecommendation {
  _CoachRecommendationImpl({
    required String kind,
    String? ref,
    required String title,
    required String body,
  }) : super._(
         kind: kind,
         ref: ref,
         title: title,
         body: body,
       );

  /// Returns a shallow copy of this [CoachRecommendation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CoachRecommendation copyWith({
    String? kind,
    Object? ref = _Undefined,
    String? title,
    String? body,
  }) {
    return CoachRecommendation(
      kind: kind ?? this.kind,
      ref: ref is String? ? ref : this.ref,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}
