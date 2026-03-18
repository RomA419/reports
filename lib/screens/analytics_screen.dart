import 'package:flutter/material.dart';
import 'dart:math';

// ИСПРАВЛЕННЫЕ ИМПОРТЫ:
import 'package:car_care/models/car_model.dart';
import 'package:car_care/configs/car_config.dart';

class AnalyticsScreen extends StatefulWidget {
  final Car car;
  const AnalyticsScreen({super.key, required this.car});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Метод для добавления расхода
  void _addExpense(String category, double amount) {
    setState(() {
      widget.car.expenses.add(Expense(
        category: category,
        amount: amount,
        date: DateTime.now(),
      ));
    });
    // Тут в будущем можно добавить сохранение в базу данных (Hive/SharedPrefs)
  }

  // Диалог ввода суммы
  void _showAddExpenseDialog(String category) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CarConfig.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("ДОБАВИТЬ: $category", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Введите сумму (₸)",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: CarConfig.accentBlue)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ОТМЕНА")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CarConfig.accentBlue),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addExpense(category, double.parse(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text("ОК"),
          ),
        ],
      ),
    );
  }

  // Меню выбора типа траты
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CarConfig.primaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("ЧТО ОПЛАТИЛИ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
GridView.count(
  shrinkWrap: true,
  crossAxisCount: 2,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: 2.5,
  children: [
    _categoryBtn("Бензин", Icons.local_gas_station, Colors.orangeAccent),
    _categoryBtn("Запчасти", Icons.settings_suggest, Colors.redAccent),
    _categoryBtn("Мойка", Icons.waves, Colors.lightBlueAccent),
    // ИСПРАВЛЕНО: auto_awesome вместо AutoAwesome
    _categoryBtn("Тюнинг", Icons.auto_awesome, Colors.purpleAccent), 
  ],
),
          ],
        ),
      ),
    );
  }

  Widget _categoryBtn(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        Navigator.pop(context);
        _showAddExpenseDialog(label);
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Считаем суммы по категориям динамически
    Map<String, double> categoryTotals = {};
    for (var e in widget.car.expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    // Если данных нет, график не упадет, а покажет пустой круг
    if (categoryTotals.isEmpty) {
      categoryTotals["Нет данных"] = 0.0001; 
    }

    return Scaffold(
      backgroundColor: CarConfig.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("АНАЛИТИКА: ${widget.car.name.toUpperCase()}", 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCategoryPicker,
        backgroundColor: CarConfig.accentNeon,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("ДОБАВИТЬ ТРАТУ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 25, 25, 100),
        child: Column(
          children: [
            // Кастомный График
            SdartChart(data: categoryTotals),
            
            const SizedBox(height: 40),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("ДЕТАЛИЗАЦИЯ", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            
            if (widget.car.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("Трат пока нет. Нажмите +, чтобы добавить.", style: TextStyle(color: Colors.white24)),
              ),

            ...categoryTotals.entries.where((e) => e.value > 0.01).map((entry) => 
              _buildStatRow(entry.key, entry.value, widget.car.totalExpenses)
            ).toList(),
            
            const SizedBox(height: 30),
            _buildTotalCard(widget.car.totalExpenses),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double amount, double total) {
    double percent = total > 0 ? (amount / total) * 100 : 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CarConfig.cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 12, color: _getCategoryColor(label)),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${amount.toInt()} ₸", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${percent.toStringAsFixed(1)}%", style: TextStyle(color: CarConfig.accentNeon, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [CarConfig.accentBlue, const Color(0xFF4A00E0)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: CarConfig.accentBlue.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text("ИТОГО ПОТРАЧЕНО", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          Text("${total.toInt()} ₸", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Бензин': return Colors.orangeAccent;
      case 'Запчасти': return Colors.redAccent;
      case 'Мойка': return Colors.lightBlueAccent;
      case 'Тюнинг': return Colors.purpleAccent;
      default: return CarConfig.accentNeon;
    }
  }
}

// РИСУЕМ ГРАФИК
class SdartChart extends StatelessWidget {
  final Map<String, double> data;
  const SdartChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: 220,
      child: CustomPaint(
        painter: PiePainter(data),
        child: Center(
          child: Icon(Icons.speed_rounded, color: CarConfig.accentNeon.withOpacity(0.2), size: 60),
        ),
      ),
    );
  }
}

class PiePainter extends CustomPainter {
  final Map<String, double> data;
  PiePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    double total = data.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return;

    double startAngle = -pi / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * pi;
      if (sweepAngle == 0) return;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..color = _getColor(key);

      // Рисуем тень для объема
      canvas.drawArc(rect.deflate(12), startAngle, sweepAngle, false, 
        Paint()..color = _getColor(key).withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 35..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

      canvas.drawArc(rect.deflate(12), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }

  Color _getColor(String cat) {
    if (cat == 'Бензин') return Colors.orangeAccent;
    if (cat == 'Запчасти') return Colors.redAccent;
    if (cat == 'Мойка') return Colors.lightBlueAccent;
    if (cat == 'Тюнинг') return Colors.purpleAccent;
    return Colors.grey.withOpacity(0.2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}