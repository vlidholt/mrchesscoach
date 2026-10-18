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

/// What the opponent would do if it were their move.
abstract class ThreatInsight
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ThreatInsight._({
    required this.hasThreat,
    this.uci,
    this.san,
    required this.text,
  });

  factory ThreatInsight({
    required bool hasThreat,
    String? uci,
    String? san,
    required String text,
  }) = _ThreatInsightImpl;

  factory ThreatInsight.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThreatInsight(
      hasThreat: _is.BoolJsonExtension.fromJson(jsonSerialization['hasThreat']),
      uci: jsonSerialization['uci'] as String?,
      san: jsonSerialization['san'] as String?,
      text: jsonSerialization['text'] as String,
    );
  }

  bool hasThreat;

  /// The opponent's threatened move.
  String? uci;

  String? san;

  String text;

  /// Returns a shallow copy of this [ThreatInsight]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ThreatInsight copyWith({
    bool? hasThreat,
    String? uci,
    String? san,
    String? text,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThreatInsight',
      'hasThreat': hasThreat,
      if (uci != null) 'uci': uci,
      if (san != null) 'san': san,
      'text': text,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThreatInsight',
      'hasThreat': hasThreat,
      if (uci != null) 'uci': uci,
      if (san != null) 'san': san,
      'text': text,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThreatInsightImpl extends ThreatInsight {
  _ThreatInsightImpl({
    required bool hasThreat,
    String? uci,
    String? san,
    required String text,
  }) : super._(
         hasThreat: hasThreat,
         uci: uci,
         san: san,
         text: text,
       );

  /// Returns a shallow copy of this [ThreatInsight]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ThreatInsight copyWith({
    bool? hasThreat,
    Object? uci = _Undefined,
    Object? san = _Undefined,
    String? text,
  }) {
    return ThreatInsight(
      hasThreat: hasThreat ?? this.hasThreat,
      uci: uci is String? ? uci : this.uci,
      san: san is String? ? san : this.san,
      text: text ?? this.text,
    );
  }
}
