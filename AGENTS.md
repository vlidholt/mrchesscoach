# Flutter & Serverpod project

This project is a Flutter app (frontend) backed by a Serverpod server (backend). Always build the app's backend with Serverpod.
Build for multiple users, use Serverpod's built-in authentication, which is already set up in `lib/server.dart`.

The server and Flutter app run under the Serverpod runner, a background process per server package. The user attaches to it with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then call `tail_runner_logs` to learn whether it is still starting or why it stopped. If nothing is running, start it with `serverpod runner start` in `mrchesscoach_server`, which returns once the server is up and leaves it running for the user to attach to. If it fails, fix the cause it reports (a build error, a port held by another process, Docker) instead of retrying; only a `serverpod runner start` your shell killed on a timeout is run again, since the runner keeps starting. Flutter apps declared with `auto_launch` launch once the user attaches; launch any app before that with the MCP tool `spawn_flutter_app`. Leave the runner running, and run `serverpod runner stop` only when asked.

While running, the runner watches for file changes to run incremental code generation and hot reload both the server and the Flutter app. `serverpod runner status` prints its state and the server addresses, which are not always the configured ports when another Serverpod runner on the machine holds them.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

## The app: Mr. Chess Coach

Signed-in users (email sign-in with one-time codes) play chess against "the coach" at 8 named strengths (Novice to Grandmaster). The coach is both the opponent and the teacher: he grades every player move (he does not comment on his own moves in games), and trains you with opening courses, rated puzzles, position lessons and a mistake trainer. Games are saved per user and can be resumed and reviewed.

Voice: never mention Stockfish, engines or computers in anything the user sees (UI copy, templates, AI prompts). The opponent is "the coach" / "I". Coach messages are short (1–2 sentences) so they fit the speech bubbles on a phone.

### Server (`mrchesscoach_server/lib/src/`)

Chess (`chess/`):

- `game_endpoint.dart`: `client.game.*` (`levels`, `startGame(level, color?, coachEnabled)`, `activeGame`, `finishedGames`, `getGame`, `move`, `retry`, `playOn`, `undo`, `resign`). Requires login. The server is the authority on the rules. With the coach on, a mistake, miss or blunder pauses the game (`awaitingDecision`) until `retry` (the move is retracted but kept for the mistake trainer) or `playOn`. Every response carries `lastFeedback`/`opponentFeedback` (MoveAnalysis) and `legalMoves` (non-persisted). Lesson goals (draw / keep advantage) are checked after each turn. `createGame` is shared with the learn endpoint.
- `chess_engine.dart`: the Stockfish wrapper, using the `stockfish_dart` package from pub.dev. Only ONE embedded Stockfish can run per process, so it is a singleton guarded by a lock (tests call `ChessEngine.instance.shutdown()` in `tearDownAll`; `dart_test.yaml` runs files with `concurrency: 1`). `analyse()` returns multi-PV lines with White-relative scores.
- `levels.dart`: the level definitions. The three lowest levels use Skill Level 0 with a shallow depth, because Stockfish's Elo limit bottoms out around 1320.
- `chess_rules.dart`: replays UCI moves with `dartchess`, optionally from a start FEN (lessons).

Coach (`coach/`):

