import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flashcard.dart';

class DatabaseHelper {
  static const _databaseName = "flashcards.db";
  static const _databaseVersion = 1;

  // Flashcard table
  static const tableFlashcards = 'flashcards';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create the database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFlashcards (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        targetLanguageCode TEXT NOT NULL,
        translation TEXT NOT NULL,
        nativeLanguageCode TEXT NOT NULL,
        imageUrl TEXT,
        cachedImagePath TEXT,
        srsInterval REAL NOT NULL,
        srsEaseFactor REAL NOT NULL,
        srsNextReviewDate INTEGER NOT NULL,
        srsLastReviewDate INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Flashcard CRUD operations
  Future<int> insertFlashcard(Flashcard flashcard) async {
    final db = await database;
    return await db.insert(
      tableFlashcards,
      flashcard.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Flashcard?> getFlashcard(int id) async {
    final db = await database;
    final maps = await db.query(
      tableFlashcards,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Flashcard.fromMap(maps.first);
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final db = await database;
    final maps = await db.query(tableFlashcards);
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getDueFlashcards() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      tableFlashcards,
      where: 'srsNextReviewDate <= ?',
      whereArgs: [now],
      orderBy: 'srsNextReviewDate ASC',
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<int> updateFlashcard(Flashcard flashcard) async {
    final db = await database;
    return await db.update(
      tableFlashcards,
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  Future<int> deleteFlashcard(int id) async {
    final db = await database;
    return await db.delete(
      tableFlashcards,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllFlashcards() async {
    final db = await database;
    await db.delete(tableFlashcards);
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      tableFlashcards,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Flashcard>> getUnsynced() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFlashcards,
      where: 'synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
