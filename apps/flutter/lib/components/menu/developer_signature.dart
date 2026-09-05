import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/screens/AboutScreen.dart';
import 'package:material_shapes/material_shapes.dart';

class DeveloperSignature extends StatelessWidget {
  const DeveloperSignature({
    super.key,
    this.avatarUrl,
    this.developerName = '404khai',
  });

  final String? avatarUrl;
  final String developerName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final TextStyle style = GoogleFonts.nanumPenScript(
      textStyle: tt.titleMedium,
      color: cs.onSurfaceVariant,
    );

    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Crafted by', style: style),
              8.gap,
              ClipPath(
                clipper: ShapeBorderClipper(
                  shape: MaterialShapeBorder(shape: MaterialShapes.bun),
                ),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: OfflineImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    fallback: Image.asset(
                      'images/404khai.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              4.gap,
              Text(developerName, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
