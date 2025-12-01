import '../models/shopping_list.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService dbService;
  final ApiService apiService;
  SyncService(this.dbService, this.apiService);

  // Sincroniza dados pendentes na fila
  Future<void> syncPending() async {
    final queue = await dbService.getSyncQueue();
    for (final item in queue) {
      final table = item['tableName'];
      final action = item['action'];
      final payload = item['payload'];
      final updatedAt = DateTime.parse(item['updatedAt']);
      // Exemplo para produtos
      if (table == 'products') {
        // Buscar versão do servidor
        final serverProduct = await apiService.fetchProductById(item['rowId']);
        if (serverProduct != null) {
          final serverUpdatedAt = DateTime.parse(serverProduct['updatedAt']);
          if (isLocalWinner(updatedAt, serverUpdatedAt)) {
            // Local é mais recente: enviar para servidor
            await apiService.updateProduct(Product.fromMap(payload));
          } else {
            // Servidor é mais recente: sobrescrever local
            await dbService.updateProduct(
              Product.fromMap(serverProduct),
              item['rowId'],
            );
          }
        } else {
          // Produto não existe no servidor: criar
          await apiService.addProduct(Product.fromMap(payload));
        }
      }
      // Remover da fila após sincronizar
      await dbService.removeFromSyncQueue(item['id']);
    }
  }

  // Lógica de resolução de conflitos LWW
  bool isLocalWinner(DateTime local, DateTime remote) {
    return local.isAfter(remote);
  }
}
