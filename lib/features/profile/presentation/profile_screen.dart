import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/calculations.dart';
import '../../health/domain/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen(
      {super.key,
      required this.repository,
      required this.user,
      required this.onChange,
      required this.onSignOut,
      required this.onDeleteAccount});
  final HealthRepository repository;
  final UserProfile user;
  final VoidCallback onChange;
  final VoidCallback onSignOut;
  final Future<void> Function() onDeleteAccount;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool health = false;
  bool watch = false;
  bool notifications = true;

  Future<void> edit() async {
    final name = TextEditingController(text: widget.user.name);
    final height =
        TextEditingController(text: widget.user.heightCm.toStringAsFixed(0));
    final weight =
        TextEditingController(text: widget.user.weightKg.toStringAsFixed(1));
    final target =
        TextEditingController(text: widget.user.targetKg.toStringAsFixed(1));
    final calories =
        TextEditingController(text: '${widget.user.calorieTarget}');
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Редактировать профиль'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Имя')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Рост, см')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: weight,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Текущий вес, кг')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: target,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Желаемый вес, кг')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: calories,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Норма, ккал'))
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Отмена')),
                  FilledButton(
                      onPressed: () async {
                        final h =
                            double.tryParse(height.text.replaceAll(',', '.'));
                        final w =
                            double.tryParse(weight.text.replaceAll(',', '.'));
                        final t =
                            double.tryParse(target.text.replaceAll(',', '.'));
                        final c = int.tryParse(calories.text);
                        if (name.text.trim().isEmpty ||
                            h == null ||
                            h <= 0 ||
                            w == null ||
                            w <= 0 ||
                            t == null ||
                            t <= 0 ||
                            c == null ||
                            c <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Проверьте введённые значения')));
                          return;
                        }
                        await widget.repository.saveUser(widget.user.copyWith(
                            name: name.text.trim(),
                            heightCm: h,
                            weightKg: w,
                            targetKg: t,
                            calorieTarget: c));
                        widget.onChange();
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      },
                      child: const Text('Сохранить'))
                ]));
    name.dispose();
    height.dispose();
    weight.dispose();
    target.dispose();
    calories.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bmi =
        HealthCalculations.bmi(widget.user.weightKg, widget.user.heightCm);
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          WhiteCard(
              child: Column(children: [
            const CircleAvatar(
                radius: 43,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.person_outline,
                    color: AppColors.green, size: 48)),
            const SizedBox(height: 11),
            Text(widget.user.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Профиль здоровья',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '${widget.user.goal.title} — ${widget.user.calorieTarget} ккал',
                    style: const TextStyle(
                        color: AppColors.green, fontWeight: FontWeight.w700))),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                    onPressed: edit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Редактировать профиль')))
          ])),
          const SizedBox(height: 21),
          Row(children: [
            Expanded(
                child: Text('Параметры тела',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge)),
            Text('ИМТ ${bmi.toStringAsFixed(1)}',
                style: const TextStyle(color: AppColors.green, fontSize: 11))
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(
                child: _Metric(
                    'Рост',
                    '${widget.user.heightCm.toStringAsFixed(0)} см',
                    Icons.height,
                    'Параметр профиля')),
            const SizedBox(width: 10),
            Expanded(
                child: _Metric(
                    'Текущий вес',
                    '${widget.user.weightKg.toStringAsFixed(1)} кг',
                    Icons.monitor_weight_outlined,
                    'Последнее измерение'))
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _Metric(
                    'Желаемый вес',
                    '${widget.user.targetKg.toStringAsFixed(1)} кг',
                    Icons.flag_outlined,
                    'Осталось ${(widget.user.weightKg - widget.user.targetKg).abs().toStringAsFixed(1)} кг')),
            const SizedBox(width: 10),
            const Expanded(
                child: _Metric('Активность', 'Средний', Icons.fitness_center,
                    '3–4 тренировки в неделю'))
          ]),
          const SizedBox(height: 20),
          Text('Интеграции и устройства',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 9),
          WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(children: [
                SwitchListTile(
                    title: const Text('Датчики здоровья'),
                    subtitle: const Text('Подключение будет доступно позже'),
                    secondary:
                        const Icon(Icons.favorite_outline, color: Colors.red),
                    value: health,
                    onChanged: (v) => setState(() => health = v)),
                const Divider(height: 1),
                SwitchListTile(
                    title: const Text('Смарт-часы'),
                    subtitle: const Text('Подключение будет доступно позже'),
                    secondary:
                        const Icon(Icons.watch_outlined, color: AppColors.blue),
                    value: watch,
                    onChanged: (v) => setState(() => watch = v)),
                const Divider(height: 1),
                SwitchListTile(
                    title: const Text('Уведомления'),
                    subtitle: const Text('Напоминания о воде и еде'),
                    secondary: const Icon(Icons.notifications_outlined,
                        color: AppColors.orange),
                    value: notifications,
                    onChanged: (v) => setState(() => notifications = v))
              ])),
          const SizedBox(height: 20),
          Text('Поддержка и приложение',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 9),
          WhiteCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Справка и FAQ'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _info('Справка и FAQ',
                        'Данные хранятся на вашем устройстве. Добавляйте продукты в дневник и редактируйте параметры в профиле.')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Связаться с поддержкой'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _info(
                        'Поддержка', 'Контакт поддержки пока не настроен.')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Конфиденциальность'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _info('Конфиденциальность',
                        'Профиль и записи хранятся локально в SQLite.'))
              ])),
          const SizedBox(height: 18),
          WhiteCard(
              child: TextButton.icon(
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Выйти из аккаунта',
                      style: TextStyle(color: Colors.red)))),
          TextButton(
              onPressed: () async {
                final approved = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                          title: const Text('Удалить аккаунт?'),
                          content: const Text(
                              'Профиль, записи питания, вес и активность будут удалены с этого устройства.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Отмена')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Удалить')),
                          ],
                        ));
                if (approved == true) await widget.onDeleteAccount();
              },
              child: const Text('Удалить аккаунт',
                  style: TextStyle(color: Colors.red))),
        ]);
  }

  void _info(String title, String body) => showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(title: Text(title), content: Text(body), actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'))
          ]));
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.note);
  final String label;
  final String value;
  final IconData icon;
  final String note;
  @override
  Widget build(BuildContext context) => WhiteCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
          height: 125,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12))),
                  Icon(icon, color: AppColors.green, size: 19)
                ]),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                Text(note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.green))
              ])));
}
