import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_models.dart';
import '../models/manga.dart';
import '../services/library_repository.dart';
import '../services/local_scope.dart';
import '../services/manga_repository.dart';

class LibraryFilterState {
  bool filterDownloaded = false;
  bool filterUnread = false;
  bool filterStarted = false;
  bool filterBookmarked = false;
  bool filterCompleted = false;
  String? search;
  String sortBy = 'last_read';
  String order = 'desc';

  LibraryFilterState();

  LibraryFilterState copyWith({
    bool? filterDownloaded,
    bool? filterUnread,
    bool? filterStarted,
    bool? filterBookmarked,
    bool? filterCompleted,
    String? search,
    String? sortBy,
    String? order,
  }) {
    final newState = LibraryFilterState();
    newState.filterDownloaded = filterDownloaded ?? this.filterDownloaded;
    newState.filterUnread = filterUnread ?? this.filterUnread;
    newState.filterStarted = filterStarted ?? this.filterStarted;
    newState.filterBookmarked = filterBookmarked ?? this.filterBookmarked;
    newState.filterCompleted = filterCompleted ?? this.filterCompleted;
    newState.search = search ?? this.search;
    newState.sortBy = sortBy ?? this.sortBy;
    newState.order = order ?? this.order;
    return newState;
  }
}

class OfflineLibraryProvider with ChangeNotifier {
  final LibraryRepository libraryRepo;
  final MangaRepository mangaRepo;
  final String? Function() getToken;
  String _currentUserId = guestLocalScopeUserId;

  List<LocalLibraryEntry> _allLibrary = [];
  List<LocalCategory> _allCategories = [];
  List<LocalCategoryAssignment> _allCategoryAssignments = [];
  List<LocalLibraryEntry> _library = [];
  List<LocalCategory> _categories = [];
  List<LocalCategoryAssignment> _categoryAssignments = [];
  bool _isLoading = false;
  LibraryFilterState _filterState = LibraryFilterState();

  OfflineLibraryProvider({
    required this.libraryRepo,
    required this.mangaRepo,
    required this.getToken,
  }) {
    _init();
  }

  void _init() {
    libraryRepo.watchLibrary().listen((entries) {
      _allLibrary = entries;
      _applyScope();
    });

    libraryRepo.watchCategoryAssignments().listen((assignments) {
      _allCategoryAssignments = assignments;
      _applyScope();
    });

    libraryRepo.watchCategories().listen((categories) {
      _allCategories = categories;
      _applyScope();
    });

    _loadSortPreferences();
  }

  void bindUserScope(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _applyScope();
  }

  void _applyScope() {
    _library = _allLibrary
        .where((entry) => entry.ownerUserId == _currentUserId)
        .toList();
    _categories = _allCategories
        .where((category) => category.ownerUserId == _currentUserId)
        .toList();
    _categoryAssignments = _allCategoryAssignments
        .where((assignment) => assignment.ownerUserId == _currentUserId)
        .toList();
    notifyListeners();
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sortBy = prefs.getString('library_sort_by') ?? 'last_read';
    final order = prefs.getString('library_sort_order') ?? 'desc';

    _filterState.sortBy = sortBy;
    _filterState.order = order;
    notifyListeners();
    refresh(true);
  }

  List<LocalLibraryEntry> get library => _library;
  List<LocalCategory> get categories => _categories;
  List<LocalCategoryAssignment> get categoryAssignments => _categoryAssignments;
  bool get isLoading => _isLoading;
  LibraryFilterState get filterState => _filterState;

  void updateFilters(LibraryFilterState newState) {
    _filterState = newState;
    _saveSortPreferences(newState.sortBy, newState.order);
    notifyListeners();
    refresh(true);
  }

  Future<void> _saveSortPreferences(String sortBy, String order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('library_sort_by', sortBy);
    await prefs.setString('library_sort_order', order);
  }

