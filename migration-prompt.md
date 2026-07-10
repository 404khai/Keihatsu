You are now acting as a senior Apple platform architect, SwiftUI migration planner, and product UX systems designer.

Your task is NOT to directly generate SwiftUI code yet.

Your task is to generate a COMPLETE implementation master-prompt that I will later give to GPT inside Xcode for phased UI migration of my Flutter app called Keihatsu into a fully native iOS application.

You must deeply use the attached migration analysis and architecture documents as context.

The goal is to create a PHASED implementation strategy focused FIRST on UI replication and navigation structure before backend/business logic migration.

IMPORTANT CONTEXT

Keihatsu is:
- a manhwa/manga reader app
- originally built in Flutter
- being rebuilt natively in SwiftUI
- targeting modern iOS design language
- prioritizing premium UX
- inspired by Apple-native interaction patterns
- should feel like a real App Store-quality iOS app

The implementation should:
- preserve product behavior from Flutter
- NOT mirror Flutter widgets literally
- follow modern SwiftUI architecture
- follow Apple Human Interface Guidelines
- feel designed specifically for iOS
- prioritize smooth navigation and reading UX

Your job:
Generate a ROBUST MASTER PROMPT that I can later paste into GPT inside Xcode.

That prompt must instruct GPT to:
- implement the migration PHASE BY PHASE
- strictly follow the Flutter structure/features
- build reusable design systems first
- use modern SwiftUI patterns
- maintain scalability
- avoid architecture drift
- preserve feature parity
- maintain native Apple aesthetics

VERY IMPORTANT

The generated master prompt should:
- sound like instructions from a senior iOS lead engineer
- be extremely detailed
- include architecture rules
- include coding standards
- include folder organization rules
- include naming conventions
- include navigation standards
- include animation guidance
- include design language guidance
- include component reuse rules
- include phase goals
- include completion requirements per phase
- include what NOT to do

The generated prompt must instruct GPT to:
- pause after each phase
- summarize completed work
- explain created files
- explain architectural decisions
- wait for approval before continuing

The generated prompt should structure the migration into multiple phases like this:

PHASE 0
Project scaffolding and architecture foundation

PHASE 1
Core app shell
- splash screen
- onboarding shell
- tab navigation
- navigation architecture
- routing
- icons
- typography
- theme system
- base reusable components

PHASE 2
Core pages UI replication
- home
- search
- library
- profile
- settings

PHASE 3
Manga details flow
- manga detail screen
- chapter lists
- hero transitions
- artwork handling

PHASE 4
Reader engine UI
- immersive reading UI
- gestures
- overlays
- pagination shell
- reader controls
- brightness UI
- orientation handling

PHASE 5
Authentication flows

PHASE 6
Offline/download systems UI

PHASE 7
Animation polishing
- microinteractions
- haptics
- transitions
- iOS-native motion

PHASE 8
Performance optimization

The generated prompt MUST ALSO include:

1. DESIGN LANGUAGE REQUIREMENTS

The app should follow:
- iOS 26 visual language
- glassmorphism where appropriate
- layered depth
- large title navigation
- native tab behavior
- dynamic island awareness where relevant
- adaptive dark mode
- smooth spring animations
- immersive edge-to-edge layouts
- premium typography rhythm
- native safe-area handling
- modern content-first layouts

2. SWIFTUI REQUIREMENTS

Enforce:
- SwiftUI only
- MVVM
- feature-first architecture
- reusable design system
- async/await
- NavigationStack
- environment-based dependency injection
- modular components
- observable state management

3. FILE STRUCTURE REQUIREMENTS

The generated prompt should include:
- exact folder structure
- responsibilities per folder
- where reusable components live
- where feature-local components live
- where navigation logic lives
- where reader-specific systems live

4. READER PRIORITY REQUIREMENTS

The generated prompt must emphasize:
- reader is the highest priority subsystem
- gestures must feel premium
- scrolling performance matters
- image loading matters
- memory management matters
- immersive experience matters

5. OUTPUT FORMAT REQUIREMENTS

The generated prompt must force GPT inside Xcode to always:
- explain before coding
- list files before generating
- generate code incrementally
- avoid massive single-file outputs
- maintain clean architecture
- explain SwiftUI decisions
- explain Flutter-to-SwiftUI mapping

6. WHAT TO AVOID

The generated prompt should explicitly forbid:
- UIKit unless necessary
- massive God ViewModels
- tight coupling
- duplicated components
- Flutter-style UI imitation
- poor SwiftUI practices
- giant files
- hardcoded spacing/colors
- random architecture changes

7. FINAL OUTPUT FORMAT

The output should be:
- one SINGLE polished master prompt
- ready to directly paste into GPT inside Xcode
- highly professional
- highly detailed
- implementation-oriented
- optimized for long-term iterative migration

IMPORTANT:
Do not generate SwiftUI code.
Only generate the migration master prompt.