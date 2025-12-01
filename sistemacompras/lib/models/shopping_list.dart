class ShoppingList {
  final int? id;
  String name;
  DateTime updatedAt;
  List<Product> products;
  bool isSynced;

  ShoppingList({
    this.id,
    required this.name,
    required this.updatedAt,
    this.products = const [],
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }
}

class Product {
  final int? id;
  String name;
  int shoppingListId;
  DateTime updatedAt;
  bool isSynced;

  Product({
    this.id,
    required this.name,
    required this.shoppingListId,
    required this.updatedAt,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shoppingListId': shoppingListId,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      shoppingListId: map['shoppingListId'],
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }
}
