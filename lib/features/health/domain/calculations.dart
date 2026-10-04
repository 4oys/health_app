import 'models.dart';

class HealthCalculations {
  static double bmi(double weightKg, double heightCm) =>
      heightCm <= 0 ? 0 : weightKg / (heightCm / 100 * heightCm / 100);
  static String bmiStatus(double value) => value < 18.5
      ? 'Недостаточный вес'
      : value < 25
          ? 'Нормальный вес'
          : value < 30
              ? 'Избыточный вес'
              : 'Ожирение';
  static double progress(num value, num target) =>
      target <= 0 ? 0 : (value / target).clamp(0, 1).toDouble();
  static int remainingCalories(int target, Iterable<FoodEntry> entries) =>
      target -
      entries.fold<double>(0, (sum, entry) => sum + entry.kcal).round();
  static double totalProtein(Iterable<FoodEntry> entries) =>
      entries.fold(0, (sum, entry) => sum + entry.protein);
  static double totalFat(Iterable<FoodEntry> entries) =>
      entries.fold(0, (sum, entry) => sum + entry.fat);
  static double totalCarbs(Iterable<FoodEntry> entries) =>
      entries.fold(0, (sum, entry) => sum + entry.carbs);
}
