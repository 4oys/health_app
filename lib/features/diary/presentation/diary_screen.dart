import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/calculations.dart';
import '../../health/domain/models.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen(
      {super.key,
      required this.repository,
      required this.user,
      required this.entries,
      required this.date,
      required this.onDate,
      required this.onChange});
  final HealthRepository repository;
  final UserProfile user;
  final List<FoodEntry> entries;
  final DateTime date;
  final ValueChanged<DateTime> onDate;
  final VoidCallback onChange;
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final search = TextEditingController();
  bool searching = false;
  bool loading = false;
  String? searchError;
  List<Product> results = [];
  Timer? searchTimer;
  DateTime? lastOnlineSearch;
  int searchVersion = 0;

  void onSearchChanged(String value) {
    searchTimer?.cancel();
    final version = ++searchVersion;
    setState(() {
      searching = value.trim().isNotEmpty;
      loading = false;
      searchError = null;
      results = [];
    });
    if (!searching) return;
    loadLocalProducts(value, version);
    if (value.trim().length < 2) return;
    searchTimer = Timer(
        const Duration(milliseconds: 700), () => runSearch(value, version));
  }

  Future<void> loadLocalProducts(String query, int version) async {
    final local = await widget.repository.products(query);
    if (!mounted || version != searchVersion) return;
    setState(() => results = local);
  }

  void submitSearch() {
    final query = search.text.trim();
    if (query.isEmpty) return;
    searchTimer?.cancel();
    final version = ++searchVersion;
    setState(() {
      searching = true;
      loading = true;
      searchError = null;
    });
    runSearch(query, version);
  }

  Future<void> runSearch(String query, int version) async {
    try {
      final local = await widget.repository.products(query);
      if (!mounted || version != searchVersion) return;
      setState(() {
        results = local;
        loading = query.trim().length >= 2;
      });
      if (query.trim().length < 2) {
        setState(() => loading = false);
        return;
      }
      final last = lastOnlineSearch;
      if (last != null) {
        final wait =
            const Duration(seconds: 6) - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      if (!mounted || version != searchVersion) return;
      lastOnlineSearch = DateTime.now();
      final online = await widget.repository.searchProductsOnline(query);
      if (!mounted || version != searchVersion) return;
      final known = local
          .where((p) => p.barcode.isNotEmpty)
          .map((p) => p.barcode)
          .toSet();
      setState(() {
        results = [
          ...local,
          ...online.where((p) => !known.contains(p.barcode))
        ];
        loading = false;
      });
    } on ProductLookupException catch (error) {
      if (!mounted || version != searchVersion) return;
      setState(() {
        searchError = error.message;
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    searchTimer?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> scan() async {
    final barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _ScannerScreen()));
    if (barcode == null || !mounted) return;
    searchTimer?.cancel();
    final version = ++searchVersion;
    search.text = barcode;
    setState(() {
      searching = true;
      loading = true;
      searchError = null;
      results = [];
    });
    try {
      final local = await widget.repository.products(barcode);
      if (!mounted || version != searchVersion) return;
      if (local.isNotEmpty) {
        setState(() {
          results = local;
          loading = false;
        });
        return;
      }
      final remote =
          await widget.repository.findProductByBarcodeOnline(barcode);
      if (!mounted || version != searchVersion) return;
      if (remote != null) {
        setState(() {
          results = [remote];
          loading = false;
        });
        return;
      }
      setState(() => loading = false);
      final created = await showDialog<bool>(
          context: context,
          builder: (_) => _NewProductDialog(
              repository: widget.repository, barcode: barcode));
      if (created == true && mounted) onSearchChanged(barcode);
    } on ProductLookupException catch (error) {
      if (!mounted || version != searchVersion) return;
      setState(() {
        searchError = error.message;
        loading = false;
      });
    }
  }

  Future<void> add(String meal, {Product? selectedProduct}) async {
    final products = searching ? results : await widget.repository.products();
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _AddFoodSheet(
            products: products,
            initialProduct: selectedProduct,
            meal: meal,
            date: widget.date,
            repository: widget.repository,
            onDone: widget.onChange));
  }

  @override
  Widget build(BuildContext context) {
    final kcal = widget.entries.fold<double>(0, (s, e) => s + e.kcal).round();
    final first = DateTime(widget.date.year, widget.date.month, widget.date.day)
        .subtract(Duration(days: widget.date.weekday - 1));
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
        children: [
          Row(
              children: List.generate(7, (i) {
            final day = first.add(Duration(days: i));
            final selected = day.year == widget.date.year &&
                day.month == widget.date.month &&
                day.day == widget.date.day;
            return Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => widget.onDate(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: selected ? AppColors.green : Colors.white,
                      borderRadius: BorderRadius.circular(13)),
                  child: Column(children: [
                    Text(['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i],
                        style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : AppColors.ink)),
                    Text('${day.day}',
                        style: TextStyle(
                            fontSize: 18,
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ));
          })),
          const SizedBox(height: 12),
          WhiteCard(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                      child: Text('Итого за сегодня',
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Flexible(
                      child: Text('$kcal / ${widget.user.calorieTarget} ккал',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w700)))
                ]),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                    value: HealthCalculations.progress(
                        kcal, widget.user.calorieTarget),
                    color: AppColors.green,
                    backgroundColor: AppColors.pale),
                const SizedBox(height: 8),
                Text(
                    'Белки: ${HealthCalculations.totalProtein(widget.entries).round()} г    Жиры: ${HealthCalculations.totalFat(widget.entries).round()} г    Углеводы: ${HealthCalculations.totalCarbs(widget.entries).round()} г',
                    style: const TextStyle(fontSize: 10))
              ])),
          const SizedBox(height: 12),
          WhiteCard(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: search,
                          onChanged: onSearchChanged,
                          onSubmitted: (_) => submitSearch(),
                          textInputAction: TextInputAction.search,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: submitSearch,
                                  icon: const Icon(Icons.search),
                                  tooltip: 'Искать продукты'),
                              hintText: 'Поиск продукта по базе...',
                              isDense: true))),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                      onPressed: scan, icon: const Icon(Icons.qr_code_scanner))
                ]),
                if (searching) ...[
                  if (loading)
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()),
                  for (final p in results)
                    ListTile(
                        dense: true,
                        title: Text(p.name),
                        subtitle: Text(
                            '${p.kcal.round()} ккал  •  Б: ${p.protein.toStringAsFixed(1)} г  Ж: ${p.fat.toStringAsFixed(1)} г  У: ${p.carbs.toStringAsFixed(1)} г / 100 г'),
                        onTap: () => add('Перекус', selectedProduct: p)),
                  if (searchError != null)
                    ListTile(
                        title: Text(searchError!),
                        subtitle: const Text(
                            'Проверьте подключение и повторите поиск'),
                        trailing: TextButton(
                            onPressed: submitSearch,
                            child: const Text('Повторить'))),
                  if (!loading && searchError == null && results.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Продукты не найдены')),
                ]
              ])),
          const SizedBox(height: 12),
          for (final meal in ['Завтрак', 'Обед', 'Перекус', 'Ужин'])
            Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _MealCard(
                    meal: meal,
                    entries:
                        widget.entries.where((e) => e.meal == meal).toList(),
                    onAdd: () => add(meal),
                    onDelete: (id) async {
                      await widget.repository.deleteEntry(id);
                      widget.onChange();
                    })),
        ]);
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(
      {required this.meal,
      required this.entries,
      required this.onAdd,
      required this.onDelete});
  final String meal;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  @override
  Widget build(BuildContext context) => WhiteCard(
      padding: const EdgeInsets.all(12),
      child: ExpansionTile(
        initiallyExpanded: entries.isNotEmpty,
        tilePadding: EdgeInsets.zero,
        leading: CircleAvatar(
            backgroundColor: AppColors.mint,
            child: Icon(
                meal == 'Завтрак'
                    ? Icons.wb_twilight
                    : meal == 'Обед'
                        ? Icons.wb_sunny_outlined
                        : meal == 'Ужин'
                            ? Icons.nightlight_outlined
                            : Icons.eco_outlined,
                color: AppColors.green)),
        title: Text(meal, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            '${entries.fold<double>(0, (s, e) => s + e.kcal).round()} ккал',
            style: const TextStyle(color: AppColors.green)),
        children: [
          for (final e in entries)
            Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFE1FBEE),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(e.product.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                            '${e.grams.round()} г  •  Б: ${e.protein.round()} г   Ж: ${e.fat.round()} г   У: ${e.carbs.round()} г',
                            style: const TextStyle(fontSize: 10))
                      ])),
                  Text('${e.kcal.round()} ккал',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  IconButton(
                      onPressed: () => onDelete(e.id),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Удалить продукт')
                ])),
          TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: Text('Добавить в ${meal.toLowerCase()}'))
        ],
      ));
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet(
      {required this.products,
      this.initialProduct,
      required this.meal,
      required this.date,
      required this.repository,
      required this.onDone});
  final List<Product> products;
  final Product? initialProduct;
  final String meal;
  final DateTime date;
  final HealthRepository repository;
  final VoidCallback onDone;
  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  Product? selected;
  @override
  void initState() {
    super.initState();
    selected = widget.initialProduct;
  }

  final grams = TextEditingController(text: '100');
  @override
  void dispose() {
    grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Добавить в ${widget.meal.toLowerCase()}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SizedBox(
                height: 240,
                child: RadioGroup<Product>(
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                    child: ListView(children: [
                      for (final p in widget.products)
                        RadioListTile<Product>(
                            title: Text(p.name),
                            subtitle: Text('${p.kcal.round()} ккал / 100 г'),
                            value: p)
                    ]))),
            TextField(
                controller: grams,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Вес, г')),
            const SizedBox(height: 12),
            PrimaryButton(
                text: 'Сохранить продукт',
                onPressed: selected == null
                    ? null
                    : () async {
                        final amount =
                            double.tryParse(grams.text.replaceAll(',', '.'));
                        if (amount == null || amount <= 0) return;
                        await widget.repository.addEntry(
                            selected!, widget.meal, amount, widget.date);
                        widget.onDone();
                        if (context.mounted) Navigator.pop(context);
                      })
          ]));
}

