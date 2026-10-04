import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/health/data/health_repository.dart';
import 'core/app_shell.dart';
import 'features/auth/presentation/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = HealthRepository();
  await repository.seed();
  const auth = AuthRepository();
  final signedIn = await auth.hasSession();
  runApp(HealthApp(
      repository: repository, auth: auth, initiallySignedIn: signedIn));
}

class HealthApp extends StatefulWidget {
  const HealthApp(
      {super.key,
      required this.repository,
      required this.auth,
      required this.initiallySignedIn});
  final HealthRepository repository;
  final AuthRepository auth;
  final bool initiallySignedIn;
  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  late bool signedIn = widget.initiallySignedIn;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Здоровье',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        home: signedIn
            ? AppShell(
                repository: widget.repository,
                onSignOut: () async {
                  await widget.auth.signOut();
                  setState(() => signedIn = false);
                },
                onDeleteAccount: () async {
                  await widget.repository.deleteAccount();
                  await widget.auth.deleteAccount();
                  setState(() => signedIn = false);
                })
            : AuthScreen(
                repository: widget.repository,
                auth: widget.auth,
                onComplete: () => setState(() => signedIn = true)),
      );
}
