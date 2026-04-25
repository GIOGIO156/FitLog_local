import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'fitlog_local.db';
  static const int _dbVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE workout_sessions ADD COLUMN plan_id TEXT',
          );
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        age INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        sex_for_formula TEXT NOT NULL,
        activity_level TEXT NOT NULL,
        daily_energy_goal_type TEXT NOT NULL,
        daily_energy_goal_kcal REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE food_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal_name TEXT NOT NULL,
        total_weight_g REAL NOT NULL,
        calories_kcal REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        confidence REAL,
        estimation_notes TEXT,
        source TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_record_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        estimated_weight_g REAL NOT NULL,
        calories_kcal REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (food_record_id) REFERENCES food_records (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id TEXT,
        date TEXT NOT NULL,
        body_part TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        intensity TEXT NOT NULL,
        estimated_calories REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (workout_session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> clearAllLocalData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('food_items');
      await txn.delete('food_records');
      await txn.delete('workout_sets');
      await txn.delete('workout_sessions');
      await txn.delete('user_profile');
    });
  }
}
