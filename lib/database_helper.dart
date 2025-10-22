import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        previewImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create cards table
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        imageBytes TEXT,
        folderId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (folderId) REFERENCES folders (id)
      )
    ''');

    // Prepopulate folders
    await _prepopulateFolders(db);
    
    // Prepopulate cards
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateFolders(Database db) async {
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (String suit in suits) {
      await db.insert('folders', {
        'name': suit,
        'previewImage': null,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _prepopulateCards(Database db) async {
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    List<String> ranks = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];
    
    // Using placeholder card images (you can replace with actual card image URLs)
    for (String suit in suits) {
      for (int i = 0; i < ranks.length; i++) {
        String cardName = '${ranks[i]} of $suit';
        // Using a simple placeholder URL pattern
        String imageUrl = 'https://via.placeholder.com/150x200/FF0000/FFFFFF?text=${ranks[i]}+$suit';
        
        // Better image URLs for cards
        String suitChar = suit == 'Hearts' ? 'H' : 
                         suit == 'Spades' ? 'S' : 
                         suit == 'Diamonds' ? 'D' : 'C';
        String rankValue = (i + 1).toString();
        imageUrl = 'https://deckofcardsapi.com/static/img/${rankValue}${suitChar}.png';
        
        await db.insert('cards', {
          'name': cardName,
          'suit': suit,
          'imageUrl': imageUrl,
          'imageBytes': null,
          'folderId': null,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Folder CRUD Operations
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    Database db = await database;
    return await db.query('folders');
  }

  Future<Map<String, dynamic>?> getFolder(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertFolder(Map<String, dynamic> folder) async {
    Database db = await database;
    return await db.insert('folders', folder);
  }

  Future<int> updateFolder(Map<String, dynamic> folder) async {
    Database db = await database;
    return await db.update(
      'folders',
      folder,
      where: 'id = ?',
      whereArgs: [folder['id']],
    );
  }

  Future<int> deleteFolder(int id) async {
    Database db = await database;
    await db.transaction((txn) async {
      // First delete all cards in the folder
      await txn.delete(
        'cards',
        where: 'folderId = ?',
        whereArgs: [id],
      );
      // Then delete the folder
      await txn.delete(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    return id;
  }

  // Card CRUD Operations
  Future<List<Map<String, dynamic>>> getAllCards() async {
    Database db = await database;
    return await db.query('cards');
  }

  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    Database db = await database;
    return await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnassignedCards() async {
    Database db = await database;
    return await db.query(
      'cards',
      where: 'folderId IS NULL',
    );
  }

  Future<int> insertCard(Map<String, dynamic> card) async {
    Database db = await database;
    return await db.insert('cards', card);
  }

  Future<int> updateCard(Map<String, dynamic> card) async {
    Database db = await database;
    return await db.update(
      'cards',
      card,
      where: 'id = ?',
      whereArgs: [card['id']],
    );
  }

  Future<int> deleteCard(int id) async {
    Database db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCardCountInFolder(int folderId) async {
    Database db = await database;
    var result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folderId = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateFolderPreviewImage(int folderId) async {
    Database db = await database;
    List<Map<String, dynamic>> cards = await getCardsByFolder(folderId);
    String? previewImage = cards.isNotEmpty ? cards.first['imageUrl'] : null;
    await db.update(
      'folders',
      {'previewImage': previewImage},
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }
}