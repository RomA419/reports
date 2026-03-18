import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:car_care/models/car_model.dart';

// =========================================================================
// 1. АРХИТЕКТУРА ДАННЫХ: ТЕХНИЧЕСКИЕ КАРТЫ АВТОМОБИЛЕЙ
// =========================================================================

class VehicleGlobalRegistry {
  static Map<String, dynamic> getSpec(String carName) {
    final String q = carName.toLowerCase();

    // --- PORSCHE 911 TURBO S ---
    if (q.contains("porsche") || q.contains("911")) {
      return {
        "id": "DE_POR_992",
        "fullName": "Porsche 911 Turbo S (992)",
        "imgPath": "assets/images/Porsche 911 Turbo S.png",
        "brandColor": const Color(0xFFE10600),
        "engineType": "3.8L Flat-6 Twin-Turbo",
        "performance": {"hp": 650, "torque": 800, "0-100": 2.7},
        "limits": {"boost": 2.8, "temp": 125.0, "rpm": 7500, "oil": 1.2},
        "parts": [
          {"n": "Тормозные диски PCCB", "p": 520000, "id": "POR-BRK-992", "info": "Керамика"},
          {"n": "Катушки зажигания", "p": 85000, "id": "POR-IGN-VTG", "info": "High Voltage"},
          {"n": "Масло Mobil1 C40", "p": 45000, "id": "OIL-0W40-P", "info": "8 литров"},
          {"n": "Фильтр масляный", "p": 12000, "id": "POR-FLT-01", "info": "Оригинал"},
          {"n": "Свечи зажигания", "p": 95000, "id": "POR-SPK-992", "info": "Iridium"}
        ],
        "manual": "Прогрев масла до 80°C обязателен перед активацией Launch Control. Система VTG требует контроля герметичности вакуумных линий.",
        "stations": ["Porsche Center Almaty", "TurboMaster Karaganda", "VAG-Prof Temirtau"]
      };
    }
    // --- TESLA MODEL 3 ---
    else if (q.contains("tesla") || q.contains("model 3")) {
      return {
        "id": "US_TSL_M3",
        "fullName": "Tesla Model 3 Performance",
        "imgPath": "assets/images/Tesla Model 3.png",
        "brandColor": Colors.white,
        "engineType": "Dual Motor AWD (Электро)",
        "performance": {"hp": 513, "torque": 660, "0-100": 3.3},
        "limits": {"boost": 0.0, "temp": 95.0, "rpm": 18000, "oil": 0.0},
        "parts": [
          {"n": "Салонный фильтр HEPA", "p": 32000, "id": "TSL-FIL-03", "info": "Bioweapon Defense"},
          {"n": "Рычаги подвески (перед)", "p": 180000, "id": "TSL-ARM-F", "info": "Enhanced"},
          {"n": "Охлаждающая жидкость АКБ", "p": 65000, "id": "TSL-COOL-01", "info": "Glycol"},
          {"n": "Резина Michelin PS4S", "p": 450000, "id": "TIRE-T0", "info": "Шумоподавление"},
          {"n": "Тормозные колодки", "p": 55000, "id": "TSL-BRK-P", "info": "Performance"}
        ],
        "manual": "Не допускайте глубокого разряда ниже 5%. Рекомендуется зарядка до 80% для ежедневных поездок. Проверка 12V АКБ раз в год.",
        "stations": ["Tesla Service Karaganda", "Electro-Kz Almaty", "Ev-Master TM"]
      };
    }
    // --- BMW M5 ---
    else if (q.contains("m5") || q.contains("bmw")) {
      return {
        "id": "DE_BMW_F90",
        "fullName": "BMW M5 Competition",
        "imgPath": "assets/images/m5.png",
        "brandColor": const Color(0xFF0066B2),
        "engineType": "4.4L V8 M TwinPower Turbo",
        "performance": {"hp": 625, "torque": 750, "0-100": 3.3},
        "limits": {"boost": 1.9, "temp": 118.0, "rpm": 7200, "oil": 1.5},
        "parts": [
          {"n": "Вкладыши шатунные", "p": 290000, "id": "BMW-M5-BRG", "info": "ACL Performance"},
          {"n": "ТНВД высокого давления", "p": 145000, "id": "BMW-HPFP-01", "info": "BOSCH"},
          {"n": "Масло 5W-40 M Twin", "p": 68000, "id": "M-OIL-V8", "info": "10 литров"},
          {"n": "Интеркулеры (пара)", "p": 380000, "id": "BMW-IC-M5", "info": "Water-Air"},
          {"n": "Колодки M-Carbon", "p": 110000, "id": "BMW-M-PAD", "info": "Sport"}
        ],
        "manual": "Двигатель S63 критичен к давлению масла. Замена вкладышей рекомендована на пробеге 80,000 км. Использовать только АИ-98/100.",
        "stations": ["Bavaria Karaganda", "M-Center Astana", "German-Auto Temirtau"]
      };
    }
    // --- CHRYSLER 300 ---
    else if (q.contains("300") || q.contains("chrysler")) {
      return {
        "id": "US_CHR_300",
        "fullName": "Chrysler 300 SRT-8",
        "imgPath": "assets/images/300.png",
        "brandColor": Colors.blueGrey,
        "engineType": "6.4L HEMI V8",
        "performance": {"hp": 470, "torque": 637, "0-100": 4.5},
        "limits": {"boost": 0.0, "temp": 108.0, "rpm": 6400, "oil": 0.8},
        "parts": [
          {"n": "Гидрокомпенсаторы", "p": 140000, "id": "CHR-HEMI-L", "info": "Mopar"},
          {"n": "Свечи (16 штук)", "p": 58000, "id": "CHR-SPK-16", "info": "NGK Iridium"},
          {"n": "Радиатор основной", "p": 115000, "id": "CHR-RAD-SRT", "info": "Heavy Duty"},
          {"n": "Сайлентблоки рычагов", "p": 45000, "id": "CHR-ARM-B", "info": "Polyurethane"}
        ],
        "manual": "Характерный стук (HEMI Tick) требует немедленной ревизии распредвала. Использовать масло 0W-40 с допуском MS-12633.",
        "stations": ["Mopar-Club Karaganda", "USA-Auto Astana", "G-Service"]
      };
    }
    // --- VOLKSWAGEN PASSAT (DEFAULT / ТВОЙ АВТО) ---
    return {
      "id": "DE_VW_B7",
      "fullName": "VW Passat CC 1.8 TSI",
      "imgPath": "assets/images/passat.png",
      "brandColor": const Color(0xFF00E5FF),
      "engineType": "1.8 TSI CDAB Gen2",
      "performance": {"hp": 152, "torque": 250, "0-100": 8.5},
      "limits": {"boost": 1.5, "temp": 110.0, "rpm": 6500, "oil": 1.2},
      "parts": [
        {"n": "Цепь ГРМ (комплект)", "p": 198000, "id": "VAG-06H-CHAIN", "info": "K-версия"},
        {"n": "Помпа водяная", "p": 85000, "id": "VAG-WP-MET", "info": "Металл"},
        {"n": "Маслоотделитель", "p": 42000, "id": "VAG-SEP-AD", "info": "Ревизия AJ"},
        {"n": "Катушки R8 Red", "p": 64000, "id": "VAG-R8-IGN", "info": "Stage 1 Upgrade"},
        {"n": "Масло 5W-30 504/507", "p": 38000, "id": "VAG-OIL-5", "info": "Castrol Edge"}
      ],
      "manual": "Проверка натяжителя цепи каждые 50,000 км. Очистка впускных клапанов от нагара (Carbon Cleaning) рекомендована раз в 60,000 км.",
      "stations": ["VAG-Service Karaganda", "AutoUnion", "Master-VAG Temirtau"]
    };
  }
}

