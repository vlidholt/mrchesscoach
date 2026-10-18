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
import 'package:mrchesscoach_server/src/generated/chess/models/chess_game.dart'
    as _ijbheviu;
import 'package:mrchesscoach_server/src/generated/chess/models/chess_level.dart'
    as _i2zq20a8;
import 'package:mrchesscoach_server/src/generated/coach/models/coach_chat_turn.dart'
    as _i8706h65;
import 'package:mrchesscoach_server/src/generated/coach/models/lesson_info.dart'
    as _i74xdee0;
import 'package:mrchesscoach_server/src/generated/coach/models/move_analysis.dart'
    as _in6d780u;
import 'package:mrchesscoach_server/src/generated/coach/models/opening_summary.dart'
    as _ia360mkf;
import 'package:mrchesscoach_server/src/generated/coach/models/puzzle_theme.dart'
    as _i3qvqsky;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
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
import 'coach/models/game_summary.dart' as _iw7xoepe;
import 'coach/models/lesson_info.dart' as _i9cvgeji;
import 'coach/models/lesson_progress.dart' as _iv2n46oe;
import 'coach/models/mistake_drill.dart' as _ivloy9zq;
import 'coach/models/mistake_drill_result.dart' as _itry22ja;
import 'coach/models/move_analysis.dart' as _i54knsp5;
import 'coach/models/move_class.dart' as _ixbtpo4c;
import 'coach/models/opening_course_info.dart' as _iwec8a2i;
import 'coach/models/opening_step.dart' as _ini0nuhb;
import 'coach/models/opening_summary.dart' as _icil087y;
import 'coach/models/player_progress.dart' as _i2ix780o;
import 'coach/models/player_stats.dart' as _ifxq8anc;
import 'coach/models/puzzle_attempt.dart' as _i1k6u0te;
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
export 'coach/models/game_summary.dart';
export 'coach/models/lesson_info.dart';
export 'coach/models/lesson_progress.dart';
export 'coach/models/mistake_drill.dart';
export 'coach/models/mistake_drill_result.dart';
export 'coach/models/move_analysis.dart';
export 'coach/models/move_class.dart';
export 'coach/models/opening_course_info.dart';
export 'coach/models/opening_step.dart';
export 'coach/models/opening_summary.dart';
export 'coach/models/player_progress.dart';
export 'coach/models/player_stats.dart';
export 'coach/models/puzzle_attempt.dart';
export 'coach/models/puzzle_info.dart';
export 'coach/models/puzzle_move_result.dart';
export 'coach/models/puzzle_theme.dart';
export 'coach/models/theme_stat.dart';
export 'coach/models/threat_insight.dart';

