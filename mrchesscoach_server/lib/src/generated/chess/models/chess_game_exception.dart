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

/// Thrown when a game action is not allowed, such as an illegal move.
abstract class ChessGameException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  ChessGameException._({required this.message});

  factory ChessGameException({required String message}) =
      _ChessGameExceptionImpl;

  factory ChessGameException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChessGameException(message: jsonSerialization['message'] as String);
  }

  String message;

  /// Returns a shallow copy of this [ChessGameException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ChessGameException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChessGameException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ChessGameException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ChessGameException(message: $message)';
  }
}

class _ChessGameExceptionImpl extends ChessGameException {
  _ChessGameExceptionImpl({required String message})
    : super._(message: message);

  /// Returns a shallow copy of this [ChessGameException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ChessGameException copyWith({String? message}) {
    return ChessGameException(message: message ?? this.message);
  }
}