  Future<void> refresh(bool force) async {
    final token = getToken();
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    await libraryRepo.refreshLibrary(
      token: token,
      filterDownloaded: _filterState.filterDownloaded,
      filterUnread: _filterState.filterUnread,
      filterStarted: _filterState.filterStarted,
      filterBookmarked: _filterState.filterBookmarked,
      filterCompleted: _filterState.filterCompleted,
      sortBy: _filterState.sortBy,
      order: _filterState.order,
      search: _filterState.search,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLibrary(Manga manga, {List<String>? categories}) async {
    final token = getToken();
    if (token == null) return;

    final inLibrary = _library.any(
          (e) => e.mangaId == manga.id && e.sourceId == manga.sourceId,
    );

    if (inLibrary) {
      await libraryRepo.removeFromLibrary(token, manga.id, manga.sourceId);
    } else {
      await libraryRepo.addToLibrary(token, manga, categories: categories);
    }
  }

  Future<void> updateEntry(String mangaId, Map<String, dynamic> updates) async {
    final token = getToken();
    if (token == null) return;
    await libraryRepo.updateLibraryEntry(token, mangaId, updates);
  }

  Future<void> toggleCategoryAssignment(
      String mangaId,
      String sourceId,
      int localCategoryId,
      ) async {
    await libraryRepo.toggleCategoryAssignment(
      mangaId,
      sourceId,
      localCategoryId,
    );
  }

  bool isInLibrary(String mangaId, String sourceId) {
    return _library.any((e) => e.mangaId == mangaId && e.sourceId == sourceId);
  }

  bool isMangaInCategory(String mangaId, String sourceId, int localCategoryId) {
    return _categoryAssignments.any(
          (a) =>
      a.mangaId == mangaId &&
          a.sourceId == sourceId &&
          a.localCategoryId == localCategoryId,
    );
  }

  // --- Category operations ---

  List<LocalLibraryEntry> getLibraryForCategory(String categoryName) {
    List<LocalLibraryEntry> filtered;

    if (categoryName == "Default") {
      // Default = Items with NO category assignments
      filtered = _library.where((entry) {
        return !_categoryAssignments.any(
              (assignment) =>
          assignment.mangaId == entry.mangaId &&
              assignment.sourceId == entry.sourceId,
        );
      }).toList();
    } else {
      // Find the category ID
      final category = _categories.firstWhere(
            (c) => c.name == categoryName,
        orElse: () => LocalCategory()..id = -1,
      );

      if (category.id == -1) return [];

      filtered = _library.where((entry) {
        return _categoryAssignments.any(
              (assignment) =>
          assignment.mangaId == entry.mangaId &&
              assignment.sourceId == entry.sourceId &&
              assignment.localCategoryId == category.id,
        );
      }).toList();
    }

    // Apply local filters
    if (_filterState.filterDownloaded) {
      filtered = filtered.where((e) => e.downloadedCount > 0).toList();
    }
    if (_filterState.filterUnread) {
      filtered = filtered.where((e) => e.unreadCount > 0).toList();
    }
    if (_filterState.filterStarted) {
      filtered = filtered.where((e) => e.isStarted).toList();
    }
    if (_filterState.filterBookmarked) {
      filtered = filtered.where((e) => e.isBookmarked).toList();
    }
    if (_filterState.filterCompleted) {
      filtered = filtered.where((e) => e.isCompleted).toList();
    }
    if (_filterState.search != null && _filterState.search!.isNotEmpty) {
      final query = _filterState.search!.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
        e.title.toLowerCase().contains(query) ||
            (e.author?.toLowerCase().contains(query) ?? false),
      )
          .toList();
    }

    return _sortEntries(filtered);
  }

  List<LocalLibraryEntry> _sortEntries(List<LocalLibraryEntry> entries) {
    if (entries.isEmpty) return entries;

    final isAsc = _filterState.order == 'asc';
    final sortBy = _filterState.sortBy;

    entries.sort((a, b) {
      int cmp = 0;
      switch (sortBy) {
        case 'alphabetical':
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 'last_read':
          final aDate = a.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aDate.compareTo(bDate);
          break;
        case 'last_updated':
          final aDate =
              a.lastUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.lastUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aDate.compareTo(bDate);
          break;
        case 'unread_count':
          cmp = a.unreadCount.compareTo(b.unreadCount);
          break;
        case 'total_chapters':
          cmp = a.totalChapters.compareTo(b.totalChapters);
          break;
        case 'date_added':
          final aDate = a.dateAddedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.dateAddedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aDate.compareTo(bDate);
          break;
        default:
          cmp = 0;
      }
      return isAsc ? cmp : -cmp;
    });

    return entries;
  }

  Future<void> createCategory(String name) async {
    await libraryRepo.createCategory(name);
  }

  Future<void> updateCategory(int id, String name) async {
    await libraryRepo.updateCategory(id, name);
  }

  Future<void> deleteCategory(int id) async {
    await libraryRepo.deleteCategory(id);
  }

  // Chapter Download logic
  final Set<String> _downloadingIds = {};
  Set<String> get downloadingIds => _downloadingIds;

  Future<void> downloadChapter(
      String sourceId,
      String mangaId,
      String chapterId,
      ) async {
    final token = getToken();
    if (token == null) return;

    _downloadingIds.add(chapterId);
    notifyListeners();

    try {
      await mangaRepo.downloadChapter(token, sourceId, mangaId, chapterId);
    } finally {
      _downloadingIds.remove(chapterId);
      notifyListeners();
    }
  }
}
