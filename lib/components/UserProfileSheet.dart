import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import 'user_blobatar.dart';
import '../screens/PublicProfileScreen.dart';
import '../services/auth_api.dart';
import '../theme_provider.dart';

class UserProfileSheet extends StatefulWidget {
  final String userId;
  final String username;
  final String? userImage;

  const UserProfileSheet({
    super.key,
    required this.userId,
    required this.username,
    this.userImage,
  });

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> {
  late Future<PublicProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthApi().getPublicProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = themeProvider.effectiveBgColor;
    final isDarkMode = themeProvider.isDarkTheme;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: FutureBuilder<PublicProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final displayName = profile?.username ?? widget.username;
          final bio = profile?.bio?.trim().isNotEmpty == true
              ? profile!.bio!.trim()
              : 'No bio available';
          final bannerUrl = profile?.bannerUrl;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: _buildBanner(bannerUrl),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildAvatar(profile, displayName, 90),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile != null && !profile.isProfilePublic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIcons.lock(),
                                    size: 14,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Private library',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (snapshot.hasError)
                        Text(
                          'Failed to load profile details',
                          style: TextStyle(color: textColor.withOpacity(0.6)),
                        )
                      else if (profile != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              '${profile.stats?.commentsCount ?? 0}',
                              'Comments',
                              textColor,
                            ),
                            _buildStatItem(
                              '${profile.stats?.mangasReadToday ?? 0}',
                              'Read today',
                              textColor,
                            ),
                            _buildStatItem(
                              '${profile.stats?.libraryCount ?? 0}',
                              'Library',
                              textColor,
                            ),
                            _buildStatItem(
                              '${profile.stats?.points ?? 0}',
                              'Points',
                              textColor,
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PublicProfileScreen(
                                  userId: widget.userId,
                                  fallbackUsername: widget.username,
                                  fallbackAvatarUrl: widget.userImage,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: textColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'View profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(PhosphorIcons.caretRight(), size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner(String? bannerUrl) {
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      return Image.network(
        bannerUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('images/profileBg.jpeg', fit: BoxFit.cover),
      );
    }

    return Image.asset('images/profileBg.jpeg', fit: BoxFit.cover);
  }

  Widget _buildAvatar(PublicProfile? profile, String label, double size) {
    return UserBlobatar(
      seed: profile?.id ?? widget.userId,
      label: label,
      size: size,
      hue: profile?.avatarHue,
      shape: profile?.avatarShape,
      expression: profile?.avatarExpression ?? 'happy',
      animated: profile?.avatarAnimated ?? false,
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5)),
        ),
      ],
    );
  }
}
