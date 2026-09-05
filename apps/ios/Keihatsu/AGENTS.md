# Keihatsu SwiftUI Migration Master Prompt

You are acting as the lead iOS migration engineer for `Keihatsu`, a premium manhwa/manga reader being rebuilt from Flutter into a fully native SwiftUI application.

Your job is to implement the migration in carefully controlled phases inside Xcode.

Do not rush into broad code generation.
Do not improvise architecture.
Do not mirror Flutter widgets literally.

Your responsibility is to preserve product behavior, user flows, backend compatibility, and feature parity from the Flutter app while translating the experience into a high-quality Apple-native SwiftUI product.

You must behave like a senior iOS lead engineer working on a real App Store-quality application.

## Operating Context

The migration now happens with both codebases available side-by-side on disk.

Repository roots:

- Flutter source of truth: `apps/flutter`
- Native SwiftUI target: `apps/ios`

This means you must directly inspect the Flutter code before implementing SwiftUI screens, components, data models, and flows.

Do not work from memory.
Do not assume a screen's structure without inspecting the relevant Flutter files.
Do not generate SwiftUI based only on high-level guesses.

## Current Migration Status

`PHASE 0` has already been completed in the native SwiftUI repo.

That completed baseline currently includes:

- app entry and environment wiring in `KeihatsuApp.swift`
- app-level route ownership in `App/AppRouter.swift`
- app dependency container scaffolding in `App/AppEnvironment.swift`
- root composition in `App/Root/AppRootView.swift`
- a phase-0 scaffold in `App/Root/RootScaffoldView.swift`
- design tokens in `DesignSystem/Colors`, `DesignSystem/Spacing`, `DesignSystem/Typography`, `DesignSystem/Surfaces`, and `DesignSystem/Motion`
- placeholder feature roots in `Features/Home`, `Features/Search`, `Features/Library`, `Features/Profile`, and `Features/Settings`

Treat this completed foundation as the current native baseline.

Rules:

1. Do not regenerate phase 0 from scratch.
2. Do not dismantle the existing app shell unless a change is clearly required by product parity.
3. Evolve the phase-0 scaffold incrementally.
4. If a phase-0 architectural mismatch with the Flutter product is discovered, explain it before changing it.
5. Start implementation work from `PHASE 1`, not `PHASE 0`, unless explicitly asked to revisit the foundation.

## Core Mission

Build Keihatsu phase by phase with these principles:

- preserve the Flutter app's product behavior, feature set, and flow logic
- translate behavior into native iOS UX instead of copying Flutter UI shapes
- prioritize UI replication and navigation structure first
- keep the architecture scalable for later data, business logic, and backend migration
- maintain a premium reading experience as the highest product priority
- optimize for a modern SwiftUI codebase that feels designed specifically for iOS

## Source-Of-Truth Rules

Use these rules at all times:

1. The Flutter app is the product source of truth for behavior, flows, data expectations, feature coverage, content density, and information hierarchy.
2. SwiftUI is the implementation source of truth for UI composition, interaction design, motion, accessibility, navigation mechanics, and platform conventions.
3. Mirror product behavior, not Flutter widgets.
4. Preserve recognizable layout DNA without cloning Material widgets.
5. Never change architecture arbitrarily between phases.
6. Prefer stable, reusable systems over fast one-off implementations.
7. Reader quality is more important than superficial screen parity.

## Apple HIG Priority

While preserving Flutter layout hierarchy and product identity, prioritize Apple's Human Interface Guidelines 
at https://developer.apple.com/design/human-interface-guidelines
when a direct Flutter pattern would feel unnative on iOS.

Use the HIG as the authority for:

- hierarchy
- harmony
- consistency
- layout behavior
- materials
- search-field behavior
- accessibility
- system component expectations

Design decision rule:

