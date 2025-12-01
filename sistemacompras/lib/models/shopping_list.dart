class ShoppingList {
  final String? id;
  String name;
  String description;
  DateTime updatedAt;
  DateTime createdAt;
  List<Product> products;
  bool isSynced;
  int totalItems;
  int purchasedItems;
  double estimatedTotal;

  ShoppingList({
    this.id,
    required this.name,
    required this.description,
    required this.updatedAt,
    required this.createdAt,
    this.products = const [],
    this.isSynced = true,
    this.totalItems = 0,
    this.purchasedItems = 0,
    this.estimatedTotal = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'items': products.map((item) => item.toMap()).toList(),
      'summary': {
        'totalItems': totalItems,
        'purchasedItems': purchasedItems,
        'estimatedTotal': estimatedTotal,
      },
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String()),
      products: (map['items'] as List? ?? [])
          .map((item) => Product.fromMap(item)).toList(),
      isSynced: true,
      totalItems: map['summary']?['totalItems'] ?? 0,
      purchasedItems: map['summary']?['purchasedItems'] ?? 0,
      estimatedTotal: (map['summary']?['estimatedTotal'] ?? 0).toDouble(),
    );
  }
}

class Product {
  final String? itemId;
  String itemName;
  double quantity;
  String unit;
  double estimatedPrice;
  bool purchased;
  String notes;
  DateTime addedAt;
  DateTime updatedAt;
  bool isSynced;

  Product({
    this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.estimatedPrice,
    required this.purchased,
    required this.notes,
    required this.addedAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'estimatedPrice': estimatedPrice,
      'purchased': purchased,
      'notes': notes,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      itemId: map['itemId']?.toString(),
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] ?? 1).toDouble(),
      unit: map['unit'] ?? 'un',
      estimatedPrice: (map['estimatedPrice'] ?? 0).toDouble(),
      purchased: map['purchased'] ?? false,
      notes: map['notes'] ?? '',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isSynced: (map['isSynced'] ?? 1) == 1,
    );
  }
}
