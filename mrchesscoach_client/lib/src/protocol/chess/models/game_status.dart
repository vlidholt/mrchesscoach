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

/// The state of a chess game, from the human player's point of view.
enum GameStatus implements _isc.SerializableModel {
  active,
  playerWon,
  computerWon,
  draw,

  /// The player started a new game without finishing this one.
  abandoned;

  static GameStatus fromJson(String name) {
    switch (name) {
      case 'active':
        return GameStatus.active;
      case 'playerWon':
        return GameStatus.playerWon;
      case 'computerWon':
        return GameStatus.computerWon;
      case 'draw':
        return GameStatus.draw;
      case 'abandoned':
        return GameStatus.abandoned;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "GameStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
