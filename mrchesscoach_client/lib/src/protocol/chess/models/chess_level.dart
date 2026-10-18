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

/// A difficulty level the computer can play at.
abstract class ChessLevel
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ChessLevel._({
    required this.index,
    required this.name,
    required this.description,
    required this.rating,
  });

  factory ChessLevel({
    required int index,
    required String name,
    required String description,
    required int rating,
  }) = _ChessLevelImpl;

  factory ChessLevel.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChessLevel(
      index: jsonSerialization['index'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      rating: jsonSerialization['rating'] as int,
    );
  }

  /// Index used when starting a game.
  int index;

  /// Display name, e.g. "Club player".
  String name;

  /// One-line description for the level picker.
  String description;

  /// Approximate playing strength (Elo).
  int rating;

  /// Returns a shallow copy of this [ChessLevel]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ChessLevel copyWith({
    int? index,
    String? name,
    String? description,
    int? rating,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChessLevel',
      'index': index,
      'name': name,
      'description': description,
      'rating': rating,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ChessLevel',
      'index': index,
      'name': name,
      'description': description,
      'rating': rating,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ChessLevelImpl extends ChessLevel {
  _ChessLevelImpl({
    required int index,
    required String name,
    required String description,
    required int rating,
  }) : super._(
         index: index,
         name: name,
         description: description,
         rating: rating,
       );

  /// Returns a shallow copy of this [ChessLevel]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ChessLevel copyWith({
    int? index,
    String? name,
    String? description,
    int? rating,
  }) {
    return ChessLevel(
      index: index ?? this.index,
      name: name ?? this.name,
      description: description ?? this.description,
      rating: rating ?? this.rating,
    );
  }
}
