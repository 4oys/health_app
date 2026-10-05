import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme.dart';
import '../../health/domain/calculations.dart';
import '../../health/domain/models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen(
      {super.key,
      required this.user,
      required this.weights,
      required this.activity,
      this.healthConnected = false});
  final UserProfile user;
  final List<WeightRecord> weights;
  final ActivityRecord activity;
  final bool healthConnected;
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int period = 1;
  Future<Uint8List> report() async {
    final doc = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/NotoSans.ttf'));
    final bold = font;
    final bmi =
        HealthCalculations.bmi(widget.user.weightKg, widget.user.heightCm);
    doc.addPage(pw.Page(
        build: (_) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      widget.healthConnected
                          ? 'Отчёт о здоровье'
                          : 'Отчёт о здоровье — пример данных',
                      style: pw.TextStyle(font: bold, fontSize: 24)),
                  pw.SizedBox(height: 20),
                  pw.Text('Имя: ${widget.user.name}',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Рост: ${widget.user.heightCm.toStringAsFixed(0)} см',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Вес: ${widget.user.weightKg.toStringAsFixed(1)} кг',
                      style: pw.TextStyle(font: font)),
                  pw.Text(
                      'Целевой вес: ${widget.user.targetKg.toStringAsFixed(1)} кг',
                      style: pw.TextStyle(font: font)),
                  pw.Text(
                      'ИМТ: ${bmi.toStringAsFixed(1)} — ${HealthCalculations.bmiStatus(bmi)}',
                      style: pw.TextStyle(font: font)),
                  pw.SizedBox(height: 15),
                  pw.Text('История веса',
                      style: pw.TextStyle(font: bold, fontSize: 17)),
                  for (final w in widget.weights)
                    pw.Text(
                        '${w.date.day}.${w.date.month}.${w.date.year}: ${w.kg.toStringAsFixed(1)} кг',
                        style: pw.TextStyle(font: font)),
                  pw.SizedBox(height: 15),
                  pw.Text('Шаги: ${widget.activity.steps}',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Пульс: ${widget.activity.heartRate} уд/мин',
                      style: pw.TextStyle(font: font)),
                  pw.Text(
                      'Сон: ${widget.activity.sleepMinutes ~/ 60} ч ${widget.activity.sleepMinutes % 60} мин',
                      style: pw.TextStyle(font: font)),
                ])));
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final bmi =
        HealthCalculations.bmi(widget.user.weightKg, widget.user.heightCm);
    final days = [7, 30, 90, 365][period];
    final deep = widget.healthConnected ? widget.activity.deepMinutes : 22;
    final rem = widget.healthConnected ? widget.activity.remMinutes : 25;
    final light = widget.healthConnected ? widget.activity.lightMinutes : 53;
    final hasSleepPhases = deep + rem + light > 0;
    final recent = widget.weights
        .where((w) => DateTime.now().difference(w.date).inDays <= days)
        .toList();
    final points = recent.isEmpty
        ? [WeightRecord(DateTime.now(), widget.user.weightKg)]
        : recent;
    final minimum = points.map((e) => e.kg).reduce((a, b) => a < b ? a : b) - 1;
    final maximum = points.map((e) => e.kg).reduce((a, b) => a > b ? a : b) + 1;
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          const Text('ОТЧЁТНОСТЬ',
              style: TextStyle(fontSize: 11, letterSpacing: 1)),
          Row(children: [
            Expanded(
                child: Text('Аналитика здоровья',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium)),
            IconButton.filledTonal(
                onPressed: () => Printing.layoutPdf(onLayout: (_) => report()),
                icon: const Icon(Icons.picture_as_pdf_outlined))
          ]),
          const SizedBox(height: 15),
          WhiteCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                          child: Text('Индекс массы тела\n(ИМТ)',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700))),
                      Text(HealthCalculations.bmiStatus(bmi),
                          style: const TextStyle(
                              color: AppColors.green, fontSize: 11))
                    ]),
                const SizedBox(height: 10),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: bmi.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const TextSpan(
                      text: ' кг/м²', style: TextStyle(color: AppColors.ink))
                ])),
                const SizedBox(height: 10),
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const Row(children: [
                      Expanded(
                          child: ColoredBox(
                              color: AppColors.blue,
                              child: SizedBox(height: 10))),
                      Expanded(
                          flex: 2,
                          child: ColoredBox(
                              color: Color(0xFF17B888),
                              child: SizedBox(height: 10))),
                      Expanded(
                          child: ColoredBox(
                              color: AppColors.orange,
                              child: SizedBox(height: 10))),
                      Expanded(
                          child: ColoredBox(
                              color: Colors.red, child: SizedBox(height: 10)))
                    ])),
                const SizedBox(height: 10),
                const Text('Дефицит (<18.5)      Норма (18.5–24.9)      >25',
                    style: TextStyle(fontSize: 10)),
                const SizedBox(height: 18),
                Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F1FF),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                        'Ваш вес: ${HealthCalculations.bmiStatus(bmi).toLowerCase()}. ИМТ рассчитывается как вес в кг, делённый на рост в метрах в квадрате.',
                        style: const TextStyle(fontSize: 13)))
              ])),
          const SizedBox(height: 18),
          WhiteCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('ДИНАМИКА ВЕСА', style: TextStyle(fontSize: 11)),
                Text('${widget.user.weightKg.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                        fontSize: 29, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                        child: InkWell(
                      onTap: () => setState(() => period = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: period == i
                                ? AppColors.green
                                : const Color(0xFFE8EAFE),
                            borderRadius: BorderRadius.circular(9)),
                        child: Text(['1 Нед', '1 Мес', '3 Мес', 'Год'][i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: period == i
                                    ? Colors.white
                                    : AppColors.ink)),
                      ),
                    ))
                ]),
                const SizedBox(height: 22),
                SizedBox(
                    height: 190,
                    child: LineChart(LineChartData(
                        minY: minimum,
                        maxY: maximum,
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false))),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                              spots: [
                                for (var i = 0; i < points.length; i++)
                                  FlSpot(i.toDouble(), points[i].kg)
                              ],
                              isCurved: true,
                              color: AppColors.green,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.mint.withValues(alpha: 0.5)))
                        ])))
              ])),
          const SizedBox(height: 18),
          WhiteCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('☾ Сон и восстановление',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                      child: _SleepMetric('Общая длительность',
                          '${widget.activity.sleepMinutes ~/ 60} ч ${widget.activity.sleepMinutes % 60} мин')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _SleepMetric(
                          'Пульс',
                          widget.activity.heartRate == 0
                              ? 'Нет данных'
                              : '${widget.activity.heartRate} уд/мин'))
                ]),
                const SizedBox(height: 16),
                Text(widget.healthConnected ? 'Фазы сна' : 'Фазы сна — пример',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                if (hasSleepPhases)
                  Row(children: [
                    if (deep > 0)
                      Expanded(
                          flex: deep,
                          child: const ColoredBox(
                              color: AppColors.green,
                              child: SizedBox(height: 9))),
                    if (rem > 0)
                      Expanded(
                          flex: rem,
                          child: const ColoredBox(
                              color: Color(0xFFA8C2FF),
                              child: SizedBox(height: 9))),
                    if (light > 0)
                      Expanded(
                          flex: light,
                          child: const ColoredBox(
                              color: Color(0xFFDCE5EE),
                              child: SizedBox(height: 9))),
                  ]),
                const SizedBox(height: 12),
                Text(
                    widget.healthConnected && !hasSleepPhases
                        ? 'Нет данных о фазах сна'
                        : widget.healthConnected
                            ? '● Глубокий ${widget.activity.deepMinutes} мин     ● Быстрый ${widget.activity.remMinutes} мин     ● Лёгкий ${widget.activity.lightMinutes} мин'
                            : '● Глубокий 22%     ● Быстрый 25%     ● Лёгкий 53%',
                    style: const TextStyle(fontSize: 11))
              ])),
          const SizedBox(height: 18),
          WhiteCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Экспорт отчёта в PDF',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                    'Данные о весе, ИМТ и активности для врача или тренера.'),
                const SizedBox(height: 14),
                PrimaryButton(
                    text: 'Скачать медицинский отчёт',
                    icon: Icons.download,
                    onPressed: () =>
                        Printing.layoutPdf(onLayout: (_) => report()))
              ])),
        ]);
  }
}

class _SleepMetric extends StatelessWidget {
  const _SleepMetric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.pale, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))
      ]));
}