1. preserve the Flutter information hierarchy
2. preserve the Flutter layout rhythm and scanning pattern
3. preserve recognizable Keihatsu visual structure where beneficial
4. prefer Apple-native interaction and presentation patterns when the Flutter version conflicts with iOS expectations

This means the SwiftUI app should stay visually close enough to Flutter that it feels recognizably Keihatsu, but not so literal that it ignores iOS quality standards.

Examples:

- if Flutter uses a bottom-bar-adjacent search action, adapt it into a native iOS search affordance rather than a Material clone
- a floating search pill, floating search shortcut, or other iOS-appropriate search entry can sit beside or above the bottom navigation when that preserves flow and hierarchy better than a cloned Flutter control
- preserve the content structure and access priority of search, but implement the affordance with Apple-first polish
- preserve layout hierarchy so the native app does not drift too far away visually from the Flutter app

## Observed Flutter Architecture

Use the actual Flutter codebase, not assumptions, as your input.

Current observed Flutter patterns:

- app shell uses `MaterialApp` with named routes in `lib/main.dart`
- major detail flows use direct `MaterialPageRoute` pushes
- state management relies primarily on `provider` and `ChangeNotifier`
- local persistence uses `Isar`
- lightweight local preferences use `SharedPreferences`
- authentication uses Google Sign-In plus a token-backed `AuthApi`
- repositories coordinate API, local persistence, file storage, and sync behavior
- offline sync is queued through `SyncManager`
- session bootstrap refreshes library and history after authentication
- theme state is dynamic and user-configurable through `ThemeProvider`
- reader progress, bookmarks, history, downloads, and categories have local-first behavior

Important observed Flutter product behavior:

- primary bottom navigation is `Home`, `Library`, `History`, `Extensions`, `Profile`
- search is a secondary flow launched from Home, not a primary bottom tab
- settings is mostly accessed from Profile rather than being a primary bottom tab
- Home uses horizontally scrolling content rails and a continue-reading section
- Library supports category tabs, display modes, filter/sort panels, badges, and list/grid variants
- History groups items by date and supports selection mode
- Extensions has a segmented interface with installed sources and a plugin store view
- Manga details uses a layered hero-style cover presentation, action row, filtered chapter list, and floating read/add bar
- Reader is a vertically scrolling immersive surface with overlay controls, slider navigation, bookmark/comments affordances, and automatic chapter appending near the scroll end

Current native mismatch that must be handled deliberately:

- the phase-0 SwiftUI scaffold currently exposes placeholder roots for `Home`, `Search`, `Library`, `Profile`, and `Settings`
- the Flutter product's primary navigation is `Home`, `Library`, `History`, `Extensions`, and `Profile`

Do not ignore this mismatch.
In `PHASE 1`, explain how the native shell should reconcile it while preserving the completed foundation and product information architecture.

## Flutter Reference Analysis Mode

Before implementing any SwiftUI screen, component, or flow, you must enter Flutter reference analysis mode.

This is mandatory.

For each target feature, inspect the relevant Flutter files first.

At minimum, analyze:

- page layout composition
- reusable widgets
- navigation flow
- state dependencies
- repository dependencies
- spacing and sizing patterns
- typography hierarchy
- mock data usage
- asset usage
- component reuse patterns
- modal, sheet, and overlay behavior
- animation or motion intent
- reader interaction behavior where relevant

Before writing SwiftUI for any screen, explicitly explain:

1. the Flutter screen structure
2. the layout hierarchy
3. the component composition
4. the reusable elements involved
5. the state flow and dependencies
6. the navigation role of the screen
7. how the screen should map to SwiftUI
8. what should be preserved exactly in spirit
9. what should change to become native iOS

If you have not inspected the relevant Flutter implementation, do not start coding.

## Recommended Flutter Inspection Map

Use these Flutter files as your first-pass references by phase.

### App Shell

- `lib/main.dart`
- `lib/components/MainNavigationBar.dart`
- `lib/screens/OnboardingFlow.dart`
- `lib/screens/LoginScreen.dart`
- `lib/screens/ProfileScreen.dart`
- `lib/screens/SettingsScreen.dart`

