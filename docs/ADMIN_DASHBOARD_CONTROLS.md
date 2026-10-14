# Admin dashboard controls

Deployed to the existing beta API and `https://keihatsu.vercel.app` on
2026-10-14. API source is from PR #126; the final web source commit is
`7c64c406f24ab75497257a22fdb99cc5211d2fef`.

## Available controls

- **System messages** (`/admin/messages`): title, body, importance, optional push,
  preview before sending, duplicate-click prevention, and recent publication
  history. Every registered account receives an Inbox notification. Device push
  respects notification preferences. Published means Inbox creation completed;
  it does not confirm reading or device push delivery.
- **Team & access**: all database ADMIN accounts from a separate safe-field query,
  without the recent-signup limit or ordinary readers in the table.
- **Overview / Engagement**: weekly active readers, synced reading minutes,
  monthly active readers and enabled valid push-device registrations. CSV exports
  include the engagement metrics. Chapter-history/library inventory totals are
  no longer displayed as dashboard cards.

Weekly readers use the current and preceding six calendar days in UTC, exclude
soft-deleted history and future activity, and count distinct accounts. Reading
minutes use the same seven date keys in the stored daily statistics; invalid,
future, negative or greater-than-24-hour daily values are excluded. This is
recorded synced time, not an estimate of unsynced reading.

The onboarding flag is not currently maintained by the backend, so onboarding
completion is not displayed. Registered push devices is a device count, not a
user count or a guarantee that the operating system will show notifications.

## Verification and deployment

- API container build and all **23 test suites** passed: **58 tests passed,
  3 skipped**. The API is healthy locally and through its public HTTPS endpoint.
- Web production build and separate TypeScript checks passed. Vercel reports
  READY / production and aliases the release to `keihatsu.vercel.app`.
- Local browser checks against a mock API covered preview/send/reset/history,
  duplicate clicks, malformed payloads, the admin-only table and metrics.
- Live API requests: administrator 200, ordinary account 403 and anonymous 401
  for analytics, administrator roster and announcement history. Claiming ADMIN
  in a reader token did not override the database role. The roster matched the
  database's single ADMIN account among three registered users at audit time.
- Live authenticated HTML checks: `/admin`, `/admin/team`, `/admin/catalogue`
  and `/admin/messages` all returned 200 with the new controls. Invalid web
  messages returned 400, cross-origin requests 403, anonymous sends 401.
- Read-only live checks used two-minute audit credentials generated inside the
  API container. Credentials were not logged or saved.
- No actual announcement was sent. Announcement rows and SYSTEM_ANNOUNCEMENT
  Inbox rows both remained **zero** before and after verification. Production
  send/push delivery was intentionally not exercised.

Runtime logs and sanitized checks are ignored under `output/admin-deploy`.
Source backups and the pre-deployment image
`keihatsu-api:pre-admin-controls-20261014` are retained on the server for rollback.
No schema change, secret rotation, account mutation or library mutation was
needed. Rollback should coordinate the API image and the Vercel production
release because the new dashboard requires the new API endpoints.

The first server test attempt stopped before switching the running API because
macOS AppleDouble metadata files were treated as tests and the server had older
badge test expectations. The clean archive excluded metadata, current tracked
tests were synchronized, and the full successful gate ran before the switch.
