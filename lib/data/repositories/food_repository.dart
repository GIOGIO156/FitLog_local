import '../../core/utils/date_utils.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_record.dart';
import '../db/app_database.dart';

class FoodRepository {
  FoodRepository(this._database);

  final AppDatabase _database;

  Future<int> insertFoodRecord(FoodRecord record) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();

    return db.transaction((txn) async {
      final int recordId = await txn.insert(
        'food_records',
        record.copyWith(createdAt: now, updatedAt: now).toMap()..remove('id'),
      );

      for (final item in record.items) {
        await txn.insert(
          'food_items',
          item.copyWith(foodRecordId: recordId).toMap()..remove('id'),
        );
      }

      return recordId;
    });
  }

  Future<void> updateFoodRecord(FoodRecord record) async {
    if (record.id == null) {
      throw ArgumentError('Food record id is required for update.');
    }

    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    final existingRows = await db.query(
      'food_records',
      columns: <String>['created_at'],
      where: 'id = ?',
      whereArgs: <Object?>[record.id],
      limit: 1,
    );

    if (existingRows.isEmpty) {
      throw StateError('Food record not found: id=${record.id}');
    }

    final existingCreatedAt =
        existingRows.first['created_at']?.toString() ?? now;
    final payload = record.copyWith(
      createdAt: existingCreatedAt,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.update(
        'food_records',
        payload.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: <Object?>[record.id],
      );

      await txn.delete(
        'food_items',
        where: 'food_record_id = ?',
        whereArgs: <Object?>[record.id],
      );

      for (final item in record.items) {
        await txn.insert(
          'food_items',
          item.copyWith(foodRecordId: record.id).toMap()..remove('id'),
        );
      }
    });
  }

  Future<void> deleteFoodRecord(int id) async {
    final db = await _database.database;
    await db.delete('food_records', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<FoodRecord?> getFoodRecordById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'food_records',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final items = await getFoodItemsByRecordId(id);
    return FoodRecord.fromMap(rows.first, items: items);
  }

  Future<List<FoodRecord>> getAllFoodRecords() async {
    final db = await _database.database;
    final rows = await db.query(
      'food_records',
      orderBy: 'date DESC, created_at DESC',
    );

    final List<FoodRecord> records = <FoodRecord>[];
    for (final row in rows) {
      final int id = row['id'] as int;
      final items = await getFoodItemsByRecordId(id);
      records.add(FoodRecord.fromMap(row, items: items));
    }
    return records;
  }

  Future<List<FoodRecord>> getFoodRecordsByDate(String day) async {
    final db = await _database.database;
    final rows = await db.query(
      'food_records',
      where: 'date = ?',
      whereArgs: <Object?>[day],
      orderBy: 'created_at DESC',
    );

    final List<FoodRecord> records = <FoodRecord>[];
    for (final row in rows) {
      final int id = row['id'] as int;
      final items = await getFoodItemsByRecordId(id);
      records.add(FoodRecord.fromMap(row, items: items));
    }
    return records;
  }

  Future<List<FoodItem>> getFoodItemsByRecordId(int foodRecordId) async {
    final db = await _database.database;
    final rows = await db.query(
      'food_items',
      where: 'food_record_id = ?',
      whereArgs: <Object?>[foodRecordId],
      orderBy: 'id ASC',
    );

    return rows.map(FoodItem.fromMap).toList();
  }

  Future<double> getCaloriesInByDate(String day) async {
    final records = await getFoodRecordsByDate(day);
    return records.fold<double>(0, (sum, item) => sum + item.caloriesKcal);
  }

  Future<List<String>> getDistinctDates() async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date FROM food_records ORDER BY date DESC',
    );
    return rows.map((row) => row['date'].toString()).toList();
  }

  Future<List<FoodRecord>> getTodayFoodRecords() async {
    return getFoodRecordsByDate(DateUtilsX.todayKey());
  }
}
