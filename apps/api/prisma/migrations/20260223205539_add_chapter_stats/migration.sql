/*
  Warnings:

  - A unique constraint covering the columns `[userId,mangaId,chapterId]` on the table `history_entries` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "history_entries_userId_mangaId_key";

-- AlterTable
ALTER TABLE "history_entries" ADD COLUMN     "isBookmarked" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isRead" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE UNIQUE INDEX "history_entries_userId_mangaId_chapterId_key" ON "history_entries"("userId", "mangaId", "chapterId");
