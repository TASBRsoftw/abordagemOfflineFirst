import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../services/api_service.dart';
import 'shopping_list_detail_screen.dart';
import '../widgets/connectivity_status.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ShoppingListsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listas de Compras'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ConnectivityStatus(),
          ),
        ],
      ),
      body: ShoppingListsBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameController = TextEditingController();
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Nova Lista'),
              content: TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: 'Nome da lista'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      // Cria lista localmente
                      final newList = ShoppingList(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        description: '',
                        updatedAt: DateTime.now(),
                        createdAt: DateTime.now(),
                        products: const [],
                      );
                      await DatabaseService.insertShoppingList(newList);
                      // Adiciona à sync queue
                      await DatabaseService.addToSyncQueue('shopping_lists', newList.id ?? '', 'CREATE', newList.toMap());
                      Navigator.pop(context);
                      final state = ShoppingListsBody.of(context);
                      await state?._refreshLists();
                    }
                  },
                  child: Text('Criar'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class ShoppingListsBody extends StatefulWidget {
  const ShoppingListsBody({Key? key}) : super(key: key);

  @override
  State<ShoppingListsBody> createState() => _ShoppingListsBodyState();

  static _ShoppingListsBodyState? of(BuildContext context) {
    final state = context.findAncestorStateOfType<_ShoppingListsBodyState>();
    return state;
  }
}

class _ShoppingListsBodyState extends State<ShoppingListsBody> {
  late Future<List<ShoppingList>> _listsFuture;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadListsLocalFirst();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
    if (_isOnline) {
      await _syncAndReload();
    }
  }

  Future<void> _loadListsLocalFirst() async {
    final lists = await DatabaseService.getAllShoppingLists();
    setState(() {
      _listsFuture = Future.value(lists);
    });
  }

  Future<void> _syncAndReload() async {
    await SyncService(ApiService()).syncPending();
    final lists = await DatabaseService.getAllShoppingLists();
    setState(() {
      _listsFuture = Future.value(lists);
    });
  }

  Future<void> _refreshLists() async {
    await _loadListsLocalFirst();
    await _initConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ShoppingList>>(
      future: _listsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar listas'));
        }
        final lists = snapshot.data ?? [];
        if (lists.isEmpty) {
          return Center(child: Text('Nenhuma lista encontrada'));
        }
        return RefreshIndicator(
          onRefresh: _refreshLists,
          child: ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Dismissible(
                key: Key(list.id ?? ''),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Excluir Lista'),
                      content: Text('Deseja realmente excluir esta lista?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  // Remove localmente
                  await DatabaseService.deleteShoppingList(int.tryParse(list.id ?? '') ?? 0);
                  // Adiciona à sync queue
                  await DatabaseService.addToSyncQueue('shopping_lists', list.id ?? '', 'DELETE', list.toMap());
                  await _refreshLists();
                },
                child: ListTile(
                  title: Text(list.name),
                  subtitle: Text('Atualizada em: ' + list.updatedAt.toString()),
                  // trailing: Icon(list.isSynced ? Icons.cloud_done : Icons.cloud_off),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShoppingListDetailScreen(list: list),
                      ),
                    );
                    await _refreshLists();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
