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
import '../../chess/models/player_color.dart' as _ivqn4l49;

/// An opening course in the catalog.
abstract class OpeningSummary
    implements _is.SerializableModel, _is.ProtocolSerialization {
  OpeningSummary._({
    required this.id,
    required this.name,
    required this.eco,
    required this.side,
    required this.level,
    required this.tagline,
    required this.plies,
    required this.finalFen,
    required this.trapCount,
    required this.completed,
  });

  factory OpeningSummary({
    required String id,
    required String name,
    required String eco,
    required _ivqn4l49.PlayerColor side,
    required String level,
    required String tagline,
    required int plies,
    required String finalFen,
    required int trapCount,
    required bool completed,
  }) = _OpeningSummaryImpl;

  factory OpeningSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return OpeningSummary(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      eco: jsonSerialization['eco'] as String,
      side: _ivqn4l49.PlayerColor.fromJson(
        (jsonSerialization['side'] as String),
      ),
      level: jsonSerialization['level'] as String,
      tagline: jsonSerialization['tagline'] as String,
      plies: jsonSerialization['plies'] as int,
      finalFen: jsonSerialization['finalFen'] as String,
      trapCount: jsonSerialization['trapCount'] as int,
      completed: _is.BoolJsonExtension.fromJson(jsonSerialization['completed']),
    );
  }

  String id;

  String name;

  String eco;

  _ivqn4l49.PlayerColor side;

  String level;

  String tagline;

  int plies;

  /// The position at the end of the main line, for the card preview.
  String finalFen;

  int trapCount;

  bool completed;

  /// Returns a shallow copy of this [OpeningSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OpeningSummary copyWith({
    String? id,
    String? name,
    String? eco,
    _ivqn4l49.PlayerColor? side,
    String? level,
    String? tagline,
    int? plies,
    String? finalFen,
    int? trapCount,
    bool? completed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OpeningSummary',
      'id': id,
      'name': name,
      'eco': eco,
      'side': side.toJson(),
      'level': level,
      'tagline': tagline,
      'plies': plies,
      'finalFen': finalFen,
      'trapCount': trapCount,
      'completed': completed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OpeningSummary',
      'id': id,
      'name': name,
      'eco': eco,
      'side': side.toJson(),
      'level': level,
      'tagline': tagline,
      'plies': plies,
      'finalFen': finalFen,
      'trapCount': trapCount,
      'completed': completed,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _OpeningSummaryImpl extends OpeningSummary {
  _OpeningSummaryImpl({
    required String id,
    required String name,
    required String eco,
    required _ivqn4l49.PlayerColor side,
    required String level,
    required String tagline,
    required int plies,
    required String finalFen,
    required int trapCount,
    required bool completed,
  }) : super._(
         id: id,
         name: name,
         eco: eco,
         side: side,
         level: level,
         tagline: tagline,
         plies: plies,
         finalFen: finalFen,
         trapCount: trapCount,
         completed: completed,
       );

  /// Returns a shallow copy of this [OpeningSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OpeningSummary copyWith({
    String? id,
    String? name,
    String? eco,
    _ivqn4l49.PlayerColor? side,
    String? level,
    String? tagline,
    int? plies,
    String? finalFen,
    int? trapCount,
    bool? completed,
  }) {
    return OpeningSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      eco: eco ?? this.eco,
      side: side ?? this.side,
      level: level ?? this.level,
      tagline: tagline ?? this.tagline,
      plies: plies ?? this.plies,
      finalFen: finalFen ?? this.finalFen,
      trapCount: trapCount ?? this.trapCount,
      completed: completed ?? this.completed,
    );
  }
}
