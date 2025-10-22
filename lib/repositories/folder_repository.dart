import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'folder_model.dart';

class FolderRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Folder>> getAllFolders() async {
    final db = await dbHelper.database;
    final result = await db.query('folders', orderBy: 'id ASC');
    return result.map((map) => Folder.fromMap(map)).toList();
  }

  Future<Folder?> getFolder(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Folder.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertFolder(Folder folder) async {
    final db = await dbHelper.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await dbHelper.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await dbHelper.database;
    
    await db.transaction((txn) async {
      await txn.delete('cards', where: 'folderId = ?', whereArgs: [id]);
      await txn.delete('folders', where: 'id = ?', whereArgs: [id]);
    });
    
    return 1;
  }

  Future<int> getCardCount(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folderId = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updatePreviewImage(int folderId, String? imageUrl) async {
    final db = await dbHelper.database;
    await db.update(
      'folders',
      {'previewImage': imageUrl},
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }
}