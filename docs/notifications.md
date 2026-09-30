# Notifications

## Deploy

Run `cd apps/api && npx prisma migrate deploy && npx prisma generate` before starting the new API. The migration creates Inbox notifications, push installations and deliveries, preferences, chapter snapshots, source health and announcements. Keep existing migrations in order. Configure APNs and FCM credentials on the API host; neither secret belongs in a mobile build.

| Variable | Purpose |
| --- | --- |
| `PUSH_PROVIDER` | `noop` for local development and tests; set to `remote` to use APNs/FCM. Defaults to `noop`. |
| `APNS_PRIVATE_KEY_PATH` | Absolute path to an Apple `.p8` provider key. |
| `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID` | Apple key ID, team ID and app bundle identifier. |
| `APNS_ENV` | `production` for App Store builds; any other value selects the sandbox endpoint. |
| `FCM_PROJECT_ID` | Firebase project ID for the FCM HTTP v1 API. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the Firebase service account JSON used by Google Auth. |
| `CHAPTER_CHECK_INTERVAL_MS` | Interval for library chapter checks; at least 60000 enables the job, zero disables it. |
| `CHAPTER_CHECK_CONCURRENCY` | Concurrent manga checks, capped at 8; default 2. |
| `SOURCE_OUTAGE_THRESHOLD` | Consecutive failed source sweeps before an outage alert; default 3. |
| `MIN_IOS_APP_VERSION`, `MIN_ANDROID_APP_VERSION` | Optional minimum supported versions; registering an older version creates a required update notification. |

The iOS target has development and production APNs entitlements. Enable Push Notifications for the app identifier and provisioning profiles in Apple Developer. Set the corresponding Firebase project in the Android `google-services.json`. Android 13 and newer asks for notification permission at sign-in. Native iOS uses APNs directly; Flutter/Android uses FCM.

The scheduler is enabled only when `CHAPTER_CHECK_INTERVAL_MS` is set. Run one scheduler instance per database; multiple API replicas can serve HTTP with the check interval disabled. The first successful chapter check establishes a baseline without alerting readers. Empty or failed source responses retain the prior snapshot. Delivery retries are persisted in `push_deliveries`, back off exponentially and disable permanently invalid tokens. Logs contain notification IDs and platforms, never push tokens.

## API and payload

Authenticated endpoints: `POST /notifications/devices`, `DELETE /notifications/devices/:installationId`, `GET /notifications`, `GET /notifications/unread-count`, `PATCH /notifications/:id/read`, `POST /notifications/read-all`, `DELETE /notifications/:id`, `GET/PATCH /notifications/preferences`. `GET /notifications` accepts `cursor`, `limit` (1–100), `type`, `category` (`UPDATES`, `COMMENTS`, `SYSTEM`, `ACCOUNT`) and `unread` (`true` or `false`). It returns `{ "items": [...], "nextCursor": "..." | null }`. Reads and mutations are scoped to the authenticated user. Device registration accepts `{ "installationId", "platform": "IOS" | "ANDROID", "token", "appVersion" }`; re-register on token refresh or account switching and unregister before logout.

The visible push includes a short title and generic body. Custom APNs fields / FCM data fields are `notificationId`, `type`, `deepLink`, `groupingKey`, and available `sourceId`, `mangaId`, `chapterId`, `commentId`, `threadId`. No bearer token or comment body is included. APNs uses `aps.alert`, `thread-id` and `apns-collapse-id`; Android uses the matching group/collapse key and the `library_updates`, `comments_social` or `system_announcements` channel. Bad or incomplete links fall back to Inbox.

Stable links use `keihatsu://manga/{source}/{manga}`, `keihatsu://chapter/{source}/{manga}/{chapter}`, `keihatsu://comment/{source}/{manga}/{chapter}/{comment}`, `keihatsu://inbox`, `keihatsu://announcement/{id}` and `keihatsu://settings/update`. Each segment is percent encoded. Chapter updates are ordinary alert pushes, never Live Activities. Downloads, waiting states and Incognito use local platform notifications only and never create an Inbox row.

Preferences control push delivery only. Durable Inbox creation is retained when a user disables optional alerts. Account security and required updates have no suppression switch.

## Send a test announcement

With an administrator bearer token, send:

```sh
curl -X POST "$API_BASE_URL/admin/announcements" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"Test notice","body":"Open your Inbox to verify delivery.","severity":"INFO","pushEnabled":true,"publishAt":"2026-09-30T00:00:00Z","deepLink":"keihatsu://inbox"}'
```

Use `PUSH_PROVIDER=noop` to test synchronized Inbox behavior without APNs/FCM credentials. For a real push, set `PUSH_PROVIDER=remote`, register a device from the signed-in app, then send the announcement. The admin route and device registration route are rate limited.