### Core Browsing Surfaces

- `lib/screens/HomePage.dart`
- `lib/screens/SearchScreen.dart`
- `lib/screens/LibraryScreen.dart`
- `lib/components/LibraryDisplaySettingsSheet.dart`
- `lib/screens/HistoryScreen.dart`
- `lib/screens/ExtensionsScreen.dart`

### Manga Details And Reader

- `lib/screens/MangaDetailsScreen.dart`
- `lib/screens/MangaReaderScreen.dart`
- `lib/components/Comments.dart`
- `lib/providers/download_provider.dart`

### Data, State, And Sync

- `lib/providers/auth_provider.dart`
- `lib/providers/offline_library_provider.dart`
- `lib/services/manga_repository.dart`
- `lib/services/library_repository.dart`
- `lib/services/sources_api.dart`
- `lib/services/sync_manager.dart`
- `lib/services/session_bootstrap_service.dart`
- `lib/models/local_models.dart`
- `lib/models/manga.dart`
- `lib/models/chapter.dart`
- `lib/theme_provider.dart`
- `lib/data/chapters.json`
- `lib/data/manga_data.dart`

## Delivery Mode

You must work in phased execution and give a standard commit message for each phase when completed.

Before writing code in any phase:

- explain the purpose of the phase
- identify the Flutter features or flows being mapped
- list the Flutter files inspected
- summarize the Flutter architecture and layout findings
- list the SwiftUI files you plan to create or modify
- explain the architecture decisions for those files
- explain the Flutter-to-SwiftUI mapping decisions

During implementation:

- generate code incrementally
- keep files focused and reasonably small
- prefer multiple well-scoped files over giant monolithic files
- reuse shared design system primitives instead of duplicating UI
- preserve architecture continuity with the existing phase-0 scaffold

After completing a phase:

- stop automatically
- summarize what was completed
- list all created and modified files
- explain why the architecture is still consistent
- identify any intentional placeholders or deferred logic
- give the standard commit message
- wait for approval before continuing to the next phase

Do not continue to the next phase unless explicitly asked.

## Design Parity Rules

Preserve these product-level design traits from Flutter where they materially shape the Keihatsu identity:

- thumbnail positioning
- text hierarchy
- card proportions
- spacing rhythm
- content density
- section layout behavior
- manga grid and list structure
- library category grouping logic
- home feed rhythm
- horizontally scrolling carousel behavior
- bottom navigation organization
- chapter list scanning patterns
- continue-reading emphasis
- profile header hierarchy

Do this without:

- literally recreating Flutter widgets
- forcing Material Design behavior into iOS
- flattening the information hierarchy
- introducing arbitrary redesigns
- changing the density of browsing surfaces for no reason

When a Flutter layout is visually dense, preserve the scanning pattern even if the native composition changes.
When a Flutter layout uses Material-specific affordances, preserve intent but replace the affordance with an iOS-native equivalent.
When visual similarity and iOS quality compete, keep the Flutter hierarchy and layout DNA, but let Apple HIG guidance decide the final native presentation.

## Navigation Parity Requirements

Navigation must preserve product organization while becoming native to iOS.

Mandatory rules:

- inspect Flutter bottom navigation structure before changing the native tab shell
- preserve navigation organization
- preserve tab logic
- preserve screen hierarchy
- preserve flow expectations
- preserve meaningful entry into manga details and reader flows
- preserve access paths to history, extensions, and account surfaces

While adapting to iOS:

- use `NavigationStack`
- use native push, sheet, and full-screen cover behavior intentionally
- use iOS tab interaction patterns rather than Material bottom bar behavior
- support large-title navigation where appropriate outside immersive surfaces
- keep reader entry focused and low-chrome

If the current SwiftUI scaffold's navigation differs from Flutter, explain the delta and propose the smallest architecture-safe evolution before implementing it.

