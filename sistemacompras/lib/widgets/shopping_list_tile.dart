import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class ShoppingListTile extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onTap;
  ShoppingListTile({required this.list, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(list.name),
      trailing: Icon(list.isSynced ? Icons.cloud_done : Icons.cloud_off),
      onTap: onTap,
    );
  }
}
