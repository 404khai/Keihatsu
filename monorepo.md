# Task: Reorganize Keihatsu into a Monorepo

You are working inside the existing `Keihatsu` repository.

This repository currently contains:

1. The existing Flutter application at the repository root.
2. A NestJS/TypeScript backend inside `Keihatsu-API`.
3. A native Swift iOS application inside `Keihatsu-iOS`.

I have manually copied `Keihatsu-iOS` into the root `Keihatsu` repository before starting this task.

Your ONLY task is to reorganize these existing projects into a clean monorepo structure.

DO NOT refactor application code.
DO NOT rewrite application code.
DO NOT delete application files.
DO NOT modify functionality.
DO NOT make unrelated improvements.
DO NOT install dependencies.
DO NOT upgrade dependencies.
DO NOT change package versions.
DO NOT change application architecture.
DO NOT rename classes, Swift types, Dart types, NestJS modules, bundle identifiers, package names, or application display names unless a path reference absolutely requires an update.
DO NOT modify files outside the current `Keihatsu` repository.

Before making changes, inspect the repository and understand the current Flutter, NestJS, and Swift/Xcode structures.

---

## Target Structure

Transform the repository into approximately:

Keihatsu/
├── apps/
│   ├── flutter/
│   │   ├── lib/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   ├── pubspec.yaml
│   │   └── [all other existing Flutter project files]
│   │
│   ├── api/
│   │   ├── src/
│   │   ├── test/
│   │   ├── package.json
│   │   ├── nest-cli.json
│   │   ├── tsconfig.json
│   │   └── [all other existing Keihatsu-API files]
│   │
│   └── ios/
│       ├── [existing Xcode project/workspace]
│       ├── [existing Swift source directories]
│       └── [all other existing Keihatsu-iOS files]
│
├── .gitignore
├── README.md
└── [repository-level configuration/docs that genuinely belong at root]

The names of the three application directories MUST be:

apps/flutter
apps/api
apps/ios

Do NOT confuse `apps/flutter/ios/` with `apps/ios/`.

`apps/flutter/ios/` is Flutter's generated/native iOS host.

`apps/ios/` is the separate, fully native Swift implementation of Keihatsu.

They must remain completely separate projects.

---

# Phase 1 — Inspect Before Modifying

First inspect the entire current repository structure.

Identify:

- Flutter project root
- `Keihatsu-API`
- `Keihatsu-iOS`
- Xcode `.xcodeproj` files
- Xcode `.xcworkspace` files, if any
- `pubspec.yaml`
- `package.json`
- NestJS configuration
- `.gitignore` files
- environment files
- scripts
- configuration files
- documentation
- relative path references
- absolute path references
- Xcode file references
- Flutter asset paths
- NestJS path/config references

Determine exactly which files belong to each application.

DO NOT modify anything during this inspection step.

Before moving files, formulate the exact migration plan internally based on the actual repository rather than blindly assuming the repository matches the target structure.

---

# Phase 2 — Create Monorepo Directories

Create:

apps/
apps/flutter/
apps/api/
apps/ios/

Do not create unnecessary directories.

---

# Phase 3 — Move Flutter Project

Move the EXISTING Flutter project from the repository root into:

apps/flutter/

This includes Flutter-specific files/directories such as:

lib/
android/
ios/
web/
macos/
windows/
linux/
test/
assets/
pubspec.yaml
pubspec.lock
analysis_options.yaml

and any other files that clearly belong to the Flutter application.

IMPORTANT:

Do not move repository-level files into `apps/flutter/` simply because they currently exist at the root.

For example, evaluate files such as:

README.md
.gitignore
LICENSE
AGENTS.md
.github/

before moving them.

If they describe or configure the entire repository, leave them at the repository root.

If they are clearly Flutter-specific, move them appropriately.

Preserve all Flutter application code exactly.

---

# Phase 4 — Move NestJS Backend

Move:

Keihatsu-API/

to:

apps/api/

The final result should NOT be:

apps/api/Keihatsu-API/

Instead, the CONTENTS of `Keihatsu-API` should become the contents of:

