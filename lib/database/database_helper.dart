import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/folder.dart';
import '../models/card.dart';

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
    // Create Folders table
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL UNIQUE,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create Cards table
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        value TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        imageData BLOB,
        folderId INTEGER,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // Initialize with default folders and cards
    await _initializeDefaultData(db);
  }

  Future<void> _initializeDefaultData(Database db) async {
    // Create default folders for each suit
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (String suit in suits) {
      await db.insert('folders', {
        'name': suit,
        'suit': suit,
        'timestamp': now,
      });
    }

    // Create all standard cards
    final values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    for (String suit in suits) {
      for (String value in values) {
        String cardName = value == 'A' ? 'Ace' :
                         value == 'J' ? 'Jack' :
                         value == 'Q' ? 'Queen' :
                         value == 'K' ? 'King' : value;
        
        String suitCode = suit.substring(0, 1).toLowerCase();
        String valueCode = value.toLowerCase();
        
        // Use a more reliable card image URL structure
        String imageUrl = 'https://deckofcardsapi.com/static/img/$valueCode$suitCode.png';
        
        await db.insert('cards', {
          'name': '$cardName of $suit',
          'suit': suit,
          'value': value,
          'imageUrl': imageUrl,
          'imageData': null, // Will be populated if downloaded
          'folderId': null, // Initially not assigned to any folder
        });
      }
    }
  }

  // Folder CRUD operations
  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final result = await db.query('folders');
    return result.map((map) => Folder.fromMap(map)).toList();
  }

  Future<Folder> insertFolder(Folder folder) async {
    final db = await database;
    final id = await db.insert('folders', folder.toMap());
    return folder.copyWith(id: id);
  }

  Future<void> updateFolder(Folder folder) async {
    final db = await database;
    await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> deleteFolder(int id) async {
    final db = await database;
    // First, remove cards from this folder
    await db.update(
      'cards',
      {'folderId': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    // Then delete the folder
    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Card CRUD operations
  Future<List<Card>> getAllCards() async {
    final db = await database;
    final result = await db.query('cards');
    return result.map((map) => Card.fromMap(map)).toList();
  }

  Future<List<Card>> getCardsInFolder(int folderId) async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    return result.map((map) => Card.fromMap(map)).toList();
  }

  Future<List<Card>> getUnassignedCards() async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'folderId IS NULL',
    );
    return result.map((map) => Card.fromMap(map)).toList();
  }

  Future<List<Card>> getUnassignedCardsBySuit(String suit) async {
    final db = await database;
    final result = await db.query(
      'cards',
      where: 'folderId IS NULL AND suit = ?',
      whereArgs: [suit],
    );
    return result.map((map) => Card.fromMap(map)).toList();
  }

  Future<void> updateCard(Card card) async {
    final db = await database;
    await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteCard(int id) async {
    final db = await database;
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCardCountInFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folderId = ?',
      [folderId],
    );
    return result.first['count'] as int;
  }

  // Image handling methods
  Future<void> updateCardImage(int cardId, List<int> imageData) async {
    final db = await database;
    await db.update(
      'cards',
      {'imageData': imageData},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<List<int>?> getCardImageData(int cardId) async {
    final db = await database;
    final result = await db.query(
      'cards',
      columns: ['imageData'],
      where: 'id = ?',
      whereArgs: [cardId],
    );
    
    if (result.isNotEmpty && result.first['imageData'] != null) {
      return List<int>.from(result.first['imageData'] as List);
    }
    return null;
  }

  Future<void> clearAllImageData() async {
    final db = await database;
    await db.update(
      'cards',
      {'imageData': null},
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}