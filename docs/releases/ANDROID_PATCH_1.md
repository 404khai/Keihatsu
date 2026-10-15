# Android 0.1.0+7: account themes and comment composer

This Dart-only update targets the existing signed build-7 Shorebird baseline;
it does not require a replacement APK or alter native dependencies/assets.

- Mention suggestions insert `@username`. Older braced comments render as plain
  mentions while retaining theme color and backend notification compatibility.
- The image button and send button are always visible in the composer. The send
  arrow is black inside a theme-colored circle. Focusing/typing grows the text
  area upward, with a four-line limit, without moving the action row below it.
- Theme mode, brand/background colors and pure-black mode are stored in one
  local snapshot per authenticated account ID, separately from guest settings.
  Switching accounts resets the displayed palette before loading the new scope.
  Serialized storage and revision checks protect rapid writes/switches.
- Old builds kept only one device-wide theme, so historical per-account choices
  cannot be recovered. That legacy theme is migrated once to the first signed-in
  account after this update. Other accounts start with defaults and retain their
  own changes thereafter. Themes are local per account/device, not server synced.

Validation logs, exact patch number/track and the baseline receipt are retained
under ignored `output/beta`. Relevant tests cover independent account/guest
restoration, legacy migration once, rapid switching and pending writes, corrupt
settings, mention insertion/rendering, composer layout/actions, auth/session
races, local cached content and the existing update-sheet flow. Publication
uses `tool/shorebird.py patch android --release-version 0.1.0+7 --baseline ...
--publish` to stage the patch, followed by promotion of the validated patch to
stable under the user's explicit request to receive the update in build 7.

On build 7, open Settings > App updates while online. The automatic background
updater may already have downloaded it, in which case the sheet asks for a
full close/reopen rather than offering another download. Simply backgrounding
and foregrounding is not a full process restart. The next launch uses the patch.
The baseline APK file remains unchanged; no Firebase upload or email is needed.