apps/api/

For example:

Keihatsu-API/src
Keihatsu-API/package.json

becomes:

apps/api/src
apps/api/package.json

Preserve all backend source code and configuration.

Do not refactor the NestJS application.

---

# Phase 5 — Move Native iOS Project

Move:

Keihatsu-iOS/

to:

apps/ios/

Again, avoid unnecessary nesting.

Do NOT produce:

apps/ios/Keihatsu-iOS/...

The contents of `Keihatsu-iOS` should live directly under:

apps/ios/

Preserve:

- Swift source files
- Xcode project
- Xcode workspace, if present
- asset catalogs
- Info.plist files
- entitlements
- build configuration
- Swift packages
- schemes
- tests
- project settings

Do NOT recreate the Xcode project.

Do NOT generate a new Xcode project.

Do NOT rename the actual Keihatsu application or its targets merely because the directory moved.

remove this origin origin	https://github.com/404khai/Keihatsu-iOS.git from /Users/admin/Developer/Keihatsu/Keihatsu-iOS/Keihatsu-iOS so that it can be pushed to the main origin https://github.com/404khai/Keihatsu.git

---

# Phase 6 — Repair ONLY Broken Path References

After moving the projects, inspect them for paths that became invalid because of the move.

Only update references that MUST change because of the new filesystem structure.

Pay particular attention to:

### Flutter

- asset paths
- local Dart package paths
- scripts using repository-relative paths
- build scripts

### NestJS

- scripts
- local file references
- environment/config paths
- TypeScript path configuration

### Native iOS

- Xcode file references
- project-relative paths
- build scripts
- Swift Package references
- configuration file paths
- Info.plist references
- entitlements paths

Prefer preserving relative project-local paths.

Do NOT introduce absolute machine-specific paths.

Do NOT modify source code merely to make it "cleaner."

---

# Phase 7 — Gitignore

Review the existing `.gitignore` files.

Create/update the ROOT `.gitignore` only as necessary so it correctly handles:

- Flutter/Dart
- Node/NestJS
- Swift/Xcode
- macOS

Preserve existing meaningful ignore rules.

Do NOT blindly replace the existing `.gitignore`.

Merge rules carefully.

Be particularly careful NOT to add:

ios/

as a global ignore rule because this repository intentionally contains both:

apps/flutter/ios/
apps/ios/

Do not remove already tracked source/config files merely because you believe they should normally be ignored.

---

# Phase 8 — Validation

After the filesystem reorganization, validate the structure.

Check that:

## Flutter

`apps/flutter/pubspec.yaml` exists.

Run only safe/non-destructive checks such as:

flutter pub get

and, if dependencies are available:

flutter analyze

Do NOT automatically run commands that modify application architecture.

## API

`apps/api/package.json` exists.

Do NOT change dependencies.

If existing dependencies allow it, run the project's existing typecheck/build/test commands.

Use the scripts already defined in package.json.

Do not invent replacement scripts.

## Native iOS

Confirm that the existing `.xcodeproj` and/or `.xcworkspace` can still locate its source files.

If command-line Xcode tooling is available, you may perform a non-destructive project inspection/build validation.

Do not alter signing configuration, team IDs, provisioning profiles, bundle IDs, capabilities, deployment targets, or schemes just to make a command-line build succeed.

If signing prevents validation, report it instead of modifying signing configuration.

---

# STRICT SAFETY BOUNDARIES

This is a filesystem reorganization task, NOT a refactoring task.

You MAY:

- create `apps/`
- create `apps/flutter/`
- create `apps/api/`
- create `apps/ios/`
- move existing files into their appropriate locations
- update references broken specifically by those moves
- carefully update `.gitignore`
- update repository documentation if paths are now incorrect

You MUST NOT:

- delete source code
- delete projects
- rewrite working features
- redesign architecture
- rename application classes/types
- rename API endpoints
- change database schemas
- modify business logic
- modify UI
- change dependencies
- upgrade Flutter
- upgrade Dart
- upgrade Node
- upgrade NestJS
- upgrade Swift packages
- run automated migration tools
- regenerate Xcode projects
- regenerate the Flutter project
- change bundle identifiers
- change signing configuration
- change environment variable values
- expose secrets
- modify anything outside the `Keihatsu` repository
- make "cleanup" changes unrelated to this migration

