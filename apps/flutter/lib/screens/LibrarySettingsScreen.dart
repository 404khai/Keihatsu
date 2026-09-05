import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../components/CustomBackButton.dart';
import '../providers/offline_library_provider.dart';
import '../models/local_models.dart';

class LibrarySettingsScreen extends StatelessWidget {
  const LibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final offlineLibrary = Provider.of<OfflineLibraryProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Library Settings',
          style: GoogleFonts.hennyPenny(
            textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader(textColor, "Categories"),
          const SizedBox(height: 10),
          if (offlineLibrary.categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No categories created yet.",
                  style: TextStyle(color: textColor.withOpacity(0.5)),
                ),
              ),
            )
          else
            ...offlineLibrary.categories.map((category) => _buildCategoryTile(
              context,
              category: category,
              textColor: textColor,
              brandColor: brandColor,
              offlineLibrary: offlineLibrary,
            )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(context, offlineLibrary, brandColor, bgColor, textColor),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Category", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(Color textColor, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.dynaPuff(
          textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      BuildContext context, {
        required LocalCategory category,
        required Color textColor,
        required Color brandColor,
        required OfflineLibraryProvider offlineLibrary,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(
          category.name,
          style: GoogleFonts.delius(
            textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: textColor.withOpacity(0.6), size: 20),
              onPressed: () => _showEditCategoryDialog(context, category, offlineLibrary, brandColor, textColor),
            ),
            IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.redAccent.withOpacity(0.8), size: 20),
              onPressed: () => _showDeleteConfirmDialog(context, category, offlineLibrary, textColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, OfflineLibraryProvider offlineLibrary, Color brandColor, Color bgColor, Color textColor) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("New Category", style: GoogleFonts.denkOne(color: textColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "Category name",
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: brandColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await offlineLibrary.createCategory(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text("Create", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, LocalCategory category, OfflineLibraryProvider offlineLibrary, Color brandColor, Color textColor) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text("Edit Category", style: GoogleFonts.denkOne(color: textColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: brandColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await offlineLibrary.updateCategory(category.id, controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text("Save", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, LocalCategory category, OfflineLibraryProvider offlineLibrary, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text("Delete Category", style: GoogleFonts.denkOne(color: textColor)),
        content: Text("Are you sure you want to delete '${category.name}'?", style: TextStyle(color: textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await offlineLibrary.deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
