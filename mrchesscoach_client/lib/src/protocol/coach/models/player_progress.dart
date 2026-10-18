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
import '../../coach/models/coach_recommendation.dart' as _ivwqlc2m;
import '../../coach/models/theme_stat.dart' as _iek5uzxi;

/// Everything the progress screen shows.
abstract class PlayerProgress
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PlayerProgress._({
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.recentAccuracy,
    this.averageAccuracy,
    required this.puzzleRating,
    required this.puzzleRatingHistory,
    required this.puzzlesSolved,
    required this.puzzlesFailed,
    required this.puzzleStreak,
    required this.bestPuzzleStreak,
    required this.dayStreak,
    required this.themeStats,
    required this.motifStats,
    required this.classTotals,
    required this.lessonsCompleted,
    required this.openingsCompleted,
    required this.mistakesToReview,
    required this.recommendations,
  });

  factory PlayerProgress({
    required int gamesPlayed,
    required int wins,
    required int draws,
    required int losses,
    required List<double> recentAccuracy,
    double? averageAccuracy,
    required int puzzleRating,
    required List<int> puzzleRatingHistory,
    required int puzzlesSolved,
    required int puzzlesFailed,
    required int puzzleStreak,
    required int bestPuzzleStreak,
    required int dayStreak,
    required List<_iek5uzxi.ThemeStat> themeStats,
    required List<_iek5uzxi.ThemeStat> motifStats,
    required Map<String, int> classTotals,
    required int lessonsCompleted,
    required int openingsCompleted,
    required int mistakesToReview,
    required List<_ivwqlc2m.CoachRecommendation> recommendations,
  }) = _PlayerProgressImpl;

  factory PlayerProgress.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlayerProgress(
      gamesPlayed: jsonSerialization['gamesPlayed'] as int,
      wins: jsonSerialization['wins'] as int,
      draws: jsonSerialization['draws'] as int,
      losses: jsonSerialization['losses'] as int,
      recentAccuracy: _iqtjiupe.Protocol().deserialize<List<double>>(
        jsonSerialization['recentAccuracy'],
      ),
      averageAccuracy: (jsonSerialization['averageAccuracy'] as num?)
          ?.toDouble(),
      puzzleRating: jsonSerialization['puzzleRating'] as int,
      puzzleRatingHistory: _iqtjiupe.Protocol().deserialize<List<int>>(
        jsonSerialization['puzzleRatingHistory'],
      ),
      puzzlesSolved: jsonSerialization['puzzlesSolved'] as int,
      puzzlesFailed: jsonSerialization['puzzlesFailed'] as int,
      puzzleStreak: jsonSerialization['puzzleStreak'] as int,
      bestPuzzleStreak: jsonSerialization['bestPuzzleStreak'] as int,
      dayStreak: jsonSerialization['dayStreak'] as int,
      themeStats: _iqtjiupe.Protocol().deserialize<List<_iek5uzxi.ThemeStat>>(
        jsonSerialization['themeStats'],
      ),
      motifStats: _iqtjiupe.Protocol().deserialize<List<_iek5uzxi.ThemeStat>>(
        jsonSerialization['motifStats'],
      ),
      classTotals: _iqtjiupe.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['classTotals'],
      ),
      lessonsCompleted: jsonSerialization['lessonsCompleted'] as int,
      openingsCompleted: jsonSerialization['openingsCompleted'] as int,
      mistakesToReview: jsonSerialization['mistakesToReview'] as int,
      recommendations: _iqtjiupe.Protocol()
          .deserialize<List<_ivwqlc2m.CoachRecommendation>>(
            jsonSerialization['recommendations'],
          ),
    );
  }

  int gamesPlayed;

  int wins;

  int draws;

  int losses;

  /// Accuracy of recent games, oldest first.
  List<double> recentAccuracy;

  double? averageAccuracy;

  int puzzleRating;

  /// Puzzle rating after each recent attempt, oldest first.
  List<int> puzzleRatingHistory;

  int puzzlesSolved;

  int puzzlesFailed;

  int puzzleStreak;

  int bestPuzzleStreak;

  /// Days in a row with activity.
  int dayStreak;

  List<_iek5uzxi.ThemeStat> themeStats;

  /// The themes behind the player's mistakes in games.
  List<_iek5uzxi.ThemeStat> motifStats;

  /// Totals of each classification over the player's games, by name.
  Map<String, int> classTotals;

  int lessonsCompleted;

  int openingsCompleted;

  /// Mistakes from the player's games waiting to be practised.
  int mistakesToReview;

  List<_ivwqlc2m.CoachRecommendation> recommendations;

  /// Returns a shallow copy of this [PlayerProgress]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PlayerProgress copyWith({
    int? gamesPlayed,
    int? wins,
    int? draws,
    int? losses,
    List<double>? recentAccuracy,
    double? averageAccuracy,
    int? puzzleRating,
    List<int>? puzzleRatingHistory,
    int? puzzlesSolved,
    int? puzzlesFailed,
    int? puzzleStreak,
    int? bestPuzzleStreak,
    int? dayStreak,
    List<_iek5uzxi.ThemeStat>? themeStats,
    List<_iek5uzxi.ThemeStat>? motifStats,
    Map<String, int>? classTotals,
    int? lessonsCompleted,
    int? openingsCompleted,
    int? mistakesToReview,
    List<_ivwqlc2m.CoachRecommendation>? recommendations,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlayerProgress',
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'recentAccuracy': recentAccuracy.toJson(),
      if (averageAccuracy != null) 'averageAccuracy': averageAccuracy,
      'puzzleRating': puzzleRating,
      'puzzleRatingHistory': puzzleRatingHistory.toJson(),
      'puzzlesSolved': puzzlesSolved,
      'puzzlesFailed': puzzlesFailed,
      'puzzleStreak': puzzleStreak,
      'bestPuzzleStreak': bestPuzzleStreak,
      'dayStreak': dayStreak,
      'themeStats': themeStats.toJson(valueToJson: (v) => v.toJson()),
      'motifStats': motifStats.toJson(valueToJson: (v) => v.toJson()),
      'classTotals': classTotals.toJson(),
      'lessonsCompleted': lessonsCompleted,
      'openingsCompleted': openingsCompleted,
      'mistakesToReview': mistakesToReview,
      'recommendations': recommendations.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PlayerProgress',
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'recentAccuracy': recentAccuracy.toJson(),
      if (averageAccuracy != null) 'averageAccuracy': averageAccuracy,
      'puzzleRating': puzzleRating,
      'puzzleRatingHistory': puzzleRatingHistory.toJson(),
      'puzzlesSolved': puzzlesSolved,
      'puzzlesFailed': puzzlesFailed,
      'puzzleStreak': puzzleStreak,
      'bestPuzzleStreak': bestPuzzleStreak,
      'dayStreak': dayStreak,
      'themeStats': themeStats.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'motifStats': motifStats.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'classTotals': classTotals.toJson(),
      'lessonsCompleted': lessonsCompleted,
      'openingsCompleted': openingsCompleted,
      'mistakesToReview': mistakesToReview,
      'recommendations': recommendations.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PlayerProgressImpl extends PlayerProgress {
  _PlayerProgressImpl({
    required int gamesPlayed,
    required int wins,
    required int draws,
    required int losses,
    required List<double> recentAccuracy,
    double? averageAccuracy,
    required int puzzleRating,
    required List<int> puzzleRatingHistory,
    required int puzzlesSolved,
    required int puzzlesFailed,
    required int puzzleStreak,
    required int bestPuzzleStreak,
    required int dayStreak,
    required List<_iek5uzxi.ThemeStat> themeStats,
    required List<_iek5uzxi.ThemeStat> motifStats,
    required Map<String, int> classTotals,
    required int lessonsCompleted,
    required int openingsCompleted,
    required int mistakesToReview,
    required List<_ivwqlc2m.CoachRecommendation> recommendations,
  }) : super._(
         gamesPlayed: gamesPlayed,
         wins: wins,
         draws: draws,
         losses: losses,
         recentAccuracy: recentAccuracy,
         averageAccuracy: averageAccuracy,
         puzzleRating: puzzleRating,
         puzzleRatingHistory: puzzleRatingHistory,
         puzzlesSolved: puzzlesSolved,
         puzzlesFailed: puzzlesFailed,
         puzzleStreak: puzzleStreak,
         bestPuzzleStreak: bestPuzzleStreak,
         dayStreak: dayStreak,
         themeStats: themeStats,
         motifStats: motifStats,
         classTotals: classTotals,
         lessonsCompleted: lessonsCompleted,
         openingsCompleted: openingsCompleted,
         mistakesToReview: mistakesToReview,
         recommendations: recommendations,
       );

  /// Returns a shallow copy of this [PlayerProgress]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PlayerProgress copyWith({
    int? gamesPlayed,
    int? wins,
    int? draws,
    int? losses,
    List<double>? recentAccuracy,
    Object? averageAccuracy = _Undefined,
    int? puzzleRating,
    List<int>? puzzleRatingHistory,
    int? puzzlesSolved,
    int? puzzlesFailed,
    int? puzzleStreak,
    int? bestPuzzleStreak,
    int? dayStreak,
    List<_iek5uzxi.ThemeStat>? themeStats,
    List<_iek5uzxi.ThemeStat>? motifStats,
    Map<String, int>? classTotals,
    int? lessonsCompleted,
    int? openingsCompleted,
    int? mistakesToReview,
    List<_ivwqlc2m.CoachRecommendation>? recommendations,
  }) {
    return PlayerProgress(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      recentAccuracy:
          recentAccuracy ?? this.recentAccuracy.map((e0) => e0).toList(),
      averageAccuracy: averageAccuracy is double?
          ? averageAccuracy
          : this.averageAccuracy,
      puzzleRating: puzzleRating ?? this.puzzleRating,
      puzzleRatingHistory:
          puzzleRatingHistory ??
          this.puzzleRatingHistory.map((e0) => e0).toList(),
      puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
      puzzlesFailed: puzzlesFailed ?? this.puzzlesFailed,
      puzzleStreak: puzzleStreak ?? this.puzzleStreak,
      bestPuzzleStreak: bestPuzzleStreak ?? this.bestPuzzleStreak,
      dayStreak: dayStreak ?? this.dayStreak,
      themeStats:
          themeStats ?? this.themeStats.map((e0) => e0.copyWith()).toList(),
      motifStats:
          motifStats ?? this.motifStats.map((e0) => e0.copyWith()).toList(),
      classTotals:
          classTotals ??
          this.classTotals.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      openingsCompleted: openingsCompleted ?? this.openingsCompleted,
      mistakesToReview: mistakesToReview ?? this.mistakesToReview,
      recommendations:
          recommendations ??
          this.recommendations.map((e0) => e0.copyWith()).toList(),
    );
  }
}
