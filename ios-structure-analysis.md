# Analysis of `ios-structure.md`

## Executive Summary

`ios-structure.md` is not an implementation spec. It is a strategic migration brief plus a proposed native iOS project layout for rebuilding Keihatsu in SwiftUI. The document is strongest as a high-level architectural north star: it clearly prioritizes understanding the existing Flutter app first, preserving product behavior over widget-level parity, and treating the Reader as the most critical system in the app.

The file is well aligned with a modern Apple-platform rebuild. It recommends a sensible stack, emphasizes feature-based organization, and correctly identifies the manga reader as the engineering center of gravity. However, it remains intentionally broad. It does not yet define concrete module boundaries, data contracts, navigation ownership, persistence rules, offline sync behavior, API client layering, or ViewModel/service responsibilities. In other words, it is an excellent vision document, but not yet a build-ready architecture specification.

## What The Document Is Optimizing For

The guidance in `ios-structure.md` optimizes for:

- native SwiftUI feel rather than Flutter UI mirroring
- feature parity with the existing product
- clean separation of cross-cutting infrastructure from user-facing features
- long-term scalability for a content-heavy reading application
- special engineering investment in reading performance and UX

This is the correct priority set for a manga/manhwa reader. Reader quality, image loading behavior, caching, gestures, and continuity of progress matter more than strict UI cloning.

## Strong Architectural Choices

### 1. Product Behavior Over Widget Parity

The strongest principle in the document is the instruction to mirror product behavior rather than Flutter widgets. That is the right migration rule because:

- Flutter widgets do not map 1:1 to SwiftUI concepts
- native iOS interaction patterns will feel better for users
- preserving domain behavior protects backend compatibility and user expectations
- it reduces the risk of building an awkward "Flutter-shaped" iOS app

This principle should remain foundational throughout migration planning.

### 2. Feature-Based Folder Organization

The proposed top-level split into `App`, `Core`, `Models`, `Services`, `Features`, `DesignSystem`, and `Resources` is sound. It encourages:

- local ownership of feature-specific views and state
- reuse of cross-cutting infrastructure without polluting feature folders
- easier parallel development
- clearer separation between app composition and domain behavior

For a medium-to-large app, this is more scalable than a flat MVVM-by-type structure.

### 3. Reader As A Dedicated Subsystem

Calling the Reader a "mini-engine" is one of the most important and most correct recommendations in the file. In this app category, the reader is not just another screen. It is a specialized runtime subsystem with its own:

- pagination behavior
- image preloading rules
- gesture arbitration
- rendering performance constraints
- reading progress lifecycle
- settings model
- offline/caching concerns

Treating it as a first-class subsystem will prevent the common mistake of over-simplifying the most performance-sensitive feature in the product.

### 4. Recommended Native Stack

The suggested stack is pragmatic:

- `SwiftUI` for UI
- `MVVM` for presentation-layer organization
- `URLSession` + `async/await` for networking
- `NavigationStack` for navigation
- `Nuke` or `Kingfisher` for image loading
- `Swift Package Manager` for dependency management

These are mature choices and fit current Apple-platform development norms.

## What Is Missing Or Under-Specified

The document intentionally avoids low-level decisions, but several areas need more precision before implementation begins.

### 1. Architecture Style Is Named, But Not Defined

The file mentions MVVM, repositories, dependency injection, singleton usage, and utility abstractions as things to detect in Flutter, but it does not define the target architecture for iOS in a concrete way.

Open questions include:

- where business logic should live: ViewModels, services, repositories, or use cases
- whether repositories are protocol-based
- whether features own their own domain adapters
- how dependencies are injected into views and ViewModels
- whether global managers are environment objects, actors, or service singletons

Without these rules, teams can accidentally drift into inconsistent patterns across features.

### 2. `Models/` At Root May Become Ambiguous

A global `Models` folder is easy to start with, but it can become a dumping ground. In a real migration, the following model categories should be distinguished:

- API DTOs
- domain models
- persistence models
- feature-local view state models

If all of these go into `Models/`, naming collisions and unclear ownership will appear quickly. A better direction is:

- shared domain entities stay centralized only when genuinely cross-feature
- feature-specific models live inside each feature
- network DTOs and database models stay close to the layer that owns them

