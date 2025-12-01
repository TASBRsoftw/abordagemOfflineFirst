import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class ShoppingListDetailScreen extends StatelessWidget {
  final ShoppingList list;
  ShoppingListDetailScreen({required this.list});

  @override
  Widget build(BuildContext context) {
    // Exemplo de tela de detalhes
    return Scaffold(
      appBar: AppBar(title: Text(list.name)),
      body: Center(child: Text('Produtos da lista aqui')),
    );
  }
}
