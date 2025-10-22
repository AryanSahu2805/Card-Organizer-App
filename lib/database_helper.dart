import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        previewImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // Prepopulate folders
    await _prepopulateFolders(db);
    
    // Prepopulate cards
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateFolders(Database db) async {
    final folders = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final now = DateTime.now().toIso8601String();

    for (var folder in folders) {
      await db.insert('folders', {
        'name': folder,
        'previewImage': null,
        'createdAt': now,
      });
    }
  }

  Future<void> _prepopulateCards(Database db) async {
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final ranks = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];
    final now = DateTime.now().toIso8601String();

    for (var suit in suits) {
      for (var rank in ranks) {
        String imageUrl = 'https://deckofcardsapi.com/static/img/${_getCardCode(rank, suit)}.png';
        
        await db.insert('cards', {
          'name': '$rank of $suit',
          'suit': suit,
          'imageUrl': imageUrl,
          'folderId': null,
          'createdAt': now,
        });
      }
    }
  }

  String _getCardCode(String rank, String suit) {
    String rankCode;
    switch (rank) {
      case 'Ace':
        rankCode = 'A';
        break;
      case 'Jack':
        rankCode = 'J';
        break;
      case 'Queen':
        rankCode = 'Q';
        break;
      case 'King':
        rankCode = 'K';
        break;
      default:
        rankCode = rank;
    }

    String suitCode = suit.substring(0, 1);
    return '$rankCode$suitCode';
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}