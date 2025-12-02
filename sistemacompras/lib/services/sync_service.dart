import '../models/shopping_list.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'dart:convert';

class SyncService {
  final ApiService apiService;
  SyncService(this.apiService);

  // Sincroniza dados pendentes na fila
  Future<void> syncPending() async {
    print('[SyncService] Starting syncPending');
    // 1. Post local-only lists to backend
    final localLists = await DatabaseService.getAllShoppingLists();
    final backendLists = await apiService.fetchShoppingLists();
    final backendIds = backendLists.map((l) => l.id).toSet();
    final syncQueue = await DatabaseService.getSyncQueue();
    final localListIdsInQueue = syncQueue
      .where((item) => item['tableName'] == 'shopping_lists' && item['action'] == 'CREATE')
      .map((item) => item['rowId'] as String?)
      .toSet();
    for (final localList in localLists) {
      // Only post lists that are not yet synced and not already in the sync queue
      final db = await DatabaseService.database;
      final res = await db.query('shopping_lists', where: 'id = ?', whereArgs: [localList.id]);
      if (res.isNotEmpty && res.first['isSynced'] == 0 && localList.id != null && !backendIds.contains(localList.id) && !localListIdsInQueue.contains(localList.id)) {
        try {
          await apiService.createShoppingList(localList.name, localList.description);
          // Mark as synced
          await db.update('shopping_lists', {'isSynced': 1}, where: 'id = ?', whereArgs: [localList.id]);
          print('[SyncService] Posted local-only list to backend: ${localList.id}');
        } catch (e) {
          print('[SyncService] Error posting local-only list: $e');
        }
      }
    }

    // 2. Process sync queue (products and lists)
    final queue = await DatabaseService.getSyncQueue();
    print('[SyncService] Sync queue length: \'${queue.length}\'');
    for (final item in queue) {
      print('[SyncService] Processing item: \'${item}\'');
      final table = item['tableName'];
      final action = item['action'];
      final payload = item['payload'] is String ? jsonDecode(item['payload']) : item['payload'];
      final updatedAt = DateTime.parse(item['updatedAt']);

      bool letSyncQueueRemove = false;
      if (table == 'products') {
        final payloadCopy = Map<String, dynamic>.from(payload);
        final shoppingListId = payloadCopy.remove('shoppingListId') ?? '';
        final product = Product.fromMap(payloadCopy);
        if (action == 'CREATE') {
          try {
            await apiService.addItemToList(shoppingListId, product);
            letSyncQueueRemove = true;
          } catch (e) {
            print('[SyncService] Error adding product: $e');
          }
        } else if (action == 'UPDATE') {
          try {
            await apiService.updateProduct(product);
            letSyncQueueRemove = true;
          } catch (e) {
            print('[SyncService] Error updating product: $e');
          }
        } else if (action == 'DELETE') {
          try {
            await apiService.deleteItemFromList(shoppingListId, product.itemId ?? '');
            letSyncQueueRemove = true;
          } catch (e) {
            print('[SyncService] Error deleting product: $e');
          }
        }
      } else if (table == 'shopping_lists') {
        final list = ShoppingList.fromMap(payload);
        if (action == 'CREATE') {
          try {
            await apiService.createShoppingList(list.name, list.description);
            letSyncQueueRemove = true;
          } catch (e) {
            print('[SyncService] Error creating shopping list: $e');
          }
        } else if (action == 'UPDATE') {
          // Implement update logic if you have an updateShoppingList API method
        } else if (action == 'DELETE') {
          try {
            await apiService.deleteShoppingList(list.id ?? '');
            // Delete locally after successful backend deletion
            final db = await DatabaseService.database;
            await db.delete('shopping_lists', where: 'id = ?', whereArgs: [list.id]);
            letSyncQueueRemove = true;
          } catch (e) {
            print('[SyncService] Error deleting shopping list: $e');
          }
        }
      }
      if (letSyncQueueRemove) {
        await DatabaseService.removeFromSyncQueue(item['id']);
      }
    }

    // 3. Merge backend lists with local DB (update if exists, insert if not), and remove local-only lists if backend version exists
    try {
      final backendListsLatest = await apiService.fetchShoppingLists();
      final localListsLatest = await DatabaseService.getAllShoppingLists();
      final backendIdsLatest = backendListsLatest.map((l) => l.id).toSet();
      final localIdsLatest = localListsLatest.map((l) => l.id).toSet();
      for (final list in backendListsLatest) {
        if (localIdsLatest.contains(list.id)) {
          await DatabaseService.updateShoppingList(list);
        } else {
          await DatabaseService.insertShoppingList(list);
        }
      }
      // Remove local-only lists that now exist in backend
      final db = await DatabaseService.database;
      for (final localList in localListsLatest) {
        // Remove duplicate local-only copy if needed
        if (localList.id != null && backendIdsLatest.contains(localList.id)) {
          await db.delete('shopping_lists', where: 'id = ? AND isSynced = 0', whereArgs: [localList.id]);
        }
        // Remove any local lists that do NOT exist in backend anymore
        if (localList.id != null && !backendIdsLatest.contains(localList.id)) {
          await db.delete('shopping_lists', where: 'id = ?', whereArgs: [localList.id]);
        }
      }
    } catch (e) {
      print('[SyncService] Error merging backend lists: $e');
    }
  }

  // Lógica de resolução de conflitos LWW
  bool isLocalWinner(DateTime local, DateTime remote) {
    return local.isAfter(remote);
  }
}
