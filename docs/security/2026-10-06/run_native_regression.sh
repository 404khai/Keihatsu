#!/bin/bash
set -euo pipefail
swiftc \
  apps/ios/Keihatsu/Core/Storage/ChapterArchiveStore.swift \
  apps/ios/Keihatsu/Domain/Entities/Download.swift \
  apps/ios/Keihatsu/Domain/Entities/Catalogue.swift \
  apps/ios/Keihatsu/Domain/ValueObjects/ContentIdentity.swift \
  apps/ios/Keihatsu/Core/Networking/APIConfiguration.swift \
  apps/ios/Keihatsu/Core/Networking/APIRequest.swift \
  apps/ios/Keihatsu/Core/Networking/APIError.swift \
  docs/security/2026-10-06/NativeSecurityRegression.swift \
  -o /tmp/keihatsu-native-security-regression
/tmp/keihatsu-native-security-regression