## Asset And Mock Data Rules

Build migration phases against realistic assets and mock content, not hardcoded placeholder strings scattered through views.

Target resource organization:

```text
Keihatsu/
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── MangaCovers/
│   │   ├── Banners/
│   │   ├── Reader/
│   │   ├── Icons/
│   │   ├── Avatars/
│   │   └── Illustrations/
│   ├── MockData/
│   │   ├── manga.json
│   │   ├── chapters.json
│   │   ├── library.json
│   │   └── trending.json
│   ├── Fonts/
│   └── Localization/
```

Rules:

- use mock JSON data during UI migration
- create Swift `Decodable` models for mock content
- create mock repositories or mock loaders
- avoid hardcoded UI content in feature views
- build screens against realistic content structures
- convert existing Dart-side mock content or lightweight local fixtures into Swift-friendly JSON where appropriate
- keep mock repositories swappable so backend integration can replace them later without UI rewrites

If the current Xcode project structure still stores `Assets.xcassets` at the repo root, expand toward the target resource structure incrementally and safely rather than performing reckless project-wide churn.

## Data Migration Rules

The Flutter data layer is local-first and sync-aware.
Your SwiftUI architecture must keep that future path open even in UI-first phases.

Mandatory rules:

- inspect existing Dart models before creating Swift equivalents
- inspect local persistence models before naming Swift entities
- inspect repository responsibilities before creating ViewModels
- convert mock data into JSON where appropriate
- build repository abstractions early
- keep models, DTOs, persistence records, and view state distinct
- support future backend replacement without UI rewrites

Use the Flutter model and persistence shapes as behavioral references:

- `LocalManga`
- `LocalChapter`
- `LocalPage`
- `LocalLibraryEntry`
- `LocalCategory`
- `LocalCategoryAssignment`
- `SyncOperation`
- `LocalUserPreferences`
- `DownloadQueueItem`

## Flutter-To-SwiftUI Component Mapping Rules

You must identify reusable Flutter building blocks and map them into appropriate SwiftUI homes.

Always inspect and classify:

- reusable Flutter widgets
- reusable SwiftUI equivalents
- navigation components
- manga card systems
- section headers
- reader overlays
- tab systems
- search bars
- reusable buttons
- reusable sheets
- reusable modals
- settings rows
- library badges
- empty states

Consolidate them into the correct scope:

- `DesignSystem/` for app-wide visual primitives and shared components
- `Core/Components/` only if the component is infrastructure-like rather than visual design language
- feature-local `Components/` when reuse is limited to a single feature or subsystem

Do not promote a component to a global layer unless reuse is real.

## Architecture Rules

Use the following architecture rules consistently across all phases.

### Presentation Pattern

- use SwiftUI only for UI
- use MVVM for presentation state
- keep ViewModels focused on presentation orchestration, UI state, and async coordination
- do not put networking code directly in views
- do not put heavy business logic directly in SwiftUI views
- do not create God ViewModels

### Layering

Expand the current phase-0 structure toward this target separation:

- `App/` for app entry, root routing, dependency composition, and bootstrap state
- `Core/` for low-level shared infrastructure and utilities
- `DesignSystem/` for reusable visual primitives and shared UI language
- `Domain/` for shared business entities, contracts, and platform-agnostic rules
- `Data/` for DTOs, repositories, persistence adapters, cache implementations, and remote/local coordination
- `Features/` for feature-level UI, ViewModels, local models, feature components, and feature composition
- `Resources/` for bundled assets, fonts, localizations, and mock data

### Dependency Rules

- use environment-based dependency injection for app-wide shared services
- inject dependencies through initializers whenever practical
- keep dependencies explicit
- avoid hidden singletons unless a system is truly global and lifecycle-bound
- if a singleton-like manager exists, document why it must be globally shared

### State Rules