### 3. `Services/` Risks Becoming Too Broad

`Services/API`, `Services/Auth`, `Services/Reader`, `Services/Downloads`, `Services/Caching`, and `Services/Analytics` are reasonable categories, but "service" is an overloaded term. The file does not specify:

- whether services are low-level API clients or higher-level orchestrators
- whether caching belongs in services or in repositories
- whether downloads are background tasks, persistence coordination, or both
- whether reader logic belongs in feature-specific coordinators instead of app-wide services

For this app, some systems should likely be split into:

- transport layer: HTTP client, request building, decoding
- repository layer: entity retrieval + caching policy
- managers/coordinators: lifecycle-heavy systems like downloads or session state
- feature engines: reader pagination, prefetching, and interaction control

### 4. Offline Strategy Is Mentioned, Not Designed

The document correctly flags downloads, local storage, bookmarks/history, and offline capabilities as critical, but it does not describe:

- which entities are persisted locally
- how reading progress syncs with backend state
- conflict resolution rules
- what "downloaded chapter" means structurally
- cache eviction behavior
- background task behavior on iOS

This is a major gap because offline behavior is core product functionality for a reading app, and iOS implementation constraints differ from Flutter.

### 5. Navigation Ownership Is Not Yet Clear

`AppRouter.swift` is proposed, and `NavigationStack` is recommended, but the file does not explain:

- which flows are global vs feature-local
- how deep links are handled
- how authentication gates content
- whether modal presentation is centralized
- how reader launch context is preserved

Because navigation state is often tightly coupled to feature flow, this should be formalized early.

### 6. The Reader Breakdown Needs Runtime Rules

The Reader directory split is good, but it is still only structural. It needs explicit rules for:

- pagination strategy: page-by-page vs continuous vertical chapter reading
- image prefetch windows
- cache invalidation
- memory-pressure handling
- gesture priority between tap, drag, zoom, and system gestures
- restoration of reading state on relaunch
- accessibility behavior

These are not folder concerns; they are operational design decisions and should be documented separately.

### 7. Persistence Recommendation Needs Revalidation

The suggestion of `SwiftData initially` and `Realm later` is directionally useful but not yet justified by actual product needs.

Considerations:

- `SwiftData` is convenient for Apple-first apps but has operational tradeoffs depending on sync complexity, schema evolution, and debugging needs
- `Realm` adds power but also dependency and ecosystem complexity
- some persisted state may fit better in SQLite-backed storage, file storage, or lightweight key-value stores instead of one universal database choice

The right answer depends on the Flutter app's current offline/storage behavior, which the document itself says should be analyzed first.

## Best Reading Of The Proposed File Structure

Below is the likely intended role of each major directory.

### `App/`

Intended for application entry and top-level composition:

- app launch
- root dependency wiring
- root routing
- bootstrapping session/app state

This folder should stay thin and orchestration-focused.

### `Core/`

Intended for shared foundational utilities:

- extensions
- constants
- networking primitives
- storage primitives
- theme infrastructure
- low-level reusable components
- app-wide managers

This folder should contain infrastructure, not feature logic.

### `Models/`

Intended for shared domain entities, but should be carefully scoped to avoid becoming a generic catch-all.

### `Services/`

Intended for capability providers that talk to external systems or coordinate complex subsystems. This folder needs stricter responsibility boundaries than the document currently provides.

### `Features/`

Intended as the primary product surface. This should likely be the center of day-to-day development. Each feature should ideally own:

- views
- view models
- feature-local state
- UI components
- mappers/adapters as needed
- feature-specific services/coordinators when appropriate

### `DesignSystem/`

This is a strong inclusion. For a reader app, design consistency matters across:

- typography scale
- dark mode behavior
- reading surface chrome
- interaction affordances
- animation timing

It is especially useful if theming behavior differs between general app UI and the full-screen reading experience.

## Migration Implications For SwiftUI

### What Should Map Directly

Several recommendations map cleanly to SwiftUI:

- feature-based organization
- `NavigationStack`
- `Observable`/`ObservableObject` ViewModels depending on deployment target
- async service calls with task-based loading
- reusable design system components