Do NOT use destructive commands such as broad `rm -rf` operations.

When moving files, prefer safe move/rename operations.

If there is a naming collision or uncertainty about whether a file should be moved, PRESERVE THE FILE and report the ambiguity rather than deleting or overwriting anything.

Never overwrite one existing file with another without first determining that they are intentionally the same file.

---

# Git History

Where practical, use moves/renames rather than copy-and-delete transformations so Git can recognize the files as renames.

Do not rewrite Git history.

Do not create, delete, or modify remote repositories.

Do not push anything.

Do not force-push anything.

Do not commit unless explicitly instructed separately.

---

# Expected Final Structure

The important result should be:

Keihatsu/
├── apps/
│   ├── flutter/
│   │   └── ...
│   ├── api/
│   │   └── ...
│   └── ios/
│       └── ...
├── .gitignore
├── README.md
└── ...

There must be no accidental nested structure such as:

apps/api/Keihatsu-API/
apps/ios/Keihatsu-iOS/

unless the internal Xcode project itself already legitimately contains a directory with that name.

---

# Final Report

When finished, DO NOT perform additional cleanup.

Instead report:

1. The final directory tree.
2. Every file/path that was moved.
3. Every file whose contents were modified.
4. Why each modified file needed modification.
5. Any broken references discovered.
6. Any validation commands executed.
7. Whether Flutter validation succeeded.
8. Whether NestJS validation succeeded.
9. Whether the Xcode project appears intact.
10. Anything that requires me to manually verify in Xcode.

If you encounter something unexpected that would require deleting, overwriting, substantially refactoring, or recreating a project, STOP rather than making that change.

## Native iOS Naming Cleanup

The native iOS project currently contains names such as:

apps/ios/Keihatsu-iOS/
apps/ios/Keihatsu-iOS.xcodeproj

Since the parent `apps/ios/` directory already identifies this as the native iOS application, clean up the filesystem/project naming so the native application uses `Keihatsu` as its project name.

Desired structure:

apps/ios/
├── Keihatsu/
├── Keihatsu.xcodeproj
├── KeihatsuTests/       # if such a test target currently exists
└── KeihatsuUITests/     # if such a UI test target currently exists

IMPORTANT:

This must be an Xcode-safe rename, not a blind filesystem rename.

Before changing anything:

1. Inspect the existing `.xcodeproj/project.pbxproj`.
2. Identify the existing project name, targets, schemes, source groups, products, test targets, Info.plist references, entitlements, and build settings.
3. Determine which occurrences of `Keihatsu-iOS` refer to filesystem/project naming and which refer to identifiers/configuration that should remain unchanged.
4. Rename only what is necessary to make the Xcode project and source directory use `Keihatsu`.

The desired visible Xcode naming is:

Project: Keihatsu
Main target: Keihatsu
Product: Keihatsu.app

If existing test targets are named after `Keihatsu-iOS`, they may be safely renamed to:

KeihatsuTests
KeihatsuUITests

ONLY if their references can be updated safely.

Do NOT blindly search-and-replace `Keihatsu-iOS` across the repository.

Do NOT change:

- bundle identifiers unless required and explicitly reported
- Apple Developer Team
- signing configuration
- provisioning configuration
- deployment target
- Swift package dependencies
- application functionality
- Swift source code unrelated to the rename
- build configuration values unrelated to paths/names

Update Xcode file/group references as necessary so there are no broken/red source references after the rename.

If schemes reference the old target/project name, update those references safely.

Afterward, validate the project using Xcode tooling if available.

The final filesystem should preferably contain:

apps/ios/Keihatsu/
apps/ios/Keihatsu.xcodeproj

rather than:

apps/ios/Keihatsu-iOS/
apps/ios/Keihatsu-iOS.xcodeproj

If safely performing this rename would require destructive changes or recreating the Xcode project, STOP and report the issue instead.