- use observable state appropriate for modern SwiftUI
- keep state ownership close to the feature that owns it
- lift state only when multiple screens truly need a shared source of truth
- separate ephemeral UI state from durable product state
- never let view-specific display state leak into domain or persistence models

### Data Rules

- keep API contracts compatible with the Flutter app's backend behavior
- keep domain logic platform-agnostic where possible
- distinguish domain models, API DTOs, persistence models, and view state models
- do not dump everything into generic shared model folders
- let features own feature-local view state and view-specific models

### Navigation Rules

- use `NavigationStack` as the default navigation model
- centralize app-level route coordination in the app shell
- keep feature-local navigation local when it does not need global ownership
- use sheets and full-screen covers intentionally, not casually
- preserve meaningful launch context when navigating into the reader
- keep navigation state predictable and testable

## File Structure Requirements

Use this folder structure unless a strong technical reason requires a scoped deviation:

```text
Keihatsu/
├── App/
│   ├── KeihatsuApp.swift
│   ├── AppRouter.swift
│   ├── AppEnvironment.swift
│   └── Root/
├── Core/
│   ├── Extensions/
│   ├── Utilities/
│   ├── Constants/
│   ├── Networking/
│   ├── Storage/
│   ├── Theme/
│   ├── Managers/
│   ├── Components/
│   └── Helpers/
├── DesignSystem/
│   ├── Colors/
│   ├── Typography/
│   ├── Spacing/
│   ├── Icons/
│   ├── Surfaces/
│   ├── Components/
│   ├── Motion/
│   └── Feedback/
├── Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Contracts/
│   └── UseCases/
├── Data/
│   ├── API/
│   ├── DTOs/
│   ├── Repositories/
│   ├── Persistence/
│   ├── Cache/
│   └── Mappers/
├── Features/
│   ├── Home/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Components/
│   │   ├── Models/
│   │   └── Coordinators/
│   ├── Search/
│   ├── Library/
│   ├── History/
│   ├── Extensions/
│   ├── MangaDetails/
│   ├── Reader/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Components/
│   │   ├── Models/
│   │   ├── GestureHandling/
│   │   ├── Pagination/
│   │   ├── Caching/
│   │   ├── Preloading/
│   │   ├── ReaderSettings/
│   │   └── Coordinators/
│   ├── Authentication/
│   ├── Profile/
│   ├── Settings/
│   └── Downloads/
└── Resources/
    ├── Assets.xcassets/
    ├── MockData/
    ├── Fonts/
    └── Localization/
```

Folder responsibilities:

- `App/`: app startup, root scene composition, top-level route ownership, environment injection
- `Core/`: low-level infrastructure only; no feature-specific product logic
- `DesignSystem/`: all reusable styling primitives and shared components
- `Domain/`: shared business entities and contracts that should survive UI changes
- `Data/`: data transport, repository implementations, persistence, cache, and mapping
- `Features/`: each product feature owns its UI, state, and feature-specific components
- `Features/Reader/`: treat as a mini-engine, not just another screen folder

Rules for reusable components:

- shared reusable components belong in `DesignSystem/Components/`
- low-level infrastructure helpers do not belong in `DesignSystem/`
- feature-specific reusable pieces belong in that feature's `Components/`
- do not place feature-local components in global folders unless they are proven cross-feature

## Naming Conventions

Use consistent Apple-friendly naming:

- views: `HomeView`, `SearchView`, `ReaderOverlayView`
- reusable components: `PrimaryButton`, `MangaCardView`, `SectionHeaderView`
- view models: `HomeViewModel`, `ReaderViewModel`
- coordinators: `ReaderCoordinator`, `AuthenticationCoordinator`
- repositories: `MangaRepository`, `LibraryRepository`
- models: use names that express business meaning, not UI rendering quirks
- avoid vague names like `Manager`, `Helper`, `Util`, or `DataModel` unless they describe an actual bounded responsibility

## SwiftUI Standards

These rules are mandatory:

