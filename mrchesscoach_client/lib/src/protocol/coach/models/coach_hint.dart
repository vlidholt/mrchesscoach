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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// A step of the hint ladder: 1 = the idea, 2 = the piece, 3 = the move.
abstract class CoachHint
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CoachHint._({
    required this.level,
    required this.text,
    this.square,
    this.uci,
    this.san,
  });

  factory CoachHint({
    required int level,
    required String text,
    String? square,
    String? uci,
    String? san,
  }) = _CoachHintImpl;

  factory CoachHint.fromJson(Map<String, dynamic> jsonSerialization) {
    return CoachHint(
      level: jsonSerialization['level'] as int,
      text: jsonSerialization['text'] as String,
      square: jsonSerialization['square'] as String?,
      uci: jsonSerialization['uci'] as String?,
      san: jsonSerialization['san'] as String?,
    );
  }

  int level;

  String text;

  /// The square of the piece to move (from level 2).
  String? square;

  /// The move (level 3).
  String? uci;

  String? san;

  /// Returns a shallow copy of this [CoachHint]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CoachHint copyWith({
    int? level,
    String? text,
    String? square,
    String? uci,
    String? san,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CoachHint',
      'level': level,
      'text': text,
      if (square != null) 'square': square,
      if (uci != null) 'uci': uci,
      if (san != null) 'san': san,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CoachHint',
      'level': level,
      'text': text,
      if (square != null) 'square': square,
      if (uci != null) 'uci': uci,
      if (san != null) 'san': san,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CoachHintImpl extends CoachHint {
  _CoachHintImpl({
    required int level,
    required String text,
    String? square,
    String? uci,
    String? san,
  }) : super._(
         level: level,
         text: text,
         square: square,
         uci: uci,
         san: san,
       );

  /// Returns a shallow copy of this [CoachHint]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CoachHint copyWith({
    int? level,
    String? text,
    Object? square = _Undefined,
    Object? uci = _Undefined,
    Object? san = _Undefined,
  }) {
    return CoachHint(
      level: level ?? this.level,
      text: text ?? this.text,
      square: square is String? ? square : this.square,
      uci: uci is String? ? uci : this.uci,
      san: san is String? ? san : this.san,
    );
  }
}
