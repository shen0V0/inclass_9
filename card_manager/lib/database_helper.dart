import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY,
        folder_id INTEGER,
        asset_path TEXT NOT NULL,
        suit TEXT,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE SET NULL
      )
    ''');

    await _initializeDefaultFolders(db);
    await _initializeDefaultCards(db);
  }

  Future<void> _initializeDefaultFolders(Database db) async {
    await db.insert('folders', {'name': 'Clubs', 'type': 'default'});
    await db.insert('folders', {'name': 'Diamonds', 'type': 'default'});
    await db.insert('folders', {'name': 'Hearts', 'type': 'default'});
    await db.insert('folders', {'name': 'Spades', 'type': 'default'});
  }

  Future<void> _initializeDefaultCards(Database db) async {
    final suits = ['Clubs', 'Diamonds', 'Hearts', 'Spades'];
    final cards = [
      for (var suit in suits)
        for (var i = 1; i <= 10; i++)
          {'id': i + suits.indexOf(suit) * 10, 'suit': suit, 'asset_path': 'assets/${suit.toLowerCase()}$i.png'}
    ];

    for (var card in cards) {
      await db.insert('cards', card);
    }
  }

  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final db = await instance.database;
    return await db.query('folders');
  }

  Future<int> insertFolder(Map<String, dynamic> folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder);
  }

  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCardsFolderToNull(int folderId) async {
    final db = await instance.database;
    await db.update('cards', {'folder_id': null}, where: 'folder_id = ?', whereArgs: [folderId]);
  }

  Future<List<Map<String, dynamic>>> getCardsInFolder(int folderId) async {
    final db = await instance.database;
    return await db.query('cards', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  Future<List<Map<String, dynamic>>> getFolderlessCards() async {
    final db = await instance.database;
    return await db.query('cards', where: 'folder_id IS NULL');
  }

  Future<List<Map<String, dynamic>>> getFolderlessCardsOfSuit(String suit) async {
    final db = await instance.database;
    return await db.query('cards', where: 'folder_id IS NULL AND suit = ?', whereArgs: [suit]);
  }

  Future<int> updateCardFolder(int cardId, int? folderId) async {
    final db = await instance.database;
    return await db.update(
      'cards',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
