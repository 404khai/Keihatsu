#!/bin/bash
# Run from repository root. Only temporary sentinel files are written/deleted.
set -euo pipefail
AUDIT=docs/security/2026-10-04
NATIVE=apps/ios/Keihatsu
COMMON=("$NATIVE/Domain/Entities/Download.swift" "$NATIVE/Domain/Entities/Catalogue.swift" "$NATIVE/Domain/ValueObjects/ContentIdentity.swift" "$NATIVE/Core/Networking/APIConfiguration.swift" "$NATIVE/Core/Networking/APIRequest.swift" "$NATIVE/Core/Networking/APIError.swift")
(cd apps/flutter && flutter test ../../docs/security/2026-10-04/flutter_security_test.dart --reporter expanded)
swiftc "$NATIVE/Core/Storage/ChapterArchiveStore.swift" "${COMMON[@]}" "$AUDIT/NativeSecurityProbe.swift" -o /tmp/keihatsu-native-security
/tmp/keihatsu-native-security
python3 "$AUDIT/prepare_patch.py"
git apply --check "$AUDIT/path-containment.patch"
(cd apps/flutter && flutter test /tmp/keihatsu_hardened_test.dart --reporter expanded)
swiftc /tmp/KeihatsuHardenedChapterArchiveStore.swift "${COMMON[@]}" /tmp/KeihatsuHardenedProbe.swift -o /tmp/keihatsu-native-hardened
/tmp/keihatsu-native-hardened
