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
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:mrchesscoach_client/src/protocol/chess/models/chess_game.dart'
    as _i0ghl5l0;
import 'package:mrchesscoach_client/src/protocol/chess/models/chess_level.dart'
    as _iy8melaj;
import 'package:mrchesscoach_client/src/protocol/chess/models/player_color.dart'
    as _itisbljg;
import 'package:mrchesscoach_client/src/protocol/coach/models/coach_chat_turn.dart'
    as _iblxx7xb;
import 'package:mrchesscoach_client/src/protocol/coach/models/coach_hint.dart'
    as _isqdhgxt;
import 'package:mrchesscoach_client/src/protocol/coach/models/game_review.dart'
    as _ifxqbir3;
import 'package:mrchesscoach_client/src/protocol/coach/models/lesson_info.dart'
    as _ivg9h4pb;
import 'package:mrchesscoach_client/src/protocol/coach/models/mistake_drill.dart'
    as _ilffgy55;
import 'package:mrchesscoach_client/src/protocol/coach/models/mistake_drill_result.dart'
    as _iqij264h;
import 'package:mrchesscoach_client/src/protocol/coach/models/move_analysis.dart'
    as _ipaj7svr;
import 'package:mrchesscoach_client/src/protocol/coach/models/opening_course_info.dart'
    as _icfcy0qd;
import 'package:mrchesscoach_client/src/protocol/coach/models/opening_summary.dart'
    as _igop3rv4;
import 'package:mrchesscoach_client/src/protocol/coach/models/player_progress.dart'
    as _ipli8hx5;
import 'package:mrchesscoach_client/src/protocol/coach/models/puzzle_info.dart'
    as _iud34qwb;
import 'package:mrchesscoach_client/src/protocol/coach/models/puzzle_move_result.dart'
    as _iq7es88f;
import 'package:mrchesscoach_client/src/protocol/coach/models/puzzle_theme.dart'
    as _ifkuowcx;
import 'package:mrchesscoach_client/src/protocol/coach/models/threat_insight.dart'
    as _ih497wwc;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Plays chess against the computer. Every game belongs to the signed-in
/// user, and the server is the authority on the rules.
///
/// With the coach on, every move gets a verdict, and after a mistake the
/// game pauses until the player retries or plays on.
/// {@category Endpoint}
class EndpointGame extends _isc.EndpointRef {
  EndpointGame(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'game';

  /// The difficulty levels, weakest first.
  _ida.Future<List<_iy8melaj.ChessLevel>> levels() =>
      caller.callServerEndpoint<List<_iy8melaj.ChessLevel>>(
        'game',
        'levels',
        {},
      );

  /// Starts a new game. If [color] is null the side is picked at random.
  ///
  /// Any unfinished game is marked as abandoned. When the player is Black,
  /// the computer has already made its first move in the returned game.
  _ida.Future<_i0ghl5l0.ChessGame> startGame(
    int level,
    _itisbljg.PlayerColor? color,
    bool coachEnabled,
  ) => caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
    'game',
    'startGame',
    {
      'level': level,
      'color': color,
      'coachEnabled': coachEnabled,
    },
  );

  /// The user's unfinished game, if any.
  _ida.Future<_i0ghl5l0.ChessGame?> activeGame() =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame?>(
        'game',
        'activeGame',
        {},
      );

  /// The user's finished games, most recent first.
  _ida.Future<List<_i0ghl5l0.ChessGame>> finishedGames() =>
      caller.callServerEndpoint<List<_i0ghl5l0.ChessGame>>(
        'game',
        'finishedGames',
        {},
      );

