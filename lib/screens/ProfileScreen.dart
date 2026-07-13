import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:keihatsu/components/floating_nav_scroll_scope.dart';
import 'package:keihatsu/components/keihatsu_refresh_indicator.dart';
import 'package:keihatsu/components/MainNavigationBar.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/components/menu/bottom_padding.dart';
import 'package:keihatsu/components/menu/developer_signature.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_header.dart';
import 'package:keihatsu/components/menu/menu_section.dart';
import 'package:keihatsu/components/menu/menu_tile.dart';
import 'package:keihatsu/components/menu/styled_sheet.dart';
import 'package:keihatsu/components/menu/version_indicator.dart';
import 'package:keihatsu/components/notification_pill.dart';
import 'package:keihatsu/providers/auth_provider.dart';
import 'package:keihatsu/screens/AboutScreen.dart';
import 'package:keihatsu/screens/AppearancePage.dart';
import 'package:keihatsu/screens/DonateScreen.dart';
import 'package:keihatsu/screens/DownloadQueueScreen.dart';
import 'package:keihatsu/screens/EditProfileScreen.dart';
import 'package:keihatsu/screens/HelpAndSupportScreen.dart';
import 'package:keihatsu/screens/InboxScreen.dart';
import 'package:keihatsu/screens/SettingsScreen.dart';
import 'package:keihatsu/screens/StatsScreen.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _currentIndex = 4;

  final ScrollController _scrollController = ScrollController();
  bool _showCollapsedTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final bool show = _scrollController.offset > 160;
    if (show != _showCollapsedTitle) {
      setState(() => _showCollapsedTitle = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _formatListeningTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final int hours = (minutes / 60).floor();
    return '${hours}h';
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Future<void> _handleGoogleSignIn(
  //   BuildContext context,
  //   AuthProvider authProvider,
  // ) async {
  //   try {
  //     await authProvider.loginWithGoogle();
  //     if (!context.mounted || !authProvider.isAuthenticated) return;
  //     Navigator.pushReplacementNamed(context, '/home');
  //   } catch (e) {
  //     if (!context.mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Sign in failed: $e')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color headerColor = cs.surfaceContainer;

    // Preview authenticated profile layout.
    // final bool isAuthenticated = authProvider.isAuthenticated;
    const bool showAuthenticatedPreview = true;

    final String displayName = showAuthenticatedPreview
        ? 'Kaizel'
        : (authProvider.isAuthenticated
            ? (user?.username ?? 'Reader')
            : 'Mystery Reader');
    final String? avatarUrl = showAuthenticatedPreview
        ? null
        : (authProvider.isAuthenticated ? user?.avatarUrl : null);

    final int readingMinutes = showAuthenticatedPreview
        ? 240
        : (user?.stats?.totalReadingTimeMinutes ?? 120);
    final int libraryCount =
        showAuthenticatedPreview ? 42 : (user?.stats?.libraryCount ?? 10);

    return Scaffold(
      extendBody: true,
      backgroundColor: themeProvider.pureBlackDarkMode && isDarkTheme
          ? Colors.black
          : Theme.of(context).colorScheme.surface,
      body: FloatingNavScrollScope(
        child: KeihatsuRefreshIndicator(
          onRefresh: () => authProvider.refreshUserStats(),
          child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              // expandedHeight: 460,
              expandedHeight: 420,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: headerColor,
              surfaceTintColor: Colors.transparent,
              leading: _showCollapsedTitle
                  ? const CustomBackButton()
                  : const SizedBox.shrink(),
              leadingWidth: 56,
              title: _showCollapsedTitle
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: OfflineImage(
                                imageUrl: avatarUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                fallback: Image.asset(
                                  'images/jake.jpeg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: themeProvider.pureBlackDarkMode && isDarkTheme
                          ? Colors.black
                          : cs.surface,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: MenuHeader(
                        displayName: displayName,
                        avatarUrl: avatarUrl,
                        statValue: _formatListeningTime(readingMinutes),
                        statLabel: 'read',
                        secondaryStatValue: libraryCount.toString(),
                        secondaryStatLabel: 'series',
                        bio: showAuthenticatedPreview
                            ? 'El Endministrator, Creator of Keihatsu'
                            : null,
                        memberSince:
                            showAuthenticatedPreview ? '2025' : null,
                        location:
                            showAuthenticatedPreview ? 'Switzerland' : null,
                        badgeIcon: showAuthenticatedPreview
                            ? Icons.hardware_rounded
                            : null,
                        showProfileActions: showAuthenticatedPreview,
                        onShareTap: () {
                          Clipboard.setData(
                            ClipboardData(text: 'https://keihatsu.app/u/kaizel'),
                          );
                          NotificationPill.show(
                            context,
                            message: 'Profile link copied',
                            icon: Icons.insert_link_rounded,
                          );
                        },
                        onEditTap: showAuthenticatedPreview
                            ? () => _push(context, const EditProfileScreen())
                            : null,
                        // Guest sign-in — commented to preview authenticated layout.
                        // belowName: !authProvider.isAuthenticated
                        //     ? [
                        //         8.gap,
                        //         FilledButton.icon(
                        //           onPressed: authProvider.isLoading
                        //               ? null
                        //               : () => _handleGoogleSignIn(
                        //                     context,
                        //                     authProvider,
                        //                   ),
                        //           icon: Image.asset(
                        //             'images/google.png',
                        //             width: 20,
                        //             height: 20,
                        //           ),
                        //           label: Text(
                        //             authProvider.isLoading
                        //                 ? 'Signing in...'
                        //                 : 'Sign up with Google',
                        //           ),
                        //         ),
                        //       ]
                        //     : null,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SafeArea(
                        child: CustomBackButton(
                          iconSize: _showCollapsedTitle ? 28 : 36,
                          margin: _showCollapsedTitle ? 8 : 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                BottomPadding.of(context) + kBottomNavigationBarHeight + 16,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  46.gap,
                  MenuSection(
                    label: 'Download Queue',
                    children: [
                      MenuTile(
                        icon: Icons.cloud_download_outlined,
                        title: 'Download Queue',
                        onTap: () => _push(context, const DownloadQueueScreen()),
                      ),
                    ],
                  ),
                  32.gap,
                  MenuSection(
                    label: 'Library',
                    children: [
                      MenuTile(
                        icon: Icons.label_outline,
                        title: 'Categories',
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/history'),
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
                      MenuTile(
                        icon: Icons.theater_comedy_outlined,
                        title: 'Incognito Mode',
                        trailing: Switch(
                          value: isDarkTheme,
                          thumbIcon: const WidgetStateProperty<Icon?>.fromMap({
                            WidgetState.selected:
                                Icon(Icons.theater_comedy_outlined),
                            WidgetState.any: Icon(Icons.face_6_outlined),
                          }),
                          onChanged: (_) => themeProvider.toggleDarkTheme(),
                        ),
                      ),
                    ],
                  ),
                  32.gap,
                  MenuSection(
                    label: 'Preferences',
                    children: [
                      MenuTile(
                        icon: Icons.brightness_6_outlined,
                        title: 'Dark theme',
                        trailing: Switch(
                          value: isDarkTheme,
                          thumbIcon: const WidgetStateProperty<Icon?>.fromMap({
                            WidgetState.selected: Icon(Icons.dark_mode_rounded),
                            WidgetState.any: Icon(Icons.light_mode_rounded),
                          }),
                          onChanged: (_) => themeProvider.toggleDarkTheme(),
                        ),
                      ),
                      MenuTile(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                      MenuTile(
                        icon: Icons.storage_outlined,
                        title: 'Data & Storage',
                        onTap: () => _push(context, const AppearancePage()),
                      ),
                    ],
                  ),
                  32.gap,
                  MenuSection(
                    label: 'Support',
                    children: [
                      MenuTile(
                        icon: Icons.redeem_outlined,
                        title: 'Support the Developer',
                        onTap: () => _push(context, const DonateScreen()),
                      ),
                      MenuTile(
                        icon: Icons.lightbulb_outlined,
                        title: 'Suggest a Feature',
                        onTap: () => _push(context, const HelpAndSupportScreen()),
                      ),
                      MenuTile(
                        icon: Icons.contact_support_outlined,
                        title: 'Help & Support',
                        onTap: () => _push(context, const HelpAndSupportScreen()),
                      ),
                      MenuTile(
                        icon: Icons.info_outlined,
                        title: 'About',
                        onTap: () => _push(context, const AboutScreen()),
                      ),
                    ],
                  ),
                  if (showAuthenticatedPreview) ...[
                    32.gap,
                    MenuSection(
                      label: 'Account',
                      children: [
                        MenuTile(
                          icon: Icons.logout_outlined,
                          title: 'Log out',
                          onTap: () async {
                            final bool confirmed = await StyledSheet.show(
                              context,
                              icon: Icons.logout_rounded,
                              title: 'Log out?',
                              message:
                                  'You can sign back in anytime. Your subscriptions '
                                  'and downloads stay on this device.',
                              confirmLabel: 'Log out',
                            );
                            if (confirmed && context.mounted) {
                              await authProvider.logout();
                              if (!context.mounted) return;
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                        ),
                        MenuTile(
                          icon: Icons.delete_forever_outlined,
                          title: 'Delete account',
                          foreground: cs.error,
                          onTap: () async {
                            final bool confirmed = await StyledSheet.show(
                              context,
                              icon: Icons.delete_forever_rounded,
                              title: 'Delete account?',
                              message:
                                  'This permanently erases your account, subscriptions, '
                                  "and listening history. This can't be undone.",
                              confirmLabel: 'Delete forever',
                              destructive: true,
                            );
                            if (confirmed && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Account deletion is not available yet.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  // Guest account section — commented to preview authenticated layout.
                  // if (!authProvider.isAuthenticated) ...[
                  //   32.gap,
                  //   MenuSection(
                  //     label: 'Account',
                  //     children: [
                  //       MenuTile(
                  //         icon: Icons.login_outlined,
                  //         title: 'Log in',
                  //         onTap: () => Navigator.pushNamed(context, '/login'),
                  //       ),
                  //     ],
                  //   ),
                  // ],
                  64.gap,
                  const VersionIndicator(),
                  8.gap,
                  DeveloperSignature(avatarUrl: user?.avatarUrl),
                  16.gap,
                ]),
              ),
            ),
          ],
        ),
        ),
      ),
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        brandColor: themeProvider.brandColor,
      ),
    );
  }
}
