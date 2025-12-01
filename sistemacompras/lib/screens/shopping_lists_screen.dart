import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../services/api_service.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listas de Compras'),
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
                      await ApiService().createShoppingList(nameController.text, '');
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

  @override
  void initState() {
    super.initState();
    _listsFuture = ApiService().fetchShoppingLists();
  }

  Future<void> _refreshLists() async {
    final future = ApiService().fetchShoppingLists();
    setState(() {
      _listsFuture = future;
    });
    await future;
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
                  await ApiService().deleteShoppingList(list.id ?? '');
                  await _refreshLists();
                },
                child: ListTile(
                  title: Text(list.name),
                  subtitle: Text('Atualizada em: ' + list.updatedAt.toString()),
                  trailing: Icon(list.isSynced ? Icons.cloud_done : Icons.cloud_off),
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
