import 'package:flutter/material.dart';

// ИСПОЛЬЗУЕМ ПОЛНЫЕ ПУТИ (Package Imports)
import 'package:car_care/models/car_model.dart';
import 'package:car_care/configs/car_config.dart';
import 'package:car_care/screens/analytics_screen.dart';
import 'package:car_care/screens/home_screen.dart';
import 'package:car_care/screens/qr_scan_screen.dart';
import 'package:car_care/screens/qr_screen.dart';
import 'package:car_care/screens/chat_screen.dart';
import 'package:car_care/screens/detail_screen.dart';
import 'package:car_care/screens/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class MyCarScreen extends StatefulWidget {
  const MyCarScreen({super.key});
  @override
  State<MyCarScreen> createState() => _MyCarScreenState();
}

class _MyCarScreenState extends State<MyCarScreen> {
  late Car car;
  List<MaintenanceLog> _maintenanceLogs = [];

  Future<void> _loadCarDetails() async {
    if (car.id == null) return;

    final logs = await DatabaseHelper.instance.getMaintenanceForCar(car.id!);
    setState(() {
      _maintenanceLogs = logs.map((l) {
        return MaintenanceLog(
          id: l['id'] as int?,
          carId: car.id!,
          title: l['title'] ?? '',
          place: l['place'] ?? '',
          date: l['date'] ?? '',
          price: l['price'] ?? '',
          tag: l['tag'] ?? '',
          mileage: l['mileage'] ?? car.mileage,
        );
      }).toList();
    });
  }

  Future<void> _open2GIS(String query) async {
    final Uri url = Uri.parse('https://2gis.ru/karaganda/search/$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showToast("Не удалось открыть карту");
    }
  }

  // МЕНЮ СЕРВИСА
  void _showServiceMenu(Car car) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CarConfig.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('ОБСЛУЖИВАНИЕ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            
            _serviceOption(Icons.oil_barrel, "Заменил масло", "Сбросить износ масла", Colors.orange, () {
              setState(() => car.lastOilChange = car.mileage);
              Navigator.pop(context);
              _showToast("Масло обновлено!");
            }),
            
            _serviceOption(Icons.ac_unit, "Заменил антифриз", "Сбросить систему охлаждения", Colors.blue, () {
              setState(() => car.lastAntifreezeChange = car.mileage);
              Navigator.pop(context);
              _showToast("Антифриз обновлен!");
            }),

            _serviceOption(Icons.fact_check, "Продлить техосмотр", "Установить на 2027 год", Colors.green, () {
              setState(() {
                // Теперь дата реально меняется в модели
                car.nextTehosmotr = "02.2027";
              });
              Navigator.pop(context);
              _showToast("Техосмотр продлен до 2027 года!");
            }),
          ],
        ),
      ),
    );
  }

  Widget _serviceOption(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: onTap,
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: CarConfig.accentBlue, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    car = ModalRoute.of(context)!.settings.arguments as Car;
    _loadCarDetails();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    bool isWide = size.width > 800;

    return Scaffold(
      backgroundColor: CarConfig.primaryDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: CarConfig.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(car.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: car.name, child: Image.asset(car.image, fit: BoxFit.cover)),
                  const DecoratedBox(decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, 
                    colors: [Colors.transparent, CarConfig.primaryDark]))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // СДЕЛАЛИ DASHBOARD КЛИКАБЕЛЬНЫМ ДЛЯ ПРОСМОТРА ИНФО
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/detail', arguments: car),
                    child: _buildPremiumDashboard(car),
                  ),
                  const SizedBox(height: 25),
                  const Text("ТЕХНИЧЕСКОЕ СОСТОЯНИЕ", style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 12)),
                  const SizedBox(height: 15),
                  _adaptiveProgress("Ресурс масла", car.oilLife, isWide),
                  _adaptiveProgress("Ресурс антифриза", car.antifreezeLife, isWide),
                  const SizedBox(height: 30),
                  const Text("БЫСТРЫЕ ДЕЙСТВИЯ (КАРАГАНДА)", style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 12)),
                  const SizedBox(height: 15),
                  _buildServiceGrid(car), 
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showUpdateMileageDialog(car),
                      style: ElevatedButton.styleFrom(backgroundColor: CarConfig.accentBlue, 
                      minimumSize: const Size(220, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      icon: const Icon(Icons.speed, color: Colors.white),
                      label: const Text("ОБНОВИТЬ ПРОБЕГ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // СЕТКА КНОПОК С ДОБАВЛЕННОЙ КНОПКОЙ "ИНФО"
  Widget _buildServiceGrid(Car car) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
      children: [
        _serviceBtn("АЗС", Icons.local_gas_station, Colors.green, () => _open2GIS("АЗС")),
        _serviceBtn("СЕРВИС", Icons.build_circle, Colors.orange, () => _showServiceMenu(car)),
        _serviceBtn("ИНФО", Icons.info_outline, Colors.blue, () {
          Navigator.pushNamed(context, '/detail', arguments: car);
        }),
        _serviceBtn("МОЙКА", Icons.waves, Colors.lightBlue, () => _open2GIS("Автомойка")),
      ],
    );
  }

  Widget _serviceBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildPremiumDashboard(Car car) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statItem("Налог КЗ", car.isElectric ? "0 ₸" : "~ 18 500 ₸", Icons.payments_outlined),
            _statItem("Пробег", "${car.mileage} км", Icons.shutter_speed),
          ]),
          const Divider(height: 30, color: Colors.white10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statItem("Страховка", "До 02.2027", Icons.shield_outlined),
            // ТЕПЕРЬ БЕРЕМ ДАТУ ИЗ МОДЕЛИ
            _statItem("Техосмотр", car.nextTehosmotr, Icons.fact_check_outlined),
          ]),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 14, color: CarConfig.accentBlue), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }

  Widget _adaptiveProgress(String label, double val, bool isWide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          Text("${(val * 100).toInt()}%", style: TextStyle(color: val > 0.9 ? Colors.redAccent : CarConfig.accentNeon, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: val, minHeight: 8, borderRadius: BorderRadius.circular(10), backgroundColor: Colors.white10, color: val > 0.9 ? Colors.redAccent : CarConfig.accentNeon),
      ]),
    );
  }

  void _showUpdateMileageDialog(Car car) {
    final controller = TextEditingController(text: car.mileage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CarConfig.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Обновить пробег', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА')),
          ElevatedButton(onPressed: () { setState(() { car.mileage = int.tryParse(controller.text) ?? car.mileage; }); Navigator.pop(context); }, child: const Text('ОК')),
        ],
      ),
    );
  }
}