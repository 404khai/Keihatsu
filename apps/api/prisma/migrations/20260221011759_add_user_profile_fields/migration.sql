-- AlterTable
ALTER TABLE "users" ADD COLUMN     "bannerUrl" TEXT,
ADD COLUMN     "usernameUpdateCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "usernameUpdatedAt" TIMESTAMP(3);
