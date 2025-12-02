import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/shopping_list.dart';

class DatabaseService {
    static Future<List<Product>> getProductsForList(String shoppingListId) async {
      final db = await database;
      final maps = await db.query('products', where: 'shoppingListId = ?', whereArgs: [shoppingListId]);
      return maps.map((map) => Product.fromMap({
        'itemId': map['id'],
        'itemName': map['name'],
        'quantity': map['quantity'] ?? 1,
        'unit': map['unit'] ?? 'un',
        'estimatedPrice': map['estimatedPrice'] ?? 0,
        'purchased': map['purchased'] == 1,
        'notes': map['notes'] ?? '',
        'addedAt': map['addedAt'] ?? map['updatedAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': map['updatedAt'] ?? DateTime.now().toIso8601String(),
        'isSynced': map['isSynced'] == 1,
      })).toList();
    }
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shopping_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE shopping_lists (
            id TEXT PRIMARY KEY,
            name TEXT,
            updatedAt TEXT,
            isSynced INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT,
            shoppingListId TEXT,
            updatedAt TEXT,
            isSynced INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id TEXT PRIMARY KEY,
            tableName TEXT,
            rowId TEXT,
            action TEXT,
            payload TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
  }

  static Future<int> insertShoppingList(ShoppingList list) async {
    final db = await database;
    return await db.insert('shopping_lists', {
      'id': list.id,
      'name': list.name,
      'updatedAt': list.updatedAt.toIso8601String(),
      'isSynced': 1, // Mark backend lists as synced
    });
  }

  static Future<int> updateShoppingList(ShoppingList list) async {
    final db = await database;
    return await db.update(
      'shopping_lists',
      {
        'name': list.name,
        'updatedAt': list.updatedAt.toIso8601String(),
        'isSynced': 1, // Mark backend lists as synced
      },
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  static Future<int> deleteShoppingList(int id) async {
    final db = await database;
    return await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> insertProduct(Product product, String shoppingListId) async {
    final db = await database;
    return await db.insert('products', {
      'id': product.itemId,
      'name': product.itemName,
      'shoppingListId': shoppingListId,
      'updatedAt': product.updatedAt.toIso8601String(),
      'isSynced': 0,
    });
  }

  static Future<int> updateProduct(Product product, String productId) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'name': product.itemName,
        'updatedAt': product.updatedAt.toIso8601String(),
        'isSynced': 0,
      },
      where: 'id = ?',
      whereArgs: [product.itemId],
    );
  }

  static Future<int> deleteProduct(String productId) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [productId]);
  }

  static Future<int> addToSyncQueue(String tableName, String rowId, String action, Map<String, dynamic> payload) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tableName': tableName,
      'rowId': rowId,
      'action': action,
      'payload': payload != null ? jsonEncode(payload) : '',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue');
  }

  static Future<int> removeFromSyncQueue(String id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> processSyncQueue(Function syncAction) async {
    final queue = await getSyncQueue();
    for (final item in queue) {
      await syncAction(item);
      await removeFromSyncQueue(item['id'].toString());
    }
  }

  static Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await database;
    final maps = await db.query('shopping_lists');
    return maps.map((map) => ShoppingList(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      description: '',
      updatedAt: DateTime.parse(map['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.now(),
      products: const [],
    )).toList();
  }
}