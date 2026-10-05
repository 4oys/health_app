import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../health/domain/calculations.dart';
import '../../health/domain/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(
      {super.key,
      required this.user,
      required this.entries,
      required this.activity,
      required this.date,
      required this.onAddFood,
      this.healthConnected = false});
  final UserProfile user;
  final List<FoodEntry> entries;
  final ActivityRecord activity;
  final bool healthConnected;
  final DateTime date;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<double>(0, (sum, e) => sum + e.kcal).round();
    final remaining =
        HealthCalculations.remainingCalories(user.calorieTarget, entries);
    final weekday = [
      'ПОНЕДЕЛЬНИК',
      'ВТОРНИК',
      'СРЕДА',
      'ЧЕТВЕРГ',
      'ПЯТНИЦА',
      'СУББОТА',
      'ВОСКРЕСЕНЬЕ'
    ][date.weekday - 1];
    final month = [
      'ЯНВАРЯ',
      'ФЕВРАЛЯ',
      'МАРТА',
      'АПРЕЛЯ',
      'МАЯ',
      'ИЮНЯ',
      'ИЮЛЯ',
      'АВГУСТА',
      'СЕНТЯБРЯ',
      'ОКТЯБРЯ',
      'НОЯБРЯ',
      'ДЕКАБРЯ'
    ][date.month - 1];
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Text('$weekday, ${date.day} $month',
              style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Привет, ${user.name}!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          Text(
              healthConnected
                  ? '●  Данные системы здоровья'
                  : '●  Пример данных активности',
              style: const TextStyle(fontSize: 11, color: AppColors.green)),
          const SizedBox(height: 20),
          WhiteCard(
              child: Column(children: [
            Row(children: [
              const Expanded(
                  child: Text('Баланс энергии',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              _Badge('Ост. $remaining ккал')
            ]),
            const SizedBox(height: 19),
            SizedBox(
                width: 178,
                height: 178,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                      child: CircularProgressIndicator(
                          value: HealthCalculations.progress(
                              kcal, user.calorieTarget),
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.pale,
                          color: AppColors.green)),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$kcal',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        Text('из ${user.calorieTarget} ккал',
                            style: const TextStyle(fontSize: 12))
                      ])
                ])),
            const SizedBox(height: 24),
            Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(13)),
                child: Row(children: [
                  _Macro('Белки', HealthCalculations.totalProtein(entries), 140,
                      AppColors.green),
                  _Macro('Жиры', HealthCalculations.totalFat(entries), 70,
                      AppColors.orange),
                  _Macro('Углеводы', HealthCalculations.totalCarbs(entries),
                      260, const Color(0xFF19B98C)),
                ])),
          ])),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: WhiteCard(
                    child: SizedBox(
                        height: 140,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.favorite, color: Colors.red),
                                    Text('Пульс',
                                        style: TextStyle(fontSize: 12))
                                  ]),
                              RichText(
                                  text: TextSpan(children: [
                                TextSpan(
                                    text: activity.heartRate == 0
                                        ? '—'
                                        : '${activity.heartRate}',
                                    style: const TextStyle(
                                        fontSize: 29,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink)),
                                const TextSpan(
                                    text: ' уд/мин',
                                    style: TextStyle(
                                        fontSize: 11, color: AppColors.ink))
                              ])),
                              const Text('━━━━╱╲╱╲━━━━',
                                  style: TextStyle(color: AppColors.green)),
                              Text(
                                  healthConnected
                                      ? 'Последнее измерение'
                                      : 'В покое: 64 уд/мин',
                                  style: const TextStyle(fontSize: 11))
                            ])))),
            const SizedBox(width: 10),
            Expanded(
                child: WhiteCard(
                    child: SizedBox(
                        height: 140,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.directions_walk,
                                        color: AppColors.green),
                                    Flexible(
                                        child: Text('Активность',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12)))
                                  ]),
                              Text('${activity.steps} шагов',
                                  style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800)),
                              LinearProgressIndicator(
                                  value: HealthCalculations.progress(
                                      activity.steps, 10000),
                                  color: AppColors.green,
                                  backgroundColor: AppColors.pale),
                              const Text('Цель: 10 000 шагов',
                                  style: TextStyle(fontSize: 11))
                            ]))))
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Text('Приёмы пищи сегодня',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed: onAddFood, child: const Text('Все >'))
          ]),
          for (final meal in ['Завтрак', 'Обед'])
            if (entries.any((e) => e.meal == meal))
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WhiteCard(
                      padding: const EdgeInsets.all(13),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 24,
                            backgroundColor: meal == 'Завтрак'
                                ? const Color(0xFFFFF3E6)
                                : const Color(0xFFE5F1FF),
                            child: Icon(
                                meal == 'Завтрак'
                                    ? Icons.wb_twilight
                                    : Icons.wb_sunny_outlined,
                                color: meal == 'Завтрак'
                                    ? AppColors.orange
                                    : AppColors.blue)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(meal,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  entries
                                      .where((e) => e.meal == meal)
                                      .map((e) => e.product.name)
                                      .join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11))
                            ])),
                        Text(
                            '${entries.where((e) => e.meal == meal).fold<double>(0, (s, e) => s + e.kcal).round()} ккал',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))
                      ]))),
          const SizedBox(height: 14),
          PrimaryButton(
              text: 'Добавить приём пищи',
              icon: Icons.add_circle_outline,
              onPressed: onAddFood),
        ]);
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.pale, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.green,
              fontWeight: FontWeight.w700)));
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value, this.target, this.color);
  final String label;
  final double value;
  final double target;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w700))),
              Text(
                  '${(HealthCalculations.progress(value, target) * 100).round()}%',
                  style: const TextStyle(fontSize: 10))
            ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(
                value: HealthCalculations.progress(value, target),
                color: color,
                backgroundColor: const Color(0xFFDDE5EE)),
            const SizedBox(height: 4),
            Text('${value.round()} / ${target.round()} г',
                style: const TextStyle(fontSize: 10))
          ])));
}
