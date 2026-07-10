You are upgrading the existing Keihatsu iOS migration master-prompt.

The migration strategy has changed.

IMPORTANT NEW CONTEXT

The Flutter codebase will now exist SIDE-BY-SIDE with the native iOS project during migration.

Structure:

Developer/
├── Keihatsu-Flutter/
├── Keihatsu-iOS/

This means the migration system can directly inspect:
- Flutter pages
- widgets
- reusable components
- layouts
- spacing systems
- typography usage
- navigation structure
- assets
- mock data
- animation behavior
- reader interactions

IMPORTANT:
The SwiftUI app should NOT blindly clone Flutter widgets.

Instead:
- preserve visual rhythm
- preserve information hierarchy
- preserve content density
- preserve user scanning patterns
- preserve layout structure where beneficial
- preserve interaction intent

WHILE:
- adapting to native iOS patterns
- improving polish
- improving motion
- improving navigation
- improving accessibility
- improving responsiveness

UPDATE THE MASTER PROMPT TO INCLUDE:

1. FLUTTER REFERENCE ANALYSIS MODE

The generated prompt must instruct GPT inside Xcode to:
- inspect Flutter feature folders before implementing SwiftUI versions
- analyze page layout composition
- inspect reusable widgets
- inspect navigation flow
- inspect state dependencies
- inspect spacing and sizing patterns
- inspect typography hierarchy
- inspect mock data usage
- inspect component reuse patterns

Before implementing each SwiftUI screen, GPT should:
- explain the Flutter screen structure
- explain layout hierarchy
- explain component composition
- explain reusable elements
- explain state flow
- explain how it should map to SwiftUI

2. DESIGN PARITY RULES

The generated prompt must instruct GPT to preserve:
- thumbnail positioning
- text hierarchy
- card proportions
- spacing rhythm
- content density
- section layout behavior
- manga grid/list structure
- bottom navigation organization
- home feed rhythm
- carousel behavior
- category grouping logic

WITHOUT:
- literally recreating Flutter widgets
- forcing Material Design patterns into iOS

3. ASSET MANAGEMENT RULES

Update the architecture guidance to include:

Resources/
├── Assets.xcassets/
│   ├── MangaCovers/
│   ├── Banners/
│   ├── Reader/
│   ├── Icons/
│   ├── Avatars/
│   └── Illustrations/
│
├── MockData/
│   ├── manga.json
│   ├── chapters.json
│   ├── library.json
│   └── trending.json

The generated prompt must instruct GPT to:
- use mock JSON data during UI migration
- create Swift decodable models
- create mock repositories
- avoid hardcoded UI content
- build screens against realistic content structures

4. FLUTTER → SWIFTUI COMPONENT MAPPING

The generated prompt must instruct GPT to identify:
- reusable Flutter widgets
- reusable SwiftUI equivalents
- navigation components
- manga card systems
- reader overlays
- tab systems
- search bars
- reusable buttons
- reusable sheets
- reusable modals

And consolidate them into:
DesignSystem/
Core/Components/
or Feature-local Components/

appropriately.

5. NAVIGATION PARITY REQUIREMENTS

The generated prompt must instruct GPT to:
- inspect Flutter bottom navigation structure
- preserve navigation organization
- preserve tab logic
- preserve screen hierarchy
- preserve flow expectations

BUT:
- adapt to native iOS NavigationStack behavior
- use native transitions
- use iOS tab interaction patterns
- support large-title navigation where appropriate

6. READER REPLICATION PRIORITY

The generated prompt must heavily emphasize:
- inspecting the Flutter reader carefully
- preserving reading immersion
- preserving gesture intent
- preserving reading flow
- preserving overlay timing
- preserving chapter navigation behavior

WHILE:
- improving iOS-native gesture fluidity
- improving scrolling performance
- improving image loading
- improving memory management

7. IMPLEMENTATION WORKFLOW

The generated prompt must enforce this workflow for EVERY phase:

STEP 1
Inspect Flutter implementation

STEP 2
Explain Flutter architecture and layout

STEP 3
Explain SwiftUI adaptation strategy

STEP 4
List files to create

STEP 5
Implement incrementally

STEP 6
Summarize architectural decisions

STEP 7
Pause for approval

8. DATA MIGRATION RULES

The generated prompt must instruct GPT to:
- inspect existing Dart mock data
- convert models into Swift equivalents
- convert mock data into JSON where appropriate
- build repository abstractions early
- support future backend replacement without UI rewrites

9. IMPORTANT RESTRICTIONS

The generated prompt must forbid:
- direct widget-for-widget Flutter cloning
- Material Design behavior in iOS
- ignoring Flutter information hierarchy
- random redesigns
- inconsistent spacing
- hardcoded assets
- giant ViewModels
- tightly coupled views

10. FINAL GOAL

The generated prompt should optimize for:
- a premium native iOS manga reader
- preserving Keihatsu identity
- preserving recognizable layout DNA
- native Apple-quality UX
- scalable architecture
- future backend integration
- maintainable SwiftUI systems

IMPORTANT:
Do NOT generate SwiftUI code.
ONLY generate the updated master prompt.