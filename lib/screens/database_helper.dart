import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('garage.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  // Создаем таблицы один раз
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        image TEXT,
        description TEXT,
        mileage INTEGER,
        lastOilChange INTEGER,
        lastAntifreezeChange INTEGER,
        nextTehosmotr TEXT,
        volume TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER,
        category TEXT,
        amount REAL,
        date TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER,
        title TEXT,
        place TEXT,
        date TEXT,
        price TEXT,
        tag TEXT,
        mileage INTEGER
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем новые поля и таблицу ТО
      await db.execute('ALTER TABLE cars ADD COLUMN lastAntifreezeChange INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE cars ADD COLUMN nextTehosmotr TEXT DEFAULT "05.2026"');
      await db.execute('ALTER TABLE cars ADD COLUMN volume TEXT DEFAULT ""');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS maintenance(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          carId INTEGER,
          title TEXT,
          place TEXT,
          date TEXT,
          price TEXT,
          tag TEXT,
          mileage INTEGER
        )
      ''');
    }
  }

  // Метод добавления (вернул как было у тебя, чтобы не было ошибок в UI)
  Future<int> addCar(String name, String image, int mileage, String volume, {int lastOilChange = 0, int lastAntifreezeChange = 0, String nextTehosmotr = '05.2026'}) async {
    final db = await instance.database;
    return await db.insert('cars', {
      'name': name,
      'image': image,
      'mileage': mileage,
      'volume': volume,
      'description': '',
      'lastOilChange': lastOilChange,
      'lastAntifreezeChange': lastAntifreezeChange,
      'nextTehosmotr': nextTehosmotr,
    });
  }

  // Метод для получения списка машин (понадобится в Home Screen)
  Future<List<Map<String, dynamic>>> getCars() async {
    final db = await instance.database;
    return await db.query('cars', orderBy: 'id DESC');
  }

  // Расходы по машине
  Future<int> addExpense(int carId, String category, double amount, String note) async {
    final db = await instance.database;
    return await db.insert('expenses', {
      'carId': carId,
      'category': category,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> getExpensesForCar(int carId) async {
    final db = await instance.database;
    return await db.query('expenses', where: 'carId = ?', whereArgs: [carId], orderBy: 'id DESC');
  }

  // Логи обслуживания (ТО)
  Future<int> addMaintenanceLog(int carId, String title, String place, String date, String price, String tag, int mileage) async {
    final db = await instance.database;
    return await db.insert('maintenance', {
      'carId': carId,
      'title': title,
      'place': place,
      'date': date,
      'price': price,
      'tag': tag,
      'mileage': mileage,
    });
  }

  Future<List<Map<String, dynamic>>> getMaintenanceForCar(int carId) async {
    final db = await instance.database;
    return await db.query('maintenance', where: 'carId = ?', whereArgs: [carId], orderBy: 'id DESC');
  }
}