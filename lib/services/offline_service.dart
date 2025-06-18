import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'offline_measurements.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE measurements(id INTEGER PRIMARY KEY, customer_id TEXT, image_path TEXT)',
        );
      },
      version: 1,
    );
    return _database!;
  }

  static Future<void> cacheMeasurement(String imagePath, String customerId) async {
    final db = await database;
    await db.insert(
      'measurements',
      {'customer_id': customerId, 'image_path': imagePath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}