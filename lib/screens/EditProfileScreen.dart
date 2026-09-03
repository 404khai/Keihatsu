import 'dart:io';

import 'package:blobatar/flutter.dart' as blobatar;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../components/user_blobatar.dart';
import '../providers/auth_provider.dart';
import '../theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _AvatarShapeOption {
  const _AvatarShapeOption(this.label, this.value);

  final String label;
  final double? value;
}

const List<_AvatarShapeOption> _avatarShapes = [
  _AvatarShapeOption('Original', null),
  _AvatarShapeOption('Round', 0.11),
  _AvatarShapeOption('Organic', 0.35),
  _AvatarShapeOption('Boxy', 0.54),
  _AvatarShapeOption('Capsule', 0.65),
  _AvatarShapeOption('Nub', 0.745),
  _AvatarShapeOption('Cloud', 0.825),
  _AvatarShapeOption('Droplet', 0.888),
  _AvatarShapeOption('Hexagon', 0.933),
  _AvatarShapeOption('Sun', 0.965),
  _AvatarShapeOption('Triangle', 0.99),
];

const List<double?> _avatarHues = [
  null,
  0,
  15,
  30,
  45,
  60,
  75,
  90,
  105,
  120,
  135,
  150,
  165,
  180,
  195,
  210,
  225,
  240,
  255,
  270,
  285,
  300,
  315,
  330,
  345,
];

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  File? _bannerFile;
  final ImagePicker _picker = ImagePicker();
  double? _avatarHue;
  double? _avatarShape;
  String _avatarExpression = 'happy';
  bool _avatarAnimated = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _avatarHue = user?.avatarHue;
    _avatarShape = user?.avatarShape;
    _avatarExpression = user?.avatarExpression ?? 'happy';
    _avatarAnimated = user?.avatarAnimated ?? false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => _bannerFile = File(image.path));
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        banner: _bannerFile,
        avatarHue: _avatarHue,
        avatarShape: _avatarShape,
        avatarExpression: _avatarExpression,
        avatarAnimated: _avatarAnimated,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final colors = Theme.of(context).colorScheme;
    final bgColor = themeProvider.effectiveBgColor;
    final avatarSeed = user?.id ?? 'keihatsu-reader';
    final avatarLabel = user?.username ?? 'Reader';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.denkOne(fontSize: 22)),
        actions: [
          if (authProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(
              colors: colors,
              backgroundColor: bgColor,
              bannerUrl: user?.bannerUrl,
              avatarSeed: avatarSeed,
              avatarLabel: avatarLabel,
            ),
            const SizedBox(height: 74),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your Blobatar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated from your private Keihatsu ID—never your Google photo.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildShapePicker(avatarSeed, avatarLabel, colors),
                  const SizedBox(height: 24),
                  _buildColorPicker(colors),
                  const SizedBox(height: 24),
                  _buildExpressionPicker(avatarSeed, avatarLabel, colors),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text('Animated avatar'),
                    subtitle: const Text(
                      'Enable breathing, blinking, and motion.',
                    ),
                    value: _avatarAnimated,
                    activeThumbColor: colors.primary,
                    onChanged: (value) =>
                        setState(() => _avatarAnimated = value),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('Username', _usernameController),
                  const SizedBox(height: 8),
                  Text(
                    'Username can only be changed twice every 7 days.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField('Bio', _bioController, maxLines: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader({
    required ColorScheme colors,
    required Color backgroundColor,
    required String? bannerUrl,
    required String avatarSeed,
    required String avatarLabel,
  }) {
    final ImageProvider bannerImage = _bannerFile != null
        ? FileImage(_bannerFile!)
        : bannerUrl != null && bannerUrl.isNotEmpty
        ? NetworkImage(bannerUrl)
        : const AssetImage('images/profileBg.jpeg');

    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _pickBanner,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(image: bannerImage, fit: BoxFit.cover),
              ),
              foregroundDecoration: const BoxDecoration(color: Colors.black26),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Change banner',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -44,
            child: Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: UserBlobatar(
                  seed: avatarSeed,
                  label: avatarLabel,
                  hue: _avatarHue,
                  shape: _avatarShape,
                  expression: _avatarExpression,
                  animated: _avatarAnimated,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapePicker(String seed, String label, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shape', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _avatarShapes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final option = _avatarShapes[index];
              return _AvatarOptionTile(
                label: option.label,
                selected: option.value == _avatarShape,
                colors: colors,
                onTap: () => setState(() => _avatarShape = option.value),
                child: UserBlobatar(
                  seed: seed,
                  label: '$label ${option.label}',
                  size: 54,
                  hue: _avatarHue,
                  shape: option.value,
                  expression: _avatarExpression,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _avatarHues.map((hue) {
            final selected = hue == _avatarHue;
            final swatch = hue == null
                ? colors.surfaceContainerHighest
                : HSVColor.fromAHSV(1, hue, 0.68, 0.92).toColor();
            return Semantics(
              label: hue == null ? 'Original color' : 'Hue ${hue.round()}',
              button: true,
              selected: selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _avatarHue = hue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? colors.onSurface : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: hue == null
                      ? Icon(
                          Icons.auto_awesome,
                          size: 17,
                          color: colors.onSurface,
                        )
                      : selected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color:
                              ThemeData.estimateBrightnessForColor(swatch) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpressionPicker(String seed, String label, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expression', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: blobatar.expressions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final expression = blobatar.expressions[index];
              return _AvatarOptionTile(
                label: expression.name,
                selected: expression.name == _avatarExpression,
                colors: colors,
                onTap: () =>
                    setState(() => _avatarExpression = expression.name),
                child: UserBlobatar(
                  seed: seed,
                  label: '$label ${expression.name}',
                  size: 54,
                  hue: _avatarHue,
                  shape: _avatarShape,
                  expression: expression.name,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AvatarOptionTile extends StatelessWidget {
  const _AvatarOptionTile({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final ColorScheme colors;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? colors.primaryContainer
          : colors.surfaceContainerHighest.withOpacity(0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child,
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