### What Should Stay Platform-Agnostic

The document correctly implies that some concerns should remain independent of UI framework:

- API request/response contracts
- business rules for bookmarks, history, and progress
- content eligibility/auth rules
- chapter ordering and pagination rules
- caching policy definitions
- download state machine semantics

These should be expressed in domain logic and repositories/services, not encoded in SwiftUI views.

### What Should Become More iOS-Native

The file explicitly pushes toward native iOS behavior, and that should include:

- navigation patterns shaped around `NavigationStack`, sheets, and full-screen covers
- gesture behavior aligned with iOS expectations
- type ramp and spacing aligned with Apple typography rhythm
- system-aware loading, backgrounding, and memory behavior
- accessibility integration using Apple APIs rather than Flutter equivalents

This is where the rebuild can improve experience without breaking feature parity.

## Risks If This Document Is Used As-Is

If a team starts implementation using only this file, the most likely risks are:

- inconsistent MVVM interpretation across features
- unclear ownership between `Core`, `Services`, and `Features`
- over-centralized global state via managers or singletons
- a bloated `Models` folder
- a Reader implementation that is structurally separated but behaviorally under-specified
- offline/download work being deferred too late
- premature persistence choices before analyzing current Flutter data flow

These are not flaws in the document's intent, but they are gaps between vision and execution.

## Recommended Next Documents

To make `ios-structure.md` implementation-ready, it should be followed by a small set of companion documents:

### 1. Target Architecture Spec

Define:

- dependency injection strategy
- service vs repository vs ViewModel responsibilities
- async patterns
- error propagation rules
- global state ownership

### 2. Reader Engine Spec

Define:

- supported reading modes
- prefetching windows
- memory management rules
- gesture arbitration
- progress persistence
- restoration behavior

### 3. Data And Persistence Spec

Define:

- persisted entities
- cache policy
- offline downloads schema
- bookmark/history storage
- sync/conflict rules

### 4. Navigation And Flow Spec

Define:

- app launch flow
- auth flow
- tab/root navigation
- deep links
- modal ownership
- reader entry/exit behavior

### 5. Feature Inventory From Flutter

Define for each feature:

- purpose
- source files
- dependencies
- APIs touched
- state lifecycle
- SwiftUI mapping notes

This would directly support the "understand first, rewrite later" philosophy stated in the original file.

## Suggested Refinements To The Proposed Structure

The current structure is good, but it can be made safer with minor refinements:

### Recommended Adjustments

- keep `App/` as composition only
- keep `Core/` low-level and framework-like
- reduce usage of a global `Models/` folder
- let features own local models and coordinators where possible
- define repository interfaces close to domains, not as generic infrastructure
- keep Reader-specific runtime systems under `Features/Reader/` unless they are truly reusable elsewhere

One practical evolution might look like:

```text
Keihatsu/
├── App/
├── Core/
├── DesignSystem/
├── Domain/
├── Data/
├── Features/
│   ├── Home/
│   ├── Search/
│   ├── Library/
│   ├── MangaDetails/
│   ├── Reader/
│   ├── Downloads/
│   ├── Authentication/
│   ├── Profile/
│   └── Settings/
└── Resources/
```

Where:

- `Domain/` holds shared business entities and use-case-level contracts
- `Data/` holds API DTOs, repositories, persistence adapters, and cache implementations
- `Features/` holds feature UI, presentation state, and feature composition

This is not mandatory, but it reduces ambiguity as the app grows.

## Final Assessment

`ios-structure.md` is a strong strategic starting point and a useful migration brief. Its biggest strengths are:

- it prioritizes understanding the Flutter app before rewriting
- it clearly centers the Reader as the most important subsystem
- it encourages native iOS UX instead of framework imitation
- it proposes a scalable feature-based SwiftUI project structure

Its biggest limitation is that it stops at the "good blueprint" stage and does not yet define execution-level architecture. To move from concept to implementation, the next step is not code generation. The next step is turning this document into a set of precise specs for data flow, dependency ownership, offline behavior, reader runtime behavior, and feature-by-feature migration mapping.

In short: this file is a solid architectural north star, but it still needs concrete operating rules before it can safely drive the full iOS rebuild.
