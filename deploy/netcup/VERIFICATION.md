# Beta deployment verification — 2026-10-12, rechecked 2026-10-13 UTC

- Public HTTPS `/health`: 200, database query successful; trusted Let's Encrypt certificate.
- Backend build passed on Node 24; 21 unit suites passed (48 tests passed, 3 skipped).
- Flutter API security tests: 3 passed. Native Xcode project file passed plist validation.
- All 13 Prisma migrations applied to a new database; Prisma schema diff found no drift.
- Temporary account created and removed for public HTTPS login/JWT verification:
  wrong password rejected, correct password accepted, profile/library readable,
  non-admin account denied admin routes, no password hash returned.
- Production database contained zero users after verification.
- Source registry returned 5 sources and HTTPS icon URLs. Live popular catalogues:
  ManhuaTop 18 items, Atsumaru 24 items.
- CORS permits `https://keihatsu.vercel.app`; Swagger disabled (`/docs` returns 404).
- Cloudinary API authentication and Firebase service-account authentication passed.
- Vercel production redeployed from its existing source, with new `API_URL`.
  `/admin/login` returns 200 and receives the Google client ID from the Netcup API.
- Daily database/uploads/configuration backup completed. PostgreSQL dump restored
  into an isolated database; all 13 migration records and zero users restored.
- SSH key login verified; password SSH disabled. UFW, Fail2ban, unattended security
  upgrades, container restart policies, and root-only backup/config files configured.
- Verified the configured administrator is now `ADMIN`. The one-time promotion completed
  and disabled its timer. User confirmed a successful Google sign-in.
- Rechecked Google sign-in button after origin correction: Google returned 200
  and the prior origin-rejection error is gone.
- Services remained healthy after 16 hours; the scheduled daily backup ran successfully.

## Remaining provider setup

- SMTP mail-block policy removed by the user on 2026-10-13. Nodemailer
  connection and authentication verification now passes. No test email sent.
- APNs signing key/team configuration is not installed; iOS remote push delivery
  still needs APNs credentials. Firebase credential authentication alone does not
  verify notification delivery to an actual Android device.
- Backups currently reside on the same server; off-server backup storage is not
  configured.
