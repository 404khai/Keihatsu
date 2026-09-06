-- Phase 5 account sync: source-aware identities, durable history snapshots/tombstones,
-- and idempotent reading-time operations.
DROP INDEX IF EXISTS "library_entries_userId_mangaId_key";
CREATE UNIQUE INDEX "library_entries_userId_sourceId_mangaId_key"
ON "library_entries"("userId", "sourceId", "mangaId");

ALTER TABLE "comments"
ADD COLUMN "sourceId" TEXT NOT NULL DEFAULT 'manhuatop';

DROP INDEX IF EXISTS "comments_mangaId_chapterId_idx";
CREATE INDEX "comments_sourceId_mangaId_chapterId_idx"
ON "comments"("sourceId", "mangaId", "chapterId");

ALTER TABLE "history_entries"
ADD COLUMN "title" TEXT,
ADD COLUMN "thumbnailUrl" TEXT,
ADD COLUMN "author" TEXT,
ADD COLUMN "chapterName" TEXT,
ADD COLUMN "chapterNumber" DOUBLE PRECISION,
ADD COLUMN "deletedAt" TIMESTAMP(3);

DROP INDEX IF EXISTS "history_entries_userId_mangaId_chapterId_key";
CREATE UNIQUE INDEX "history_entries_userId_sourceId_mangaId_chapterId_key"
ON "history_entries"("userId", "sourceId", "mangaId", "chapterId");
CREATE INDEX "history_entries_userId_deletedAt_lastReadAt_idx"
ON "history_entries"("userId", "deletedAt", "lastReadAt");

CREATE TABLE "history_sync_events" (
    "id" TEXT NOT NULL,
    "operationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "history_sync_events_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "history_sync_events_userId_operationId_key"
ON "history_sync_events"("userId", "operationId");
CREATE INDEX "history_sync_events_createdAt_idx"
ON "history_sync_events"("createdAt");
ALTER TABLE "history_sync_events"
ADD CONSTRAINT "history_sync_events_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
