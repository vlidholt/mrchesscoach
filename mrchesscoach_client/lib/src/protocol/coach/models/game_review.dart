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
import 'package:mrchesscoach_client/src/protocol/protocol.dart' as _iqtjiupe;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../coach/models/move_analysis.dart' as _ix39qary;

/// A full review of a game: accuracy, verdicts on every move and key moments.
abstract class GameReview
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  GameReview._({
    required this.gameId,
    required this.playerAccuracy,
    required this.opponentAccuracy,
    required this.moves,
    required this.keyMoments,
    required this.playerCounts,
    required this.opponentCounts,
    required this.winGraph,
    this.summary,
    this.openingName,
  });

  factory GameReview({
    required int gameId,
    required double playerAccuracy,
    required double opponentAccuracy,
    required List<_ix39qary.MoveAnalysis> moves,
    required List<int> keyMoments,
    required Map<String, int> playerCounts,
    required Map<String, int> opponentCounts,
    required List<double> winGraph,
    String? summary,
    String? openingName,
  }) = _GameReviewImpl;

  factory GameReview.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameReview(
      gameId: jsonSerialization['gameId'] as int,
      playerAccuracy: (jsonSerialization['playerAccuracy'] as num).toDouble(),
      opponentAccuracy: (jsonSerialization['opponentAccuracy'] as num)
          .toDouble(),
      moves: _iqtjiupe.Protocol().deserialize<List<_ix39qary.MoveAnalysis>>(
        jsonSerialization['moves'],
      ),
      keyMoments: _iqtjiupe.Protocol().deserialize<List<int>>(
        jsonSerialization['keyMoments'],
      ),
      playerCounts: _iqtjiupe.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['playerCounts'],
      ),
      opponentCounts: _iqtjiupe.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['opponentCounts'],
      ),
      winGraph: _iqtjiupe.Protocol().deserialize<List<double>>(
        jsonSerialization['winGraph'],
      ),
      summary: jsonSerialization['summary'] as String?,
      openingName: jsonSerialization['openingName'] as String?,
    );
  }

  int gameId;

  double playerAccuracy;

  double opponentAccuracy;

  /// Every move with its verdict, in order.
  List<_ix39qary.MoveAnalysis> moves;

  /// Plies worth studying: the biggest swings and the best moves.
  List<int> keyMoments;

  /// Count of each classification for the player's moves, by name.
  Map<String, int> playerCounts;

  Map<String, int> opponentCounts;

  /// White's winning chances (0-100) before each move and after the last.
  List<double> winGraph;

  /// The coach's written summary, if available.
  String? summary;

  /// Name of the opening, if recognised.
  String? openingName;

  /// Returns a shallow copy of this [GameReview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  GameReview copyWith({
    int? gameId,
    double? playerAccuracy,
    double? opponentAccuracy,
    List<_ix39qary.MoveAnalysis>? moves,
    List<int>? keyMoments,
    Map<String, int>? playerCounts,
    Map<String, int>? opponentCounts,
    List<double>? winGraph,
    String? summary,
    String? openingName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameReview',
      'gameId': gameId,
      'playerAccuracy': playerAccuracy,
      'opponentAccuracy': opponentAccuracy,
      'moves': moves.toJson(valueToJson: (v) => v.toJson()),
      'keyMoments': keyMoments.toJson(),
      'playerCounts': playerCounts.toJson(),
      'opponentCounts': opponentCounts.toJson(),
      'winGraph': winGraph.toJson(),
      if (summary != null) 'summary': summary,
      if (openingName != null) 'openingName': openingName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameReview',
      'gameId': gameId,
      'playerAccuracy': playerAccuracy,
      'opponentAccuracy': opponentAccuracy,
      'moves': moves.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'keyMoments': keyMoments.toJson(),
      'playerCounts': playerCounts.toJson(),
      'opponentCounts': opponentCounts.toJson(),
      'winGraph': winGraph.toJson(),
      if (summary != null) 'summary': summary,
      if (openingName != null) 'openingName': openingName,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameReviewImpl extends GameReview {
  _GameReviewImpl({
    required int gameId,
    required double playerAccuracy,
    required double opponentAccuracy,
    required List<_ix39qary.MoveAnalysis> moves,
    required List<int> keyMoments,
    required Map<String, int> playerCounts,
    required Map<String, int> opponentCounts,
    required List<double> winGraph,
    String? summary,
    String? openingName,
  }) : super._(
         gameId: gameId,
         playerAccuracy: playerAccuracy,
         opponentAccuracy: opponentAccuracy,
         moves: moves,
         keyMoments: keyMoments,
         playerCounts: playerCounts,
         opponentCounts: opponentCounts,
         winGraph: winGraph,
         summary: summary,
         openingName: openingName,
       );

  /// Returns a shallow copy of this [GameReview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  GameReview copyWith({
    int? gameId,
    double? playerAccuracy,
    double? opponentAccuracy,
    List<_ix39qary.MoveAnalysis>? moves,
    List<int>? keyMoments,
    Map<String, int>? playerCounts,
    Map<String, int>? opponentCounts,
    List<double>? winGraph,
    Object? summary = _Undefined,
    Object? openingName = _Undefined,
  }) {
    return GameReview(
      gameId: gameId ?? this.gameId,
      playerAccuracy: playerAccuracy ?? this.playerAccuracy,
      opponentAccuracy: opponentAccuracy ?? this.opponentAccuracy,
      moves: moves ?? this.moves.map((e0) => e0.copyWith()).toList(),
      keyMoments: keyMoments ?? this.keyMoments.map((e0) => e0).toList(),
      playerCounts:
          playerCounts ??
          this.playerCounts.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      opponentCounts:
          opponentCounts ??
          this.opponentCounts.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      winGraph: winGraph ?? this.winGraph.map((e0) => e0).toList(),
      summary: summary is String? ? summary : this.summary,
      openingName: openingName is String? ? openingName : this.openingName,
    );
  }
}
