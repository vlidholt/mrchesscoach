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

/// A puzzle as sent to the app. The solution stays on the server.
abstract class PuzzleInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PuzzleInfo._({
    required this.id,
    required this.fen,
    required this.setupMove,
    required this.rating,
    required this.themes,
    required this.solutionMoves,
    required this.legalMoves,
    required this.playerRating,
    this.setName,
  });

  factory PuzzleInfo({
    required String id,
    required String fen,
    required String setupMove,
    required int rating,
    required List<String> themes,
    required int solutionMoves,
    required Map<String, String> legalMoves,
    required int playerRating,
    String? setName,
  }) = _PuzzleInfoImpl;

  factory PuzzleInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return PuzzleInfo(
      id: jsonSerialization['id'] as String,
      fen: jsonSerialization['fen'] as String,
      setupMove: jsonSerialization['setupMove'] as String,
      rating: jsonSerialization['rating'] as int,
      themes: _iqtjiupe.Protocol().deserialize<List<String>>(
        jsonSerialization['themes'],
      ),
      solutionMoves: jsonSerialization['solutionMoves'] as int,
      legalMoves: _iqtjiupe.Protocol().deserialize<Map<String, String>>(
        jsonSerialization['legalMoves'],
      ),
      playerRating: jsonSerialization['playerRating'] as int,
      setName: jsonSerialization['setName'] as String?,
    );
  }

  String id;

  /// The position before the opponent's setup move.
  String fen;

  /// The opponent's move that sets up the puzzle (UCI).
  String setupMove;

  int rating;

  List<String> themes;

  /// Number of moves the solver has to find.
  int solutionMoves;

  /// Legal moves after the setup move, UCI to SAN.
  Map<String, String> legalMoves;

  /// The player's puzzle rating when the puzzle was served.
  int playerRating;

  /// A friendly name for the set the puzzle came from, e.g. "Forks".
  String? setName;

  /// Returns a shallow copy of this [PuzzleInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PuzzleInfo copyWith({
    String? id,
    String? fen,
    String? setupMove,
    int? rating,
    List<String>? themes,
    int? solutionMoves,
    Map<String, String>? legalMoves,
    int? playerRating,
    String? setName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PuzzleInfo',
      'id': id,
      'fen': fen,
      'setupMove': setupMove,
      'rating': rating,
      'themes': themes.toJson(),
      'solutionMoves': solutionMoves,
      'legalMoves': legalMoves.toJson(),
      'playerRating': playerRating,
      if (setName != null) 'setName': setName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PuzzleInfo',
      'id': id,
      'fen': fen,
      'setupMove': setupMove,
      'rating': rating,
      'themes': themes.toJson(),
      'solutionMoves': solutionMoves,
      'legalMoves': legalMoves.toJson(),
      'playerRating': playerRating,
      if (setName != null) 'setName': setName,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PuzzleInfoImpl extends PuzzleInfo {
  _PuzzleInfoImpl({
    required String id,
    required String fen,
    required String setupMove,
    required int rating,
    required List<String> themes,
    required int solutionMoves,
    required Map<String, String> legalMoves,
    required int playerRating,
    String? setName,
  }) : super._(
         id: id,
         fen: fen,
         setupMove: setupMove,
         rating: rating,
         themes: themes,
         solutionMoves: solutionMoves,
         legalMoves: legalMoves,
         playerRating: playerRating,
         setName: setName,
       );

  /// Returns a shallow copy of this [PuzzleInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PuzzleInfo copyWith({
    String? id,
    String? fen,
    String? setupMove,
    int? rating,
    List<String>? themes,
    int? solutionMoves,
    Map<String, String>? legalMoves,
    int? playerRating,
    Object? setName = _Undefined,
  }) {
    return PuzzleInfo(
      id: id ?? this.id,
      fen: fen ?? this.fen,
      setupMove: setupMove ?? this.setupMove,
      rating: rating ?? this.rating,
      themes: themes ?? this.themes.map((e0) => e0).toList(),
      solutionMoves: solutionMoves ?? this.solutionMoves,
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
      playerRating: playerRating ?? this.playerRating,
      setName: setName is String? ? setName : this.setName,
    );
  }
}
