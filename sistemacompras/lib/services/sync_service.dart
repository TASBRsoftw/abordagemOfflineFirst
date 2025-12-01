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
    final queue = await DatabaseService.getSyncQueue();
    print('[SyncService] Sync queue length: \'${queue.length}\'');
    for (final item in queue) {
      print('[SyncService] Processing item: \'${item}\'');
      final table = item['tableName'];
      final action = item['action'];
      final payload = item['payload'] is String ? jsonDecode(item['payload']) : item['payload'];
      final updatedAt = DateTime.parse(item['updatedAt']);
      // Exemplo para produtos
      if (table == 'products') {
        final payloadCopy = Map<String, dynamic>.from(payload);
        final shoppingListId = payloadCopy.remove('shoppingListId') ?? '';
        final product = Product.fromMap(payloadCopy);
        if (action == 'CREATE') {
          print('[SyncService] CREATE product: listId=${shoppingListId}, product=${product.toMap()}');
          try {
            await apiService.addItemToList(shoppingListId, product);
          } catch (e) {
            print('[SyncService] Error adding product: $e');
          }
        } else if (action == 'UPDATE') {
          print('[SyncService] UPDATE product: id=${product.itemId}, product=${product.toMap()}');
          try {
            await apiService.updateProduct(product);
          } catch (e) {
            print('[SyncService] Error updating product: $e');
          }
        } else if (action == 'DELETE') {
          print('[SyncService] DELETE product: listId=${shoppingListId}, id=${product.itemId}');
          try {
            await apiService.deleteItemFromList(shoppingListId, product.itemId ?? '');
          } catch (e) {
            print('[SyncService] Error deleting product: $e');
          }
        }
      }
      // Remover da fila após sincronizar
      await DatabaseService.removeFromSyncQueue(item['id']);
      await DatabaseService.removeFromSyncQueue(item['id']);
    }
  }

  // Lógica de resolução de conflitos LWW
  bool isLocalWinner(DateTime local, DateTime remote) {
    return local.isAfter(remote);
  }
}
