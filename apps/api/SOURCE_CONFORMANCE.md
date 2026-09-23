# Extension rollout gate

The shared API contract is in `src/sources/source-conformance.spec.ts`. Keep a source gated in both clients until its live case passes from the deployment environment. New sources are opt-in; ManhuaTop remains enabled by default.

The live case covers popular and latest listings, search, page two when available, manga metadata, descending chapter order, page indexes and reader URLs, image transfer with the page referer, and a verified CBZ archive. The deterministic case checks that upstream failures, including rate limits, keep their original error instead of falling through to an unrelated source.

Run from `apps/api`:

```sh
npm test -- --runInBand src/sources/source-conformance.spec.ts
RUN_LIVE_SOURCE_CONFORMANCE=1 npm test -- --runInBand src/sources/source-conformance.spec.ts --testNamePattern=atsumaru
RUN_LIVE_SOURCE_CONFORMANCE=1 npm test -- --runInBand src/sources/source-conformance.spec.ts --testNamePattern=mangafire
RUN_LIVE_SOURCE_CONFORMANCE=1 npm test -- --runInBand src/sources/source-conformance.spec.ts --testNamePattern=weebcentral
```

Client checks:

- Flutter: `flutter test test/services/source_rollout_test.dart test/services/reader_image_headers_test.dart test/services/sources_api_test.dart test/services/file_service_test.dart test/services/extension_cbz_test.dart`
- iOS: `BrowsingTests` checks opt-in source preferences, image proxy routing and MangaFire's reader referer. `DownloadTests` checks background download records and portable CBZ paths and contents.

Current rollout:

| Source | Live API contract | Flutter | iOS |
| --- | --- | --- | --- |
| ManhuaTop | Existing production source | On by default | On by default |
| Atsumaru | Passed | Available, opt-in | Available, opt-in |
| MangaFire | Passed | Available, opt-in | Available, opt-in |
| WeebCentral | Blocked by provider challenge in this environment | Gated | Gated |
| BatCave | Not in this rollout | Gated | Gated |

The live suite downloads up to two pages for the archive check. Platform download tests cover the local queues and archive readers. An iOS simulator run is still required after the existing test-target actor isolation errors are resolved.