  /// One of the user's games.
  _ida.Future<_i0ghl5l0.ChessGame> getGame(int gameId) =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
        'game',
        'getGame',
        {'gameId': gameId},
      );

  /// Plays the player's [uci] move. With the coach on and a mistake played,
  /// the game pauses (`awaitingDecision`); otherwise the computer replies.
  _ida.Future<_i0ghl5l0.ChessGame> move(
    int gameId,
    String uci,
  ) => caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
    'game',
    'move',
    {
      'gameId': gameId,
      'uci': uci,
    },
  );

  /// Takes back the move the coach paused on, so the player can try again.
  _ida.Future<_i0ghl5l0.ChessGame> retry(int gameId) =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
        'game',
        'retry',
        {'gameId': gameId},
      );

  /// Keeps the move the coach paused on and lets the computer reply.
  _ida.Future<_i0ghl5l0.ChessGame> playOn(int gameId) =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
        'game',
        'playOn',
        {'gameId': gameId},
      );

  /// Takes back the player's last move (and the computer's reply to it).
  ///
  /// Also reopens a game that ended on the board, but not a resigned one.
  _ida.Future<_i0ghl5l0.ChessGame> undo(int gameId) =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
        'game',
        'undo',
        {'gameId': gameId},
      );

  /// Resigns the game.
  _ida.Future<_i0ghl5l0.ChessGame> resign(int gameId) =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
        'game',
        'resign',
        {'gameId': gameId},
      );
}

/// The AI coach: explanations, hints, threats, questions and reviews.
/// {@category Endpoint}
class EndpointCoach extends _isc.EndpointRef {
  EndpointCoach(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'coach';

  /// The coach's explanation of the move at [ply] of a game. Cached.
  _ida.Future<_ipaj7svr.MoveAnalysis> explainMove(
    int gameId,
    int ply,
  ) => caller.callServerEndpoint<_ipaj7svr.MoveAnalysis>(
    'coach',
    'explainMove',
    {
      'gameId': gameId,
      'ply': ply,
    },
  );

  /// The verdicts recorded so far for a game, in move order.
  _ida.Future<List<_ipaj7svr.MoveAnalysis>> moveVerdicts(int gameId) =>
      caller.callServerEndpoint<List<_ipaj7svr.MoveAnalysis>>(
        'coach',
        'moveVerdicts',
        {'gameId': gameId},
      );

  /// A hint for the player's move: 1 = the idea, 2 = the piece, 3 = the move.
  _ida.Future<_isqdhgxt.CoachHint> hint(
    int gameId,
    int level,
  ) => caller.callServerEndpoint<_isqdhgxt.CoachHint>(
    'coach',
    'hint',
    {
      'gameId': gameId,
      'level': level,
    },
  );

  /// What the opponent threatens: their best move if they could move again.
  _ida.Future<_ih497wwc.ThreatInsight> threat(int gameId) =>
      caller.callServerEndpoint<_ih497wwc.ThreatInsight>(
        'coach',
        'threat',
        {'gameId': gameId},
      );

  /// Answers a question about the position [fen].
  _ida.Future<String> ask(
    String fen,
    List<String> recentSan,
    String question,
    List<_iblxx7xb.CoachChatTurn> history,
    _itisbljg.PlayerColor? studentColor,
  ) => caller.callServerEndpoint<String>(
    'coach',
    'ask',
    {
      'fen': fen,
      'recentSan': recentSan,
      'question': question,
      'history': history,
      'studentColor': studentColor,
    },
  );

  /// A full review of a game. Missing verdicts are filled in first, so this
  /// can take a few seconds for older games.
  _ida.Future<_ifxqbir3.GameReview> review(int gameId) =>
      caller.callServerEndpoint<_ifxqbir3.GameReview>(
        'coach',
        'review',
        {'gameId': gameId},
      );
}

/// Openings, lessons, puzzles and the mistake trainer.
/// {@category Endpoint}
class EndpointLearn extends _isc.EndpointRef {
  EndpointLearn(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'learn';

  /// The opening courses.
  _ida.Future<List<_igop3rv4.OpeningSummary>> openings() =>
      caller.callServerEndpoint<List<_igop3rv4.OpeningSummary>>(
        'learn',
        'openings',
        {},
      );

  /// One opening course with its moves and commentary.
  _ida.Future<_icfcy0qd.OpeningCourseInfo> opening(String id) =>
      caller.callServerEndpoint<_icfcy0qd.OpeningCourseInfo>(
        'learn',
        'opening',
        {'id': id},
      );

  /// Marks an opening's drill as completed.
  _ida.Future<void> completeOpening(String id) =>
      caller.callServerEndpoint<void>(
        'learn',
        'completeOpening',
        {'id': id},
      );

  /// The legal moves in [fen], UCI to SAN (the app has no move generator).
  _ida.Future<Map<String, String>> legalMoves(String fen) =>
      caller.callServerEndpoint<Map<String, String>>(
        'learn',
        'legalMoves',
        {'fen': fen},
      );

  /// Starts a coached game from the end of an opening's main line.
  _ida.Future<_i0ghl5l0.ChessGame> startOpeningGame(
    String id,
    int level,
  ) => caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
    'learn',
    'startOpeningGame',
    {
      'id': id,
      'level': level,
    },
  );

