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

/// A position lesson: a technique to practise against the engine.
abstract class LessonInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LessonInfo._({
    required this.id,
    required this.category,
    required this.title,
    required this.tagline,
    required this.concept,
    required this.tips,
    required this.fen,
    required this.side,
    required this.goal,
    required this.targetMoves,
    required this.difficulty,
    required this.completed,
  });

  factory LessonInfo({
    required String id,
    required String category,
    required String title,
    required String tagline,
    required String concept,
    required List<String> tips,
    required String fen,
    required _ivqn4l49.PlayerColor side,
    required String goal,
    required int targetMoves,
    required int difficulty,
    required bool completed,
  }) = _LessonInfoImpl;

  factory LessonInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return LessonInfo(
      id: jsonSerialization['id'] as String,
      category: jsonSerialization['category'] as String,
      title: jsonSerialization['title'] as String,
      tagline: jsonSerialization['tagline'] as String,
      concept: jsonSerialization['concept'] as String,
      tips: _idwhoq0v.Protocol().deserialize<List<String>>(
        jsonSerialization['tips'],
      ),
      fen: jsonSerialization['fen'] as String,
      side: _ivqn4l49.PlayerColor.fromJson(
        (jsonSerialization['side'] as String),
      ),
      goal: jsonSerialization['goal'] as String,
      targetMoves: jsonSerialization['targetMoves'] as int,
      difficulty: jsonSerialization['difficulty'] as int,
      completed: _is.BoolJsonExtension.fromJson(jsonSerialization['completed']),
    );
  }

  String id;

  /// `endgame` or `middlegame`.
  String category;

  String title;

  String tagline;

  String concept;

  List<String> tips;

  String fen;

  _ivqn4l49.PlayerColor side;

  /// `win`, `draw` or `keepAdvantage`.
  String goal;

  int targetMoves;

  int difficulty;

  bool completed;

  /// Returns a shallow copy of this [LessonInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LessonInfo copyWith({
    String? id,
    String? category,
    String? title,
    String? tagline,
    String? concept,
    List<String>? tips,
    String? fen,
    _ivqn4l49.PlayerColor? side,
    String? goal,
    int? targetMoves,
    int? difficulty,
    bool? completed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LessonInfo',
      'id': id,
      'category': category,
      'title': title,
      'tagline': tagline,
      'concept': concept,
      'tips': tips.toJson(),
      'fen': fen,
      'side': side.toJson(),
      'goal': goal,
      'targetMoves': targetMoves,
      'difficulty': difficulty,
      'completed': completed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LessonInfo',
      'id': id,
      'category': category,
      'title': title,
      'tagline': tagline,
      'concept': concept,
      'tips': tips.toJson(),
      'fen': fen,
      'side': side.toJson(),
      'goal': goal,
      'targetMoves': targetMoves,
      'difficulty': difficulty,
      'completed': completed,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _LessonInfoImpl extends LessonInfo {
  _LessonInfoImpl({
    required String id,
    required String category,
    required String title,
    required String tagline,
    required String concept,
    required List<String> tips,
    required String fen,
    required _ivqn4l49.PlayerColor side,
    required String goal,
    required int targetMoves,
    required int difficulty,
    required bool completed,
  }) : super._(
         id: id,
         category: category,
         title: title,
         tagline: tagline,
         concept: concept,
         tips: tips,
         fen: fen,
         side: side,
         goal: goal,
         targetMoves: targetMoves,
         difficulty: difficulty,
         completed: completed,
       );

  /// Returns a shallow copy of this [LessonInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LessonInfo copyWith({
    String? id,
    String? category,
    String? title,
    String? tagline,
    String? concept,
    List<String>? tips,
    String? fen,
    _ivqn4l49.PlayerColor? side,
    String? goal,
    int? targetMoves,
    int? difficulty,
    bool? completed,
  }) {
    return LessonInfo(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      concept: concept ?? this.concept,
      tips: tips ?? this.tips.map((e0) => e0).toList(),
      fen: fen ?? this.fen,
      side: side ?? this.side,
      goal: goal ?? this.goal,
      targetMoves: targetMoves ?? this.targetMoves,
      difficulty: difficulty ?? this.difficulty,
      completed: completed ?? this.completed,
    );
  }
}
