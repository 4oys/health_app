import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/theme.dart';
import 'package:health_app/features/analytics/presentation/analytics_screen.dart';
import 'package:health_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:health_app/features/diary/presentation/diary_screen.dart';
import 'package:health_app/features/health/data/health_repository.dart';
import 'package:health_app/features/health/domain/models.dart';
import 'package:health_app/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('Основные экраны открываются на узком телефоне', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final date = DateTime(2026, 10, 4);
    const user = UserProfile();
    final activity = ActivityRecord(
        date: date, steps: 8420, heartRate: 72, sleepMinutes: 465);
    final entry = FoodEntry(
        id: 1,
        product: const Product(
            id: 1,
            name: 'Овсяная каша',
            kcal: 112,
            protein: 3.2,
            fat: 3.6,
            carbs: 16.8),
        meal: 'Завтрак',
        grams: 250,
        date: date);
    final screens = <Widget>[
      DashboardScreen(
          user: user,
          entries: [entry],
          activity: activity,
          date: date,
          onAddFood: () {}),
      DiaryScreen(
          repository: HealthRepository(),
          user: user,
          entries: [entry],
          date: date,
          onDate: (_) {},
          onChange: () {}),
      AnalyticsScreen(
          user: user, weights: [WeightRecord(date, 74.2)], activity: activity),
      ProfileScreen(
          repository: HealthRepository(),
          user: user,
          onChange: () {},
          onSignOut: () {},
          onDeleteAccount: () async {}),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(
          MaterialApp(theme: buildTheme(), home: Scaffold(body: screen)));
      await tester.pump();
      final failure = tester.takeException();
      expect(failure, isNull, reason: screen.runtimeType.toString());
    }
  });
}
