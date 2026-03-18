import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart' as audio_player;

import 'package:car_care/models/car_model.dart';
import 'package:car_care/configs/car_config.dart';
import 'package:car_care/screens/analytics_screen.dart';
import 'database_helper.dart';

enum AppTheme { cyber, matrix, sport }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  AppTheme _currentTheme = AppTheme.cyber;

  // Контроллеры для добавления авто
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _carVolumeController = TextEditingController();
  final TextEditingController _carMileageController = TextEditingController();
  
  // Контроллеры магазина
  final TextEditingController _vinController = TextEditingController();
  
  // Контроллеры ТО
  final TextEditingController _serviceTaskController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();
  final TextEditingController _servicePlaceController = TextEditingController();

  // Состояние Damage Picker (Выбор зоны ремонта)
  String _selectedPart = "Кузов";

  // Данные профиля
  String _userName = "Driver Karaganda";
  String _userEmail = "volkswagen_fan@mail.kz";
  String _profilePic = 'https://i.pravatar.cc/300?img=11';

  // Настройки подключения
  String _selectedProtocol = 'ISO 15765-4';
  bool _autoConnect = false;
  bool _logToSqlite = false;

  // OpenAI API key
  String _openAiKey = '';

  // Спортивный профиль
  double _bodyWeight = 96;
  int _benchGoal = 150;
  final Set<String> _trainingDays = {'Пн', 'Ср', 'Пт'};

  // Техническая конфигурация авто
  String _oilSpec = '504/507';
  int _serviceIntervalKm = 7000;
  String _pressureUnit = 'Бар';
  String _tempUnit = '°C';
  String _powerUnit = 'кВт';

  // Управление бригадой
  bool _dispatchMode = false;

  // Каталог марок/моделей (динамический конфигуратор)
  final Map<String, Map<String, dynamic>> _brandCatalog = {
    'BMW': {
      'color': const Color(0xFF0066B2),
      'models': {
        'M5': 'assets/images/m5.png',
      },
    },
    'Toyota': {
      'color': const Color(0xFFEB0A16),
      'models': {
        'Land Cruiser 300': 'assets/images/300.png',
      },
    },
    'VW': {
      'color': const Color(0xFF00E5FF),
      'models': {
        'Passat CC': 'assets/images/passat.png',
      },
    },
    'Porsche': {
      'color': const Color(0xFFE10600),
      'models': {
        '911 Turbo S': 'assets/images/Porsche 911 Turbo S.png',
      },
    },
    'Tesla': {
      'color': const Color(0xFF00D9FF),
      'models': {
        'Model 3': 'assets/images/Tesla Model 3.png',
      },
    },
    'Mercedes': {
      'color': const Color(0xFF00A5E0),
      'models': {
        'AMG GT': 'assets/images/passat.png',
      },
    },
  };

  String _selectedBrand = 'BMW';
  String _selectedModel = 'M5';
  Color? _brandAccent;

  // Параллакс фона
  final ScrollController _scrollController = ScrollController();
  double _bgOffset = 0.0;

  // Звуковые эффекты
  final audio_player.AudioPlayer _audioPlayer = audio_player.AudioPlayer();

  // История ТО (локальная база)
  // Добавляем mileage и теги для прогноза износа
  final List<Map<String, String>> _maintenanceLogs = [
    {"title": "Chain replaced", "place": "Right Auto Parts", "date": "12.03.2026", "price": "28 000 ₸", "type": "check", "mileage": "124000", "tag": "chain"},
    {"title": "Замена масла", "place": "Right Auto Parts", "date": "15.01.2026", "price": "18 500 ₸", "type": "check", "mileage": "122500", "tag": "oil"},
    {"title": "Комплект фильтров", "place": "Right Auto Parts", "date": "15.01.2026", "price": "12 000 ₸", "type": "check", "mileage": "122500", "tag": "filters"},
    {"title": "Замена тормозных дисков", "place": "СТО Karaganda", "date": "10.12.2025", "price": "45 000 ₸", "type": "history", "mileage": "118000", "tag": "brakes"},
  ];

  // Динамический цвет темы
  Color get _accentColor {
    if (_brandAccent != null) return _brandAccent!;
    switch (_currentTheme) {
      case AppTheme.matrix:
        return const Color(0xFF00FF41); // Матрица
      case AppTheme.sport:
        return const Color(0xFFFF0000); // Спорт
      case AppTheme.cyber:
      default:
        return CarConfig.accentBlue; // Оригинал
    }
  }

  // --- УТИЛИТЫ ---
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showToast("Не удалось открыть ссылку");
      }
    } catch (e) {
      _showToast("Ошибка подключения: $e");
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  // Проигрывает короткий звук UI (клик/подтверждение)
  Future<void> _playClick() async {
    const clickUrl = 'https://assets.mixkit.co/sfx/preview/mixkit-fast-click-1116.mp3';
    try {
      await _audioPlayer.play(audio_player.UrlSource(clickUrl), volume: 0.8);
    } catch (_) {
      // Игнорируем ошибки воспроизведения
    }
  }

  Future<void> _loadSavedCars() async {
    final rows = await DatabaseHelper.instance.getCars();
    if (rows.isNotEmpty) {
      setState(() {
        myGarage.clear();
        myGarage.addAll(rows.map((row) {
          final int carId = row['id'] as int;
          final mileage = row['mileage'] ?? 0;

          DatabaseHelper.instance.getExpensesForCar(carId).then((expRows) {
            setState(() {
              final idx = myGarage.indexWhere((c) => c.id == carId);
              if (idx != -1) {
                myGarage[idx].expenses = expRows.map((e) {
                  return Expense(
                    category: e['category'] ?? 'Расход',
                    amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
                    date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
                    note: e['note'] ?? '',
                  );
                }).toList();
              }
            });
          });

          DatabaseHelper.instance.getMaintenanceForCar(carId).then((logs) {
            setState(() {
              final idx = myGarage.indexWhere((c) => c.id == carId);
              if (idx != -1) {
                myGarage[idx].maintenanceLogs = logs.map((l) {
                  return MaintenanceLog(
                    id: l['id'] as int?,
                    carId: carId,
                    title: l['title'] ?? '',
                    place: l['place'] ?? '',
                    date: l['date'] ?? '',
                    price: l['price'] ?? '',
                    tag: l['tag'] ?? '',
                    mileage: l['mileage'] ?? mileage,
                  );
                }).toList();
              }
            });
          });

          return Car(
            id: carId,
            name: row['name'] ?? 'Unknown',
            image: row['image'] ?? 'assets/images/passat.png',
            description: row['description'] ?? '',
            mileage: mileage,
            lastOilChange: row['lastOilChange'] ?? 0,
            lastAntifreezeChange: row['lastAntifreezeChange'] ?? 0,
            nextTehosmotr: row['nextTehosmotr'] ?? '05.2026',
            specs: [(row['volume'] ?? 'Не указан').toString()],
            consumables: [],
          );
        }).toList());
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _openAiKey = prefs.getString('openai_api_key') ?? '';
      _selectedBrand = prefs.getString('selected_brand') ?? _selectedBrand;
      _selectedModel = prefs.getString('selected_model') ?? _selectedModel;
      _brandAccent = _brandCatalog[_selectedBrand]?['color'] as Color? ?? _brandAccent;
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _bgOffset = _scrollController.offset * 0.25;
      });
    });
    _loadSettings();
    _loadSavedCars();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- SMART ALERTS (УМНЫЕ УВЕДОМЛЕНИЯ) ---
  Widget _buildSmartAlerts() {
    int temp = -25; // Имитация погоды для Караганды
    bool isCold = temp <= -20;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.fromLTRB(20, 110, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCold 
            ? [Colors.blue.withOpacity(0.5), Colors.cyan.withOpacity(0.2)]
            : [_accentColor.withOpacity(0.2), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isCold ? Colors.blueAccent : _accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: isCold ? Colors.blue.withOpacity(0.2) : _accentColor.withOpacity(0.1), blurRadius: 15)
        ]
      ),
      child: Row(
        children: [
          Icon(isCold ? Icons.ac_unit : Icons.wb_sunny, color: isCold ? Colors.white : _accentColor, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isCold ? "ВНИМАНИЕ: МОРОЗ $temp°C" : "СИСТЕМЫ В НОРМЕ",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 5),
                Text(isCold ? "Проверьте АКБ и активируйте прогрев" : "Удачной дороги, $_userName!",
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          if (isCold && myGarage.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () => _showTelemetryControl(myGarage[0]),
              child: const Text("ПРОГРЕВ", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  // --- ИИ ПРОГНОЗ ТО ---
  String _calculateNextTO(Car car) {
    int averageUsage = 45; // км в день в среднем
    int kmLeft = 10000 - (car.mileage % 10000);
    int daysLeft = kmLeft ~/ averageUsage;
    return "Ожидаемое ТО: через ~$daysLeft дней";
  }

  // --- DAMAGE PICKER ---
  Widget _buildDamagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("УКАЖИТЕ ЗОНУ ОБСЛУЖИВАНИЯ", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ["Двигатель", "Ходовая", "Кузов", "Салон", "Электрика"].map((part) {
            bool isSel = _selectedPart == part;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPart = part;
                  _serviceTaskController.text = "Ремонт: $part"; // Автозаполнение
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? _accentColor : Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? _accentColor : Colors.transparent)
                ),
                child: Text(part, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CarConfig.primaryDark,
      extendBodyBehindAppBar: true,
      drawer: _buildSideDrawer(),
      appBar: _buildAppBar(),
      body: _buildCurrentScreen(),
      floatingActionButton: _selectedIndex == 0 ? _buildNeonFab() : null,
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0: return _buildGarageGrid(); 
      case 1: return _buildShopScreen(); 
      case 2: return _buildProfileScreen(); 
      default: return _buildGarageGrid();
    }
  }

  // ==========================================
  // 1. ЭКРАН ГАРАЖА
  // ==========================================
  Widget _buildGarageGrid() {
    return Stack(
      children: [
        // Параллаксный фон (звездное небо / техно сетка)
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, -_bgOffset),
            child: CustomPaint(
              painter: _TechnoGridPainter(color: Colors.white12),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CarConfig.primaryDark.withOpacity(0.95), Colors.black],
            ),
          ),
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildSmartAlerts(),
              if (myGarage.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: Text("Гараж пуст. Нажми +", style: TextStyle(color: Colors.white24, fontSize: 18))),
                ),
              ...myGarage.asMap().entries.map((entry) => _buildCarCard(context, entry.value, entry.key)),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard(BuildContext context, Car car, int index) {
    double health = 1.0 - car.oilLife;
    bool isNetworkImage = car.image.startsWith('http');

    return GestureDetector(
      onLongPress: () => _confirmDelete(index),
      onTap: () => Navigator.pushNamed(context, '/my_car', arguments: car),
      child: Hero(
        tag: car.name,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
              image: isNetworkImage ? NetworkImage(car.image) as ImageProvider : AssetImage(car.image), 
              fit: BoxFit.cover
            ),
            boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.95), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(car.name.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                    GestureDetector(
                      onTap: () => _showTelemetryControl(car),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: _accentColor.withOpacity(0.5))
                        ),
                        child: Icon(Icons.shield_outlined, color: _accentColor, size: 26),
                      ),
                    ),
                  ],
                ),
                Text(_calculateNextTO(car), style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: health,
                          backgroundColor: Colors.white10,
                          color: health < 0.2 ? Colors.redAccent : _accentColor,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("${car.mileage} KM", style: const TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.none, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (health < 0.2)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("ТРЕБУЕТСЯ СРОЧНОЕ ТЕХОБСЛУЖИВАНИЕ", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. ЭКРАН МАГАЗИНА
  // ==========================================
  Widget _buildShopScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
              boxShadow: [BoxShadow(color: const Color(0xFF8E2DE2).withOpacity(0.4), blurRadius: 20)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SPECIAL OFFER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text("Скидка -15% на первый заказ в Right Auto Parts", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => _launchURL("https://kaspi.kz/shop/search/?text=Right%20Auto%20Parts"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  child: const Text("ПОЛУЧИТЬ СКИДКУ", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("ПОИСК ЗАПЧАСТЕЙ ПО VIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: CarConfig.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vinController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Введите 17 знаков VIN...",
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_vinController.text.isNotEmpty) {
                      _launchURL("https://kaspi.kz/shop/search/?text=${_vinController.text}");
                    } else {
                      _showToast("Введите VIN код");
                    }
                  },
                  icon: Icon(Icons.search_rounded, color: _accentColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("КАТЕГОРИИ RIGHT AUTO", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _buildCategoryTile(Icons.oil_barrel, "МАСЛА", "масло"),
              _buildCategoryTile(Icons.tire_repair, "ШИНЫ", "шины"),
              _buildCategoryTile(Icons.bolt, "СВЕЧИ", "свечи"),
              _buildCategoryTile(Icons.filter_alt, "ФИЛЬТРЫ", "фильтр"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(IconData icon, String label, String query) {
    return GestureDetector(
      onTap: () => _launchURL("https://kaspi.kz/shop/search/?text=Right%20Auto%20Parts%20$query"),
      child: Container(
        decoration: BoxDecoration(color: CarConfig.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accentColor, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. ЭКРАН ПРОФИЛЯ
  // ==========================================
  // Профайл пользователя (Cyberpunk / Minimal)
  Widget _buildProfileScreen() {
    double totalSpend = myGarage.isNotEmpty ? myGarage[0].totalExpenses : 0;
    final Car? activeCar = myGarage.isNotEmpty ? myGarage[0] : null;

    final Map<String, int> fitnessRecords = {
      "Best Bench": 145,
      "Deadlift": 210,
      "Max Torque": 780,
    };

    final List<Map<String, String>> serviceLogs = [
      {"title": "Chain replaced", "date": "12.03.2026"},
      {"title": "Oil change", "date": "02.03.2026"},
      {"title": "Battery cycle", "date": "28.02.2026"},
    ];

    return Stack(
      children: [
        Positioned(top: -50, right: -50, child: CircleAvatar(radius: 120, backgroundColor: _accentColor.withOpacity(0.05))),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accentColor, width: 3)),
                child: CircleAvatar(radius: 65, backgroundImage: NetworkImage(_profilePic)),
              ),
              const SizedBox(height: 16),
              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(_userEmail, style: TextStyle(color: _accentColor, letterSpacing: 1.2)),

              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge("ID: 8f2a-alim-01"),
                  const SizedBox(width: 10),
                  _buildBadge("REGION: 09 (KGD, KZ)"),
                ],
              ),

              const SizedBox(height: 18),
              if (activeCar != null) _buildActiveCarCard(activeCar),

              const SizedBox(height: 18),
              _buildSectionTitle("RECORDS"),
              _buildRecordsRow(fitnessRecords),

              const SizedBox(height: 18),
              _buildSectionTitle("СКОРОЕ ОБСЛУЖИВАНИЕ"),
              _buildServicePrediction(activeCar),
              const SizedBox(height: 12),
              _buildServiceLog(serviceLogs),

              const SizedBox(height: 18),
              _buildSectionTitle("Выбор протокола"),
              _buildProtocolSelector(),
              const SizedBox(height: 12),
              _buildToggleOption("Автоподключение", "Подключаться при запуске двигателя", _autoConnect, (value) => setState(() => _autoConnect = value)),
              const SizedBox(height: 12),
              _buildToggleOption("Логирование", "Записывать логи поездки в SQLite", _logToSqlite, (value) => setState(() => _logToSqlite = value)),

              const SizedBox(height: 22),
              _buildSectionTitle("Спортивный профиль"),
              _buildAthleteSettings(),

              const SizedBox(height: 22),
              _buildSectionTitle("Техническая конфигурация авто"),
              _buildCarConfigSettings(),

              const SizedBox(height: 22),
              _buildSectionTitle("Управление командой"),
              _buildTeamManagement(),

              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statMiniColumn("РАСХОДЫ", "${totalSpend.toInt()} ₸"),
                    Container(width: 1, height: 30, color: Colors.white10),
                    _statMiniColumn("ТО ЧЕРЕЗ", activeCar != null ? "${10000 - (activeCar.mileage % 10000)} км" : "N/A"),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              _buildGlassActionBtn(Icons.shopping_bag_outlined, "МОИ ЗАКАЗЫ", () => setState(() => _selectedIndex = 1)),
              _buildGlassActionBtn(Icons.analytics_outlined, "АНАЛИТИКА РАСХОДОВ", () {
                if (activeCar != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticsScreen(car: activeCar)));
                } else {
                  _showToast("Гараж пуст");
                }
              }),
              _buildGlassActionBtn(Icons.settings_suggest_outlined, "НАСТРОЙКИ АККАУНТА", _showEditProfileSheet),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildActiveCarCard(Car car) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(car.image, width: 80, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text("Пробег: ${car.mileage} км", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text("System OK", style: TextStyle(color: Colors.greenAccent.shade200, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsRow(Map<String, int> records) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: records.entries.map((entry) {
        final goal = entry.key == 'Best Bench' ? _benchGoal : null;
        final progress = goal != null ? (entry.value / goal).clamp(0.0, 1.0) : 0.0;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Text(entry.key, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 6),
                Text("${entry.value}", style: TextStyle(color: _accentColor, fontSize: 16, fontWeight: FontWeight.w900)),
                if (goal != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: _accentColor),
                  const SizedBox(height: 4),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}% от $goal",
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  DateTime _parseDate(String date) {
    final parts = date.split('.');
    if (parts.length != 3) return DateTime.now();
    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = int.tryParse(parts[2]) ?? DateTime.now().year;
    return DateTime(year, month, day);
  }

  Widget _buildServicePrediction(Car? car) {
    if (car == null) return const SizedBox.shrink();

    final chainLog = _maintenanceLogs.reversed.firstWhere(
      (log) => log['tag'] == 'chain',
      orElse: () => {},
    );

    if (chainLog.isEmpty) return const SizedBox.shrink();

    final lastDate = _parseDate(chainLog['date'] ?? '01.01.1970');
    final lastMileage = int.tryParse(chainLog['mileage'] ?? '') ?? car.mileage;

    const intervalDays = 365;
    const intervalKm = 20000;

    final daysSince = DateTime.now().difference(lastDate).inDays;
    final kmSince = (car.mileage - lastMileage).clamp(0, intervalKm);

    final daysRemain = (intervalDays - daysSince).clamp(0, intervalDays);
    final kmRemain = (intervalKm - kmSince).clamp(0, intervalKm);

    final wearPercent = (max(daysSince / intervalDays, kmSince / intervalKm)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Service Prediction", style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text("Цепь ГРМ (износ)", style: const TextStyle(color: Colors.white70, fontSize: 12))),
              Text("${(wearPercent * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: wearPercent, backgroundColor: Colors.white10, color: _accentColor),
          const SizedBox(height: 10),
          Text("До критической замены осталось: $daysRemain дн. / $kmRemain км", style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildServiceLog(List<Map<String, String>> logs) {
    return Column(
      children: logs.map((log) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: _accentColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text("${log['title']} - ${log['date']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Text("${log['date']}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProtocolSelector() {
    final protocols = ['ISO 15765-4', 'KWP2000'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_ethernet, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProtocol,
                dropdownColor: Colors.black87,
                isExpanded: true,
                items: protocols.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white70)))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedProtocol = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: _accentColor),
        ],
      ),
    );
  }

  Widget _buildAthleteSettings() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallLabel("Вес тела"),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _bodyWeight,
                  min: 60,
                  max: 120,
                  divisions: 60,
                  activeColor: _accentColor,
                  inactiveColor: Colors.white10,
                  label: "${_bodyWeight.toInt()} кг",
                  onChanged: (v) => setState(() => _bodyWeight = v),
                ),
              ),
              Text("${_bodyWeight.toInt()} кг", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmallLabel("Целевой жим"),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _benchGoal.toDouble(),
                  min: 100,
                  max: 220,
                  divisions: 12,
                  activeColor: _accentColor,
                  inactiveColor: Colors.white10,
                  label: "$_benchGoal кг",
                  onChanged: (v) => setState(() => _benchGoal = v.toInt()),
                ),
              ),
              Text("$_benchGoal кг", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmallLabel("Дни тренировок"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day) {
              final selected = _trainingDays.contains(day);
              return ChoiceChip(
                label: Text(day, style: TextStyle(color: selected ? Colors.black : Colors.white70)),
                selected: selected,
                backgroundColor: Colors.white10,
                selectedColor: _accentColor,
                onSelected: (value) {
                  setState(() {
                    if (value) _trainingDays.add(day); else _trainingDays.remove(day);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarConfigSettings() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallLabel("Тип масла / допуск"),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white70),
                  decoration: InputDecoration(
                    hintText: "504/507",
                    hintStyle: const TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  ),
                  controller: TextEditingController(text: _oilSpec),
                  onChanged: (v) => _oilSpec = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmallLabel("Интервал замены (км)"),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _serviceIntervalKm.toDouble(),
                  min: 3000,
                  max: 20000,
                  divisions: 17,
                  activeColor: _accentColor,
                  inactiveColor: Colors.white10,
                  label: "$_serviceIntervalKm км",
                  onChanged: (v) => setState(() => _serviceIntervalKm = v.toInt()),
                ),
              ),
              Text("$_serviceIntervalKm км", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmallLabel("Единицы измерения"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdownField("Давление", _pressureUnit, ['Бар', 'PSI'], (v) => setState(() => _pressureUnit = v)),
              _buildDropdownField("Темп", _tempUnit, ['°C', '°F'], (v) => setState(() => _tempUnit = v)),
              _buildDropdownField("Мощность", _powerUnit, ['кВт', 'л.с.'], (v) => setState(() => _powerUnit = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamManagement() {
    return Column(
      children: [
        _buildToggleOption("Режим выезда", "Включает пуш-уведомления о задачах бригады", _dispatchMode, (value) => setState(() => _dispatchMode = value)),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accentColor, minimumSize: const Size.fromHeight(50)),
          onPressed: () => _showToast("Обновление базы запчастей..."),
          child: const Text("Обновить базу запчастей с сервера", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: Colors.black87,
                isExpanded: true,
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(color: Colors.white70)))).toList(),
                onChanged: (v) => v != null ? onChanged(v) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statMiniColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: _accentColor, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildGlassActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            tileColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
            leading: Icon(icon, color: _accentColor),
            title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // МОДАЛКИ: ДОБАВЛЕНИЕ АВТО
  // ==========================================
  void _showAddCarSheet(BuildContext context) {
    // Динамический конфигуратор марки/модели + акцентного цвета
    final brands = _brandCatalog.keys.toList();
    String selectedBrand = _selectedBrand;
    String selectedModel = _selectedModel;
    String selectedImage = (_brandCatalog[selectedBrand]?['models'] as Map<String, String>? ?? {}).entries
            .firstWhere((e) => e.key == selectedModel, orElse: () => MapEntry('', 'assets/images/passat.png'))
            .value;
    Color selectedAccent = (_brandCatalog[selectedBrand]?['color'] as Color?) ?? _accentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CarConfig.cardDark,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 30, left: 25, right: 25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("КОНФИГУРАЦИЯ АВТО", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 25),

                  const Text("ШАГ 1: ВЫБОР МАРКИ С ИНТЕНСИВНЫМ АКЦЕНТОМ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDropdownField("Марка", selectedBrand, brands, (value) {
                        setSheetState(() {
                          selectedBrand = value;
                          selectedModel = (_brandCatalog[value]?['models'] as Map<String, String>?)?.keys.first ?? '';
                          selectedImage = (_brandCatalog[value]?['models'] as Map<String, String>?)?[selectedModel] ?? selectedImage;
                          selectedAccent = (_brandCatalog[value]?['color'] as Color?) ?? selectedAccent;

                          if (_nameController.text.isEmpty) {
                            _nameController.text = '$selectedBrand $selectedModel';
                          }
                        });
                      }),
                      const SizedBox(width: 12),
                      _buildDropdownField(
                        "Модель",
                        selectedModel,
                        (_brandCatalog[selectedBrand]?['models'] as Map<String, String>?)?.keys.toList() ?? [],
                        (value) {
                          setSheetState(() {
                            selectedModel = value;
                            selectedImage = (_brandCatalog[selectedBrand]?['models'] as Map<String, String>?)?[value] ?? selectedImage;
                            if (_nameController.text.isEmpty) {
                              _nameController.text = '$selectedBrand $selectedModel';
                            }
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedAccent.withOpacity(0.4)),
                        boxShadow: [BoxShadow(color: selectedAccent.withOpacity(0.2), blurRadius: 12, spreadRadius: 1)],
                      ),
                      child: Image.asset(selectedImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Марка и модель (напр: BMW X5)", labelStyle: TextStyle(color: Colors.white24), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10))),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _carVolumeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "Объем (напр: 3.0)", labelStyle: TextStyle(color: Colors.white24), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10))),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _carMileageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "Пробег (км)", labelStyle: TextStyle(color: Colors.white24), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: selectedAccent,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      _playClick();
                      if (_nameController.text.isNotEmpty) {
                        int mileage = int.tryParse(_carMileageController.text) ?? 0;
                        String volume = _carVolumeController.text.isEmpty ? "Не указан" : "${_carVolumeController.text} L";

                        int? newId;
                        try {
                          newId = await DatabaseHelper.instance.addCar(
                            _nameController.text,
                            selectedImage,
                            mileage,
                            _carVolumeController.text,
                            lastOilChange: mileage,
                            lastAntifreezeChange: mileage,
                            nextTehosmotr: "05.2026",
                          );

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selected_brand', selectedBrand);
                          await prefs.setString('selected_model', selectedModel);
                        } catch (e) {
                          // Игнорируем локальные ошибки
                        }

                        setState(() {
                          _selectedBrand = selectedBrand;
                          _selectedModel = selectedModel;
                          _brandAccent = selectedAccent;

                          myGarage.insert(
                            0,
                            Car(
                              id: newId,
                              name: _nameController.text,
                              image: selectedImage,
                              description: 'Двигатель: $volume',
                              mileage: mileage,
                              lastOilChange: mileage,
                              lastAntifreezeChange: mileage,
                              nextTehosmotr: "05.2026",
                              isElectric: false,
                              expenses: [], 
                              maintenanceLogs: [],
                              specs: [volume, 'Бензин', 'AWD'],
                              consumables: [
                                Consumable(name: 'Моторное масло 5W-40', recommendation: 'Рекомендуется синтетика', interval: '8 000 км', kmInterval: 8000.0),
                                Consumable(name: 'Воздушный фильтр', recommendation: 'Замена каждую весну', interval: '15 000 км', kmInterval: 15000.0),
                                Consumable(name: 'Свечи зажигания', recommendation: 'Иридиевые свечи', interval: '40 000 км', kmInterval: 40000.0),
                              ],
                            )
                          );
                        });

                        _nameController.clear();
                        _carVolumeController.clear();
                        _carMileageController.clear();
                        Navigator.pop(context);
                        _showToast("Автомобиль добавлен в гараж!");
                      } else {
                        _showToast("Введите марку автомобиля");
                      }
                    },
                    child: const Text("ДОБАВИТЬ В ГАРАЖ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // ИСТОРИЯ ОБСЛУЖИВАНИЯ (МОДАЛКА И ДОБАВЛЕНИЕ)
  // ==========================================
  void _showMaintenanceHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CarConfig.primaryDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ИСТОРИЯ ТО", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(
                    onPressed: () => _showAddServiceLogDialog(setModalState),
                    icon: Icon(Icons.add_circle_outline, color: _accentColor, size: 30),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _maintenanceLogs.length,
                  itemBuilder: (context, index) {
                    final log = _maintenanceLogs[index];
                    return _historyItem(
                      log["title"]!, 
                      log["place"]!, 
                      log["date"]!, 
                      log["price"]!, 
                      log["type"] == "check" ? Icons.check_circle : Icons.history
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddServiceLogDialog(Function setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CarConfig.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("НОВАЯ ЗАПИСЬ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDamagePicker(), // Внедрен умный выбор зоны
              const SizedBox(height: 15),
              _buildServiceField(_serviceTaskController, "Что сделали?", Icons.build),
              _buildServiceField(_servicePlaceController, "Где (СТО/Магазин)?", Icons.place),
              _buildServiceField(_servicePriceController, "Стоимость (₸)", Icons.payments),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ОТМЕНА")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            onPressed: () {
              if (_serviceTaskController.text.isNotEmpty) {
                final now = DateTime.now();
                final dateStr = "${now.day}.${now.month}.${now.year}";
                
                setState(() {
                  _maintenanceLogs.insert(0, {
                    "title": _serviceTaskController.text,
                    "place": _servicePlaceController.text.isEmpty ? "Частное обслуживание" : _servicePlaceController.text,
                    "date": dateStr,
                    "price": "${_servicePriceController.text} ₸",
                    "type": "check"
                  });
                });
                
                setModalState(() {});
                _serviceTaskController.clear();
                _servicePlaceController.clear();
                _servicePriceController.clear();
                Navigator.pop(context);
                _showToast("Запись успешно добавлена!");
              }
            }, 
            child: const Text("ДОБАВИТЬ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _buildServiceField(TextEditingController ctrl, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white24),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor.withOpacity(0.3))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
        ),
      ),
    );
  }

  Widget _historyItem(String title, String place, String date, String price, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: CarConfig.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: _accentColor, size: 24),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text("$date • $place", style: const TextStyle(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis),
                    ]
                  ),
                ),
              ],
            ),
          ),
          Text(price, style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // НАСТРОЙКИ ПРОФИЛЯ
  // ==========================================
  void _showEditProfileSheet() {
    final nameEdit = TextEditingController(text: _userName);
    final emailEdit = TextEditingController(text: _userEmail);

    List<String> avatars = [
      'https://i.pravatar.cc/300?img=11',
      'https://i.pravatar.cc/300?img=68',
      'https://i.pravatar.cc/300?img=59',
      'https://i.pravatar.cc/300?img=33',
      'https://i.pravatar.cc/300?img=12',
    ];
    String selectedAvatar = _profilePic;

    showModalBottomSheet(
      context: context,
      backgroundColor: CarConfig.cardDark,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 30, left: 30, right: 30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("НАСТРОЙКИ АККАУНТА", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  const SizedBox(height: 25),
                  const Text("АВАТАР ПРОФИЛЯ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: avatars.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedAvatar == avatars[index];
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedAvatar = avatars[index]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? _accentColor : Colors.transparent, width: 3)),
                            child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(avatars[index])),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: nameEdit, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Ваше имя", labelStyle: TextStyle(color: Colors.white24))),
                  const SizedBox(height: 10),
                  TextField(controller: emailEdit, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Ваш Email", labelStyle: TextStyle(color: Colors.white24))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: _openAiKey),
                    onChanged: (value) => _openAiKey = value,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "OpenAI API Key", labelStyle: TextStyle(color: Colors.white24)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _accentColor, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('openai_api_key', _openAiKey);

                        setState(() {
                          _userName = nameEdit.text;
                          _userEmail = emailEdit.text;
                          _profilePic = selectedAvatar;
                        });
                        Navigator.pop(context);
                        _showToast("Профиль успешно обновлен");
                      },
                      child: const Text("СОХРАНИТЬ ИЗМЕНЕНИЯ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // ТЕЛЕМЕТРИЯ (ДЕТАЛЬНАЯ КАК В ОРИГИНАЛЕ)
  // ==========================================
  void _showTelemetryControl(Car car) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Telemetry",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: CarConfig.cardDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: _accentColor.withOpacity(0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(car.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 30),
                  const Icon(Icons.security_rounded, color: Colors.greenAccent, size: 80),
                  const SizedBox(height: 10),
                  const Text("СИСТЕМА ПОД ОХРАНОЙ", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeleStat(Icons.battery_charging_full, "12.7V", "АКБ"),
                      _buildTeleStat(Icons.thermostat_rounded, "84°C", "ДВС"),
                      _buildTeleStat(Icons.ac_unit_rounded, "-15°C", "САЛОН"),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildTeleAction(Icons.power_settings_new_rounded, "АВТОЗАПУСК", Colors.orangeAccent, () {
                    Navigator.pop(context);
                    _showToast("Команда запуска отправлена...");
                  }),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTeleAction(Icons.lock_open_rounded, "ОТКРЫТЬ", Colors.white10, () => _showToast("Авто открыто"))),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTeleAction(Icons.lock_outline_rounded, "ЗАКРЫТЬ", _accentColor, () => _showToast("Авто закрыто"))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeleStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildTeleAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ОБЩИЙ UI И НАВИГАЦИЯ
  // ==========================================
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CarConfig.cardDark,
        title: const Text("Удалить авто?", style: TextStyle(color: Colors.white)),
        content: const Text("Это действие нельзя отменить.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ОТМЕНА")),
          TextButton(
              onPressed: () {
                setState(() => myGarage.removeAt(index));
                Navigator.pop(context);
                _showToast("Автомобиль удален");
              },
              child: const Text("УДАЛИТЬ", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _buildNeonFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
      ),
      child: FloatingActionButton(
        backgroundColor: _accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 35),
        onPressed: () {
          _playClick();
          _showAddCarSheet(context);
        },
      ),
    );
  }

  Widget _buildBottomNavbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      height: 75,
      decoration: BoxDecoration(
        color: CarConfig.cardDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.directions_car_rounded, 0),
          _navItem(Icons.shopping_bag_rounded, 1),
          _navItem(Icons.person_rounded, 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? _accentColor : Colors.white24, size: 32),
      onPressed: () {
        _playClick();
        setState(() => _selectedIndex = index);
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: ClipRect(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.transparent))),
      title: const Text('AUTO CORE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.palette_outlined, color: _accentColor),
          onPressed: () {
            setState(() {
              if (_currentTheme == AppTheme.cyber) _currentTheme = AppTheme.matrix;
              else if (_currentTheme == AppTheme.matrix) _currentTheme = AppTheme.sport;
              else _currentTheme = AppTheme.cyber;
            });
            _showToast("Тема оформления изменена");
          },
        )
      ],
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: CarConfig.primaryDark,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E1E26)),
            accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_userEmail),
            currentAccountPicture: CircleAvatar(backgroundImage: NetworkImage(_profilePic)),
          ),
          _drawerItem(Icons.map_outlined, "Карта СТО (2ГИС)", () => _launchURL("https://2gis.kz/karaganda/search/СТО")),
          _drawerItem(Icons.history_edu_rounded, "История обслуживания", () {
            Navigator.pop(context);
            _showMaintenanceHistory();
          }),
          _drawerItem(Icons.analytics_outlined, "Аналитика расходов", () {
            Navigator.pop(context);
            if (myGarage.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticsScreen(car: myGarage[0])));
            } else {
              _showToast("Сначала добавьте автомобиль");
            }
          }),
          _drawerItem(Icons.smart_toy, "ИИ МЕХАНИК", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/chat', arguments: myGarage.isNotEmpty ? myGarage[0] : null);
          }),
          _drawerItem(Icons.qr_code_scanner, "Сканировать QR", () async {
            Navigator.pop(context);
            final result = await Navigator.pushNamed(context, '/qr_scan');
            if (result != null && result is String) {
              final car = myGarage.firstWhere((c) => c.name == result, orElse: () => myGarage.isNotEmpty ? myGarage[0] : Car(
                name: 'Не найден',
                image: 'assets/images/passat.png',
                description: '',
                mileage: 0,
                lastOilChange: 0,
                specs: [],
                consumables: [],
              ));
              if (car.name != 'Не найден') {
                Navigator.pushNamed(context, '/my_car', arguments: car);
              } else {
                _showToast("Автомобиль не найден");
              }
            }
          }),
          _drawerItem(Icons.qr_code, "QR КОД", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/qr', arguments: myGarage.isNotEmpty ? myGarage[0] : null);
          }),
          const Spacer(),
          _drawerItem(Icons.info_outline_rounded, "О программе", () {
            Navigator.pop(context);
            _showAboutAppDialog();
          }),
          _drawerItem(Icons.logout, "Выход", () {
            Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
          }, color: Colors.redAccent),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: CarConfig.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(25),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Icon(Icons.directions_car, size: 50, color: _accentColor),
              const SizedBox(height: 10),
              const Text("AUTO CORE v2.0", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text("Твой персональный механик", style: TextStyle(color: _accentColor, fontSize: 12)),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView(
                  children: [
                    _buildInfoSection(Icons.garage, "Мой Гараж", "Главный экран приложения. Здесь вы можете добавить свой автомобиль, следить за его пробегом и состоянием масла."),
                    _buildInfoSection(Icons.shield_outlined, "Телеметрия", "Нажмите на иконку щита на карточке автомобиля, чтобы открыть панель управления."),
                    _buildInfoSection(Icons.shopping_bag, "Магазин", "Второй экран в нижнем меню. Позволяет искать запчасти по VIN коду."),
                    _buildInfoSection(Icons.history_edu, "История ТО", "Записывайте туда все ремонты, чтобы не забыть, когда и что вы меняли. Используйте функцию 'Выбор зоны обслуживания'."),
                    _buildInfoSection(Icons.analytics, "Аналитика", "Смотрите графики того, сколько денег уходит на обслуживание."),
                    _buildInfoSection(Icons.palette, "Темы оформления", "Нажмите на палитру в правом верхнем углу, чтобы сменить стиль приложения."),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accentColor, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => Navigator.pop(context),
                child: const Text("ЗАКРЫТЬ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        onTap: onTap);
  }
}

class _TechnoGridPainter extends CustomPainter {
  final Color color;

  _TechnoGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final step = 20.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Добавим ряды точек как звезды
    final dotPaint = Paint()..color = color.withOpacity(0.3);
    for (double x = 0; x < size.width; x += step * 2) {
      for (double y = 0; y < size.height; y += step * 2) {
        canvas.drawCircle(Offset(x + step / 2, y + step / 2), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
