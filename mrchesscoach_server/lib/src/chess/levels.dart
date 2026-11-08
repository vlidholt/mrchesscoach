import 'package:stockfish_dart/stockfish_dart.dart';

import '../generated/protocol.dart';

/// How the engine plays at one difficulty level.
class LevelSpec {
  const LevelSpec({
    required this.name,
    required this.description,
    required this.rating,
    required this.strength,
    required this.limits,
  });

  final String name;
  final String description;
  final int rating;
  final StrengthLimit strength;
  final SearchLimits limits;
}

/// The difficulty levels, from weakest to strongest.
///
/// Stockfish's own Elo limit bottoms out around 1320, so the three lowest
/// levels use Skill Level 0 with a shallow search instead.
const levelSpecs = <LevelSpec>[
  LevelSpec(
    name: 'Novice',
    description: 'I play like I just learned the moves',
    rating: 400,
    strength: StrengthLimit.skill(0),
    limits: SearchLimits(depth: 1),
  ),
  LevelSpec(
    name: 'Beginner',
    description: 'I know the rules, but I drop pieces',
    rating: 700,
    strength: StrengthLimit.skill(0),
    limits: SearchLimits(depth: 3),
  ),
  LevelSpec(
    name: 'Casual',
    description: 'A relaxed game at the kitchen table',
    rating: 1000,
    strength: StrengthLimit.skill(0),
    limits: SearchLimits(depth: 6),
  ),
  LevelSpec(
    name: 'Club player',
    description: 'Solid basics and simple tactics',
    rating: 1350,
    strength: StrengthLimit.elo(1350),
    limits: SearchLimits(moveTime: Duration(milliseconds: 500)),
  ),
  LevelSpec(
    name: 'Advanced',
    description: 'I punish loose pieces and weak squares',
    rating: 1700,
    strength: StrengthLimit.elo(1700),
    limits: SearchLimits(moveTime: Duration(milliseconds: 700)),
  ),
  LevelSpec(
    name: 'Expert',
    description: 'Sharp tactics and a positional plan',
    rating: 2000,
    strength: StrengthLimit.elo(2000),
    limits: SearchLimits(moveTime: Duration(milliseconds: 800)),
  ),
  LevelSpec(
    name: 'Master',
    description: 'Tournament strength. Bring your best',
    rating: 2400,
    strength: StrengthLimit.elo(2400),
    limits: SearchLimits(moveTime: Duration(seconds: 1)),
  ),
  LevelSpec(
    name: 'Grandmaster',
    description: 'No mercy: my full strength',
    rating: 3200,
    strength: StrengthLimit.full,
    limits: SearchLimits(moveTime: Duration(milliseconds: 1500)),
  ),
];

/// The levels as sent to the client.
List<ChessLevel> get chessLevels => [
  for (final (i, spec) in levelSpecs.indexed)
    ChessLevel(
      index: i,
      name: spec.name,
      description: spec.description,
      rating: spec.rating,
    ),
];
