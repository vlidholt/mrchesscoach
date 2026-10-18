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

/// How good a move was, in the style of chess.com move classifications.
enum MoveClass implements _is.SerializableModel {
  brilliant,
  great,
  best,
  excellent,
  good,
  book,
  inaccuracy,
  mistake,
  miss,
  blunder;

  static MoveClass fromJson(String name) {
    switch (name) {
      case 'brilliant':
        return MoveClass.brilliant;
      case 'great':
        return MoveClass.great;
      case 'best':
        return MoveClass.best;
      case 'excellent':
        return MoveClass.excellent;
      case 'good':
        return MoveClass.good;
      case 'book':
        return MoveClass.book;
      case 'inaccuracy':
        return MoveClass.inaccuracy;
      case 'mistake':
        return MoveClass.mistake;
      case 'miss':
        return MoveClass.miss;
      case 'blunder':
        return MoveClass.blunder;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "MoveClass"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
