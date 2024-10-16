import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _dbName = "cardOrganizer.db";
  static final _dbVersion = 1;

  static final tableFolders = 'folders';
  static final tableCards = 'cards';

  static final columnId = 'id';
  static final columnFolderName = 'name';
  static final columnFolderLimit = 'max_limit';
  
  static final columnFolderId = 'folder_id';
  static final columnCardNumber = 'card_number';
  static final columnImagePath = 'image_path';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFolders (
        $columnId INTEGER PRIMARY KEY,
        $columnFolderName TEXT NOT NULL,
        $columnFolderLimit INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE $tableCards (
        $columnId INTEGER PRIMARY KEY,
        $columnFolderId INTEGER NOT NULL,
        $columnCardNumber INTEGER NOT NULL,
        $columnImagePath TEXT NOT NULL,
        FOREIGN KEY ($columnFolderId) REFERENCES $tableFolders($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // Insert Folder
  Future<int> insertFolder(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableFolders, row);
  }

  // Insert Card
  Future<int> insertCard(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCards, row);
  }

  // Get all folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    Database db = await instance.database;
    return await db.query(tableFolders);
  }

  // Get cards for a specific folder
  Future<List<Map<String, dynamic>>> getCards(int folderId) async {
    Database db = await instance.database;
    return await db.query(tableCards, where: '$columnFolderId = ?', whereArgs: [folderId]);
  }

  // Delete a folder (will also delete its cards)
  Future<int> deleteFolder(int id) async {
    Database db = await instance.database;
    return await db.delete(tableFolders, where: '$columnId = ?', whereArgs: [id]);
  }

  // Delete a card
  Future<int> deleteCard(int id) async {
    Database db = await instance.database;
    return await db.delete(tableCards, where: '$columnId = ?', whereArgs: [id]);
  }
}
