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

/// Why a chess game ended.
enum GameEndReason implements _is.SerializableModel {
  checkmate,
  resignation,
  stalemate,
  insufficientMaterial,
  threefoldRepetition,
  fiftyMoveRule,
  abandoned,

  /// The lesson goal was reached.
  goalReached;

  static GameEndReason fromJson(String name) {
    switch (name) {
      case 'checkmate':
        return GameEndReason.checkmate;
      case 'resignation':
        return GameEndReason.resignation;
      case 'stalemate':
        return GameEndReason.stalemate;
      case 'insufficientMaterial':
        return GameEndReason.insufficientMaterial;
      case 'threefoldRepetition':
        return GameEndReason.threefoldRepetition;
      case 'fiftyMoveRule':
        return GameEndReason.fiftyMoveRule;
      case 'abandoned':
        return GameEndReason.abandoned;
      case 'goalReached':
        return GameEndReason.goalReached;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "GameEndReason"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
