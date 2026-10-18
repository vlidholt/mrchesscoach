BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "chess_game" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid,
    "level" bigint NOT NULL,
    "playerColor" text NOT NULL,
    "moves" json NOT NULL,
    "sanMoves" json NOT NULL,
    "fen" text NOT NULL,
    "status" text NOT NULL,
    "endReason" text,
    "evalCp" bigint,
    "evalMate" bigint,
    "hintsUsed" bigint NOT NULL DEFAULT 0,
    "takebacks" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "chess_game_user_idx" ON "chess_game" USING btree ("userId", "status");


--
-- MIGRATION VERSION FOR mrchesscoach
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('mrchesscoach', '20261017210107817-chess-games', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261017210107817-chess-games', "timestamp" = now();

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