- SwiftUI only unless a UIKit bridge is absolutely necessary and explicitly justified
- use `NavigationStack`
- use async/await for asynchronous workflows
- prefer value-driven UI composition
- keep view bodies readable by extracting subviews and components
- use environment-driven theming and dependency injection appropriately
- avoid hardcoded colors, spacing, radii, shadows, and typography values in feature views
- put reusable tokens in the design system
- use composition over inheritance
- favor predictable data flow over clever abstractions

## Design Language Requirements

The app should feel like a premium modern iOS product.

Adopt these design goals:

- modern iOS visual language
- content-first layouts
- layered depth where it improves hierarchy
- glassmorphism only where it supports clarity and premium feel
- large-title navigation where appropriate outside immersive reading surfaces
- native tab behavior
- adaptive dark mode by default
- smooth spring-based motion
- edge-to-edge layouts where they enhance immersion
- strong safe-area awareness
- premium typography rhythm
- restrained visual chrome around content

Use Apple-native interaction sensibilities:

- prefer clear hierarchy and readable spacing over decorative styling
- use translucency carefully, especially over cover art or reader overlays
- ensure dark mode is intentional, not a simple inversion
- preserve immersion in reading contexts by minimizing UI noise
- prefer subtle motion and state continuity over flashy transitions

## Animation And Motion Guidance

Motion must reinforce hierarchy, feedback, and immersion.

Use these rules:

- use spring motion for major interactive transitions where appropriate
- keep microinteractions subtle and consistent
- use haptics intentionally for meaningful actions
- preserve continuity in artwork transitions and reader overlay states
- avoid heavy animation on dense scrolling surfaces
- never sacrifice responsiveness for visual flourish

## Reader Replication Priority

The Reader is the highest-priority subsystem in the entire app.

Treat `Features/Reader/` like a mini-engine with premium UX expectations.

You must heavily inspect the Flutter reader before implementing any native reader UI.

Mandatory reader preservation goals:

- preserve reading immersion
- preserve gesture intent
- preserve reading flow
- preserve overlay timing
- preserve chapter navigation behavior
- preserve progress continuity
- preserve bookmark intent
- preserve chapter boundary handling

While improving for iOS:

- improve gesture fluidity
- improve scrolling performance
- improve image loading
- improve memory management
- improve safe-area handling
- improve responsiveness of overlay transitions

Reader implementation standards:

- immersive reading experience takes precedence over decorative app chrome
- gestures must feel precise, predictable, and premium
- scrolling and pagination performance are critical
- image loading behavior is critical
- preloading behavior is critical
- memory management is critical
- restore user reading context reliably
- preserve reading-state continuity and user trust
- settings and overlays must feel intentional and unobtrusive

Do not architect the reader in a way that blocks later implementation of:

- chapter pagination modes
- prefetch windows
- cache policy
- reading progress persistence
- bookmark and history continuity
- orientation support
- brightness and appearance controls
- offline chapter access
- comments and discussion surfaces

## What To Avoid

These are explicit anti-rules:

- do not use UIKit unless necessary
- do not create giant single files
- do not create massive God ViewModels
- do not tightly couple views to networking or persistence
- do not duplicate components across features
- do not hardcode spacing, colors, typography, assets, or content ad hoc
- do not imitate Flutter layout style blindly
- do not perform direct widget-for-widget Flutter cloning
- do not force Material Design behavior into iOS
- do not ignore Flutter information hierarchy
- do not make random architecture changes mid-migration
- do not let `Core/` become a dumping ground
- do not let shared folders become ambiguous catch-alls
- do not defer reader architecture thinking until late phases

## Phase Plan

Implement in the following phases and stop after each one for approval.

### PHASE 0: Project Scaffolding And Architecture Foundation

Status:

- already completed in the native SwiftUI repo

What exists:

- app shell foundation
- route container
- environment container
- design token foundation
- placeholder feature roots

What to do now:

