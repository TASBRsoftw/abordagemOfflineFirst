import '../models/shopping_list.dart';
import 'database_service.dart';

class SyncService {
  // Sincroniza dados pendentes na fila
  Future<void> syncPending() async {
    // Buscar registros na sync_queue e enviar para API
    // Implementar lógica LWW (Last-Write-Wins)
  }

  // Lógica de resolução de conflitos LWW
  bool isLocalWinner(DateTime local, DateTime remote) {
    return local.isAfter(remote);
  }
}
