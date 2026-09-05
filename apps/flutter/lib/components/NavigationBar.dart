import 'package:flutter/material.dart';

class ReaderBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ReaderBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green.shade700,
      unselectedItemColor: Colors.grey.shade500,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/home.png', height: 26),
          activeIcon: Image.asset('assets/icons/home_filled.png', height: 28),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/library.png', height: 26),
          activeIcon: Image.asset('assets/icons/library_filled.png', height: 28),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/history.png', height: 26),
          activeIcon: Image.asset('assets/icons/history_filled.png', height: 28),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/favorite.png', height: 26),
          activeIcon: Image.asset('assets/icons/favorite_filled.png', height: 28),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/profile.png', height: 26),
          activeIcon: Image.asset('assets/icons/profile_filled.png', height: 28),
          label: 'Profile',
        ),
      ],
    );
  }
}
