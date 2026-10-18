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

/// One message in a conversation with the coach.
abstract class CoachChatTurn
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CoachChatTurn._({
    required this.fromCoach,
    required this.text,
  });

  factory CoachChatTurn({
    required bool fromCoach,
    required String text,
  }) = _CoachChatTurnImpl;

  factory CoachChatTurn.fromJson(Map<String, dynamic> jsonSerialization) {
    return CoachChatTurn(
      fromCoach: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['fromCoach'],
      ),
      text: jsonSerialization['text'] as String,
    );
  }

  bool fromCoach;

  String text;

  /// Returns a shallow copy of this [CoachChatTurn]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CoachChatTurn copyWith({
    bool? fromCoach,
    String? text,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CoachChatTurn',
      'fromCoach': fromCoach,
      'text': text,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CoachChatTurn',
      'fromCoach': fromCoach,
      'text': text,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _CoachChatTurnImpl extends CoachChatTurn {
  _CoachChatTurnImpl({
    required bool fromCoach,
    required String text,
  }) : super._(
         fromCoach: fromCoach,
         text: text,
       );

  /// Returns a shallow copy of this [CoachChatTurn]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CoachChatTurn copyWith({
    bool? fromCoach,
    String? text,
  }) {
    return CoachChatTurn(
      fromCoach: fromCoach ?? this.fromCoach,
      text: text ?? this.text,
    );
  }
}
