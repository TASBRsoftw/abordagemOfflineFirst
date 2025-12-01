import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shopping_list.dart';

class DatabaseService {
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
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            updatedAt TEXT,
            isSynced INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            shoppingListId INTEGER,
            updatedAt TEXT,
            isSynced INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tableName TEXT,
            rowId INTEGER,
            action TEXT,
            payload TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
  }

  // Métodos CRUD para ShoppingList, Product e SyncQueue
  // ...
}
