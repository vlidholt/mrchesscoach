BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "chess_game" ADD COLUMN "coachEnabled" boolean NOT NULL DEFAULT true;
ALTER TABLE "chess_game" ADD COLUMN "startFen" text;
ALTER TABLE "chess_game" ADD COLUMN "lessonId" text;
ALTER TABLE "chess_game" ADD COLUMN "awaitingDecision" boolean NOT NULL DEFAULT false;
ALTER TABLE "chess_game" ADD COLUMN "retries" bigint NOT NULL DEFAULT 0;
ALTER TABLE "chess_game" ADD COLUMN "analysisCache" text;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "game_summary" (
    "id" bigserial PRIMARY KEY,
    "gameId" bigint NOT NULL,
    "summary" text NOT NULL,
    "plies" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "game_summary_game_idx" ON "game_summary" USING btree ("gameId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "lesson_progress" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "lessonId" text NOT NULL,
    "kind" text NOT NULL,
    "completed" boolean NOT NULL DEFAULT false,
    "attempts" bigint NOT NULL DEFAULT 0,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "lesson_progress_idx" ON "lesson_progress" USING btree ("userId", "lessonId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "move_analysis" (
    "id" bigserial PRIMARY KEY,
    "gameId" bigint NOT NULL,
    "userId" uuid,
    "ply" bigint NOT NULL,
    "uci" text NOT NULL,
    "san" text NOT NULL,
    "byPlayer" boolean NOT NULL,
    "classification" text NOT NULL,
    "winBefore" double precision NOT NULL,
    "winAfter" double precision NOT NULL,
    "accuracy" double precision NOT NULL,
    "evalCp" bigint,
    "evalMate" bigint,
    "bestUci" text,
    "bestSan" text,
    "bestLine" json NOT NULL,
    "replyLine" json NOT NULL,
    "fenBefore" text NOT NULL,
    "headline" text,
    "explanation" text,
    "lesson" text,
    "motif" text,
    "retracted" boolean NOT NULL DEFAULT false,
    "drillAttempts" bigint NOT NULL DEFAULT 0,
    "drillSuccesses" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "move_analysis_game_idx" ON "move_analysis" USING btree ("gameId", "ply");
CREATE INDEX "move_analysis_user_idx" ON "move_analysis" USING btree ("userId", "classification");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "player_stats" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "puzzleRating" bigint NOT NULL DEFAULT 1200,
    "puzzleStreak" bigint NOT NULL DEFAULT 0,
    "bestPuzzleStreak" bigint NOT NULL DEFAULT 0,
    "puzzlesSolved" bigint NOT NULL DEFAULT 0,
    "puzzlesFailed" bigint NOT NULL DEFAULT 0,
    "lastActiveDay" text,
    "dayStreak" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "player_stats_user_idx" ON "player_stats" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "puzzle_attempt" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "puzzleId" text NOT NULL,
    "solved" boolean NOT NULL,
    "puzzleRating" bigint NOT NULL,
    "ratingAfter" bigint NOT NULL,
    "themes" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "puzzle_attempt_user_idx" ON "puzzle_attempt" USING btree ("userId", "createdAt");


--
-- MIGRATION VERSION FOR mrchesscoach
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('mrchesscoach', '20261018001407033-ai-coach', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018001407033-ai-coach', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
