-- AlterTable
ALTER TABLE "users" ADD COLUMN     "preferences" JSONB;

-- CreateTable
CREATE TABLE "library_entries" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "mangaId" TEXT NOT NULL,
    "sourceId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "thumbnailUrl" TEXT,
    "author" TEXT,
    "language" TEXT,
    "unreadCount" INTEGER NOT NULL DEFAULT 0,
    "downloadedCount" INTEGER NOT NULL DEFAULT 0,
    "totalChapters" INTEGER NOT NULL DEFAULT 0,
    "isUnread" BOOLEAN NOT NULL DEFAULT false,
    "isStarted" BOOLEAN NOT NULL DEFAULT false,
    "isBookmarked" BOOLEAN NOT NULL DEFAULT true,
    "isCompleted" BOOLEAN NOT NULL DEFAULT false,
    "lastReadAt" TIMESTAMP(3),
    "lastUpdatedAt" TIMESTAMP(3),
    "dateAddedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "library_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_CategoryToLibraryEntry" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL,

    CONSTRAINT "_CategoryToLibraryEntry_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE UNIQUE INDEX "library_entries_userId_mangaId_key" ON "library_entries"("userId", "mangaId");

-- CreateIndex
CREATE UNIQUE INDEX "categories_userId_name_key" ON "categories"("userId", "name");

-- CreateIndex
CREATE INDEX "_CategoryToLibraryEntry_B_index" ON "_CategoryToLibraryEntry"("B");

-- AddForeignKey
ALTER TABLE "library_entries" ADD CONSTRAINT "library_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categories" ADD CONSTRAINT "categories_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_CategoryToLibraryEntry" ADD CONSTRAINT "_CategoryToLibraryEntry_A_fkey" FOREIGN KEY ("A") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_CategoryToLibraryEntry" ADD CONSTRAINT "_CategoryToLibraryEntry_B_fkey" FOREIGN KEY ("B") REFERENCES "library_entries"("id") ON DELETE CASCADE ON UPDATE CASCADE;
