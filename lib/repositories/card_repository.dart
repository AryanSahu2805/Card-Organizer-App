import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/card_model.dart';

class CardRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<CardModel>> getAllCards() async {
    final db = await dbHelper.database;
    final result = await db.query('cards', orderBy: 'id ASC');
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<List<CardModel>> getCardsByFolder(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
    );
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<List<CardModel>> getUnassignedCards() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'cards',
      where: 'folderId IS NULL',
      orderBy: 'id ASC',
    );
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<List<CardModel>> getUnassignedCardsBySuit(String suit) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'cards',
      where: 'folderId IS NULL AND suit = ?',
      whereArgs: [suit],
      orderBy: 'id ASC',
    );
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<CardModel?> getCard(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return CardModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertCard(CardModel card) async {
    final db = await dbHelper.database;
    return await db.insert('cards', card.toMap());
  }

  Future<int> updateCard(CardModel card) async {
    final db = await dbHelper.database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<CardModel?> getFirstCardInFolder(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return CardModel.fromMap(result.first);
    }
    return null;
  }
}