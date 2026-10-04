import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/auth/data/auth_repository.dart';
import 'package:health_app/features/health/data/health_repository.dart';
import 'package:health_app/main.dart';

void main() {
  testWidgets('Экран регистрации содержит русские поля и цели', (tester) async {
    await tester.pumpWidget(HealthApp(
      repository: HealthRepository(),
      auth: const AuthRepository(),
      initiallySignedIn: false,
    ));
    expect(find.text('Создание аккаунта'), findsOneWidget);
    expect(find.text('Ваше имя'), findsOneWidget);
    expect(find.text('Снизить вес'), findsOneWidget);
    expect(find.text('Продолжить'), findsOneWidget);
    await tester.tap(find.text('Войти').first);
    await tester.pump();
    expect(find.text('Вход в аккаунт'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
