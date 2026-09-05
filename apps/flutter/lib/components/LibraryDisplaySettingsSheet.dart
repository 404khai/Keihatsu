import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/offline_library_provider.dart';
import '../providers/auth_provider.dart';
import '../theme_provider.dart';

class LibraryDisplaySettingsSheet extends StatelessWidget {
  const LibraryDisplaySettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brandColor = themeProvider.brandColor;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              indicatorColor: brandColor,
              labelColor: brandColor,
              unselectedLabelColor: textColor.withOpacity(0.6),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.denkOne(fontSize: 16),
              tabs: const [
                Tab(text: "Filter"),
                Tab(text: "Sort"),
                Tab(text: "Display"),
              ],
            ),
            const Divider(height: 1, thickness: 0.5),
            SizedBox(
              height: 450,
              child: TabBarView(
                children: [
                  _buildFilterTab(brandColor, textColor),
                  _buildSortTab(brandColor, textColor),
                  _buildDisplayTab(brandColor, textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(Color brandColor, Color textColor) {
    return Consumer<OfflineLibraryProvider>(
      builder: (context, provider, _) {
        final state = provider.filterState;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildToggle(
                "Downloaded",
                state.filterDownloaded,
                brandColor,
                textColor,
                    (val) {
                  provider.updateFilters(state.copyWith(filterDownloaded: val));
                },
              ),
              _buildToggle(
                "Unread",
                state.filterUnread,
                brandColor,
                textColor,
                    (val) {
                  provider.updateFilters(state.copyWith(filterUnread: val));
                },
              ),
              _buildToggle(
                "Started",
                state.filterStarted,
                brandColor,
                textColor,
                    (val) {
                  provider.updateFilters(state.copyWith(filterStarted: val));
                },
              ),
              _buildToggle(
                "Bookmarked",
                state.filterBookmarked,
                brandColor,
                textColor,
                    (val) {
                  provider.updateFilters(state.copyWith(filterBookmarked: val));
                },
              ),
              _buildToggle(
                "Completed",
                state.filterCompleted,
                brandColor,
                textColor,
                    (val) {
                  provider.updateFilters(state.copyWith(filterCompleted: val));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTab(Color brandColor, Color textColor) {
    return Consumer<OfflineLibraryProvider>(
      builder: (context, provider, _) {
        final state = provider.filterState;
        final sortOptions = {
          'alphabetical': 'Alphabetical',
          'last_read': 'Last read',
          'last_updated': 'Last updated',
          'unread_count': 'Unread count',
          'total_chapters': 'Total chapters',
          'date_added': 'Date added',
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ...sortOptions.entries.map(
                    (entry) => RadioListTile<String>(
                  title: Text(entry.value, style: TextStyle(color: textColor)),
                  value: entry.key,
                  groupValue: state.sortBy,
                  activeColor: brandColor,
                  onChanged: (val) {
                    if (val != null) {
                      // Set default order based on sort type
                      String newOrder = state.order;
                      if (val == 'alphabetical') {
                        newOrder = 'asc';
                      } else {
                        newOrder = 'desc';
                      }
                      provider.updateFilters(state.copyWith(sortBy: val, order: newOrder));
                    }
                  },
                ),
              ),
              const Divider(),
              _buildToggle(
                "Ascending",
                state.order == 'asc',
                brandColor,
                textColor,
                    (val) {
                  provider.updateFilters(
                    state.copyWith(order: val ? 'asc' : 'desc'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayTab(Color brandColor, Color textColor) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final prefs = authProvider.preferences;
        if (prefs == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(textColor, "Display mode"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    "Compact grid",
                    "compact grid",
                    brandColor,
                    textColor,
                    prefs.categoriesDisplayMode == 'compact grid',
                        (val) {
                      authProvider.updatePreferences({
                        'categories_display_mode': val,
                      });
                    },
                  ),
                  _buildChoiceChip(
                    "Comfortable grid",
                    "comfortable grid",
                    brandColor,
                    textColor,
                    prefs.categoriesDisplayMode == 'comfortable grid',
                        (val) {
                      authProvider.updatePreferences({
                        'categories_display_mode': val,
                      });
                    },
                  ),
                  _buildChoiceChip(
                    "Cover grid",
                    "cover grid",
                    brandColor,
                    textColor,
                    prefs.categoriesDisplayMode == 'cover grid',
                        (val) {
                      authProvider.updatePreferences({
                        'categories_display_mode': val,
                      });
                    },
                  ),
                  _buildChoiceChip(
                    "List",
                    "list",
                    brandColor,
                    textColor,
                    prefs.categoriesDisplayMode == 'list',
                        (val) {
                      authProvider.updatePreferences({
                        'categories_display_mode': val,
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(textColor, "Items per row"),
                  Text(
                    "${prefs.libraryItemsPerRow}",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: brandColor,
                  inactiveTrackColor: brandColor.withOpacity(0.2),
                  thumbColor: brandColor,
                  overlayColor: brandColor.withOpacity(0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: prefs.libraryItemsPerRow.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  onChanged: (val) {
                    authProvider.updatePreferences({
                      'library_items_per_row': val.toInt(),
                    });
                  },
                ),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle(textColor, "Overlay"),
              _buildToggle(
                "Downloaded chapters",
                prefs.overlayShowDownloaded,
                brandColor,
                textColor,
                    (val) {
                  authProvider.updatePreferences({
                    'overlay_show_downloaded': val,
                  });
                },
              ),
              _buildToggle(
                "Unread chapters",
                prefs.overlayShowUnread,
                brandColor,
                textColor,
                    (val) {
                  authProvider.updatePreferences({'overlay_show_unread': val});
                },
              ),
              _buildToggle(
                "Language",
                prefs.overlayShowLanguage,
                brandColor,
                textColor,
                    (val) {
                  authProvider.updatePreferences({
                    'overlay_show_language': val,
                  });
                },
              ),
              const SizedBox(height: 25),
              _buildSectionTitle(textColor, "Tabs"),
              _buildToggle(
                "Show category tabs",
                prefs.tabsShowCategories,
                brandColor,
                textColor,
                    (val) {
                  authProvider.updatePreferences({'tabs_show_categories': val});
                },
              ),
              _buildToggle(
                "Show number of items",
                prefs.tabsShowItemCount,
                brandColor,
                textColor,
                    (val) {
                  authProvider.updatePreferences({'tabs_show_item_count': val});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(Color textColor, String title) {
    return Text(
      title,
      style: GoogleFonts.dynaPuff(
        textStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
      String label,
      String value,
      Color brandColor,
      Color textColor,
      bool isSelected,
      Function(String) onSelected,
      ) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? brandColor : textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(
      String label,
      bool value,
      Color brandColor,
      Color textColor,
      Function(bool) onChanged,
      ) {
    return ListTile(
      title: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
      contentPadding: EdgeInsets.zero,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: brandColor,
        activeTrackColor: brandColor.withOpacity(0.5),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