class _NewProductDialog extends StatefulWidget {
  const _NewProductDialog({required this.repository, required this.barcode});
  final HealthRepository repository;
  final String barcode;
  @override
  State<_NewProductDialog> createState() => _NewProductDialogState();
}

class _NewProductDialogState extends State<_NewProductDialog> {
  final name = TextEditingController();
  final kcal = TextEditingController();
  final protein = TextEditingController();
  final fat = TextEditingController();
  final carbs = TextEditingController();
  @override
  void dispose() {
    for (final c in [name, kcal, protein, fat, carbs]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    double? number(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.'));
    final values = [kcal, protein, fat, carbs].map(number).toList();
    if (name.text.trim().isEmpty || values.any((v) => v == null || v < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните название и КБЖУ на 100 г')));
      return;
    }
    await widget.repository.addProduct(
        name: name.text,
        kcal: values[0]!,
        protein: values[1]!,
        fat: values[2]!,
        carbs: values[3]!,
        barcode: widget.barcode);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Новый продукт'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Штрихкод: ${widget.barcode}'),
          const SizedBox(height: 10),
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Название')),
          const SizedBox(height: 8),
          TextField(
              controller: kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ккал на 100 г')),
          const SizedBox(height: 8),
          TextField(
              controller: protein,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Белки на 100 г')),
          const SizedBox(height: 8),
          TextField(
              controller: fat,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Жиры на 100 г')),
          const SizedBox(height: 8),
          TextField(
              controller: carbs,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Углеводы на 100 г')),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          FilledButton(onPressed: save, child: const Text('Сохранить'))
        ],
      );
}

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();
  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  bool found = false;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Сканирование штрихкода')),
      body: MobileScanner(onDetect: (capture) {
        if (found) return;
        final value = capture.barcodes.firstOrNull?.rawValue;
        if (value == null) return;
        found = true;
        Navigator.pop(context, value);
      }));
}
