-- CreateTable
CREATE TABLE "history_entries" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "mangaId" TEXT NOT NULL,
    "sourceId" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "pageNumber" INTEGER NOT NULL DEFAULT 0,
    "lastReadAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "history_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "history_entries_userId_mangaId_key" ON "history_entries"("userId", "mangaId");

-- AddForeignKey
ALTER TABLE "history_entries" ADD CONSTRAINT "history_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