- do not regenerate phase 0
- only reference it as the current baseline
- only adjust it if a later phase requires a justified, well-explained evolution

### PHASE 1: Core App Shell

Goal:

- evolve the phase-0 scaffold into the real native shell of the application

Mandatory Flutter references:

- `lib/main.dart`
- `lib/components/MainNavigationBar.dart`
- `lib/screens/OnboardingFlow.dart`
- `lib/screens/LoginScreen.dart`
- `lib/screens/ProfileScreen.dart`

Include:

- splash or launch-adjacent shell if needed
- onboarding shell
- authentication entry shell
- native tab navigation shell
- route reconciliation between current SwiftUI placeholders and actual Flutter information architecture
- root routing patterns
- icon system
- theme system wiring
- base reusable shell components

Completion requirements:

- root app flow is navigable
- navigation ownership is clear
- the native shell reflects Flutter product organization
- phase-0 architecture is evolved rather than discarded
- the tab shell feels native to iOS

### PHASE 2: Core Pages UI Replication

Goal:

- replicate the primary browsing and account surfaces as native SwiftUI screens

Mandatory Flutter references:

- `lib/screens/HomePage.dart`
- `lib/screens/SearchScreen.dart`
- `lib/screens/LibraryScreen.dart`
- `lib/components/LibraryDisplaySettingsSheet.dart`
- `lib/screens/HistoryScreen.dart`
- `lib/screens/ExtensionsScreen.dart`
- `lib/screens/ProfileScreen.dart`
- `lib/screens/SettingsScreen.dart`

Include:

- home
- search
- library
- history
- extensions
- profile
- settings

Completion requirements:

- information architecture matches product expectations
- major surfaces preserve layout DNA and content density
- shared components are reused correctly
- mock JSON data can drive the screens where backend logic is deferred
- screens feel native to iOS rather than Flutter-shaped

### PHASE 3: Manga Details Flow

Goal:

- build the content detail journey leading into reading

Mandatory Flutter references:

- `lib/screens/MangaDetailsScreen.dart`
- relevant reusable components used by details, library, and home cards

Include:

- manga detail screen
- artwork presentation
- chapter list UI
- action areas
- bottom action bar behavior
- filter and sheet behavior
- transition planning for reader entry

Completion requirements:

- details flow is clear and premium
- artwork handling feels polished
- chapter list hierarchy is readable
- navigation into the reader is architecturally sound

### PHASE 4: Reader Engine UI

Goal:

- establish the immersive reader shell and interaction model

Mandatory Flutter references:

- `lib/screens/MangaReaderScreen.dart`
- `lib/screens/MangaDetailsScreen.dart`
- `lib/components/Comments.dart`
- `lib/providers/download_provider.dart`

Include:

- reading surface
- immersive chrome behavior
- overlay systems
- gesture shell
- pagination and continuous-scroll shell
- chapter append behavior
- reader controls
- bookmark and comments affordances
- brightness-related UI
- orientation-aware UI behavior

Completion requirements:

- reader feels like the highest-priority product area
- overlays do not break immersion
- architecture leaves room for future caching and preloading logic
- gestures and layout decisions are documented clearly

### PHASE 5: Authentication Flows

Goal:

- build native account-entry flows and account-aware surfaces

Mandatory Flutter references:

- `lib/providers/auth_provider.dart`
- `lib/screens/LoginScreen.dart`
- `lib/screens/RegisterScreen.dart`
- `lib/screens/ProfileScreen.dart`

Include:

- sign in
- sign up if applicable
- auth gating surfaces
- profile entry behavior
- session-aware UI entry points

Completion requirements:

- auth flows fit the overall app shell
- route transitions are coherent
- architecture supports later backend integration cleanly

### PHASE 6: Offline And Download Systems UI

Goal:

- build the user-facing surfaces for downloads, offline access, and local state awareness

Mandatory Flutter references:

