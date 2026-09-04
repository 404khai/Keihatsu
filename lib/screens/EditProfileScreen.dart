import 'package:blobatar/flutter.dart' as blobatar;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../components/user_blobatar.dart';
import '../providers/auth_provider.dart';

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

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bgColor = theme.scaffoldBackgroundColor;
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
        title: Text(
          'Edit Profile',
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
              child: FilledButton.icon(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHigh,
                  foregroundColor: colors.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: colors.onSurface,
                ),
                label: Text(
                  'Save',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            _buildAvatarPreview(
              colors: colors,
              avatarSeed: avatarSeed,
              avatarLabel: avatarLabel,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Customize your Blobatar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Give your blob some personality, tweak the shape, its expression and even animate it.',
                    textAlign: TextAlign.center,
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
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildAvatarPreview({
    required ColorScheme colors,
    required String avatarSeed,
    required String avatarLabel,
  }) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: label == 'Username'
                ? 'Enter your username'
                : 'Tell readers about yourself',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colors.primary : Colors.transparent,
          width: 2,
        ),
      ),
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
                    color: selected ? colors.primary : colors.onSurfaceVariant,
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
