enum Goal { lose, maintain, gain }

extension GoalTitle on Goal {
  String get title => switch (this) {
        Goal.lose => 'Снизить вес',
        Goal.maintain => 'Баланс / вес',
        Goal.gain => 'Набрать мышцы',
      };
}

class UserProfile {
  const UserProfile(
      {this.name = 'Александр',
      this.email = '',
      this.heightCm = 182,
      this.weightKg = 74.2,
      this.targetKg = 71,
      this.goal = Goal.lose,
      this.calorieTarget = 2200});
  final String name;
  final String email;
  final double heightCm;
  final double weightKg;
  final double targetKg;
  final Goal goal;
  final int calorieTarget;

  UserProfile copyWith(
          {String? name,
          String? email,
          double? heightCm,
          double? weightKg,
          double? targetKg,
          Goal? goal,
          int? calorieTarget}) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        targetKg: targetKg ?? this.targetKg,
        goal: goal ?? this.goal,
        calorieTarget: calorieTarget ?? this.calorieTarget,
      );
}

class Product {
  const Product(
      {required this.id,
      required this.name,
      required this.kcal,
      required this.protein,
      required this.fat,
      required this.carbs,
      this.barcode = ''});
  final int id;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final String barcode;
}

class FoodEntry {
  const FoodEntry(
      {required this.id,
      required this.product,
      required this.meal,
      required this.grams,
      required this.date});
  final int id;
  final Product product;
  final String meal;
  final double grams;
  final DateTime date;
  double get kcal => product.kcal * grams / 100;
  double get protein => product.protein * grams / 100;
  double get fat => product.fat * grams / 100;
  double get carbs => product.carbs * grams / 100;
}

class WeightRecord {
  const WeightRecord(this.date, this.kg);
  final DateTime date;
  final double kg;
}

class ActivityRecord {
  const ActivityRecord(
      {required this.date,
      required this.steps,
      required this.heartRate,
      required this.sleepMinutes});
  final DateTime date;
  final int steps;
  final int heartRate;
  final int sleepMinutes;
}
