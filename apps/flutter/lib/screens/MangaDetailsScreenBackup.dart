import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class MangaDetailsScreenBackup extends StatelessWidget {
  final Map<String, String> manga;

  const MangaDetailsScreenBackup({super.key, required this.manga});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.bgColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Blurred/Darkened Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    manga["bgImage"] ?? manga["image"]!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          bgColor,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft(), color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(onPressed: () {}, icon: Icon(PhosphorIcons.downloadSimple(), color: Colors.white)),
                  IconButton(onPressed: () {}, icon: Icon(PhosphorIcons.funnel(), color: Colors.white)),
                  IconButton(onPressed: () {}, icon: Icon(PhosphorIcons.dotsThreeVertical(), color: Colors.white)),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foreground Manga Cover
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                manga["image"]!,
                                height: 180,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  manga["title"]!,
                                  style: GoogleFonts.hennyPenny(
                                    textStyle: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black,
                                          offset: Offset(2.0, 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(PhosphorIcons.user(), "Jong-Seok Park"),
                                const SizedBox(height: 4),
                                _buildInfoRow(PhosphorIcons.pencilLine(), "Hyeon-Jun Oh"),
                                const SizedBox(height: 4),
                                _buildInfoRow(PhosphorIcons.clock(), "Ongoing • Vortex Scans"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(PhosphorIcons.heart(PhosphorIconsStyle.fill), "In library", brandColor),
                          _buildActionButton(PhosphorIcons.hourglassHigh(), "5 days", Colors.black54),
                          _buildActionButton(PhosphorIcons.arrowsClockwise(), "Tracking", Colors.black54),
                          _buildActionButton(PhosphorIcons.globe(), "WebView", Colors.black54),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Through posting a \"Best Comment\", I somehow became the main character of a webtoon!",
                        style: TextStyle(color: Colors.black87, height: 1.4),
                      ),
                      Center(child: Icon(PhosphorIcons.caretDown(), color: Colors.black54)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _buildTag("Manhwa"),
                          const SizedBox(width: 10),
                          _buildTag("Action"),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "246 chapters",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _buildChapterTile(context, 245 - index, brandColor);
                  },
                  childCount: 10,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brandColor,
        onPressed: () {},
        icon: Icon(PhosphorIcons.play(), color: Colors.white),
        label: const Text("Resume", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoRow(PhosphorIconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 5.0, color: Colors.black, offset: Offset(1.0, 1.0)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(PhosphorIconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black87)),
    );
  }

  Widget _buildChapterTile(BuildContext context, int chapterNumber, Color brandColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(PhosphorIcons.circle(PhosphorIconsStyle.fill), size: 10, color: brandColor),
      title: Text("Chapter $chapterNumber", style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: const Text("7/21/25", style: TextStyle(fontSize: 12, color: Colors.black54)),
      trailing: IconButton(
        icon: Icon(PhosphorIcons.downloadSimple(), color: Colors.black38),
        onPressed: () {},
      ),
    );
  }
}