class Protocol extends _is.DatabaseSerializationManager
    implements _is.DatabaseProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _is.ProtocolDeserialization get deserializationMetadata =>
      _is.ProtocolDeserialization.cached(
        this,
        types: const [
          _is.getType<_i12dxgql.ChessGame>,
          _is.getType<_iyb3pwfo.ChessGameException>,
          _is.getType<_iv62pu31.ChessLevel>,
          _is.getType<_iiyw6cwk.GameEndReason>,
          _is.getType<_iu58arqx.GameStatus>,
          _is.getType<_i43bi8bp.PlayerColor>,
          _is.getType<_iefime6r.CoachChatTurn>,
          _is.getType<_i62wcpvj.CoachHint>,
          _is.getType<_i07e05jx.CoachRecommendation>,
          _is.getType<_iq7ezsqy.GameReview>,
          _is.getType<_iw7xoepe.GameSummary>,
          _is.getType<_i9cvgeji.LessonInfo>,
          _is.getType<_iv2n46oe.LessonProgress>,
          _is.getType<_ivloy9zq.MistakeDrill>,
          _is.getType<_itry22ja.MistakeDrillResult>,
          _is.getType<_i54knsp5.MoveAnalysis>,
          _is.getType<_ixbtpo4c.MoveClass>,
          _is.getType<_iwec8a2i.OpeningCourseInfo>,
          _is.getType<_ini0nuhb.OpeningStep>,
          _is.getType<_icil087y.OpeningSummary>,
          _is.getType<_i2ix780o.PlayerProgress>,
          _is.getType<_ifxq8anc.PlayerStats>,
          _is.getType<_i1k6u0te.PuzzleAttempt>,
          _is.getType<_iomh00t2.PuzzleInfo>,
          _is.getType<_i6m2zlnv.PuzzleMoveResult>,
          _is.getType<_ioaslfri.PuzzleTheme>,
          _is.getType<_ialbwhzf.ThemeStat>,
          _is.getType<_iomnox31.ThreatInsight>,
          _is.getType<_i12dxgql.ChessGame?>,
          _is.getType<_iyb3pwfo.ChessGameException?>,
          _is.getType<_iv62pu31.ChessLevel?>,
          _is.getType<_iiyw6cwk.GameEndReason?>,
          _is.getType<_iu58arqx.GameStatus?>,
          _is.getType<_i43bi8bp.PlayerColor?>,
          _is.getType<_iefime6r.CoachChatTurn?>,
          _is.getType<_i62wcpvj.CoachHint?>,
          _is.getType<_i07e05jx.CoachRecommendation?>,
          _is.getType<_iq7ezsqy.GameReview?>,
          _is.getType<_iw7xoepe.GameSummary?>,
          _is.getType<_i9cvgeji.LessonInfo?>,
          _is.getType<_iv2n46oe.LessonProgress?>,
          _is.getType<_ivloy9zq.MistakeDrill?>,
          _is.getType<_itry22ja.MistakeDrillResult?>,
          _is.getType<_i54knsp5.MoveAnalysis?>,
          _is.getType<_ixbtpo4c.MoveClass?>,
          _is.getType<_iwec8a2i.OpeningCourseInfo?>,
          _is.getType<_ini0nuhb.OpeningStep?>,
          _is.getType<_icil087y.OpeningSummary?>,
          _is.getType<_i2ix780o.PlayerProgress?>,
          _is.getType<_ifxq8anc.PlayerStats?>,
          _is.getType<_i1k6u0te.PuzzleAttempt?>,
          _is.getType<_iomh00t2.PuzzleInfo?>,
          _is.getType<_i6m2zlnv.PuzzleMoveResult?>,
          _is.getType<_ioaslfri.PuzzleTheme?>,
          _is.getType<_ialbwhzf.ThemeStat?>,
          _is.getType<_iomnox31.ThreatInsight?>,
          _is.getType<List<String>>,
          _is.getType<Map<String, String>>,
          _is.getType<Map<String, String>?>,
          _is.getType<List<_i54knsp5.MoveAnalysis>>,
          _is.getType<List<int>>,
          _is.getType<Map<String, int>>,
          _is.getType<List<double>>,
          _is.getType<List<_ini0nuhb.OpeningStep>>,
          _is.getType<List<_ialbwhzf.ThemeStat>>,
          _is.getType<List<_i07e05jx.CoachRecommendation>>,
          _is.getType<List<String>?>,
          _is.getType<List<_i2zq20a8.ChessLevel>>,
          _is.getType<List<_ijbheviu.ChessGame>>,
          _is.getType<List<_in6d780u.MoveAnalysis>>,
          _is.getType<List<String>>,
          _is.getType<List<_i8706h65.CoachChatTurn>>,
          _is.getType<List<_ia360mkf.OpeningSummary>>,
          _is.getType<Map<String, String>>,
          _is.getType<List<_i74xdee0.LessonInfo>>,
          _is.getType<List<_i3qvqsky.PuzzleTheme>>,
        ],
        modules: const [
          _iais.Protocol.new,
          _iacs.Protocol.new,
          _isp.Protocol.new,
        ],
      );

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'chess_game',
      dartName: 'ChessGame',
      schema: 'public',
      module: 'mrchesscoach',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'level',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'playerColor',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:PlayerColor',
        ),
        _isp.ColumnDefinition(
          name: 'moves',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'sanMoves',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'fen',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:GameStatus',
        ),
        _isp.ColumnDefinition(
          name: 'endReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:GameEndReason?',
        ),
        _isp.ColumnDefinition(
          name: 'evalCp',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'evalMate',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'hintsUsed',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'takebacks',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'coachEnabled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'startFen',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lessonId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'awaitingDecision',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'retries',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'analysisCache',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'chess_game_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'game_summary',
      dartName: 'GameSummary',
      schema: 'public',
      module: 'mrchesscoach',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'gameId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'summary',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'plies',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'game_summary_game_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'gameId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'lesson_progress',
      dartName: 'LessonProgress',
      schema: 'public',
      module: 'mrchesscoach',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'lessonId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'completed',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'lesson_progress_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lessonId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'move_analysis',
      dartName: 'MoveAnalysis',
      schema: 'public',
      module: 'mrchesscoach',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'gameId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'ply',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'uci',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'san',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'byPlayer',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'classification',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MoveClass',
        ),
        _isp.ColumnDefinition(
          name: 'winBefore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'winAfter',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'accuracy',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'evalCp',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'evalMate',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'bestUci',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'bestSan',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'bestLine',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'replyLine',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'replyUci',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fenBefore',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'headline',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'explanation',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lesson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'motif',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'retracted',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'drillAttempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'drillSuccesses',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'move_analysis_game_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'gameId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'ply',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'move_analysis_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'classification',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'player_stats',
      dartName: 'PlayerStats',
      schema: 'public',
      module: 'mrchesscoach',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'puzzleRating',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1200',
        ),
        _isp.ColumnDefinition(
          name: 'puzzleStreak',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'bestPuzzleStreak',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'puzzlesSolved',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'puzzlesFailed',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'lastActiveDay',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'dayStreak',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'player_stats_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'puzzle_attempt',
      dartName: 'PuzzleAttempt',
      schema: 'public',
      module: 'mrchesscoach',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'puzzleId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'solved',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'puzzleRating',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ratingAfter',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'themes',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'puzzle_attempt_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _iw7xoepe.GameSummary) {
      return _iw7xoepe.GameSummary.fromJson(data) as T;
    }
    if (t == _i9cvgeji.LessonInfo) {
      return _i9cvgeji.LessonInfo.fromJson(data) as T;
    }
    if (t == _iv2n46oe.LessonProgress) {
      return _iv2n46oe.LessonProgress.fromJson(data) as T;
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
    if (t == _ifxq8anc.PlayerStats) {
      return _ifxq8anc.PlayerStats.fromJson(data) as T;
    }
    if (t == _i1k6u0te.PuzzleAttempt) {
      return _i1k6u0te.PuzzleAttempt.fromJson(data) as T;
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
    if (t == _is.getType<_i12dxgql.ChessGame?>()) {
      return (data != null ? _i12dxgql.ChessGame.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyb3pwfo.ChessGameException?>()) {
      return (data != null ? _iyb3pwfo.ChessGameException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv62pu31.ChessLevel?>()) {
      return (data != null ? _iv62pu31.ChessLevel.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iiyw6cwk.GameEndReason?>()) {
      return (data != null ? _iiyw6cwk.GameEndReason.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu58arqx.GameStatus?>()) {
      return (data != null ? _iu58arqx.GameStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i43bi8bp.PlayerColor?>()) {
      return (data != null ? _i43bi8bp.PlayerColor.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iefime6r.CoachChatTurn?>()) {
      return (data != null ? _iefime6r.CoachChatTurn.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i62wcpvj.CoachHint?>()) {
      return (data != null ? _i62wcpvj.CoachHint.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i07e05jx.CoachRecommendation?>()) {
      return (data != null
              ? _i07e05jx.CoachRecommendation.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iq7ezsqy.GameReview?>()) {
      return (data != null ? _iq7ezsqy.GameReview.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iw7xoepe.GameSummary?>()) {
      return (data != null ? _iw7xoepe.GameSummary.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9cvgeji.LessonInfo?>()) {
      return (data != null ? _i9cvgeji.LessonInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iv2n46oe.LessonProgress?>()) {
      return (data != null ? _iv2n46oe.LessonProgress.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivloy9zq.MistakeDrill?>()) {
      return (data != null ? _ivloy9zq.MistakeDrill.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itry22ja.MistakeDrillResult?>()) {
      return (data != null ? _itry22ja.MistakeDrillResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i54knsp5.MoveAnalysis?>()) {
      return (data != null ? _i54knsp5.MoveAnalysis.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixbtpo4c.MoveClass?>()) {
      return (data != null ? _ixbtpo4c.MoveClass.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwec8a2i.OpeningCourseInfo?>()) {
      return (data != null ? _iwec8a2i.OpeningCourseInfo.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ini0nuhb.OpeningStep?>()) {
      return (data != null ? _ini0nuhb.OpeningStep.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icil087y.OpeningSummary?>()) {
      return (data != null ? _icil087y.OpeningSummary.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i2ix780o.PlayerProgress?>()) {
      return (data != null ? _i2ix780o.PlayerProgress.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifxq8anc.PlayerStats?>()) {
      return (data != null ? _ifxq8anc.PlayerStats.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1k6u0te.PuzzleAttempt?>()) {
      return (data != null ? _i1k6u0te.PuzzleAttempt.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iomh00t2.PuzzleInfo?>()) {
      return (data != null ? _iomh00t2.PuzzleInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6m2zlnv.PuzzleMoveResult?>()) {
      return (data != null ? _i6m2zlnv.PuzzleMoveResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ioaslfri.PuzzleTheme?>()) {
      return (data != null ? _ioaslfri.PuzzleTheme.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ialbwhzf.ThemeStat?>()) {
      return (data != null ? _ialbwhzf.ThemeStat.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iomnox31.ThreatInsight?>()) {
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
    if (t == _is.getType<Map<String, String>?>()) {
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
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i2zq20a8.ChessLevel>) {
      return (data as List)
              .map((e) => deserialize<_i2zq20a8.ChessLevel>(e))
              .toList()
          as T;
    }
    if (t == List<_ijbheviu.ChessGame>) {
      return (data as List)
              .map((e) => deserialize<_ijbheviu.ChessGame>(e))
              .toList()
          as T;
    }
    if (t == List<_in6d780u.MoveAnalysis>) {
      return (data as List)
              .map((e) => deserialize<_in6d780u.MoveAnalysis>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i8706h65.CoachChatTurn>) {
      return (data as List)
              .map((e) => deserialize<_i8706h65.CoachChatTurn>(e))
              .toList()
          as T;
    }
    if (t == List<_ia360mkf.OpeningSummary>) {
      return (data as List)
              .map((e) => deserialize<_ia360mkf.OpeningSummary>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i74xdee0.LessonInfo>) {
      return (data as List)
              .map((e) => deserialize<_i74xdee0.LessonInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i3qvqsky.PuzzleTheme>) {
      return (data as List)
              .map((e) => deserialize<_i3qvqsky.PuzzleTheme>(e))
              .toList()
          as T;
    }
    final modules = dataClassName == null
        ? deserializationMetadata.modulesForType(t)
        : deserializationMetadata.modules;
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _is.DeserializationTypeNotFoundException catch (_) {}
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
      _iw7xoepe.GameSummary => 'GameSummary',
      _i9cvgeji.LessonInfo => 'LessonInfo',
      _iv2n46oe.LessonProgress => 'LessonProgress',
      _ivloy9zq.MistakeDrill => 'MistakeDrill',
      _itry22ja.MistakeDrillResult => 'MistakeDrillResult',
      _i54knsp5.MoveAnalysis => 'MoveAnalysis',
      _ixbtpo4c.MoveClass => 'MoveClass',
      _iwec8a2i.OpeningCourseInfo => 'OpeningCourseInfo',
      _ini0nuhb.OpeningStep => 'OpeningStep',
      _icil087y.OpeningSummary => 'OpeningSummary',
      _i2ix780o.PlayerProgress => 'PlayerProgress',
      _ifxq8anc.PlayerStats => 'PlayerStats',
      _i1k6u0te.PuzzleAttempt => 'PuzzleAttempt',
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
      case _iw7xoepe.GameSummary():
        return 'GameSummary';
      case _i9cvgeji.LessonInfo():
        return 'LessonInfo';
      case _iv2n46oe.LessonProgress():
        return 'LessonProgress';
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
      case _ifxq8anc.PlayerStats():
        return 'PlayerStats';
      case _i1k6u0te.PuzzleAttempt():
        return 'PuzzleAttempt';
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
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'GameSummary') {
      return deserialize<_iw7xoepe.GameSummary>(data['data']);
    }
    if (dataClassName == 'LessonInfo') {
      return deserialize<_i9cvgeji.LessonInfo>(data['data']);
    }
    if (dataClassName == 'LessonProgress') {
      return deserialize<_iv2n46oe.LessonProgress>(data['data']);
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
    if (dataClassName == 'PlayerStats') {
      return deserialize<_ifxq8anc.PlayerStats>(data['data']);
    }
    if (dataClassName == 'PuzzleAttempt') {
      return deserialize<_i1k6u0te.PuzzleAttempt>(data['data']);
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
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('mrchesscoach', this);
    _iacs.Protocol().registerHostProtocol('mrchesscoach', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i12dxgql.ChessGame:
        return _i12dxgql.ChessGame.t;
      case _iw7xoepe.GameSummary:
        return _iw7xoepe.GameSummary.t;
      case _iv2n46oe.LessonProgress:
        return _iv2n46oe.LessonProgress.t;
      case _i54knsp5.MoveAnalysis:
        return _i54knsp5.MoveAnalysis.t;
      case _ifxq8anc.PlayerStats:
        return _ifxq8anc.PlayerStats.t;
      case _i1k6u0te.PuzzleAttempt:
        return _i1k6u0te.PuzzleAttempt.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
