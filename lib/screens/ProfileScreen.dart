import 'package:flutter/material.dart';
import 'package:keihatsu/components/MainNavigationBar.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:keihatsu/components/menu/bottom_padding.dart';
import 'package:keihatsu/components/menu/confirm_sheet.dart';
import 'package:keihatsu/components/menu/developer_signature.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_header.dart';
import 'package:keihatsu/components/menu/menu_section.dart';
import 'package:keihatsu/components/menu/menu_tile.dart';
import 'package:keihatsu/components/menu/version_indicator.dart';
import 'package:keihatsu/providers/auth_provider.dart';
import 'package:keihatsu/screens/AboutScreen.dart';
import 'package:keihatsu/screens/DonateScreen.dart';
import 'package:keihatsu/screens/DownloadQueueScreen.dart';
import 'package:keihatsu/screens/EditProfileScreen.dart';
import 'package:keihatsu/screens/HelpAndSupportScreen.dart';
import 'package:keihatsu/screens/InboxScreen.dart';
import 'package:keihatsu/screens/SettingsScreen.dart';
import 'package:keihatsu/screens/StatsScreen.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const int _currentIndex = 4;

  String _formatReadingTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final double hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: themeProvider.effectiveBgColor,
      body: RefreshIndicator(
        onRefresh: () => authProvider.refreshUserStats(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            BottomPadding.of(context) + kBottomNavigationBarHeight + 16,
          ),
          children: [
            if (authProvider.isAuthenticated)
              MenuHeader(
                displayName: user?.username ?? 'Reader',
                avatarUrl: user?.avatarUrl,
                readingTimeValue: _formatReadingTime(
                  user?.stats?.totalReadingTimeMinutes ?? 0,
                ),
                libraryCountValue:
                    (user?.stats?.libraryCount ?? 0).toString(),
                onEditTap: () => _push(context, const EditProfileScreen()),
              )
            else
              _GuestHeader(
                onSignIn: () => Navigator.pushNamed(context, '/login'),
                onGoogleSignIn: () => authProvider.loginWithGoogle(),
              ),
            56.gap,
            MenuSection(
              label: 'Library',
              children: [
                MenuTile(
                  icon: Icons.download_outlined,
                  title: 'Download Queue',
                  onTap: () => _push(context, const DownloadQueueScreen()),
                ),
                MenuTile(
                  icon: Icons.history_outlined,
                  title: 'Reading history',
                  onTap: () => Navigator.pushReplacementNamed(context, '/history'),
                ),
                MenuTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'Stats',
                  onTap: () => _push(context, const StatsScreen()),
                ),
                MenuTile(
                  icon: Icons.inbox_outlined,
                  title: 'Inbox',
                  onTap: () => _push(context, const InboxScreen()),
                ),
              ],
            ),
            32.gap,
            MenuSection(
              label: 'Preferences',
              children: [
                MenuTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Theme',
                  trailing: Switch(
                    value: themeProvider.pureBlackDarkMode,
                    thumbIcon: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Icon(Icons.dark_mode_rounded);
                      }
                      return const Icon(Icons.light_mode_rounded);
                    }),
                    onChanged: themeProvider.setPureBlackDarkMode,
                  ),
                ),
                MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => _push(context, const SettingsScreen()),
                ),
              ],
            ),
            32.gap,
            MenuSection(
              label: 'Support',
              children: [
                MenuTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Support the developer',
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                  onTap: () => _push(context, const DonateScreen()),
                ),
                MenuTile(
                  icon: Icons.lightbulb_outlined,
                  title: 'Suggest a feature',
                  onTap: () => _push(context, const HelpAndSupportScreen()),
                ),
                MenuTile(
                  icon: Icons.alternate_email_outlined,
                  title: 'Contact',
                  onTap: () => _push(context, const HelpAndSupportScreen()),
                ),
                MenuTile(
                  icon: Icons.info_outlined,
                  title: 'About',
                  onTap: () => _push(context, const AboutScreen()),
                ),
              ],
            ),
            if (authProvider.isAuthenticated) ...[
              32.gap,
              MenuSection(
                label: 'Account',
                children: [
                  MenuTile(
                    icon: Icons.logout_outlined,
                    title: 'Log out',
                    onTap: () {
                      ConfirmSheet.show(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Log out?',
                        message:
                            'You can sign back in anytime. Your library '
                            'and downloads stay on this device.',
                        confirmLabel: 'Log out',
                        onConfirm: () async {
                          await authProvider.logout();
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      );
                    },
                  ),
                  MenuTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete account',
                    foreground: cs.error,
                    onTap: () {
                      ConfirmSheet.show(
                        context,
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete account?',
                        message:
                            'This permanently erases your account, library, '
                            "and reading history. This can't be undone.",
                        confirmLabel: 'Delete forever',
                        destructive: true,
                        onConfirm: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Account deletion is not available yet.',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ] else ...[
              32.gap,
              MenuSection(
                label: 'Account',
                children: [
                  MenuTile(
                    icon: Icons.login_outlined,
                    title: 'Log in',
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            ],
            64.gap,
            const VersionIndicator(),
            8.gap,
            DeveloperSignature(avatarUrl: user?.avatarUrl),
            16.gap,
          ],
        ),
      ),
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        brandColor: themeProvider.brandColor,
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader({
    required this.onSignIn,
    required this.onGoogleSignIn,
  });

  final VoidCallback onSignIn;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          ClipPath(
            clipper: ShapeBorderClipper(
              shape: MaterialShapeBorder(shape: MaterialShapes.pill),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset('images/avatar.jpeg', fit: BoxFit.cover),
            ),
          ),
          24.gap,
          Text(
            'Guest',
            textAlign: TextAlign.center,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          16.gap,
          FilledButton.icon(
            onPressed: onGoogleSignIn,
            icon: Image.asset('images/google.png', width: 20, height: 20),
            label: const Text('Sign up with Google'),
          ),
          8.gap,
          TextButton(
            onPressed: onSignIn,
            child: Text('Log in', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }
}
