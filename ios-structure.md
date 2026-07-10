You are a senior mobile architect and codebase analyst.

Your task is to deeply understand this Flutter codebase for an app called Keihatsu, a manhwa/manga reader application.

I am rebuilding the iOS version natively using SwiftUI while preserving all business logic, features, flows, and user experience concepts from the Flutter implementation.

Your responsibilities:

1. Analyze the ENTIRE Flutter architecture

* Identify app structure
* Feature modules
* State management approach
* Routing/navigation system
* Service layers
* API integrations
* Data models
* Caching strategy
* Reader implementation
* Offline capabilities
* Authentication flows
* Theme handling
* Search architecture
* Library/bookmark system
* Pagination/loading systems

2. Build a mental map of the application
   For every feature:

* explain its purpose
* dependencies
* data flow
* API usage
* state lifecycle
* UI composition
* reusable components

3. Help prepare for native iOS replication
   For each Flutter feature:

* explain how it should map to SwiftUI
* suggest native iOS UX improvements
* identify Apple-native interaction patterns
* recommend SwiftUI architecture equivalents
* identify what should remain platform-agnostic

4. Detect architectural patterns
   Identify:

* MVVM
* Clean architecture
* Repository pattern
* Provider/Riverpod/BLoC usage
* Dependency injection
* Singleton usage
* Utility abstractions

5. Create migration guidance
   When asked:

* generate SwiftUI equivalents
* map Flutter widgets to SwiftUI concepts
* preserve business logic behavior
* maintain API compatibility

6. Prioritize understanding over rewriting
   Do NOT immediately rewrite everything.
   First:

* understand deeply
* explain clearly
* trace data flow carefully
* identify critical app systems

7. Special focus areas
   Pay EXTRA attention to:

* reader engine
* image loading
* chapter pagination
* scrolling performance
* gesture systems
* download/offline systems
* local storage
* bookmarks/history
* animation systems
* theming

8. Coding philosophy
   The new iOS app should:

* feel fully native to iOS
* use SwiftUI best practices
* preserve feature parity
* improve UX where appropriate
* maintain backend/API compatibility

9. When explaining code:
   Always include:

* purpose
* dependencies
* lifecycle
* architecture role
* migration notes for SwiftUI

10. Never assume shallow understanding
    Before suggesting architecture changes:

* inspect related files
* trace dependencies
* understand business intent
* identify hidden coupling

Your role is not just code generation.
Your role is to become an expert on this codebase and help guide a professional native iOS migration.




Recommended Keihatsu iOS File Structure

This is modern, scalable, and very suitable for:

SwiftUI
MVVM
feature-based architecture
content-heavy apps

Keihatsu-iOS/
├── Keihatsu.xcodeproj
│
├── Keihatsu/
│
│   ├── App/
│   │   ├── KeihatsuApp.swift
│   │   ├── AppRouter.swift
│   │   └── AppEnvironment.swift
│   │
│   ├── Core/
│   │   ├── Extensions/
│   │   ├── Utilities/
│   │   ├── Constants/
│   │   ├── Networking/
│   │   ├── Storage/
│   │   ├── Theme/
│   │   ├── Components/
│   │   └── Managers/
│   │
│   ├── Models/
│   │   ├── Manga.swift
│   │   ├── Chapter.swift
│   │   ├── User.swift
│   │   └── Bookmark.swift
│   │
│   ├── Services/
│   │   ├── API/
│   │   ├── Auth/
│   │   ├── Reader/
│   │   ├── Downloads/
│   │   ├── Caching/
│   │   └── Analytics/
│   │
│   ├── Features/
│   │
│   │   ├── Home/
│   │   │   ├── Views/
│   │   │   ├── ViewModels/
│   │   │   ├── Components/
│   │   │   └── Models/
│   │   │
│   │   ├── Search/
│   │   ├── Library/
│   │   ├── Reader/
│   │   ├── MangaDetails/
│   │   ├── Authentication/
│   │   ├── Profile/
│   │   ├── Settings/
│   │   └── Downloads/
│   │
│   ├── DesignSystem/
│   │   ├── Colors/
│   │   ├── Typography/
│   │   ├── Spacing/
│   │   ├── Animations/
│   │   └── Components/
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Fonts/
│   │   └── Localization/
│   │
│   └── Preview Content/



IMPORTANT architectural advice

For Keihatsu specifically:

The Reader feature is the MOST important engineering system.

Treat it almost like its own mini-engine.

Meaning:
Features/
└── Reader/
    ├── Views/
    ├── ViewModels/
    ├── Components/
    ├── GestureHandling/
    ├── Pagination/
    ├── Caching/
    ├── Preloading/
    └── ReaderSettings/

This is where premium UX will come from.

Recommended SwiftUI stack for you
UI
SwiftUI
Architecture
MVVM
Networking
URLSession
async/await
Image Loading
Nuke
OR
Kingfisher
Local Storage
SwiftData initially
OR
Realm later
Dependency Management
Swift Package Manager
Navigation
NavigationStack
One final recommendation

As you migrate:

DO NOT try to perfectly mirror Flutter widgets
Mirror PRODUCT BEHAVIOR instead

Example:

same feature
same backend
same logic

BUT:

native iOS navigation
native transitions
native gestures
native animations
native typography rhythm

That’s what will make Keihatsu feel truly premium on iOS.