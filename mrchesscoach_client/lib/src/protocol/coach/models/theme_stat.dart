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

/// Success rate on one theme (puzzle theme or mistake motif).
abstract class ThemeStat
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ThemeStat._({
    required this.key,
    required this.name,
    required this.attempts,
    required this.successes,
  });

  factory ThemeStat({
    required String key,
    required String name,
    required int attempts,
    required int successes,
  }) = _ThemeStatImpl;

  factory ThemeStat.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeStat(
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      attempts: jsonSerialization['attempts'] as int,
      successes: jsonSerialization['successes'] as int,
    );
  }

  String key;

  String name;

  int attempts;

  int successes;

  /// Returns a shallow copy of this [ThemeStat]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ThemeStat copyWith({
    String? key,
    String? name,
    int? attempts,
    int? successes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeStat',
      'key': key,
      'name': name,
      'attempts': attempts,
      'successes': successes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeStat',
      'key': key,
      'name': name,
      'attempts': attempts,
      'successes': successes,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ThemeStatImpl extends ThemeStat {
  _ThemeStatImpl({
    required String key,
    required String name,
    required int attempts,
    required int successes,
  }) : super._(
         key: key,
         name: name,
         attempts: attempts,
         successes: successes,
       );

  /// Returns a shallow copy of this [ThemeStat]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ThemeStat copyWith({
    String? key,
    String? name,
    int? attempts,
    int? successes,
  }) {
    return ThemeStat(
      key: key ?? this.key,
      name: name ?? this.name,
      attempts: attempts ?? this.attempts,
      successes: successes ?? this.successes,
    );
  }
}
