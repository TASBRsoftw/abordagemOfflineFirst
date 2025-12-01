import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class ShoppingListsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Exemplo de tela inicial
    return Scaffold(
      appBar: AppBar(title: Text('Listas de Compras')),
      body: Center(child: Text('Exibir listas aqui')),
    );
  }
}