  /// The endgame and middlegame lessons.
  _ida.Future<List<_ivg9h4pb.LessonInfo>> lessons() =>
      caller.callServerEndpoint<List<_ivg9h4pb.LessonInfo>>(
        'learn',
        'lessons',
        {},
      );

  /// Starts a lesson: a game from the lesson's position against
  /// full-strength Stockfish.
  _ida.Future<_i0ghl5l0.ChessGame> startLesson(String id) =>
      caller.callServerEndpoint<_i0ghl5l0.ChessGame>(
        'learn',
        'startLesson',
        {'id': id},
      );

  /// The puzzle sets, with the player's results on each.
  _ida.Future<List<_ifkuowcx.PuzzleTheme>> puzzleSets() =>
      caller.callServerEndpoint<List<_ifkuowcx.PuzzleTheme>>(
        'learn',
        'puzzleSets',
        {},
      );

  /// The next puzzle from [setKey], matched to the player's rating.
  _ida.Future<_iud34qwb.PuzzleInfo> nextPuzzle(String setKey) =>
      caller.callServerEndpoint<_iud34qwb.PuzzleInfo>(
        'learn',
        'nextPuzzle',
        {'setKey': setKey},
      );

  /// Checks the solver's move in the current puzzle.
  _ida.Future<_iq7es88f.PuzzleMoveResult> puzzleMove(
    String puzzleId,
    String uci,
  ) => caller.callServerEndpoint<_iq7es88f.PuzzleMoveResult>(
    'learn',
    'puzzleMove',
    {
      'puzzleId': puzzleId,
      'uci': uci,
    },
  );

  /// The coach explains why the last wrong move in the puzzle fails.
  _ida.Future<String> explainPuzzle(String puzzleId) =>
      caller.callServerEndpoint<String>(
        'learn',
        'explainPuzzle',
        {'puzzleId': puzzleId},
      );

  /// The next position from the player's games where they went wrong.
  _ida.Future<_ilffgy55.MistakeDrill?> nextMistake() =>
      caller.callServerEndpoint<_ilffgy55.MistakeDrill?>(
        'learn',
        'nextMistake',
        {},
      );

  /// Checks a move in a mistake drill. Any move about as good as the
  /// engine's best counts.
  _ida.Future<_iqij264h.MistakeDrillResult> mistakeMove(
    int analysisId,
    String uci,
  ) => caller.callServerEndpoint<_iqij264h.MistakeDrillResult>(
    'learn',
    'mistakeMove',
    {
      'analysisId': analysisId,
      'uci': uci,
    },
  );
}

/// The player's progress and the coach's suggestions.
/// {@category Endpoint}
class EndpointProgress extends _isc.EndpointRef {
  EndpointProgress(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'progress';

  _ida.Future<_ipli8hx5.PlayerProgress> progress() =>
      caller.callServerEndpoint<_ipli8hx5.PlayerProgress>(
        'progress',
        'progress',
        {},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    game = EndpointGame(this);
    coach = EndpointCoach(this);
    learn = EndpointLearn(this);
    progress = EndpointProgress(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointGame game;

  late final EndpointCoach coach;

  late final EndpointLearn learn;

  late final EndpointProgress progress;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'game': game,
    'coach': coach,
    'learn': learn,
    'progress': progress,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
