class SourcePreference {
  final bool enabled;
  final bool pinned;

  SourcePreference({this.enabled = true, this.pinned = false});

  factory SourcePreference.fromJson(Map<String, dynamic> json) {
    return SourcePreference(
      enabled: json['enabled'] ?? true,
      pinned: json['pinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'pinned': pinned,
    };
  }
}

class UserPreferences {
  final String libraryDisplayStyle; // "grid" or "list"
  final int libraryItemsPerRow;
  final bool overlayShowDownloaded;
  final bool overlayShowUnread;
  final bool overlayShowLanguage;
  final bool tabsShowCategories;
  final bool tabsShowItemCount;
  final String categoriesDisplayMode; // "compact grid", "cover grid", "comfortable grid", "list"
  final Map<String, SourcePreference> sourcePreferences;

  UserPreferences({
    this.libraryDisplayStyle = 'grid',
    this.libraryItemsPerRow = 3,
    this.overlayShowDownloaded = true,
    this.overlayShowUnread = true,
    this.overlayShowLanguage = true,
    this.tabsShowCategories = true,
    this.tabsShowItemCount = true,
    this.categoriesDisplayMode = 'comfortable grid',
    this.sourcePreferences = const {},
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> sourcePrefsJson = json['source_preferences'] ?? {};
    final Map<String, SourcePreference> sourcePrefs = {};
    
    sourcePrefsJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        sourcePrefs[key] = SourcePreference.fromJson(value);
      }
    });

    return UserPreferences(
      libraryDisplayStyle: json['library_display_style'] ?? 'grid',
      libraryItemsPerRow: json['library_items_per_row'] ?? 3,
      overlayShowDownloaded: json['overlay_show_downloaded'] ?? true,
      overlayShowUnread: json['overlay_show_unread'] ?? true,
      overlayShowLanguage: json['overlay_show_language'] ?? true,
      tabsShowCategories: json['tabs_show_categories'] ?? true,
      tabsShowItemCount: json['tabs_show_item_count'] ?? true,
      categoriesDisplayMode: json['categories_display_mode'] ?? 'comfortable grid',
      sourcePreferences: sourcePrefs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'library_display_style': libraryDisplayStyle,
      'library_items_per_row': libraryItemsPerRow,
      'overlay_show_downloaded': overlayShowDownloaded,
      'overlay_show_unread': overlayShowUnread,
      'overlay_show_language': overlayShowLanguage,
      'tabs_show_categories': tabsShowCategories,
      'tabs_show_item_count': tabsShowItemCount,
      'categories_display_mode': categoriesDisplayMode,
      'source_preferences': sourcePreferences.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  UserPreferences copyWith({
    String? libraryDisplayStyle,
    int? libraryItemsPerRow,
    bool? overlayShowDownloaded,
    bool? overlayShowUnread,
    bool? overlayShowLanguage,
    bool? tabsShowCategories,
    bool? tabsShowItemCount,
    String? categoriesDisplayMode,
    Map<String, SourcePreference>? sourcePreferences,
  }) {
    return UserPreferences(
      libraryDisplayStyle: libraryDisplayStyle ?? this.libraryDisplayStyle,
      libraryItemsPerRow: libraryItemsPerRow ?? this.libraryItemsPerRow,
      overlayShowDownloaded: overlayShowDownloaded ?? this.overlayShowDownloaded,
      overlayShowUnread: overlayShowUnread ?? this.overlayShowUnread,
      overlayShowLanguage: overlayShowLanguage ?? this.overlayShowLanguage,
      tabsShowCategories: tabsShowCategories ?? this.tabsShowCategories,
      tabsShowItemCount: tabsShowItemCount ?? this.tabsShowItemCount,
      categoriesDisplayMode: categoriesDisplayMode ?? this.categoriesDisplayMode,
      sourcePreferences: sourcePreferences ?? this.sourcePreferences,
    );
  }
}