- `game_coach.dart`: analyses each position once (MultiPV 2), caches recent analyses on the game (`analysisCache`), classifies every move of both sides and stores `MoveAnalysis` rows. `backfill` fills in missing verdicts for reviews.
- `move_classifier.dart`: winning chances (Lichess curve), the chess.com-style classes (brilliant, great, best, excellent, good, book, inaccuracy, mistake, miss, blunder) and Lichess accuracy.
- `coach_ai.dart`: the language model via `dartantic_ai`. Configured by passwords: `geminiApiKey` (also `openaiApiKey`/`anthropicApiKey`) and optional `coachModel` (`provider:model`, default `google:gemini-3.8-flash`; older Gemini models are retired for new keys). `CoachAi.override` swaps in a fake for tests.
- `coach_writer.dart`: all prompts. The model only gets engine-verified facts (lines in SAN, win chances, loose pieces from `position_facts.dart`) and must not invent moves. The system prompt keeps answers brief and in the coach's voice (the opponent's moves are "my" moves). Every text has a template fallback, so the app works without the model (and when the per-user rate limit in `CoachEndpoint` is hit); `_clip` trims long answers at a sentence end.
- `coach_endpoint.dart`: `client.coach.*`: `moveVerdicts`, `explainMove` (cached on the row), `hint(level 1-3)` (idea, piece, move), `threat` (null-move analysis), `ask` (chat about any FEN), `review` (accuracy, win graph, key moments, cached AI summary in `game_summary`).
- `learn_endpoint.dart`: `client.learn.*`: opening courses (`openings`, `opening`, `completeOpening`, `startOpeningGame`), position lessons (`lessons`, `startLesson`), puzzles (`puzzleSets`, `nextPuzzle`, `puzzleMove`, `explainPuzzle`; the solution stays on the server, the active puzzle is kept in memory per user), the mistake trainer (`nextMistake`, `mistakeMove`) and `legalMoves(fen)`.
- `progress_endpoint.dart`: `client.progress.progress()`: stats, charts data, theme strengths, mistake motifs and rule-based recommendations.
- `stats_service.dart`: puzzle rating (Elo with a settling K), streaks, lesson progress.
- `content/`: hand-written `openings.dart` (12 courses with per-move commentary) and `lessons.dart` (endgame and middlegame positions), validated by `test/unit/openings_content_test.dart` and `test/unit/lessons_content_test.dart` (the latter checks every position with Stockfish). `catalog.dart` converts them for the API; `opening_book.dart` gives "book" verdicts and opening names.
- `puzzles.dart`: parses `content/puzzle_data.dart`, a CSV compiled into the server: 4,894 puzzles selected from the Lichess puzzle database (CC0; popular, well-rated, spread over 32 themes and ratings 400–2800, plus opening traps). It is Dart code on purpose: Serverpod Cloud builds its own image with only the executable, `config/`, `web/` and `migrations/`, so data files next to the server are lost in production. Keep any runtime resource the server needs in Dart code (or under `web/` if it may be public). `test/unit/puzzle_catalog_test.dart` guards this.
- Auth: `auth/email_idp_endpoint.dart` extends `EmailOtpIdpBaseEndpoint` (passwordless sign-in with one-time codes; in development the codes are logged by the server, see `tail_runner_logs`).

### Flutter (`mrchesscoach_flutter/lib/`)

Scrollables can be dragged with a mouse or trackpad too (`scrollBehavior` in `main.dart`), so carousels swipe on the web.

Every main screen must fit a phone (down to 375x667) WITHOUT scrolling: compute the board size from the remaining height and let the coach's chat area take what is left (long messages scroll inside it). Layouts: phone, tablet portrait (≥`Breakpoints.tablet` 700, centered column) and wide (≥`Breakpoints.desktop` 1000 or a landscape tablet: board left, `Panel` right).

