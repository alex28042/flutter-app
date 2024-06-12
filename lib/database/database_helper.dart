
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseHelper {
  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'coordinate_database.db'),
      onCreate: (db, version) async {
        await db.execute('''
           CREATE TABLE coordinates(
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           timestamp TEXT,
           latitude REAL,
           longitude REAL
           )
        ''');
      },
      version: 1,
    );
  }

  Future<void> insertCoordinate(Position position) async {
    final db = await database;
    await db.insert('coordinates', {
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'latitude': position.latitude,
      'longitude': position.longitude
    });
  }

  Future<List<Map<String, dynamic>>> getCoordinates() async {
    final db = await database;
    return await db.query('coordinates');
  }
}

