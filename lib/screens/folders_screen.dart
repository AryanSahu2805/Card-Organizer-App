import 'package:flutter/material.dart';
import 'models/folder_model.dart';
import 'models/card_model.dart';
import 'repositories/folder_repository.dart';
import 'repositories/card_repository.dart';
import 'screens/cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository _folderRepo = FolderRepository();
  final CardRepository _cardRepo = CardRepository();
  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    final folders = await _folderRepo.getAllFolders();
    Map<int, int> counts = {};

    for (var folder in folders) {
      final count = await _folderRepo.getCardCount(folder.id!);
      counts[folder.id!] = count;

      final firstCard = await _cardRepo.getFirstCardInFolder(folder.id!);
      if (firstCard != null && folder.previewImage != firstCard.imageUrl) {
        folder.previewImage = firstCard.imageUrl;
        await _folderRepo.updatePreviewImage(folder.id!, firstCard.imageUrl);
      } else if (firstCard == null && folder.previewImage != null) {
        folder.previewImage = null;
        await _folderRepo.updatePreviewImage(folder.id!, null);
      }
    }

    setState(() {
      _folders = folders;
      _cardCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _showAddFolderDialog() async {
    final nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Folder'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              hintText: 'Enter folder name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newFolder = Folder(
                    name: nameController.text,
                    createdAt: DateTime.now(),
                  );
                  await _folderRepo.insertFolder(newFolder);
                  Navigator.pop(context);
                  _loadFolders();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameFolderDialog(Folder folder) async {
    final nameController = TextEditingController(text: folder.name);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  folder.name = nameController.text;
                  await _folderRepo.updateFolder(folder);
                  Navigator.pop(context);
                  _loadFolders();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(Folder folder) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(
            'Are you sure you want to delete "${folder.name}" and all its cards?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _folderRepo.deleteFolder(folder.id!);
                Navigator.pop(context);
                _loadFolders();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showFolderOptions(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Folder'),
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(folder);
              },
            ),
          ],
        );
      },
    );
  }

  Color _getSuitColor(String folderName) {
    if (folderName.contains('Hearts') || folderName.contains('Diamonds')) {
      return Colors.red;
    }
    return Colors.black;
  }

  IconData _getSuitIcon(String folderName) {
    if (folderName.contains('Hearts')) return Icons.favorite;
    if (folderName.contains('Diamonds')) return Icons.diamond;
    if (folderName.contains('Spades')) return Icons.spa;
    if (folderName.contains('Clubs')) return Icons.local_florist;
    return Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? const Center(child: Text('No folders found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    final cardCount = _cardCounts[folder.id] ?? 0;

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
                      onLongPress: () => _showFolderOptions(folder),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: folder.previewImage != null
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          folder.previewImage!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stack) {
                                            return Center(
                                              child: Icon(
                                                _getSuitIcon(folder.name),
                                                size: 60,
                                                color: _getSuitColor(folder.name),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          _getSuitIcon(folder.name),
                                          size: 60,
                                          color: _getSuitColor(folder.name),
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$cardCount card${cardCount != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}