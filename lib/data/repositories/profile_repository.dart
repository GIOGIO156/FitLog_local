import '../../domain/models/user_profile.dart';
import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

class ProfileRepository {
  ProfileRepository(this._database);

  final AppDatabase _database;

  Future<UserProfile?> getProfile() async {
    final db = await _database.database;
    final rows = await db.query(
      'user_profile',
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();

    final UserProfile payload = profile.copyWith(
      id: profile.id ?? 1,
      createdAt: profile.createdAt ?? now,
      updatedAt: now,
    );

    await db.insert(
      'user_profile',
      payload.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearProfile() async {
    final db = await _database.database;
    await db.delete('user_profile');
  }
}
