import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HealthDatabase {
  static Database? _database;

  static Future<Database> get instance async =>
      _database ??= await openDatabase(
        join(await getDatabasesPath(), 'health_app.db'),
        version: 2,
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, height_cm REAL NOT NULL, weight_kg REAL NOT NULL, target_kg REAL NOT NULL, goal INTEGER NOT NULL, calorie_target INTEGER NOT NULL)');
          await db.execute(
              'CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, kcal REAL NOT NULL, protein REAL NOT NULL, fat REAL NOT NULL, carbs REAL NOT NULL, barcode TEXT NOT NULL DEFAULT "")');
          await db.execute(
              'CREATE TABLE food_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, meal TEXT NOT NULL, grams REAL NOT NULL, date TEXT NOT NULL, FOREIGN KEY(product_id) REFERENCES products(id))');
          await db.execute(
              'CREATE TABLE weight_history (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, kg REAL NOT NULL)');
          await db.execute(
              'CREATE TABLE activity_history (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, steps INTEGER NOT NULL, heart_rate INTEGER NOT NULL, sleep_minutes INTEGER NOT NULL)');
          await db.execute(
              'CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
                'CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
            await db.insert('app_state', {'key': 'seeded', 'value': '1'});
          }
        },
      );
}
