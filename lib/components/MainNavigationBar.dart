import 'package:flutter/material.dart';

import 'expandable_floating_main_nav.dart';

/// Bottom navigation for main tabs.
///
/// Legacy [BottomNavigationBar] implementation is preserved below (commented).
/// Active UI: M3E [ExpandableHorizontalFloatingToolbar] port — see
/// https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:compose/material3/material3/samples/src/main/java/androidx/compose/material3/samples/FloatingToolbarSamples.kt
class MainNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Color brandColor;

  const MainNavigationBar({
    super.key,
    required this.currentIndex,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableFloatingMainNav(
      currentIndex: currentIndex,
      brandColor: brandColor,
    );
  }
}

// --- Legacy bottom navigation (Phosphor icons + labels) ---
//
// import 'package:phosphor_flutter/phosphor_flutter.dart';
//
// class MainNavigationBar extends StatelessWidget {
//   final int currentIndex;
//   final Color brandColor;
//
//   const MainNavigationBar({
//     super.key,
//     required this.currentIndex,
//     required this.brandColor,
//   });
//
//   void _onTap(BuildContext context, int index) {
//     if (index == currentIndex) return;
//
//     final routes = {
//       0: '/home',
//       1: '/library',
//       2: '/history',
//       3: '/extensions',
//       4: '/profile',
//     };
//
//     final targetRoute = routes[index];
//     if (targetRoute != null) {
//       Navigator.pushReplacementNamed(context, targetRoute);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: (index) => _onTap(context, index),
//       backgroundColor: const Color(0xFF1A1A1A),
//       type: BottomNavigationBarType.fixed,
//       selectedItemColor: brandColor,
//       unselectedItemColor: Colors.grey,
//       selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
//       items: [
//         BottomNavigationBarItem(
//           icon: Icon(PhosphorIcons.house()),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(PhosphorIcons.books()),
//           label: 'Library',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(PhosphorIcons.clockCounterClockwise()),
//           label: 'History',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(PhosphorIcons.puzzlePiece()),
//           label: 'Extensions',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(PhosphorIcons.user()),
//           label: 'Profile',
//         ),
//       ],
//     );
//   }
// }
