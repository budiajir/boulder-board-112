import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/profile/data/models/draft_route_model.dart';

/// Singleton helper managing the local SQLite database instance and operations.
class LocalDatabaseService {
  LocalDatabaseService._();
  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _db;

  /// Retrieve the active SQLite database instance, opening/initializing it if needed.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wiroboard_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE draft_routes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            grade TEXT NOT NULL,
            angle INTEGER NOT NULL,
            description TEXT,
            holds TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert a new draft climbing route into SQLite. Returns the new auto-generated ID.
  Future<int> insertDraft(DraftRouteModel draft) async {
    final db = await database;
    return await db.insert('draft_routes', draft.toMap());
  }

  /// Fetch all draft routes saved locally on the device, ordered by creation date descending.
  Future<List<DraftRouteModel>> getDrafts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'draft_routes',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => DraftRouteModel.fromMap(map)).toList();
  }

  /// Update an existing local draft route.
  Future<int> updateDraft(DraftRouteModel draft) async {
    if (draft.id == null) return 0;
    final db = await database;
    return await db.update(
      'draft_routes',
      draft.toMap(),
      where: 'id = ?',
      whereArgs: [draft.id],
    );
  }

  /// Delete a local draft route from the device by its unique ID.
  Future<int> deleteDraft(int id) async {
    final db = await database;
    return await db.delete(
      'draft_routes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
