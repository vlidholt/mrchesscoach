# Flutter & Serverpod project

This project is a Flutter app (frontend) backed by a Serverpod server (backend). Always build the app's backend with Serverpod.
Build for multiple users, use Serverpod's built-in authentication, which is already set up in `lib/server.dart`.

## The app: Mr. Chess Coach

Signed-in users play chess against Stockfish at 8 named levels (Novice to Grandmaster) with an AI coach, and train with opening courses, rated puzzles, position lessons and a mistake trainer. Games are saved per user and can be resumed and reviewed.

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
- `coach_writer.dart`: all prompts. The model only gets engine-verified facts (lines in SAN, win chances, loose pieces from `position_facts.dart`) and must not invent moves. Every text has a template fallback, so the app works without the model (and when the per-user rate limit in `CoachEndpoint` is hit).
- `coach_endpoint.dart`: `client.coach.*`: `moveVerdicts`, `explainMove` (cached on the row), `hint(level 1-3)` (idea, piece, move), `threat` (null-move analysis), `ask` (chat about any FEN), `review` (accuracy, win graph, key moments, cached AI summary in `game_summary`).
- `learn_endpoint.dart`: `client.learn.*`: opening courses (`openings`, `opening`, `completeOpening`, `startOpeningGame`), position lessons (`lessons`, `startLesson`), puzzles (`puzzleSets`, `nextPuzzle`, `puzzleMove`, `explainPuzzle`; the solution stays on the server, the active puzzle is kept in memory per user), the mistake trainer (`nextMistake`, `mistakeMove`) and `legalMoves(fen)`.
- `progress_endpoint.dart`: `client.progress.progress()`: stats, charts data, theme strengths, mistake motifs and rule-based recommendations.
- `stats_service.dart`: puzzle rating (Elo with a settling K), streaks, lesson progress.
- `content/`: hand-written `openings.dart` (12 courses with per-move commentary) and `lessons.dart` (endgame and middlegame positions), validated by `test/unit/openings_content_test.dart` and `test/unit/lessons_content_test.dart` (the latter checks every position with Stockfish). `catalog.dart` converts them for the API; `opening_book.dart` gives "book" verdicts and opening names.
- `puzzles.dart`: loads `mrchesscoach_server/data/puzzles.csv`: 4,894 puzzles selected from the Lichess puzzle database (CC0; popular, well-rated, spread over 32 themes and ratings 400–2800, plus opening traps). The server must run with `mrchesscoach_server` as its working directory (also for Docker).

### Flutter (`mrchesscoach_flutter/lib/`)

- `theme.dart`: palette (onyx, ivory, gold), `Typo` text styles (Cormorant Garamond, Manrope, IBM Plex Mono), `AmbientBackground`, `Panel`, `GoldButton`, `GhostButton`.
- `game/chess_model.dart`: a small, display-only chess model (FEN parsing, applying a move). `dartchess` does NOT support web (64-bit bitboards), so the app must not depend on it. Legal moves always come from the server.
- `game/game_controller.dart`: `ChangeNotifier` for one game: optimistic moves, verdicts, the coach pause (retry / show best / play on), the hint ladder, threats and explanations (key moments are explained automatically).
- `widgets/chess_board.dart`: the board, drawn from `assets/images/board.png` and `assets/images/pieces/{w,b}{k,q,r,b,n,p}.png` (grid fractions are the `_grid*` constants). Tap and drag to move (raw pointer events via `Listener`), animations, coloured `BoardArrow`s, a pulsing marked square, verdict badges, the promotion picker.
- `widgets/coach_panel.dart` (coach avatar, speech bubble, typewriter text), `widgets/ask_coach_dialog.dart` (the "Ask the coach" chat, only opened from a button), `widgets/move_badge.dart` (verdict colours and badges), `widgets/game_panels.dart` (eval bar, player bars, move list with badges).
- `screens/`: sign-in; lobby with Play / Learn / Progress tabs (`learn_view.dart`, `progress_screen.dart`); game screen (coach panel; side panel at ≥1000px, stacked on phones); `review_screen.dart`; `opening_screen.dart` (learn walkthrough, drill, play out); `puzzle_screen.dart` (rated puzzles and the mistake trainer).

The assets were sliced from `reference/`. Black pieces have a baked-in light rim so they stay readable on dark squares.

Known quirk: when many files change at once, `serverpod start`'s incremental generation can leave the generated code half-written. Run `serverpod generate` in the server package to fix it.

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `mrchesscoach_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

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
