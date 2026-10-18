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
import '../../chess/models/player_color.dart' as _ivqn4l49;
import '../../coach/models/move_class.dart' as _iua1gast;

/// A position from the player's own games where they went wrong.
abstract class MistakeDrill
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MistakeDrill._({
    required this.analysisId,
    required this.fen,
    required this.side,
    required this.playedSan,
    required this.classification,
    required this.legalMoves,
    required this.remaining,
    required this.playedAt,
  });

  factory MistakeDrill({
    required int analysisId,
    required String fen,
    required _ivqn4l49.PlayerColor side,
    required String playedSan,
    required _iua1gast.MoveClass classification,
    required Map<String, String> legalMoves,
    required int remaining,
    required DateTime playedAt,
  }) = _MistakeDrillImpl;

  factory MistakeDrill.fromJson(Map<String, dynamic> jsonSerialization) {
    return MistakeDrill(
      analysisId: jsonSerialization['analysisId'] as int,
      fen: jsonSerialization['fen'] as String,
      side: _ivqn4l49.PlayerColor.fromJson(
        (jsonSerialization['side'] as String),
      ),
      playedSan: jsonSerialization['playedSan'] as String,
      classification: _iua1gast.MoveClass.fromJson(
        (jsonSerialization['classification'] as String),
      ),
      legalMoves: _iqtjiupe.Protocol().deserialize<Map<String, String>>(
        jsonSerialization['legalMoves'],
      ),
      remaining: jsonSerialization['remaining'] as int,
      playedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['playedAt'],
      ),
    );
  }

  int analysisId;

  String fen;

  _ivqn4l49.PlayerColor side;

  /// What the player played in the game.
  String playedSan;

  _iua1gast.MoveClass classification;

  Map<String, String> legalMoves;

  /// How many positions are waiting, including this one.
  int remaining;

  DateTime playedAt;

  /// Returns a shallow copy of this [MistakeDrill]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MistakeDrill copyWith({
    int? analysisId,
    String? fen,
    _ivqn4l49.PlayerColor? side,
    String? playedSan,
    _iua1gast.MoveClass? classification,
    Map<String, String>? legalMoves,
    int? remaining,
    DateTime? playedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MistakeDrill',
      'analysisId': analysisId,
      'fen': fen,
      'side': side.toJson(),
      'playedSan': playedSan,
      'classification': classification.toJson(),
      'legalMoves': legalMoves.toJson(),
      'remaining': remaining,
      'playedAt': playedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MistakeDrill',
      'analysisId': analysisId,
      'fen': fen,
      'side': side.toJson(),
      'playedSan': playedSan,
      'classification': classification.toJson(),
      'legalMoves': legalMoves.toJson(),
      'remaining': remaining,
      'playedAt': playedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MistakeDrillImpl extends MistakeDrill {
  _MistakeDrillImpl({
    required int analysisId,
    required String fen,
    required _ivqn4l49.PlayerColor side,
    required String playedSan,
    required _iua1gast.MoveClass classification,
    required Map<String, String> legalMoves,
    required int remaining,
    required DateTime playedAt,
  }) : super._(
         analysisId: analysisId,
         fen: fen,
         side: side,
         playedSan: playedSan,
         classification: classification,
         legalMoves: legalMoves,
         remaining: remaining,
         playedAt: playedAt,
       );

  /// Returns a shallow copy of this [MistakeDrill]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MistakeDrill copyWith({
    int? analysisId,
    String? fen,
    _ivqn4l49.PlayerColor? side,
    String? playedSan,
    _iua1gast.MoveClass? classification,
    Map<String, String>? legalMoves,
    int? remaining,
    DateTime? playedAt,
  }) {
    return MistakeDrill(
      analysisId: analysisId ?? this.analysisId,
      fen: fen ?? this.fen,
      side: side ?? this.side,
      playedSan: playedSan ?? this.playedSan,
      classification: classification ?? this.classification,
      legalMoves:
          legalMoves ??
          this.legalMoves.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      remaining: remaining ?? this.remaining,
      playedAt: playedAt ?? this.playedAt,
    );
  }
}
