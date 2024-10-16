import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 1;

  static const folderTable = 'folders';
  static const cardTable = 'cards';

  static const columnId = '_id';
  static const columnName = 'name';
  static const columnSuit = 'suit';
  static const columnImageUrl = 'imageUrl';
  static const columnFolderId = 'folderId';

  DatabaseHelper._init();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $folderTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $cardTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnSuit TEXT NOT NULL,
        $columnImageUrl TEXT NOT NULL,
        $columnFolderId INTEGER,
        FOREIGN KEY ($columnFolderId) REFERENCES $folderTable ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> createFolder(String name) async {
    final db = await database;
    final id = await db.insert(folderTable, {columnName: name});
    return id;
  }

  Future<List<Map<String, dynamic>>> fetchFolders() async {
    final db = await database;
    return await db.query(folderTable);
  }

  Future<List<Map<String, dynamic>>> fetchCards(int folderId) async {
    final db = await database;
    return await db.query(cardTable, where: '$columnFolderId = ?', whereArgs: [folderId]);
  }

  Future<int> createCard(String name, String suit, String imageUrl, int folderId) async {
    final db = await database;
    return await db.insert(cardTable, {
      columnName: name,
      columnSuit: suit,
      columnImageUrl: imageUrl,
      columnFolderId: folderId,
    });
  }
}