// =========================================================================
// 2. ГЛАВНЫЙ КОМПОНЕНТ: ИНЖЕНЕРНАЯ КОНСОЛЬ
// =========================================================================

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {
  late Car carModel;
  late Map<String, dynamic> spec;
  bool isInitialized = false;

  // --- СОСТОЯНИЕ СИМУЛЯЦИИ ДВИГАТЕЛЯ ---
  double boostValue = 0.5;
  double engineTemp = 75.0;
  double fuelConsumption = 10.2;
  double engineHealth = 100.0;
  
  // --- КОНТРОЛЬ ИНТЕРФЕЙСА ---
  int activeTab = 0;
  bool dbBusy = false;
  double dbProgress = 0.0;
  final ScrollController _scrollController = ScrollController();
  
  // --- АНИМАЦИИ ---
  late AnimationController _pulseController;
  List<double> telemetryStream = List.generate(40, (index) => 0.3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      carModel = ModalRoute.of(context)!.settings.arguments as Car;
      spec = VehicleGlobalRegistry.getSpec(carModel.name);
      
      boostValue = spec['limits']['boost'] * 0.3;
      engineTemp = 85.0;
      isInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) _simulateEnginePhysics();
    });
  }

  void _simulateEnginePhysics() {
    setState(() {
      double noise = (math.Random().nextDouble() - 0.5) * 0.05;
      fuelConsumption = 8.0 + (boostValue * 12.0) + noise;
      
      if (boostValue > (spec['limits']['boost'] * 0.8)) {
        engineTemp += 0.2;
        engineHealth -= 0.01;
      } else if (engineTemp > 90) {
        engineTemp -= 0.1;
      }

      telemetryStream.add((0.2 + (boostValue / (spec['limits']['boost'] == 0 ? 1 : spec['limits']['boost']) * 0.6) + noise).clamp(0.0, 1.0));
      if (telemetryStream.length > 40) telemetryStream.removeAt(0);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 3. ОПЕРАЦИИ С БАЗОЙ ДАННЫХ (ИМИТАЦИЯ SQLITE)
  // =========================================================================

  Future<void> _syncWithSQLite() async {
    setState(() { dbBusy = true; dbProgress = 0.0; });

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 60));
      setState(() => dbProgress = i / 100);
    }

    setState(() => dbBusy = false);
    HapticFeedback.heavyImpact();
    _toast("Конфигурация [${spec['id']}] успешно записана в локальную БД SQLite.");
  }

  // =========================================================================
  // 4. ПОСТРОЕНИЕ ИНТЕРФЕЙСА
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final Color themeColor = spec['brandColor'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0E),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernSliverAppBar(themeColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildMainHeader(themeColor),
                      const SizedBox(height: 35),
                      _buildNavigationTabs(themeColor),
                      const SizedBox(height: 30),
                      
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (w, a) => FadeTransition(opacity: a, child: w),
                        child: _renderActiveView(themeColor),
                      ),
                      
                      const SizedBox(height: 160),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (dbBusy) _buildBlurLoader(themeColor),
          _buildActionDock(themeColor),
        ],
      ),
    );
  }

  Widget _renderActiveView(Color accent) {
    switch (activeTab) {
      case 0: return _viewDiagnosticConsole(accent);
      case 1: return _viewTechnicalWiki(accent);
      case 2: return _viewSparePartsMarket(accent);
      case 3: return _viewServiceLocations(accent);
      default: return const SizedBox.shrink();
    }
  }

  // --- ВКЛАДКА 1: ДИАГНОСТИКА ---
  Widget _viewDiagnosticConsole(Color accent) {
    return Column(key: const ValueKey(0), children: [
      _sectionTitle("ТЕЛЕМЕТРИЯ ДВИГАТЕЛЯ (ПРЯМОЙ ЭФИР)"),
      _buildLiveChart(accent),
      const SizedBox(height: 30),
      
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _buildMetricBlock("КПД", "${(engineHealth).toInt()}%", Colors.greenAccent),
        _buildMetricBlock("РАСХОД", "${fuelConsumption.toStringAsFixed(1)} Л", accent),
        _buildMetricBlock("ТЕМП", "${engineTemp.toInt()}°C", Colors.orangeAccent),
      ]),
      
      const SizedBox(height: 40),
      _sectionTitle("УПРАВЛЕНИЕ НАДДУВОМ (BOOST)"),
      
      _buildComplexSlider(
        label: "ЦЕЛЕВОЕ ДАВЛЕНИЕ ТУРБИНЫ",
        val: boostValue, min: 0.0, max: spec['limits']['boost'] == 0 ? 1.0 : spec['limits']['boost'],
        unit: "БАР", color: accent,
        onChanged: (v) => setState(() => boostValue = v)
      ),

      _buildComplexSlider(
        label: "ИНТЕНСИВНОСТЬ ОХЛАЖДЕНИЯ",
        val: engineTemp, min: 40.0, max: 120.0,
        unit: "°C", color: Colors.blueAccent,
        onChanged: (v) => setState(() => engineTemp = v)
      ),
      
      _buildHealthStatus(accent),
    ]);
  }

  // --- ВКЛАДКА 2: ТЕХНИЧЕСКИЙ WIKI ---
  Widget _viewTechnicalWiki(Color accent) {
    return Column(key: const ValueKey(1), children: [
      _sectionTitle("ЗАВОДСКИЕ ХАРАКТЕРИСТИКИ"),
      _buildInfoTile("Тип агрегата", spec['engineType'], Icons.memory, accent),
      _buildInfoTile("Мощность", "${spec['performance']['hp']} л.с.", Icons.layers_outlined, accent),
      _buildInfoTile("Крутящий момент", "${spec['performance']['torque']} Нм", Icons.layers, accent),
      _buildInfoTile("Разгон 0-100", "${spec['performance']['0-100']} сек", Icons.speed, accent),
      
      const SizedBox(height: 30),
      _sectionTitle("РЕГЛАМЕНТ ОБСЛУЖИВАНИЯ"),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: accent.withOpacity(0.1))
        ),
        child: Text(spec['manual'], style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 13)),
      ),
    ]);
  }

  // --- ВКЛАДКА 3: ЗАПЧАСТИ ---
  Widget _viewSparePartsMarket(Color accent) {
    List<dynamic> partsList = spec['parts'];
    int totalSum = partsList.fold(0, (sum, item) => sum + (item['p'] as int));

    return Column(key: const ValueKey(2), children: [
      _sectionTitle("АКТУАЛЬНЫЕ ЦЕНЫ (КАЗАХСТАН / ТЕНГЕ)"),
      ...partsList.map((p) => _buildPartItem(p, accent)).toList(),
      
      const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(color: Colors.white10)),
      
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(25)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("ИТОГО ЗА ТЕХ.ОБСЛУЖИВАНИЕ", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          Text("$totalSum ₸", style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w900)),
        ]),
      ),
    ]);
  }

  // --- ВКЛАДКА 4: КАРТА СЕРВИСОВ ---
  Widget _viewServiceLocations(Color accent) {
    List<String> shops = List<String>.from(spec['stations']);
    return Column(key: const ValueKey(3), children: [
      _sectionTitle("РЕКОМЕНДУЕМЫЕ СТО В ВАШЕМ РЕГИОНЕ"),
      ...shops.map((s) => _buildShopTile(s, accent)).toList(),
      const SizedBox(height: 20),
      _buildInfoTile("Регион обслуживания", "Карагандинская область", Icons.map, accent),
    ]);
  }

  // =========================================================================
  // 5. ATOMIC DESIGN SYSTEM (UI КОМПОНЕНТЫ)
  // =========================================================================

  Widget _buildModernSliverAppBar(Color color) => SliverAppBar(
    expandedHeight: 450,
    pinned: true,
    stretch: true,
    backgroundColor: const Color(0xFF0A0B0E),
    flexibleSpace: FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          _buildVehicleVisual(color),
          _buildLinearGradientOverlay(),
        ],
      ),
    ),
  );

  Widget _buildVehicleVisual(Color color) {
    return Hero(
      tag: carModel.name,
      child: Image.asset(
        spec['imgPath'],
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Center(
          child: Icon(Icons.car_repair, size: 100, color: color.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildLinearGradientOverlay() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, const Color(0xFF0A0B0E).withOpacity(0.9), const Color(0xFF0A0B0E)],
      ),
    ),
  );

  Widget _buildMainHeader(Color accent) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(spec['fullName'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 6),
        Row(children: [
          _buildPulseDot(accent),
          const SizedBox(width: 10),
          Text("СИСТЕМА ТЕЛЕМЕТРИИ: ОНЛАЙН", style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ]),
      ]),
      _buildIdBadge(spec['id'], accent),
    ],
  );

  Widget _buildNavigationTabs(Color accent) {
    final List<String> navs = ["ДАТЧИКИ", "ИНФО", "ДЕТАЛИ", "СТО"];
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: List.generate(4, (i) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(color: activeTab == i ? accent : Colors.transparent, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(navs[i], style: TextStyle(color: activeTab == i ? Colors.black : Colors.white24, fontWeight: FontWeight.w900, fontSize: 9)),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildMetricBlock(String l, String v, Color c) => Container(
    width: (MediaQuery.of(context).size.width / 3) - 26,
    padding: const EdgeInsets.symmetric(vertical: 22),
    decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(25)),
    child: Column(children: [
      Text(l, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Text(v, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w900)),
    ]),
  );

  Widget _buildComplexSlider({required String label, required double val, required double min, required double max, required String unit, required Color color, required Function(double) onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
          Text("${val.toStringAsFixed(2)} $unit", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        Slider(value: val, min: min, max: max, activeColor: color, inactiveColor: Colors.white10, onChanged: onChanged),
      ]),
    );
  }

  Widget _buildPartItem(Map<String, dynamic> p, Color c) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      CircleAvatar(backgroundColor: c.withOpacity(0.1), radius: 22, child: Icon(Icons.settings_suggest, color: c, size: 20)),
      const SizedBox(width: 18),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p['n'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(p['id'], style: const TextStyle(color: Colors.white24, fontSize: 11)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text("${p['p']} ₸", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        Text(p['info'], style: TextStyle(color: c, fontSize: 9)),
      ]),
    ]),
  );

  Widget _buildInfoTile(String l, String v, IconData i, Color a) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      Icon(i, color: a, size: 22),
      const SizedBox(width: 18),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    ]),
  );

  Widget _buildShopTile(String n, Color a) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      Icon(Icons.location_on, color: a),
      const SizedBox(width: 15),
      Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      const Spacer(),
      const Icon(Icons.star, color: Colors.amber, size: 16),
      const Text(" 4.9", style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]),
  );

  Widget _buildLiveChart(Color color) => Container(
    height: 160,
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(30)),
    child: CustomPaint(painter: TelemetryPainter(telemetryStream, color)),
  );

  Widget _buildPulseDot(Color c) => FadeTransition(opacity: _pulseController, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)));

  Widget _buildIdBadge(String id, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: c.withOpacity(0.3))),
    child: Text(id, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _sectionTitle(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(padding: const EdgeInsets.only(bottom: 22), child: Text(t, style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold))),
  );

  Widget _buildHealthStatus(Color accent) => Padding(
    padding: const EdgeInsets.only(top: 25),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("ОБЩЕЕ СОСТОЯНИЕ АГРЕГАТОВ", style: TextStyle(color: Colors.white24, fontSize: 9)),
        Text("${engineHealth.toInt()}%", style: TextStyle(color: engineHealth < 80 ? Colors.red : accent, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      LinearProgressIndicator(value: engineHealth / 100, color: engineHealth < 80 ? Colors.red : accent, backgroundColor: Colors.white10, minHeight: 6),
    ]),
  );

  Widget _buildBlurLoader(Color accent) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 250, child: LinearProgressIndicator(value: dbProgress, color: accent, backgroundColor: Colors.white10)),
        const SizedBox(height: 30),
        Text("ЗАПИСЬ В SQLITE: ${(dbProgress * 100).toInt()}%", style: const TextStyle(color: Colors.white, letterSpacing: 5, fontSize: 10)),
      ])),
    ),
  );

  Widget _buildActionDock(Color accent) => Positioned(
    bottom: 40, left: 30, right: 30,
    child: ElevatedButton(
      onPressed: _syncWithSQLite,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent, foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 75),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 15, shadowColor: accent.withOpacity(0.5),
      ),
      child: const Text("СОХРАНИТЬ В БОРТОВОЙ ЖУРНАЛ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
    ),
  );

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: spec['brandColor'], behavior: SnackBarBehavior.floating));
}

// =========================================================================
// 6. ГРАФИКА: ОТРИСОВКА ТЕЛЕМЕТРИИ
// =========================================================================

class TelemetryPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  TelemetryPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.25), Colors.transparent]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    double spacing = size.width / (data.length - 1);
    
    path.moveTo(0, size.height * (1 - data[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - data[0]));

    for (int i = 1; i < data.length; i++) {
      path.lineTo(spacing * i, size.height * (1 - data[i]));
      fillPath.lineTo(spacing * i, size.height * (1 - data[i]));
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}