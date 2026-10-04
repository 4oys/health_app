import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';
import 'health_database.dart';

class HealthRepository {
  Future<Database> get _db => HealthDatabase.instance;

  Future<void> seed() async {
    final db = await _db;
    if ((await db.query('app_state', where: 'key = ?', whereArgs: ['seeded']))
        .isNotEmpty) {
      return;
    }
    await db.insert('users', {
      'id': 1,
      'name': 'Александр',
      'email': '',
      'height_cm': 182,
      'weight_kg': 74.2,
      'target_kg': 71,
      'goal': 0,
      'calorie_target': 2200
    });
    final products = <List<Object>>[
      ['Овсяная каша со сливочным маслом', 112, 3.2, 3.6, 16.8],
      ['Бутерброды с ветчиной и творожным сыром', 221, 12.9, 10, 20],
      ['Чай чёрный без сахара', 2, 0, 0, 0.4],
      ['Гороховый суп с копчёностями', 117, 6.3, 5.1, 10.9],
      ['Хлеб ржаной', 225, 8.3, 1.7, 43.3],
      ['Чай или компот', 25, 0, 0, 6],
      ['Чебурек с сыром', 288, 9.2, 16.2, 26.2],
      ['Куриная грудка', 165, 31, 3.6, 0],
      ['Банан', 89, 1.1, 0.3, 22.8],
    ];
    for (final p in products) {
      await db.insert('products', {
        'name': p[0],
        'kcal': p[1],
        'protein': p[2],
        'fat': p[3],
        'carbs': p[4],
        'barcode': ''
      });
    }
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final samples = <List<Object>>[
      [1, 'Завтрак', 250],
      [2, 'Завтрак', 140],
      [3, 'Завтрак', 250],
      [4, 'Обед', 350],
      [5, 'Обед', 60],
      [6, 'Обед', 200],
      [7, 'Перекус', 130]
    ];
    for (final e in samples) {
      await db.insert('food_entries',
          {'product_id': e[0], 'meal': e[1], 'grams': e[2], 'date': today});
    }
    for (var i = 29; i >= 0; i -= 10) {
      final date = DateTime.now()
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      await db.insert('weight_history', {'date': date, 'kg': 74.2 + i * 0.06});
    }
    await db.insert('activity_history',
        {'date': today, 'steps': 8420, 'heart_rate': 72, 'sleep_minutes': 465});
    await db.insert('app_state', {'key': 'seeded', 'value': '1'});
  }

  Future<UserProfile> user() async {
    final rows = await (await _db).query('users', where: 'id = 1');
    if (rows.isEmpty) return const UserProfile();
    final r = rows.first;
    return UserProfile(
        name: r['name'] as String,
        email: r['email'] as String,
        heightCm: r['height_cm'] as double,
        weightKg: r['weight_kg'] as double,
        targetKg: r['target_kg'] as double,
        goal: Goal.values[r['goal'] as int],
        calorieTarget: r['calorie_target'] as int);
  }

  Future<void> saveUser(UserProfile user) async {
    final db = await _db;
    await db.insert(
        'users',
        {
          'id': 1,
          'name': user.name,
          'email': user.email,
          'height_cm': user.heightCm,
          'weight_kg': user.weightKg,
          'target_kg': user.targetKg,
          'goal': user.goal.index,
          'calorie_target': user.calorieTarget
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('weight_history', {
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'kg': user.weightKg
    });
  }

  Future<List<Product>> products([String query = '']) async {
    final rows = await (await _db).query('products',
        where: query.isEmpty ? null : 'name LIKE ? OR barcode = ?',
        whereArgs: query.isEmpty ? null : ['%$query%', query],
        orderBy: 'name');
    return rows
        .map((r) => Product(
            id: r['id'] as int,
            name: r['name'] as String,
            kcal: (r['kcal'] as num).toDouble(),
            protein: (r['protein'] as num).toDouble(),
            fat: (r['fat'] as num).toDouble(),
            carbs: (r['carbs'] as num).toDouble(),
            barcode: r['barcode'] as String))
        .toList();
  }

  Future<List<FoodEntry>> entries(DateTime date) async {
    final key = date.toIso8601String().substring(0, 10);
    final rows = await (await _db).rawQuery(
        'SELECT e.id, e.meal, e.grams, e.date, p.id AS product_id, p.name, p.kcal, p.protein, p.fat, p.carbs, p.barcode FROM food_entries e JOIN products p ON p.id=e.product_id WHERE e.date=? ORDER BY e.id',
        [key]);
    return rows
        .map((r) => FoodEntry(
            id: r['id'] as int,
            meal: r['meal'] as String,
            grams: (r['grams'] as num).toDouble(),
            date: DateTime.parse(r['date'] as String),
            product: Product(
                id: r['product_id'] as int,
                name: r['name'] as String,
                kcal: (r['kcal'] as num).toDouble(),
                protein: (r['protein'] as num).toDouble(),
                fat: (r['fat'] as num).toDouble(),
                carbs: (r['carbs'] as num).toDouble(),
                barcode: r['barcode'] as String)))
        .toList();
  }

  Future<void> addEntry(
      Product product, String meal, double grams, DateTime date) async {
    await (await _db).insert('food_entries', {
      'product_id': product.id,
      'meal': meal,
      'grams': grams,
      'date': date.toIso8601String().substring(0, 10)
    });
  }

  Future<void> deleteEntry(int id) async {
    await (await _db).delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAccount() async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final table in [
        'food_entries',
        'weight_history',
        'activity_history',
        'users'
      ]) {
        await txn.delete(table);
      }
    });
  }

  Future<List<WeightRecord>> weights() async =>
      (await (await _db).query('weight_history', orderBy: 'date'))
          .map((r) => WeightRecord(
              DateTime.parse(r['date'] as String), (r['kg'] as num).toDouble()))
          .toList();
  Future<ActivityRecord> activity(DateTime date) async {
    final rows = await (await _db).query('activity_history',
        where: 'date = ?',
        whereArgs: [date.toIso8601String().substring(0, 10)]);
    if (rows.isEmpty) {
      return ActivityRecord(
          date: date, steps: 0, heartRate: 0, sleepMinutes: 0);
    }
    final r = rows.first;
    return ActivityRecord(
        date: date,
        steps: r['steps'] as int,
        heartRate: r['heart_rate'] as int,
        sleepMinutes: r['sleep_minutes'] as int);
  }
}
