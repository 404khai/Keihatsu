import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_models.dart';
import 'library_api.dart';
import 'sync_manager.dart';

class CategoriesRepository {
  final Isar isar;
  final LibraryApi api;
  final SyncManager syncManager;
  final String Function() getCurrentUserId;

  CategoriesRepository({
    required this.isar,
    required this.api,
    required this.syncManager,
    required this.getCurrentUserId,
  });

  String get _currentUserId => getCurrentUserId();

  String _assignmentScopedKey(
      String mangaId,
      String sourceId,
      int localCategoryId,
      String ownerUserId,
      ) {
    return '$ownerUserId::$sourceId::$mangaId::$localCategoryId';
  }

  Stream<List<LocalCategory>> watchCategories() {
    return isar.collection<LocalCategory>().where().sortByName().watch(fireImmediately: true);
  }

  Future<List<LocalCategory>> getCategories({bool forceRefresh = false, String? token, bool includeCount = false}) async {
    if (forceRefresh && token != null) {
      await refreshCategories(token, includeCount: includeCount);
    }
    return await isar
        .collection<LocalCategory>()
        .filter()
        .ownerUserIdEqualTo(_currentUserId)
        .sortByName()
        .findAll();
  }

  Future<void> refreshCategories(String token, {bool includeCount = false}) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final response = await api.getCategories(token, includeCount: includeCount);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await isar.writeTxn(() async {
          for (var item in data) {
            final serverId = item['id'];
            var localCat = await isar.collection<LocalCategory>().filter()
                .serverIdEqualTo(serverId)
                .ownerUserIdEqualTo(_currentUserId)
                .findFirst() ?? LocalCategory();

            localCat.serverId = serverId;
            localCat.name = item['name'];
            localCat.ownerUserId = _currentUserId;
            localCat.isSynced = true;
            await isar.collection<LocalCategory>().put(localCat);
          }
        });
      }
    } catch (e) {
      print('Error refreshing categories: $e');
    }
  }

  Future<void> createCategory(String name) async {
    final category = LocalCategory()
      ..name = name
      ..ownerUserId = _currentUserId
      ..isSynced = false;
    await isar.writeTxn(() async {
      await isar.collection<LocalCategory>().put(category);
    });

    await syncManager.addToQueue('CREATE_CATEGORY', {
      'name': name,
      'localId': category.id,
    });
  }

  Future<void> renameCategory(String id, String name) async {
    final category = await isar.collection<LocalCategory>().filter().serverIdEqualTo(id).ownerUserIdEqualTo(_currentUserId).findFirst();
    if (category != null) {
      category.name = name;
      category.isSynced = false;
      await isar.writeTxn(() => isar.collection<LocalCategory>().put(category));
    }
    await syncManager.addToQueue('UPDATE_CATEGORY', {'id': id, 'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await isar.writeTxn(() async {
      await isar.collection<LocalCategory>().filter().serverIdEqualTo(id).ownerUserIdEqualTo(_currentUserId).deleteAll();
    });
    await syncManager.addToQueue('DELETE_CATEGORY', {'id': id});
  }

  Future<void> assignMangaToCategory({required String mangaId, required String sourceId, required String categoryId}) async {
    // Replaces categories as per API: categories.set = [{ id: categoryId }]
    await isar.writeTxn(() async {
      // Clear existing assignments for this manga
      await isar.collection<LocalCategoryAssignment>().filter()
          .mangaIdEqualTo(mangaId)
          .sourceIdEqualTo(sourceId)
          .ownerUserIdEqualTo(_currentUserId)
          .deleteAll();

      final localCat = await isar.collection<LocalCategory>().filter().serverIdEqualTo(categoryId).ownerUserIdEqualTo(_currentUserId).findFirst();
      if (localCat != null) {
        final assignment = LocalCategoryAssignment()
          ..mangaId = mangaId
          ..sourceId = sourceId
          ..ownerUserId = _currentUserId
          ..scopedAssignmentKey = _assignmentScopedKey(
            mangaId,
            sourceId,
            localCat.id,
            _currentUserId,
          )
          ..localCategoryId = localCat.id;
        await isar.collection<LocalCategoryAssignment>().put(assignment);
      }
    });

    await syncManager.addToQueue('ASSIGN_CATEGORY', {
      'mangaId': mangaId,
      'categoryId': categoryId,
    });
  }
}
