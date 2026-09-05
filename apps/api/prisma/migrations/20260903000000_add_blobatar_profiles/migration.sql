-- Store privacy-safe Blobatar preferences instead of provider profile photos.
ALTER TABLE "users"
ADD COLUMN "avatarHue" DOUBLE PRECISION,
ADD COLUMN "avatarShape" DOUBLE PRECISION,
ADD COLUMN "avatarExpression" TEXT NOT NULL DEFAULT 'happy',
ADD COLUMN "avatarAnimated" BOOLEAN NOT NULL DEFAULT false;

-- Provider photos may contain personally identifying account imagery. Existing
-- URLs are redacted as part of the transition to generated avatars.
UPDATE "users" SET "avatarUrl" = NULL;