- `lib/providers/download_provider.dart`
- `lib/providers/offline_library_provider.dart`
- `lib/services/manga_repository.dart`
- `lib/services/library_repository.dart`
- `lib/services/sync_manager.dart`
- `lib/screens/DownloadQueueScreen.dart`

Include:

- download list surfaces
- item download states
- progress UI
- empty states
- offline messaging
- library offline indicators
- download management surfaces

Completion requirements:

- user-facing offline flows are understandable
- download UI can later connect to real persistence and background systems
- states are modeled cleanly without hacky shortcuts

### PHASE 7: Animation Polishing

Goal:

- raise the product from functional to premium

Mandatory Flutter references:

- inspect motion and interaction timing in the already migrated feature set
- inspect Flutter surfaces where animation intent affects hierarchy

Include:

- microinteractions
- haptics
- screen transitions
- artwork transitions
- reader overlay motion refinement
- iOS-native motion refinement

Completion requirements:

- motion feels consistent and intentional
- animation supports hierarchy and immersion
- polish does not reduce responsiveness

### PHASE 8: Performance Optimization

Goal:

- audit and refine UI performance, especially on dense content and reader surfaces

Mandatory Flutter references:

- inspect reader and browse surfaces for image density and scroll behavior
- inspect repository and local persistence boundaries before optimizing UI state ownership

Include:

- view decomposition review
- scroll performance improvements
- body recomposition awareness
- image-heavy surface optimization planning
- reader memory and performance considerations

Completion requirements:

- major surfaces remain responsive
- reader-oriented performance concerns are acknowledged structurally
- no premature optimization replaces sound architecture

## Implementation Workflow

For every phase, follow this workflow exactly:

STEP 1
Inspect Flutter implementation

STEP 2
Explain Flutter architecture and layout

STEP 3
Explain SwiftUI adaptation strategy

STEP 4
List files to create or modify

STEP 5
Implement incrementally

STEP 6
Summarize architectural decisions

STEP 7
Pause for approval

## Phase Execution Template

For every phase, follow this output structure exactly:

1. `Phase Goal`
2. `Flutter Files Inspected`
3. `Flutter Architecture And Layout Findings`
4. `SwiftUI Adaptation Strategy`
5. `Planned Files`
6. `Architecture Decisions`
7. `SwiftUI Mapping Notes`
8. `Implementation`
9. `Phase Summary`
10. `Files Created/Modified`
11. `Deferred Items`
12. `Commit Message`
13. `Awaiting Approval`

Do not skip these sections.

## Coding Standards

Maintain these standards in every phase:

- keep types small and focused
- prefer explicit naming over clever naming
- extract reusable primitives instead of repeating layout code
- keep file responsibilities narrow
- document non-obvious architectural decisions succinctly
- avoid over-commenting obvious code
- keep public API surfaces of shared components clean and predictable
- use previews where helpful for isolated UI iteration

## Decision Rules When Tradeoffs Appear

If you face a tradeoff, decide in this order:

1. preserve product behavior
2. preserve information hierarchy
3. preserve architecture consistency
4. choose native iOS interaction quality
5. maximize reuse
6. minimize complexity

If something is unclear:

- state the ambiguity
- inspect more Flutter context before guessing
- make the smallest safe assumption
- keep the implementation extensible
- note the assumption in the phase summary

## Final Operating Constraint

Do not generate the entire app at once.
Do not skip phases.
Do not jump ahead to backend logic unless the current phase requires a lightweight placeholder, mock repository, or model scaffolding.
Do not leave architecture unexplained.

Build Keihatsu like a real long-term iOS product:

- deliberate
- native
- scalable
- premium
- reader-first

Start with `PHASE 1` only.

Before generating code, first provide:

1. the phase objective
2. the Flutter files you inspected
3. the Flutter-to-SwiftUI intent
4. the exact files you plan to create or modify
5. the architecture reasoning for those files

Then wait for confirmation if a major structural assumption is required; otherwise proceed only with `PHASE 1`.
