// 1. Модель расхода
class Expense {
  final String category; 
  final double amount;
  final DateTime date;
  final String note;

  Expense({
    required this.category,
    required this.amount,
    required this.date,
    this.note = "",
  });
}

// 2. Модель расходников
class Consumable {
  final String name;
  final String recommendation;
  final String interval;
  final double kmInterval;

  Consumable({
    required this.name, 
    required this.recommendation, 
    required this.interval,
    required this.kmInterval,
  });
}

// 3. Лог (ТО) и расходные записи
class MaintenanceLog {
  final int? id;
  final int carId;
  final String title;
  final String place;
  final String date;
  final String price;
  final String tag;
  final int mileage;

  MaintenanceLog({
    this.id,
    required this.carId,
    required this.title,
    required this.place,
    required this.date,
    required this.price,
    required this.tag,
    required this.mileage,
  });
}

// 4. Главный класс машины
class Car {
  final int? id;
  final String name;
  final String image;
  final String? model3d; // Твое поле для 3D моделей
  final String description;
  
  int mileage;
  int lastOilChange;
  int lastAntifreezeChange;
  String nextTehosmotr; 
  
  final List<String> specs;
  final List<Consumable> consumables;
  final bool isElectric;
  List<Expense> expenses;
  List<MaintenanceLog> maintenanceLogs;

  Car({
    this.id,
    required this.name,
    required this.image,
    this.model3d,
    required this.description,
    required this.mileage,
    required this.lastOilChange,
    this.lastAntifreezeChange = 0,
    this.nextTehosmotr = "05.2026",
    required this.specs,
    required this.consumables,
    this.isElectric = false,
    List<Expense>? expenses,
    List<MaintenanceLog>? maintenanceLogs,
  }) : this.expenses = expenses ?? [],
       this.maintenanceLogs = maintenanceLogs ?? [];

  // Расчет износа масла
  double get oilLife {
    if (isElectric) return 0.0;
    double interval = 8000.0;
    try {
      interval = consumables
          .firstWhere((c) => c.name.contains('Масло'))
          .kmInterval;
    } catch (_) {}
    return ((mileage - lastOilChange) / interval).clamp(0.0, 1.0);
  }

  // Расчет износа антифриза
  double get antifreezeLife {
    return ((mileage - lastAntifreezeChange) / 40000).clamp(0.0, 1.0);
  }

  // Финансовая аналитика
  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item.amount);

  double get fuelExpenses {
    return expenses
        .where((e) => e.category == 'Бензин' || e.category == 'Зарядка')
        .fold(0, (sum, item) => sum + item.amount);
  }
  
  void updateMileage(int newKm) {
    if (newKm >= mileage) mileage = newKm;
  }

  void addExpense(String category, double amount, {String note = ""}) {
    expenses.add(Expense(
      category: category,
      amount: amount,
      date: DateTime.now(),
      note: note,
    ));
  }
}

// 4. ТВОЙ ПОЛНЫЙ ГАРАЖ (ВЕСЬ СПИСОК)
List<Car> myGarage = [
  Car(
    name: 'Volkswagen Passat CC',
    image: 'assets/images/passat.png',
    // Using shared demo 3D model (same .glb shown for all cars)
    model3d: 'assets/models/tesla.glb',
    description: 'Немецкое купе бизнес-класса. 1.8 TSI CDAB.',
    mileage: 125000,
    lastOilChange: 118000,
    lastAntifreezeChange: 100000,
    specs: ['1.8 TSI', 'DSG-7', '152 л.с.', '2012 г.'],
    consumables: [
      Consumable(name: 'Масло ДВС', recommendation: '5W-30 VW 504/507', interval: '8 000 км', kmInterval: 8000),
    ],
    expenses: [
      Expense(category: 'Бензин', amount: 12500, date: DateTime.now(), note: 'Helios'),
    ],
  ),
  Car(
    name: 'BMW M5 F90',
    image: 'assets/images/m5.png',
    // Using shared demo 3D model (same .glb shown for all cars)
    model3d: 'assets/models/tesla.glb',
    description: 'Спортивный седан 600 л.с.',
    mileage: 45000,
    lastOilChange: 44000,
    lastAntifreezeChange: 30000,
    specs: ['4.4 V8 Twin-Turbo', '600 л.с.', '2020 г.'],
    consumables: [
      Consumable(name: 'Масло ДВС', recommendation: '0W-30 BMW M', interval: '5 000 км', kmInterval: 5000),
    ],
    expenses: [
      Expense(category: 'Бензин', amount: 25000, date: DateTime.now(), note: 'Qazaq Oil'),
    ],
  ),
  Car(
    name: 'Toyota Land Cruiser 300',
    image: 'assets/images/300.png',
    // Using shared demo 3D model (same .glb shown for all cars)
    model3d: 'assets/models/tesla.glb',
    description: 'Внедорожник для любых путей.',
    mileage: 15000,
    lastOilChange: 10000,
    specs: ['3.3 V6 Diesel', '299 л.с.', '2023 г.'],
    consumables: [
      Consumable(name: 'Масло ДВС', recommendation: '5W-30 Toyota', interval: '10 000 км', kmInterval: 10000),
    ],
    expenses: [
      Expense(category: 'Бензин', amount: 18000, date: DateTime.now(), note: 'Дизель'),
    ],
  ),
  Car(
    name: 'Tesla Model 3',
    image: 'assets/images/Tesla Model 3.png', 
    model3d: 'assets/models/tesla.glb',
    description: 'Электрический инновационный седан.',
    mileage: 30000,
    lastOilChange: 0,
    isElectric: true,
    specs: ['Dual Motor', 'Long Range', '450 л.с.', '2021 г.'],
    consumables: [
      Consumable(name: 'Фильтр салона', recommendation: 'Tesla HEPA', interval: '2 года', kmInterval: 40000),
    ],
    expenses: [
      Expense(category: 'Зарядка', amount: 2000, date: DateTime.now()),
    ],
  ),
  Car(
    name: 'Porsche 911 Turbo S',
    image: 'assets/images/Porsche 911 Turbo S.png', 
    // Using shared demo 3D model (same .glb shown for all cars)
    model3d: 'assets/models/tesla.glb',
    description: 'Икона спортивных автомобилей.',
    mileage: 5000,
    lastOilChange: 4500,
    specs: ['3.8 Flat-6', 'PDK', '650 л.с.', '2022 г.'],
    consumables: [
      Consumable(name: 'Масло ДВС', recommendation: '0W-40 Mobil 1', interval: '7 500 км', kmInterval: 7500),
    ],
    expenses: [
      Expense(category: 'Налог', amount: 150000, date: DateTime.now()),
    ],
  ),
];