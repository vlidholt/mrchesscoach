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
import '../../chess/models/player_color.dart' as _ivqn4l49;
import '../../coach/models/opening_step.dart' as _iztgav30;

/// An opening course with its moves and commentary.
abstract class OpeningCourseInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  OpeningCourseInfo._({
    required this.id,
    required this.name,
    required this.eco,
    required this.side,
    required this.level,
    required this.tagline,
    required this.summary,
    required this.ideas,
    required this.steps,
    required this.family,
    required this.completed,
  });

  factory OpeningCourseInfo({
    required String id,
    required String name,
    required String eco,
    required _ivqn4l49.PlayerColor side,
    required String level,
    required String tagline,
    required String summary,
    required List<String> ideas,
    required List<_iztgav30.OpeningStep> steps,
    required String family,
    required bool completed,
  }) = _OpeningCourseInfoImpl;

  factory OpeningCourseInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return OpeningCourseInfo(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      eco: jsonSerialization['eco'] as String,
      side: _ivqn4l49.PlayerColor.fromJson(
        (jsonSerialization['side'] as String),
      ),
      level: jsonSerialization['level'] as String,
      tagline: jsonSerialization['tagline'] as String,
      summary: jsonSerialization['summary'] as String,
      ideas: _idwhoq0v.Protocol().deserialize<List<String>>(
        jsonSerialization['ideas'],
      ),
      steps: _idwhoq0v.Protocol().deserialize<List<_iztgav30.OpeningStep>>(
        jsonSerialization['steps'],
      ),
      family: jsonSerialization['family'] as String,
      completed: _is.BoolJsonExtension.fromJson(jsonSerialization['completed']),
    );
  }

  String id;

  String name;

  String eco;

  _ivqn4l49.PlayerColor side;

  String level;

  String tagline;

  String summary;

  List<String> ideas;

  List<_iztgav30.OpeningStep> steps;

  /// The Lichess opening tag used for trap puzzles.
  String family;

  bool completed;

  /// Returns a shallow copy of this [OpeningCourseInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OpeningCourseInfo copyWith({
    String? id,
    String? name,
    String? eco,
    _ivqn4l49.PlayerColor? side,
    String? level,
    String? tagline,
    String? summary,
    List<String>? ideas,
    List<_iztgav30.OpeningStep>? steps,
    String? family,
    bool? completed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OpeningCourseInfo',
      'id': id,
      'name': name,
      'eco': eco,
      'side': side.toJson(),
      'level': level,
      'tagline': tagline,
      'summary': summary,
      'ideas': ideas.toJson(),
      'steps': steps.toJson(valueToJson: (v) => v.toJson()),
      'family': family,
      'completed': completed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OpeningCourseInfo',
      'id': id,
      'name': name,
      'eco': eco,
      'side': side.toJson(),
      'level': level,
      'tagline': tagline,
      'summary': summary,
      'ideas': ideas.toJson(),
      'steps': steps.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'family': family,
      'completed': completed,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _OpeningCourseInfoImpl extends OpeningCourseInfo {
  _OpeningCourseInfoImpl({
    required String id,
    required String name,
    required String eco,
    required _ivqn4l49.PlayerColor side,
    required String level,
    required String tagline,
    required String summary,
    required List<String> ideas,
    required List<_iztgav30.OpeningStep> steps,
    required String family,
    required bool completed,
  }) : super._(
         id: id,
         name: name,
         eco: eco,
         side: side,
         level: level,
         tagline: tagline,
         summary: summary,
         ideas: ideas,
         steps: steps,
         family: family,
         completed: completed,
       );

  /// Returns a shallow copy of this [OpeningCourseInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OpeningCourseInfo copyWith({
    String? id,
    String? name,
    String? eco,
    _ivqn4l49.PlayerColor? side,
    String? level,
    String? tagline,
    String? summary,
    List<String>? ideas,
    List<_iztgav30.OpeningStep>? steps,
    String? family,
    bool? completed,
  }) {
    return OpeningCourseInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      eco: eco ?? this.eco,
      side: side ?? this.side,
      level: level ?? this.level,
      tagline: tagline ?? this.tagline,
      summary: summary ?? this.summary,
      ideas: ideas ?? this.ideas.map((e0) => e0).toList(),
      steps: steps ?? this.steps.map((e0) => e0.copyWith()).toList(),
      family: family ?? this.family,
      completed: completed ?? this.completed,
    );
  }
}
