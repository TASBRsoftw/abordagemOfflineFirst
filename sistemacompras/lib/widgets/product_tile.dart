import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  ProductTile({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name),
      trailing: Icon(product.isSynced ? Icons.cloud_done : Icons.cloud_off),
      onTap: onTap,
    );
  }
}