- `theme.dart`: palette (onyx, ivory, gold; `paper`/`ink` for speech bubbles), `Typo` text styles (Cormorant Garamond, Manrope, IBM Plex Mono; bundled in `assets/fonts/` as Latin subsets of only the weights used, built by `tool/subset_fonts.py`, so the web engine loads them before the app starts; no `google_fonts`, no runtime fetching. A new weight or a character outside the subset needs a rebuild of the fonts), `Breakpoints`, `AmbientBackground` (the GLSL shader `shaders/ambient.frag`: lamp light with slow light shafts, tintable via `tint`/`intensity`, with a gradient fallback, plus rising embers), `Panel`, `GoldButton`, `GhostButton`.
- `widgets/fx.dart`: the effects kit. `FxScope` (one per screen) hosts a particle layer (sprite atlas via `drawAtlas`: sparks, stars, flares, confetti, shards, smoke, shockwaves, fireworks), `shake()` and `flash()`; fire effects from any widget with `context.fx(localPoint, (scope, at) => ...)`. Also `LightRays`, `Shine`, `GoldText`, `Pressable`, `Entrance`, `EmberField` and `FxPageRoute`/`pushFx` (circular reveal). Effects must work on the web build (no flutter_gpu: Serverpod Cloud serves the Flutter web app).
- `game/chess_model.dart`: a small, display-only chess model (FEN parsing, applying a move). `dartchess` does NOT support web (64-bit bitboards), so the app must not depend on it. Legal moves always come from the server.
- `game/game_controller.dart`: `ChangeNotifier` for one game: optimistic moves, verdicts, the coach pause (retry / show best / play on), the hint ladder, threats and explanations (key moments are explained automatically).
- `widgets/chess_board.dart`: the board, drawn from `assets/images/board.png` (coordinates are erased from the art and drawn on the frame so they follow the orientation) and `assets/images/pieces/{w,b}{k,q,r,b,n,p}.png` (grid fractions are the `_grid*` constants). Tap and drag to move (raw pointer events via `Listener`), animations, coloured `BoardArrow`s, a pulsing marked square, verdict badges, the promotion picker, and effects (move trails, capture shatter, check shockwave, verdict flares; `effects: false` while browsing).
- `widgets/coach_avatar.dart`: `CoachMood` (neutral, happy, thoughtful, surprised; `assets/images/coach/*.webp`), `CoachAvatar` (medallion that swaps expressions with a reaction pop; it only breathes and bobs with `lively: true`, which the game uses), `CoachBubble` (ivory paper; use `BubbleText` styles inside), `CoachChat` (avatar + scrolling bubbles), `CoachSays`, `TypewriterText`, `CoachThinking`.
- `widgets/coach_panel.dart`: the game's chat (`GameCoachChat`: the verdict on the player's move, hints, threats), `gameMood`/`gameAccent`, and the `PauseBar` that replaces the action bar after a mistake. `widgets/ask_coach_dialog.dart` (the "Ask" chat), `widgets/move_badge.dart` (verdict colours and badges), `widgets/game_panels.dart` (`EvalStrip`/`EvalBar`, `MaterialRow`, `MoveStrip` with ‹ › browsing, `MoveList`, `ActionBar`), `widgets/recent_games.dart`.
- `screens/`: sign-in (armchair coach + OTP form); lobby (`PlayHome` hero with Continue / New game, the `NewGameSheet` level carousel; Play / Learn / Progress tabs, bottom tabs on phones; recent games live on the Progress tab); game screen (layout of `reference/game_layout.webp`: top bar with the level badge on the right and a status line only for check, a pause or the result; an eval strip without numbers; coach chat; board; captured pieces; move strip; action bar Resign · Hint · Threats · Ask · Undo; browse earlier positions with ‹ › or arrow keys; the board is always shown from the player's side); `review_screen.dart`; `opening_screen.dart` (learn walkthrough, drill, play out); `puzzle_screen.dart` (rated puzzles and the mistake trainer).

The art was sliced from `reference/` (`board.webp`, `pieces.webp`, `coach_heads.webp`, `coach_armchair.webp`). Black pieces have a baked-in light rim so they stay readable on dark squares.

Known quirk: when many files change at once, the runner's incremental generation can leave the generated code half-written. Run `serverpod generate` in the server package to fix it. Flutter changes to `const` classes, assets, shaders or `pubspec.yaml` are rejected by hot reload: `hot_restart` after them.

## Working with the server

ALWAYS use the MCP server instead of the command line for the tasks below. The `serverpod runner` commands are the exception: they manage the stack itself. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_runner_logs` to read the output of the runner itself (code generation, compilation, Docker, raw server output). The only tool that also works while the server is starting or after it stopped.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `mrchesscoach_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the MCP is not available or `serverpod runner start` cannot bring the server up, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; the runner applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `mrchesscoach_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.
