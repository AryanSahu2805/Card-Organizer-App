import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    List<Map<String, dynamic>> folderMaps = await _dbHelper.getAllFolders();
    List<Folder> folders = folderMaps.map((map) => Folder.fromMap(map)).toList();
    
    Map<int, int> cardCounts = {};
    for (Folder folder in folders) {
      int count = await _dbHelper.getCardCountInFolder(folder.id!);
      cardCounts[folder.id!] = count;
    }

    setState(() {
      _folders = folders;
      _cardCounts = cardCounts;
    });
  }

  void _showAddFolderDialog() {
    TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Folder'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Folder Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Folder newFolder = Folder(
                    name: nameController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await _dbHelper.insertFolder(newFolder.toMap());
                  Navigator.of(context).pop();
                  _loadFolders();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameFolderDialog(Folder folder) {
    TextEditingController nameController = TextEditingController(text: folder.name);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Folder'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Folder Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Rename'),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  folder.name = nameController.text.trim();
                  await _dbHelper.updateFolder(folder.toMap());
                  Navigator.of(context).pop();
                  _loadFolders();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Folder folder) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text('Are you sure you want to delete this folder and all its cards?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
              onPressed: () async {
                await _dbHelper.deleteFolder(folder.id!);
                Navigator.of(context).pop();
                _loadFolders();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Folder deleted successfully')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Color _getSuitColor(String suitName) {
    if (suitName.toLowerCase().contains('heart') || 
        suitName.toLowerCase().contains('diamond')) {
      return Colors.red;
    }
    return Colors.black;
  }

  IconData _getSuitIcon(String suitName) {
    String lower = suitName.toLowerCase();
    if (lower.contains('heart')) return Icons.favorite;
    if (lower.contains('diamond')) return Icons.diamond;
    if (lower.contains('spade')) return Icons.spa;
    if (lower.contains('club')) return Icons.workspaces_outlined;
    return Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddFolderDialog,
            tooltip: 'Add Folder (Bonus)',
          ),
        ],
      ),
      body: _folders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  Folder folder = _folders[index];
                  int cardCount = _cardCounts[folder.id] ?? 0;
                  
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardsScreen(folder: folder),
                        ),
                      );
                      _loadFolders();
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (folder.previewImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                folder.previewImage!,
                                height: 100,
                                width: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getSuitIcon(folder.name),
                                    size: 60,
                                    color: _getSuitColor(folder.name),
                                  );
                                },
                              ),
                            )
                          else
                            Icon(
                              _getSuitIcon(folder.name),
                              size: 60,
                              color: _getSuitColor(folder.name),
                            ),
                          SizedBox(height: 12),
                          Text(
                            folder.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$cardCount card${cardCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: () => _showRenameFolderDialog(folder),
                                tooltip: 'Rename',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(folder),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}