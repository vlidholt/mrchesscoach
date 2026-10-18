/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mrchesscoach_client/src/protocol/chess/models/chess_game.dart'
    as _i0ghl5l0;
import 'package:mrchesscoach_client/src/protocol/chess/models/chess_level.dart'
    as _iy8melaj;
import 'package:mrchesscoach_client/src/protocol/coach/models/coach_chat_turn.dart'
    as _iblxx7xb;
import 'package:mrchesscoach_client/src/protocol/coach/models/lesson_info.dart'
    as _ivg9h4pb;
import 'package:mrchesscoach_client/src/protocol/coach/models/move_analysis.dart'
    as _ipaj7svr;
import 'package:mrchesscoach_client/src/protocol/coach/models/opening_summary.dart'
    as _igop3rv4;
import 'package:mrchesscoach_client/src/protocol/coach/models/puzzle_theme.dart'
    as _ifkuowcx;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'chess/models/chess_game.dart' as _i12dxgql;
import 'chess/models/chess_game_exception.dart' as _iyb3pwfo;
import 'chess/models/chess_level.dart' as _iv62pu31;
import 'chess/models/game_end_reason.dart' as _iiyw6cwk;
import 'chess/models/game_status.dart' as _iu58arqx;
import 'chess/models/player_color.dart' as _i43bi8bp;
import 'coach/models/coach_chat_turn.dart' as _iefime6r;
import 'coach/models/coach_hint.dart' as _i62wcpvj;
import 'coach/models/coach_recommendation.dart' as _i07e05jx;
import 'coach/models/game_review.dart' as _iq7ezsqy;
import 'coach/models/lesson_info.dart' as _i9cvgeji;
import 'coach/models/mistake_drill.dart' as _ivloy9zq;
import 'coach/models/mistake_drill_result.dart' as _itry22ja;
import 'coach/models/move_analysis.dart' as _i54knsp5;
import 'coach/models/move_class.dart' as _ixbtpo4c;
import 'coach/models/opening_course_info.dart' as _iwec8a2i;
import 'coach/models/opening_step.dart' as _ini0nuhb;
import 'coach/models/opening_summary.dart' as _icil087y;
import 'coach/models/player_progress.dart' as _i2ix780o;
import 'coach/models/puzzle_info.dart' as _iomh00t2;
import 'coach/models/puzzle_move_result.dart' as _i6m2zlnv;
import 'coach/models/puzzle_theme.dart' as _ioaslfri;
import 'coach/models/theme_stat.dart' as _ialbwhzf;
import 'coach/models/threat_insight.dart' as _iomnox31;
export 'chess/models/chess_game.dart';
export 'chess/models/chess_game_exception.dart';
export 'chess/models/chess_level.dart';
export 'chess/models/game_end_reason.dart';
export 'chess/models/game_status.dart';
export 'chess/models/player_color.dart';
export 'coach/models/coach_chat_turn.dart';
export 'coach/models/coach_hint.dart';
export 'coach/models/coach_recommendation.dart';
export 'coach/models/game_review.dart';
export 'coach/models/lesson_info.dart';
export 'coach/models/mistake_drill.dart';
export 'coach/models/mistake_drill_result.dart';
export 'coach/models/move_analysis.dart';
export 'coach/models/move_class.dart';
export 'coach/models/opening_course_info.dart';
export 'coach/models/opening_step.dart';
export 'coach/models/opening_summary.dart';
export 'coach/models/player_progress.dart';
export 'coach/models/puzzle_info.dart';
export 'coach/models/puzzle_move_result.dart';
export 'coach/models/puzzle_theme.dart';
export 'coach/models/theme_stat.dart';
export 'coach/models/threat_insight.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager
    implements _isc.ProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _isc.ProtocolDeserialization get deserializationMetadata =>
      _isc.ProtocolDeserialization.cached(
        this,
        types: const [
          _isc.getType<_i12dxgql.ChessGame>,
          _isc.getType<_iyb3pwfo.ChessGameException>,
          _isc.getType<_iv62pu31.ChessLevel>,
          _isc.getType<_iiyw6cwk.GameEndReason>,
          _isc.getType<_iu58arqx.GameStatus>,
          _isc.getType<_i43bi8bp.PlayerColor>,
          _isc.getType<_iefime6r.CoachChatTurn>,
          _isc.getType<_i62wcpvj.CoachHint>,
          _isc.getType<_i07e05jx.CoachRecommendation>,
          _isc.getType<_iq7ezsqy.GameReview>,
          _isc.getType<_i9cvgeji.LessonInfo>,
          _isc.getType<_ivloy9zq.MistakeDrill>,
          _isc.getType<_itry22ja.MistakeDrillResult>,
          _isc.getType<_i54knsp5.MoveAnalysis>,
          _isc.getType<_ixbtpo4c.MoveClass>,
          _isc.getType<_iwec8a2i.OpeningCourseInfo>,
          _isc.getType<_ini0nuhb.OpeningStep>,
          _isc.getType<_icil087y.OpeningSummary>,
          _isc.getType<_i2ix780o.PlayerProgress>,
          _isc.getType<_iomh00t2.PuzzleInfo>,
          _isc.getType<_i6m2zlnv.PuzzleMoveResult>,
          _isc.getType<_ioaslfri.PuzzleTheme>,
          _isc.getType<_ialbwhzf.ThemeStat>,
          _isc.getType<_iomnox31.ThreatInsight>,
          _isc.getType<_i12dxgql.ChessGame?>,
          _isc.getType<_iyb3pwfo.ChessGameException?>,
          _isc.getType<_iv62pu31.ChessLevel?>,
          _isc.getType<_iiyw6cwk.GameEndReason?>,
          _isc.getType<_iu58arqx.GameStatus?>,
          _isc.getType<_i43bi8bp.PlayerColor?>,
          _isc.getType<_iefime6r.CoachChatTurn?>,
          _isc.getType<_i62wcpvj.CoachHint?>,
          _isc.getType<_i07e05jx.CoachRecommendation?>,
          _isc.getType<_iq7ezsqy.GameReview?>,
          _isc.getType<_i9cvgeji.LessonInfo?>,
          _isc.getType<_ivloy9zq.MistakeDrill?>,
          _isc.getType<_itry22ja.MistakeDrillResult?>,
          _isc.getType<_i54knsp5.MoveAnalysis?>,
          _isc.getType<_ixbtpo4c.MoveClass?>,
          _isc.getType<_iwec8a2i.OpeningCourseInfo?>,
          _isc.getType<_ini0nuhb.OpeningStep?>,
          _isc.getType<_icil087y.OpeningSummary?>,
          _isc.getType<_i2ix780o.PlayerProgress?>,
          _isc.getType<_iomh00t2.PuzzleInfo?>,
          _isc.getType<_i6m2zlnv.PuzzleMoveResult?>,
          _isc.getType<_ioaslfri.PuzzleTheme?>,
          _isc.getType<_ialbwhzf.ThemeStat?>,
          _isc.getType<_iomnox31.ThreatInsight?>,
          _isc.getType<List<String>>,
          _isc.getType<Map<String, String>>,
          _isc.getType<Map<String, String>?>,
          _isc.getType<List<_i54knsp5.MoveAnalysis>>,
          _isc.getType<List<int>>,
          _isc.getType<Map<String, int>>,
          _isc.getType<List<double>>,
          _isc.getType<List<_ini0nuhb.OpeningStep>>,
          _isc.getType<List<_ialbwhzf.ThemeStat>>,
          _isc.getType<List<_i07e05jx.CoachRecommendation>>,
          _isc.getType<List<String>?>,
          _isc.getType<List<_iy8melaj.ChessLevel>>,
          _isc.getType<List<_i0ghl5l0.ChessGame>>,
          _isc.getType<List<_ipaj7svr.MoveAnalysis>>,
          _isc.getType<List<String>>,
          _isc.getType<List<_iblxx7xb.CoachChatTurn>>,
          _isc.getType<List<_igop3rv4.OpeningSummary>>,
          _isc.getType<Map<String, String>>,
          _isc.getType<List<_ivg9h4pb.LessonInfo>>,
          _isc.getType<List<_ifkuowcx.PuzzleTheme>>,
        ],
        modules: const [
          _iaic.Protocol.new,
          _iacc.Protocol.new,
        ],
      );

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i12dxgql.ChessGame) {
      return _i12dxgql.ChessGame.fromJson(data) as T;
    }
    if (t == _iyb3pwfo.ChessGameException) {
      return _iyb3pwfo.ChessGameException.fromJson(data) as T;
    }
    if (t == _iv62pu31.ChessLevel) {
      return _iv62pu31.ChessLevel.fromJson(data) as T;
    }
    if (t == _iiyw6cwk.GameEndReason) {
      return _iiyw6cwk.GameEndReason.fromJson(data) as T;
    }
    if (t == _iu58arqx.GameStatus) {
      return _iu58arqx.GameStatus.fromJson(data) as T;
    }
    if (t == _i43bi8bp.PlayerColor) {
      return _i43bi8bp.PlayerColor.fromJson(data) as T;
    }
    if (t == _iefime6r.CoachChatTurn) {
      return _iefime6r.CoachChatTurn.fromJson(data) as T;
    }
    if (t == _i62wcpvj.CoachHint) {
      return _i62wcpvj.CoachHint.fromJson(data) as T;
    }
    if (t == _i07e05jx.CoachRecommendation) {
      return _i07e05jx.CoachRecommendation.fromJson(data) as T;
    }
    if (t == _iq7ezsqy.GameReview) {
      return _iq7ezsqy.GameReview.fromJson(data) as T;
    }
    if (t == _i9cvgeji.LessonInfo) {
      return _i9cvgeji.LessonInfo.fromJson(data) as T;
    }
    if (t == _ivloy9zq.MistakeDrill) {
      return _ivloy9zq.MistakeDrill.fromJson(data) as T;
    }
    if (t == _itry22ja.MistakeDrillResult) {
      return _itry22ja.MistakeDrillResult.fromJson(data) as T;
    }
    if (t == _i54knsp5.MoveAnalysis) {
      return _i54knsp5.MoveAnalysis.fromJson(data) as T;
    }
    if (t == _ixbtpo4c.MoveClass) {
      return _ixbtpo4c.MoveClass.fromJson(data) as T;
    }
    if (t == _iwec8a2i.OpeningCourseInfo) {
      return _iwec8a2i.OpeningCourseInfo.fromJson(data) as T;
    }
    if (t == _ini0nuhb.OpeningStep) {
      return _ini0nuhb.OpeningStep.fromJson(data) as T;
    }
    if (t == _icil087y.OpeningSummary) {
      return _icil087y.OpeningSummary.fromJson(data) as T;
    }
    if (t == _i2ix780o.PlayerProgress) {
      return _i2ix780o.PlayerProgress.fromJson(data) as T;
    }
    if (t == _iomh00t2.PuzzleInfo) {
      return _iomh00t2.PuzzleInfo.fromJson(data) as T;
    }
    if (t == _i6m2zlnv.PuzzleMoveResult) {
      return _i6m2zlnv.PuzzleMoveResult.fromJson(data) as T;
    }
    if (t == _ioaslfri.PuzzleTheme) {
      return _ioaslfri.PuzzleTheme.fromJson(data) as T;
    }
    if (t == _ialbwhzf.ThemeStat) {
      return _ialbwhzf.ThemeStat.fromJson(data) as T;
    }
    if (t == _iomnox31.ThreatInsight) {
      return _iomnox31.ThreatInsight.fromJson(data) as T;
    }
    if (t == _isc.getType<_i12dxgql.ChessGame?>()) {
      return (data != null ? _i12dxgql.ChessGame.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyb3pwfo.ChessGameException?>()) {
      return (data != null ? _iyb3pwfo.ChessGameException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv62pu31.ChessLevel?>()) {
      return (data != null ? _iv62pu31.ChessLevel.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iiyw6cwk.GameEndReason?>()) {
      return (data != null ? _iiyw6cwk.GameEndReason.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iu58arqx.GameStatus?>()) {
      return (data != null ? _iu58arqx.GameStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i43bi8bp.PlayerColor?>()) {
      return (data != null ? _i43bi8bp.PlayerColor.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iefime6r.CoachChatTurn?>()) {
      return (data != null ? _iefime6r.CoachChatTurn.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i62wcpvj.CoachHint?>()) {
      return (data != null ? _i62wcpvj.CoachHint.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i07e05jx.CoachRecommendation?>()) {
      return (data != null
              ? _i07e05jx.CoachRecommendation.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iq7ezsqy.GameReview?>()) {
      return (data != null ? _iq7ezsqy.GameReview.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9cvgeji.LessonInfo?>()) {
      return (data != null ? _i9cvgeji.LessonInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ivloy9zq.MistakeDrill?>()) {
      return (data != null ? _ivloy9zq.MistakeDrill.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_itry22ja.MistakeDrillResult?>()) {
      return (data != null ? _itry22ja.MistakeDrillResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i54knsp5.MoveAnalysis?>()) {
      return (data != null ? _i54knsp5.MoveAnalysis.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ixbtpo4c.MoveClass?>()) {
      return (data != null ? _ixbtpo4c.MoveClass.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwec8a2i.OpeningCourseInfo?>()) {
      return (data != null ? _iwec8a2i.OpeningCourseInfo.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ini0nuhb.OpeningStep?>()) {
      return (data != null ? _ini0nuhb.OpeningStep.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icil087y.OpeningSummary?>()) {
      return (data != null ? _icil087y.OpeningSummary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i2ix780o.PlayerProgress?>()) {
      return (data != null ? _i2ix780o.PlayerProgress.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iomh00t2.PuzzleInfo?>()) {
      return (data != null ? _iomh00t2.PuzzleInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6m2zlnv.PuzzleMoveResult?>()) {
      return (data != null ? _i6m2zlnv.PuzzleMoveResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ioaslfri.PuzzleTheme?>()) {
      return (data != null ? _ioaslfri.PuzzleTheme.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ialbwhzf.ThemeStat?>()) {
      return (data != null ? _ialbwhzf.ThemeStat.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iomnox31.ThreatInsight?>()) {
      return (data != null ? _iomnox31.ThreatInsight.fromJson(data) : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == _isc.getType<Map<String, String>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<String>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_i54knsp5.MoveAnalysis>) {
      return (data as List)
              .map((e) => deserialize<_i54knsp5.MoveAnalysis>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<double>) {
      return (data as List).map((e) => deserialize<double>(e)).toList() as T;
    }
    if (t == List<_ini0nuhb.OpeningStep>) {
      return (data as List)
              .map((e) => deserialize<_ini0nuhb.OpeningStep>(e))
              .toList()
          as T;
    }
    if (t == List<_ialbwhzf.ThemeStat>) {
      return (data as List)
              .map((e) => deserialize<_ialbwhzf.ThemeStat>(e))
              .toList()
          as T;
    }
    if (t == List<_i07e05jx.CoachRecommendation>) {
      return (data as List)
              .map((e) => deserialize<_i07e05jx.CoachRecommendation>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_iy8melaj.ChessLevel>) {
      return (data as List)
              .map((e) => deserialize<_iy8melaj.ChessLevel>(e))
              .toList()
          as T;
    }
    if (t == List<_i0ghl5l0.ChessGame>) {
      return (data as List)
              .map((e) => deserialize<_i0ghl5l0.ChessGame>(e))
              .toList()
          as T;
    }
    if (t == List<_ipaj7svr.MoveAnalysis>) {
      return (data as List)
              .map((e) => deserialize<_ipaj7svr.MoveAnalysis>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_iblxx7xb.CoachChatTurn>) {
      return (data as List)
              .map((e) => deserialize<_iblxx7xb.CoachChatTurn>(e))
              .toList()
          as T;
    }
    if (t == List<_igop3rv4.OpeningSummary>) {
      return (data as List)
              .map((e) => deserialize<_igop3rv4.OpeningSummary>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_ivg9h4pb.LessonInfo>) {
      return (data as List)
              .map((e) => deserialize<_ivg9h4pb.LessonInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_ifkuowcx.PuzzleTheme>) {
      return (data as List)
              .map((e) => deserialize<_ifkuowcx.PuzzleTheme>(e))
              .toList()
          as T;
    }
    final modules = dataClassName == null
        ? deserializationMetadata.modulesForType(t)
        : deserializationMetadata.modules;
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _isc.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i12dxgql.ChessGame => 'ChessGame',
      _iyb3pwfo.ChessGameException => 'ChessGameException',
      _iv62pu31.ChessLevel => 'ChessLevel',
      _iiyw6cwk.GameEndReason => 'GameEndReason',
      _iu58arqx.GameStatus => 'GameStatus',
      _i43bi8bp.PlayerColor => 'PlayerColor',
      _iefime6r.CoachChatTurn => 'CoachChatTurn',
      _i62wcpvj.CoachHint => 'CoachHint',
      _i07e05jx.CoachRecommendation => 'CoachRecommendation',
      _iq7ezsqy.GameReview => 'GameReview',
      _i9cvgeji.LessonInfo => 'LessonInfo',
      _ivloy9zq.MistakeDrill => 'MistakeDrill',
      _itry22ja.MistakeDrillResult => 'MistakeDrillResult',
      _i54knsp5.MoveAnalysis => 'MoveAnalysis',
      _ixbtpo4c.MoveClass => 'MoveClass',
      _iwec8a2i.OpeningCourseInfo => 'OpeningCourseInfo',
      _ini0nuhb.OpeningStep => 'OpeningStep',
      _icil087y.OpeningSummary => 'OpeningSummary',
      _i2ix780o.PlayerProgress => 'PlayerProgress',
      _iomh00t2.PuzzleInfo => 'PuzzleInfo',
      _i6m2zlnv.PuzzleMoveResult => 'PuzzleMoveResult',
      _ioaslfri.PuzzleTheme => 'PuzzleTheme',
      _ialbwhzf.ThemeStat => 'ThemeStat',
      _iomnox31.ThreatInsight => 'ThreatInsight',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'mrchesscoach.',
        '',
      );
    }

    switch (data) {
      case _i12dxgql.ChessGame():
        return 'ChessGame';
      case _iyb3pwfo.ChessGameException():
        return 'ChessGameException';
      case _iv62pu31.ChessLevel():
        return 'ChessLevel';
      case _iiyw6cwk.GameEndReason():
        return 'GameEndReason';
      case _iu58arqx.GameStatus():
        return 'GameStatus';
      case _i43bi8bp.PlayerColor():
        return 'PlayerColor';
      case _iefime6r.CoachChatTurn():
        return 'CoachChatTurn';
      case _i62wcpvj.CoachHint():
        return 'CoachHint';
      case _i07e05jx.CoachRecommendation():
        return 'CoachRecommendation';
      case _iq7ezsqy.GameReview():
        return 'GameReview';
      case _i9cvgeji.LessonInfo():
        return 'LessonInfo';
      case _ivloy9zq.MistakeDrill():
        return 'MistakeDrill';
      case _itry22ja.MistakeDrillResult():
        return 'MistakeDrillResult';
      case _i54knsp5.MoveAnalysis():
        return 'MoveAnalysis';
      case _ixbtpo4c.MoveClass():
        return 'MoveClass';
      case _iwec8a2i.OpeningCourseInfo():
        return 'OpeningCourseInfo';
      case _ini0nuhb.OpeningStep():
        return 'OpeningStep';
      case _icil087y.OpeningSummary():
        return 'OpeningSummary';
      case _i2ix780o.PlayerProgress():
        return 'PlayerProgress';
      case _iomh00t2.PuzzleInfo():
        return 'PuzzleInfo';
      case _i6m2zlnv.PuzzleMoveResult():
        return 'PuzzleMoveResult';
      case _ioaslfri.PuzzleTheme():
        return 'PuzzleTheme';
      case _ialbwhzf.ThemeStat():
        return 'ThemeStat';
      case _iomnox31.ThreatInsight():
        return 'ThreatInsight';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ChessGame') {
      return deserialize<_i12dxgql.ChessGame>(data['data']);
    }
    if (dataClassName == 'ChessGameException') {
      return deserialize<_iyb3pwfo.ChessGameException>(data['data']);
    }
    if (dataClassName == 'ChessLevel') {
      return deserialize<_iv62pu31.ChessLevel>(data['data']);
    }
    if (dataClassName == 'GameEndReason') {
      return deserialize<_iiyw6cwk.GameEndReason>(data['data']);
    }
    if (dataClassName == 'GameStatus') {
      return deserialize<_iu58arqx.GameStatus>(data['data']);
    }
    if (dataClassName == 'PlayerColor') {
      return deserialize<_i43bi8bp.PlayerColor>(data['data']);
    }
    if (dataClassName == 'CoachChatTurn') {
      return deserialize<_iefime6r.CoachChatTurn>(data['data']);
    }
    if (dataClassName == 'CoachHint') {
      return deserialize<_i62wcpvj.CoachHint>(data['data']);
    }
    if (dataClassName == 'CoachRecommendation') {
      return deserialize<_i07e05jx.CoachRecommendation>(data['data']);
    }
    if (dataClassName == 'GameReview') {
      return deserialize<_iq7ezsqy.GameReview>(data['data']);
    }
    if (dataClassName == 'LessonInfo') {
      return deserialize<_i9cvgeji.LessonInfo>(data['data']);
    }
    if (dataClassName == 'MistakeDrill') {
      return deserialize<_ivloy9zq.MistakeDrill>(data['data']);
    }
    if (dataClassName == 'MistakeDrillResult') {
      return deserialize<_itry22ja.MistakeDrillResult>(data['data']);
    }
    if (dataClassName == 'MoveAnalysis') {
      return deserialize<_i54knsp5.MoveAnalysis>(data['data']);
    }
    if (dataClassName == 'MoveClass') {
      return deserialize<_ixbtpo4c.MoveClass>(data['data']);
    }
    if (dataClassName == 'OpeningCourseInfo') {
      return deserialize<_iwec8a2i.OpeningCourseInfo>(data['data']);
    }
    if (dataClassName == 'OpeningStep') {
      return deserialize<_ini0nuhb.OpeningStep>(data['data']);
    }
    if (dataClassName == 'OpeningSummary') {
      return deserialize<_icil087y.OpeningSummary>(data['data']);
    }
    if (dataClassName == 'PlayerProgress') {
      return deserialize<_i2ix780o.PlayerProgress>(data['data']);
    }
    if (dataClassName == 'PuzzleInfo') {
      return deserialize<_iomh00t2.PuzzleInfo>(data['data']);
    }
    if (dataClassName == 'PuzzleMoveResult') {
      return deserialize<_i6m2zlnv.PuzzleMoveResult>(data['data']);
    }
    if (dataClassName == 'PuzzleTheme') {
      return deserialize<_ioaslfri.PuzzleTheme>(data['data']);
    }
    if (dataClassName == 'ThemeStat') {
      return deserialize<_ialbwhzf.ThemeStat>(data['data']);
    }
    if (dataClassName == 'ThreatInsight') {
      return deserialize<_iomnox31.ThreatInsight>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('mrchesscoach', this);
    _iacc.Protocol().registerHostProtocol('mrchesscoach', this);
  }

  @override
  String getModuleName() => 'mrchesscoach';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
