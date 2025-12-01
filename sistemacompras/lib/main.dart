import 'package:flutter/material.dart';
import 'screens/shopping_lists_screen.dart';

void main() {
  runApp(ShoppingApp());
}

class ShoppingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras Offline-First',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ShoppingListsScreen(),
    );
  }
}
