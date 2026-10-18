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

/// A set of puzzles the player can train.
abstract class PuzzleTheme
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PuzzleTheme._({
    required this.key,
    required this.name,
    required this.description,
    required this.category,
    required this.count,
    required this.attempts,
    required this.successes,
  });

  factory PuzzleTheme({
    required String key,
    required String name,
    required String description,
    required String category,
    required int count,
    required int attempts,
    required int successes,
  }) = _PuzzleThemeImpl;

  factory PuzzleTheme.fromJson(Map<String, dynamic> jsonSerialization) {
    return PuzzleTheme(
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      category: jsonSerialization['category'] as String,
      count: jsonSerialization['count'] as int,
      attempts: jsonSerialization['attempts'] as int,
      successes: jsonSerialization['successes'] as int,
    );
  }

  String key;

  String name;

  String description;

  /// `tactics`, `mates`, `endgames` or `openings`.
  String category;

  int count;

  int attempts;

  int successes;

  /// Returns a shallow copy of this [PuzzleTheme]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PuzzleTheme copyWith({
    String? key,
    String? name,
    String? description,
    String? category,
    int? count,
    int? attempts,
    int? successes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PuzzleTheme',
      'key': key,
      'name': name,
      'description': description,
      'category': category,
      'count': count,
      'attempts': attempts,
      'successes': successes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PuzzleTheme',
      'key': key,
      'name': name,
      'description': description,
      'category': category,
      'count': count,
      'attempts': attempts,
      'successes': successes,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PuzzleThemeImpl extends PuzzleTheme {
  _PuzzleThemeImpl({
    required String key,
    required String name,
    required String description,
    required String category,
    required int count,
    required int attempts,
    required int successes,
  }) : super._(
         key: key,
         name: name,
         description: description,
         category: category,
         count: count,
         attempts: attempts,
         successes: successes,
       );

  /// Returns a shallow copy of this [PuzzleTheme]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PuzzleTheme copyWith({
    String? key,
    String? name,
    String? description,
    String? category,
    int? count,
    int? attempts,
    int? successes,
  }) {
    return PuzzleTheme(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      count: count ?? this.count,
      attempts: attempts ?? this.attempts,
      successes: successes ?? this.successes,
    );
  }
}
