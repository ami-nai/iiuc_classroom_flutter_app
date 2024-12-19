import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static Future<Database> initializeDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/routine.db';
    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE routine (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            semester TEXT,
            section TEXT,
            day TEXT,
            is_free BOOLEAN,
            subject TEXT,
            instructor TEXT,
            time TEXT,
            room TEXT
          )
        ''');
      },
      version: 1,
    );
  }


  static Future<List<Map<String, dynamic>>> fetchRoutineByDayAndTime(String day, String time) async {
    final db = await initializeDB();
    return await db.query(
      'routine',
      where: 'day = ? AND time = ?',
      whereArgs: [day, time],
    );
  }
  
  static Future<List<Map<String, dynamic>>> fetchRoutines(
      String day, String section) async {
    final db = await initializeDB();
    return await db.query(
      'routine',
      where: 'day = ? AND section = ?',
      whereArgs: [day, section],
    );
  }

  static Future<List<Map<String, dynamic>>> fetchAllRoutines() async {
    final db = await initializeDB();
    return await db.query('routine');
  }

  static Future<void> insertRoutine(Map<String, dynamic> routine) async {
    final db = await initializeDB();
    await db.insert('routine', routine, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
