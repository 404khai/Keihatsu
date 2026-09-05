import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/library_api.dart';

class LibraryProvider with ChangeNotifier {
  final LibraryApi _libraryApi = LibraryApi();
  List<Manga> _library = [];
  List<String> _categories = ["Default"];
  bool _isLoading = false;
  String? _error;

  // Download state
  final Set<String> _downloadingChapterIds = {};
  final Set<String> _completedChapterIds = {};

  List<Manga> get library => _library;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get downloadingChapterIds => _downloadingChapterIds;
  Set<String> get completedChapterIds => _completedChapterIds;

  // Fetch library from backend
  Future<void> fetchLibrary(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _libraryApi.getLibrary(token: token);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        _library = decoded.map((item) => Manga.fromJson(item)).toList();
      } else {
        _error = "Failed to load library: ${response.statusCode}";
      }

      // Also fetch categories
      await fetchCategories(token);
    } catch (e) {
      _error = "Connection error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories(String token) async {
    try {
      final response = await _libraryApi.getCategories(token);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        _categories = ["Default", ...decoded.map((cat) => cat['name'] as String)];
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> addCategory(String token, String name) async {
    try {
      final response = await _libraryApi.createCategory(token, name);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _categories.add(name);
        notifyListeners();
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to create category');
      }
    } catch (e) {
      debugPrint("Error adding category: $e");
      rethrow;
    }
  }

  Future<void> downloadChapter(String token, String sourceId, String mangaId, String chapterId) async {
    if (_downloadingChapterIds.contains(chapterId) || _completedChapterIds.contains(chapterId)) {
      return;
    }

    _downloadingChapterIds.add(chapterId);
    notifyListeners();

    try {
      final response = await _libraryApi.downloadChapter(
        token: token,
        sourceId: sourceId,
        mangaId: mangaId,
        chapterId: chapterId,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _completedChapterIds.add(chapterId);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to download chapter');
      }
    } finally {
      _downloadingChapterIds.remove(chapterId);
      notifyListeners();
    }
  }

  // Add/Remove from library (Syncs with backend)
  Future<void> toggleLibrary(String token, Manga manga, {List<String>? selectedCategories}) async {
    final existingIndex = _library.indexWhere((m) => m.id == manga.id && m.sourceId == manga.sourceId);
    
    try {
      if (existingIndex >= 0) {
        // Remove from remote
        final response = await _libraryApi.deleteMangaFromLibrary(token, manga.id);
        if (response.statusCode == 200 || response.statusCode == 204) {
          _library.removeAt(existingIndex);
        }
      } else {
        // Add to remote
        final response = await _libraryApi.addMangaToLibrary(
          token, 
          manga.toJson(), 
          categories: selectedCategories
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          _library.add(manga);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Library sync error: $e");
      rethrow;
    }
  }

  bool isInLibrary(String mangaId, String sourceId) {
    return _library.any((m) => m.id == mangaId && m.sourceId == sourceId);
  }
}
