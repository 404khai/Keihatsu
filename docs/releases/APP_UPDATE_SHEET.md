# App update sheet

Implemented after OTA PR #127 was merged into main. The Flutter Android/iOS
update UI reuses `StyledSheet`, the same card as logout and delete account.

## Behavior

- Settings → **App updates** opens the sheet and performs a user-requested check.
- States cover checking, available, downloading, ready, up-to-date, unavailable
  builds and offline/retry. Download progress is indeterminate because the SDK
  does not expose a reliable percentage.
- Automatic background updates remain enabled. Startup/resume and foreground
  polling read local current/next patch metadata only; they do not call the
  network or gate app startup. Polling stops outside the foreground.
- A ready update prompts once per pending patch during that process, only on a
  named top-level route. Login/onboarding, reader/detail routes, and existing
  modals defer the prompt until returning to an eligible page.
- Download completion is confirmed by local patch metadata. An SDK call that
  returns while the native automatic updater is busy does not falsely announce
  readiness. A bounded wait offers retry without cancelling background work.
- **Later**/**Continue reading** dismiss the sheet, preserving background work.
  **Got it** explains a complete close/reopen; it does not force-quit or pretend
  to restart Android/iOS. Rollbacks to the baseline also need a restart.
- Errors use generic user-facing copy, never raw exception/credential payloads.
  A downloaded patch can be recognized while offline.

## Validation

- 10 controller tests: local-only probes, quiet read failures, real patch
  readiness versus an already-busy native update, completion, rollback, offline
  readiness/checks, sanitized errors, serialization and bounded recovery.
- 9 widget tests: available/download/ready transitions, Later, offline retry,
  320×568 dark layout at 2× text scale, existing logout confirm/cancel behavior,
  deferred/once-only prompts, reader protection, modal protection and foreground
  resumption/new-patch detection.
- Together with the 4 existing boot-diagnostic tests: **23 Flutter tests passed**.
  The 10 release-tool tests also passed. Targeted analyzer found no issues.
- Main app Android ARM64 release smoke build passed (ordinary Flutter, not an
  uploaded Shorebird baseline). Main Flutter iOS unsigned release build passed.
- Available/downloading/ready states were exercised using the production sheet
  with a fake updater in a clearly labelled, ignored QA preview on the isolated
  BetaVerification35 emulator. No real patch was published for UI testing.
  The preview is not part of the production entrypoint or PR.
- The offline Unbounded font fixture is test-only, includes its SIL OFL license,
  and is not declared as a production asset. CI runs the new tests too.

Native code, SDK/dependency versions, `shorebird.yaml` and production assets are
unchanged by this follow-up. Include the UI in the first published baseline,
or later deliver the compatible Dart changes as an authorized patch. The
existing non-Shorebird build 6 still requires installation of a new baseline.
See [the OTA runbook](SHOREBIRD_OTA.md) for release/patch instructions.
