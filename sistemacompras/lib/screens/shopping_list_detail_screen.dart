import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/shopping_list.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList list;
  ShoppingListDetailScreen({required this.list});

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  late ShoppingList _list;
  late List<bool> _selected;
  late List<double> _quantities;

  @override
  void initState() {
    super.initState();
    _list = widget.list;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseService.getProductsForList(_list.id ?? '');
    setState(() {
      _list.products = products;
      _selected = List.generate(_list.products.length, (i) => false);
      _quantities = _list.products.map((p) => p.quantity).toList();
    });
  }

  double get checkoutTotal {
    double total = 0.0;
    for (int i = 0; i < _list.products.length; i++) {
      if (_selected[i]) {
        total += _quantities[i] * _list.products[i].estimatedPrice;
      }
    }
    return total;
  }

  Future<void> _addProductDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Nome do produto'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(hintText: 'Valor unitário'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(hintText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final quantity = double.tryParse(quantityController.text.trim()) ?? 1.0;
              if (name.isNotEmpty && price > 0) {
                // Adicionar produto localmente e registrar na fila de sincronização
                final newProduct = Product(
                  itemId: DateTime.now().millisecondsSinceEpoch.toString(),
                  itemName: name,
                  quantity: quantity,
                  unit: 'un',
                  estimatedPrice: price,
                  purchased: false,
                  notes: '',
                  addedAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isSynced: false,
                );
                // Persistir localmente
                // (Ajuste shoppingListId conforme seu modelo)
                await DatabaseService.insertProduct(newProduct, _list.id ?? '');
                // Registrar na fila de sincronização
                await DatabaseService.addToSyncQueue('products', newProduct.itemId ?? '', 'CREATE', {
                  ...newProduct.toMap(),
                  'shoppingListId': _list.id ?? '',
                });
                print('[UI] Sync queue before sync: ' + (await DatabaseService.getSyncQueue()).toString());
                await SyncService(ApiService()).syncPending();
                await _loadProducts();
                Navigator.pop(context);
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_list.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _list.products.length,
              itemBuilder: (context, index) {
                final product = _list.products[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _selected[index],
                          onChanged: (val) async {
                            setState(() {
                              _selected[index] = val ?? false;
                            });
                            // Edição offline: atualizar quantidade localmente e registrar na fila
                            _list.products[index].quantity = _quantities[index];
                            _list.products[index].isSynced = false;
                            await DatabaseService.updateProduct(_list.products[index], _list.products[index].itemId ?? '');
                            await DatabaseService.addToSyncQueue('products', _list.products[index].itemId ?? '', 'UPDATE', {
                              ..._list.products[index].toMap(),
                              'shoppingListId': _list.id ?? '',
                            });
                          },
                        ),
                        Icon(
                          product.isSynced ? Icons.cloud_done : Icons.cloud_off,
                          color: product.isSynced ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                    title: Text(product.itemName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Valor unitário: R\$ ${product.estimatedPrice.toStringAsFixed(2)}'),
                        Row(
                          children: [
                            Text('Qtd:'),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              child: TextFormField(
                                initialValue: _quantities[index].toString(),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    _quantities[index] = double.tryParse(val) ?? 1.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total: R\$ ${(product.estimatedPrice * _quantities[index]).toStringAsFixed(2)}'),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Remoção offline: remover localmente e registrar na fila
                            await DatabaseService.deleteProduct(product.itemId ?? '');
                            await DatabaseService.addToSyncQueue('products', product.itemId ?? '', 'DELETE', {
                              ...product.toMap(),
                              'shoppingListId': _list.id ?? '',
                            });
                            setState(() {
                              _list.products.removeAt(index);
                              _selected.removeAt(index);
                              _quantities.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addProductDialog,
                  child: Text('Adicionar Produto'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final allSelected = _selected.every((s) => s);
                    if (allSelected) {
                      // Excluir lista
                      await ApiService().deleteShoppingList(_list.id ?? '');
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      // Excluir apenas itens selecionados
                      final toRemove = <int>[];
                      for (int i = 0; i < _list.products.length; i++) {
                        if (_selected[i]) {
                          toRemove.add(i);
                        }
                      }
                      for (final i in toRemove.reversed) {
                        final item = _list.products[i];
                        await ApiService().deleteItemFromList(_list.id ?? '', item.itemId ?? '');
                        setState(() {
                          _list.products.removeAt(i);
                          _selected.removeAt(i);
                          _quantities.removeAt(i);
                        });
                      }
                      // Exibir total do checkout
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Checkout realizado!'),
                          content: Text('Total dos itens: R\$ ${checkoutTotal.toStringAsFixed(2)}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text('Checkout'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Total selecionado: R\$ ${checkoutTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
