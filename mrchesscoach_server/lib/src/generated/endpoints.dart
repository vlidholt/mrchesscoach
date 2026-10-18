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
import 'package:mrchesscoach_server/src/generated/chess/models/player_color.dart'
    as _i5r84o7o;
import 'package:mrchesscoach_server/src/generated/coach/models/coach_chat_turn.dart'
    as _i8706h65;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../chess/game_endpoint.dart' as _ixk7u8pp;
import '../coach/coach_endpoint.dart' as _i3gqcq2l;
import '../coach/learn_endpoint.dart' as _inqw29ed;
import '../coach/progress_endpoint.dart' as _if24kgls;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'game': _ixk7u8pp.GameEndpoint()
        ..initialize(
          server,
          'game',
          null,
        ),
      'coach': _i3gqcq2l.CoachEndpoint()
        ..initialize(
          server,
          'coach',
          null,
        ),
      'learn': _inqw29ed.LearnEndpoint()
        ..initialize(
          server,
          'learn',
          null,
        ),
      'progress': _if24kgls.ProgressEndpoint()
        ..initialize(
          server,
          'progress',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['game'] = _is.EndpointConnector(
      name: 'game',
      endpoint: endpoints['game']!,
      methodConnectors: {
        'levels': _is.MethodConnector(
          name: 'levels',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['game'] as _ixk7u8pp.GameEndpoint).levels(session),
        ),
        'startGame': _is.MethodConnector(
          name: 'startGame',
          params: {
            'level': _is.ParameterDescription(
              name: 'level',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'color': _is.ParameterDescription(
              name: 'color',
              type: _is.getType<_i5r84o7o.PlayerColor?>(),
              nullable: true,
            ),
            'coachEnabled': _is.ParameterDescription(
              name: 'coachEnabled',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['game'] as _ixk7u8pp.GameEndpoint).startGame(
                    session,
                    params['level'],
                    params['color'],
                    params['coachEnabled'],
                  ),
        ),
        'activeGame': _is.MethodConnector(
          name: 'activeGame',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint)
                  .activeGame(session),
        ),
        'finishedGames': _is.MethodConnector(
          name: 'finishedGames',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint)
                  .finishedGames(session),
        ),
        'getGame': _is.MethodConnector(
          name: 'getGame',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint).getGame(
                session,
                params['gameId'],
              ),
        ),
        'move': _is.MethodConnector(
          name: 'move',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'uci': _is.ParameterDescription(
              name: 'uci',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint).move(
                session,
                params['gameId'],
                params['uci'],
              ),
        ),
        'retry': _is.MethodConnector(
          name: 'retry',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint).retry(
                session,
                params['gameId'],
              ),
        ),
        'playOn': _is.MethodConnector(
          name: 'playOn',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint).playOn(
                session,
                params['gameId'],
              ),
        ),
        'undo': _is.MethodConnector(
          name: 'undo',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint).undo(
                session,
                params['gameId'],
              ),
        ),
        'resign': _is.MethodConnector(
          name: 'resign',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['game'] as _ixk7u8pp.GameEndpoint).resign(
                session,
                params['gameId'],
              ),
        ),
      },
    );
    connectors['coach'] = _is.EndpointConnector(
      name: 'coach',
      endpoint: endpoints['coach']!,
      methodConnectors: {
        'explainMove': _is.MethodConnector(
          name: 'explainMove',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'ply': _is.ParameterDescription(
              name: 'ply',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['coach'] as _i3gqcq2l.CoachEndpoint).explainMove(
                    session,
                    params['gameId'],
                    params['ply'],
                  ),
        ),
        'moveVerdicts': _is.MethodConnector(
          name: 'moveVerdicts',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['coach'] as _i3gqcq2l.CoachEndpoint).moveVerdicts(
                    session,
                    params['gameId'],
                  ),
        ),
        'hint': _is.MethodConnector(
          name: 'hint',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'level': _is.ParameterDescription(
              name: 'level',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['coach'] as _i3gqcq2l.CoachEndpoint).hint(
                session,
                params['gameId'],
                params['level'],
              ),
        ),
        'threat': _is.MethodConnector(
          name: 'threat',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['coach'] as _i3gqcq2l.CoachEndpoint).threat(
                session,
                params['gameId'],
              ),
        ),
        'ask': _is.MethodConnector(
          name: 'ask',
          params: {
            'fen': _is.ParameterDescription(
              name: 'fen',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'recentSan': _is.ParameterDescription(
              name: 'recentSan',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'question': _is.ParameterDescription(
              name: 'question',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'history': _is.ParameterDescription(
              name: 'history',
              type: _is.getType<List<_i8706h65.CoachChatTurn>>(),
              nullable: false,
            ),
            'studentColor': _is.ParameterDescription(
              name: 'studentColor',
              type: _is.getType<_i5r84o7o.PlayerColor?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['coach'] as _i3gqcq2l.CoachEndpoint).ask(
                session,
                params['fen'],
                params['recentSan'],
                params['question'],
                params['history'],
                params['studentColor'],
              ),
        ),
        'review': _is.MethodConnector(
          name: 'review',
          params: {
            'gameId': _is.ParameterDescription(
              name: 'gameId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['coach'] as _i3gqcq2l.CoachEndpoint).review(
                session,
                params['gameId'],
              ),
        ),
      },
    );
    connectors['learn'] = _is.EndpointConnector(
      name: 'learn',
      endpoint: endpoints['learn']!,
      methodConnectors: {
        'openings': _is.MethodConnector(
          name: 'openings',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['learn'] as _inqw29ed.LearnEndpoint)
                  .openings(session),
        ),
        'opening': _is.MethodConnector(
          name: 'opening',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).opening(
                    session,
                    params['id'],
                  ),
        ),
        'completeOpening': _is.MethodConnector(
          name: 'completeOpening',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['learn'] as _inqw29ed.LearnEndpoint)
                  .completeOpening(
                    session,
                    params['id'],
                  ),
        ),
        'legalMoves': _is.MethodConnector(
          name: 'legalMoves',
          params: {
            'fen': _is.ParameterDescription(
              name: 'fen',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).legalMoves(
                    session,
                    params['fen'],
                  ),
        ),
        'startOpeningGame': _is.MethodConnector(
          name: 'startOpeningGame',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'level': _is.ParameterDescription(
              name: 'level',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['learn'] as _inqw29ed.LearnEndpoint)
                  .startOpeningGame(
                    session,
                    params['id'],
                    params['level'],
                  ),
        ),
        'lessons': _is.MethodConnector(
          name: 'lessons',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['learn'] as _inqw29ed.LearnEndpoint)
                  .lessons(session),
        ),
        'startLesson': _is.MethodConnector(
          name: 'startLesson',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).startLesson(
                    session,
                    params['id'],
                  ),
        ),
        'puzzleSets': _is.MethodConnector(
          name: 'puzzleSets',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['learn'] as _inqw29ed.LearnEndpoint)
                  .puzzleSets(session),
        ),
        'nextPuzzle': _is.MethodConnector(
          name: 'nextPuzzle',
          params: {
            'setKey': _is.ParameterDescription(
              name: 'setKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).nextPuzzle(
                    session,
                    params['setKey'],
                  ),
        ),
        'puzzleMove': _is.MethodConnector(
          name: 'puzzleMove',
          params: {
            'puzzleId': _is.ParameterDescription(
              name: 'puzzleId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'uci': _is.ParameterDescription(
              name: 'uci',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).puzzleMove(
                    session,
                    params['puzzleId'],
                    params['uci'],
                  ),
        ),
        'explainPuzzle': _is.MethodConnector(
          name: 'explainPuzzle',
          params: {
            'puzzleId': _is.ParameterDescription(
              name: 'puzzleId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).explainPuzzle(
                    session,
                    params['puzzleId'],
                  ),
        ),
        'nextMistake': _is.MethodConnector(
          name: 'nextMistake',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['learn'] as _inqw29ed.LearnEndpoint)
                  .nextMistake(session),
        ),
        'mistakeMove': _is.MethodConnector(
          name: 'mistakeMove',
          params: {
            'analysisId': _is.ParameterDescription(
              name: 'analysisId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'uci': _is.ParameterDescription(
              name: 'uci',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['learn'] as _inqw29ed.LearnEndpoint).mistakeMove(
                    session,
                    params['analysisId'],
                    params['uci'],
                  ),
        ),
      },
    );
    connectors['progress'] = _is.EndpointConnector(
      name: 'progress',
      endpoint: endpoints['progress']!,
      methodConnectors: {
        'progress': _is.MethodConnector(
          name: 'progress',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['progress'] as _if24kgls.ProgressEndpoint)
                  .progress(session),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }
}
