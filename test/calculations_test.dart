import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/health/domain/calculations.dart';
import 'package:health_app/features/health/domain/models.dart';

void main() {
  test('ИМТ учитывает сантиметры и классифицирует нормальный вес', () {
    final value = HealthCalculations.bmi(74.2, 182);
    expect(value, closeTo(22.4, 0.05));
    expect(HealthCalculations.bmiStatus(value), 'Нормальный вес');
  });

  test('КБЖУ масштабируется по весу порции', () {
    final entry = FoodEntry(
      id: 1,
      product: const Product(
          id: 1,
          name: 'Тестовый продукт',
          kcal: 100,
          protein: 10,
          fat: 5,
          carbs: 20),
      meal: 'Завтрак',
      grams: 250,
      date: DateTime(2026, 10, 4),
    );
    expect(entry.kcal, 250);
    expect(entry.protein, 25);
    expect(entry.fat, 12.5);
    expect(entry.carbs, 50);
    expect(HealthCalculations.remainingCalories(2200, [entry]), 1950);
  });

  test('Прогресс ограничен нулём и единицей', () {
    expect(HealthCalculations.progress(12000, 10000), 1);
    expect(HealthCalculations.progress(30, 0), 0);
  });
}
