import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/health/data/health_repository.dart';
import '../features/health/data/health_sync_service.dart';
import '../features/health/domain/models.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/diary/presentation/diary_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell(
      {super.key,
      required this.repository,
      required this.onSignOut,
      required this.onDeleteAccount});
  final HealthRepository repository;
  final VoidCallback onSignOut;
  final Future<void> Function() onDeleteAccount;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  DateTime date = DateTime.now();
  UserProfile user = const UserProfile();
  List<FoodEntry> entries = [];
  ActivityRecord? activity;
  List<WeightRecord> weights = [];
  bool loading = true;
  bool healthConnected = false;
  final healthSync = HealthSyncService();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final enabled = await widget.repository.healthSyncEnabled();
    if (enabled) {
      try {
        await widget.repository.saveActivity(await healthSync.read(date));
      } catch (_) {
        // Previously synced records remain available while the provider is unavailable.
      }
    }
    final values = await Future.wait<Object>([
      widget.repository.user(),
      widget.repository.entries(date),
      widget.repository.activity(date),
      widget.repository.weights()
    ]);
    if (!mounted) return;
    setState(() {
      user = values[0] as UserProfile;
      entries = values[1] as List<FoodEntry>;
      activity = values[2] as ActivityRecord;
      weights = values[3] as List<WeightRecord>;
      loading = false;
      healthConnected = enabled;
    });
  }

  Future<void> toggleHealth(bool enabled) async {
    if (enabled) {
      try {
        final granted = await healthSync.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Доступ к данным здоровья не предоставлен')));
          }
          return;
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Не удалось подключить данные здоровья. Проверьте Health Connect или Apple Health.')));
        }
        return;
      }
    }
    if (enabled) {
      await widget.repository.saveActivity(
          ActivityRecord(date: date, steps: 0, heartRate: 0, sleepMinutes: 0));
    }
    await widget.repository.setHealthSyncEnabled(enabled);
    await refresh();
  }

  Future<void> selectDate() async {
    final chosen = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        locale: const Locale('ru'));
    if (chosen == null) return;
    setState(() => date = chosen);
    await refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/logo.png')),
          titleSpacing: 0,
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Здоровье', style: TextStyle(fontSize: 11)),
            Text(['Главная', 'Дневник', 'Аналитика', 'Профиль'][tab],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
          ]),
          actions: [
            IconButton(
                onPressed: selectDate,
                icon: const Icon(Icons.calendar_today_outlined,
                    color: AppColors.green)),
            IconButton(
                onPressed: () => setState(() => tab = 3),
                icon: const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFE8EAFE),
                    child: Icon(Icons.person_outline,
                        color: AppColors.green, size: 21)))
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: tab, children: [
                DashboardScreen(
                    user: user,
                    entries: entries,
                    activity: activity!,
                    healthConnected: healthConnected,
                    date: date,
                    onAddFood: () => setState(() => tab = 1)),
                DiaryScreen(
                    repository: widget.repository,
                    user: user,
                    entries: entries,
                    date: date,
                    onDate: (d) async {
                      setState(() => date = d);
                      await refresh();
                    },
                    onChange: refresh),
                AnalyticsScreen(
                    user: user,
                    weights: weights,
                    activity: activity!,
                    healthConnected: healthConnected),
                ProfileScreen(
                    repository: widget.repository,
                    healthConnected: healthConnected,
                    onHealthChanged: toggleHealth,
                    user: user,
                    onChange: refresh,
                    onSignOut: widget.onSignOut,
                    onDeleteAccount: widget.onDeleteAccount),
              ]),
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.mint,
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.monitor_heart_outlined), label: 'Главная'),
            NavigationDestination(
                icon: Icon(Icons.restaurant_outlined), label: 'Дневник'),
            NavigationDestination(
                icon: Icon(Icons.analytics_outlined), label: 'Аналитика'),
            NavigationDestination(
                icon: Icon(Icons.account_circle_outlined), label: 'Профиль'),
          ],
        ),
      );
}
