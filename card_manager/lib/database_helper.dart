import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 1;

  // Folders table columns
  static const folderTable = 'folders';
  static const folderId = 'id';
  static const folderName = 'name';
  static const folderTimestamp = 'timestamp';

  // Cards table columns
  static const cardTable = 'cards';
  static const cardId = 'id';
  static const cardName = 'name';
  static const cardSuit = 'suit';
  static const cardImageUrl = 'image_url';
  static const cardFolderId = 'folder_id';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  late Database _database;

  Future<Database> get db async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $folderTable (
        $folderId INTEGER PRIMARY KEY AUTOINCREMENT,
        $folderName TEXT NOT NULL,
        $folderTimestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $cardTable (
        $cardId INTEGER PRIMARY KEY AUTOINCREMENT,
        $cardName TEXT NOT NULL,
        $cardSuit TEXT NOT NULL,
        $cardImageUrl TEXT NOT NULL,
        $cardFolderId INTEGER NOT NULL,
        FOREIGN KEY ($cardFolderId) REFERENCES $folderTable ($folderId) ON DELETE CASCADE
      )
    ''');
  }

  // Folders CRUD Operations
  Future<void> createFolder(String folderName) async {
    final db = await instance.db;
    await db.insert(folderTable, {
      folderName: folderName,
      folderTimestamp: DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateFolder(int id, String newName) async {
    final db = await instance.db;
    await db.update(
      folderTable,
      {folderName: newName},
      where: '$folderId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFolder(int id) async {
    final db = await instance.db;
    await db.delete(folderTable, where: '$folderId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> fetchFolders() async {
    final db = await instance.db;
    return await db.query(folderTable);
  }

  // Cards CRUD Operations
  Future<void> createCard(String name, String suit, String imageUrl, int folderId) async {
    final db = await instance.db;
    int cardCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $cardTable WHERE $cardFolderId = ?', [folderId])) ?? 0;

    if (cardCount >= 6) {
      throw Exception('This folder can only hold 6 cards.');
    }

    await db.insert(cardTable, {
      cardName: name,
      cardSuit: suit,
      cardImageUrl: imageUrl,
      cardFolderId: folderId,
    });
  }

  Future<void> updateCard(int id, Map<String, dynamic> updates) async {
    final db = await instance.db;
    await db.update(
      cardTable,
      updates,
      where: '$cardId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCard(int id) async {
    final db = await instance.db;
    await db.delete(cardTable, where: '$cardId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> fetchCards(int folderId) async {
    final db = await instance.db;
    return await db.query(cardTable, where: '$cardFolderId = ?', whereArgs: [folderId]);
  }
}
