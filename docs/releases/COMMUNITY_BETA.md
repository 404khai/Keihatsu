# Community and reading beta fixes

## Changes

- Comment mentions support `@{username}` and `@username`, theme-colored text,
  and an authenticated username/avatar picker. Suggestions expose public profile
  fields only. Developer and Android tester badges come from the server's trusted
  identity mapping and appear beside comment/reply usernames.
- Comments keep drafts on failed sends and show brief connection/action messages.
  Images are resized on selection and decoded, rotated, resized to a maximum
  2048-pixel edge, and converted to WebP before Cloudinary upload. Requests allow
  at most five images, each at most 5 MiB. Static JPEG/PNG/WebP are supported.
  Tapping a posted image opens a swipeable, zoomable preview sheet.
- Grid/customization changes are persisted locally, queued per account and kept
  when offline. Serialized writes and revision checks prevent stale refreshes
  from resetting a newer choice.
- The library stays visible during synchronization; filters and sorting use local
  records. Manga details and chapters read the account-scoped Isar cache first.
  The selected title/cover appears immediately, thumbnail caching is asynchronous,
  and pull to refresh uses the custom indicator. Uncached source data still
  requires a network request; no artificial minimum loading delay is added.
- The website has a Docs navbar link and seven Markdown guides covering install,
  startup, reading, offline behavior, comments, troubleshooting and adding pictures.
  References informed the layout. Nexvyn's Bounce Sidebar tracks sections, respects
  reduced motion, and leaves 26 px between the dot and the button edge. The global
  MCP integration is documented in `docs/NEXVYN_MCP.md`.

## Validation and handoff

Validation logs and release metadata are ignored local artifacts under
`output/beta`. API validation: 24 suites, 63 passed, 3 skipped; production API
build succeeds. Flutter validation: 44 targeted tests passed, including actual
Isar cache reads without network requests, auth/preference races, comment scoping,
credential security and OTA sheets. Scoped analyzer output has no errors or
warnings (existing deprecation/style notices remain). Website production build
and TypeScript check pass. Browser checks cover desktop and narrow layouts,
loaded screenshots, section selection and indicator spacing.

The release uses production `lib/main.dart`, the pinned production API settings,
the original Android signing certificate and all three Android ABIs. This is a
new Shorebird baseline with an increasing build number, prepared in Firebase
without notification targets. Exact signed bytes/hash and release IDs are saved
in `output/beta/community-release-audit.json` after the build/upload.

Device acceptance remains user-owned. Update in place rather than uninstalling:
check mentions and recipient avatars, developer/tester badges on roots/replies,
image upload/preview, grid persistence through restart/account switching, cached
library/details under poor network, pull to refresh, and login after force-stop.
Previously uncached content cannot be instant on a poor connection. No claim of
physical-device or process-relaunch acceptance is made by this audit.
