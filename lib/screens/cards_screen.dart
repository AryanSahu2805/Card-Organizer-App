import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/card_model.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({Key? key, required this.folder}) : super(key: key);

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardRepository _cardRepo = CardRepository();
  final FolderRepository _folderRepo = FolderRepository();
  List<CardModel> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }
}

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });

    final cards = await _cardRepo.getCardsByFolder(widget.folder.id!);

    setState(() {
      _cards = cards;
      _isLoading = false;
    });

    _checkCardLimits();
  }

  void _checkCardLimits() {
    if (_cards.length < 3 && _cards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Warning: You need at least 3 cards in this folder.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _showAddCardDialog() async {
    final cardCount = await _folderRepo.getCardCount(widget.folder.id!);

    if (cardCount >= 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Folder Full'),
          content: const Text('This folder can only hold 6 cards.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final unassignedCards = await _cardRepo.getUnassignedCardsBySuit(widget.folder.name);

    if (unassignedCards.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Cards Available'),
          content: Text('No ${widget.folder.name} cards available to add.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Card to Add'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: unassignedCards.length,
              itemBuilder: (context, index) {
                final card = unassignedCards[index];
                return GestureDetector(
                  onTap: () async {
                    card.folderId = widget.folder.id;
                    await _cardRepo.updateCard(card);
                    Navigator.pop(context);
                    _loadCards();
                  },
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.network(
                            card.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) {
                              return const Icon(Icons.broken_image);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            card.name,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCardDialog(CardModel card) async {
    final nameController = TextEditingController(text: card.name);
    final allFolders = await _folderRepo.getAllFolders();
    int? selectedFolderId = card.folderId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Card'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Card Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedFolderId,
                    decoration: const InputDecoration(
                      labelText: 'Folder',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...allFolders.map((folder) {
                        return DropdownMenuItem<int>(
                          value: folder.id,
                          child: Text(folder.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedFolderId = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      card.name = nameController.text;
                      card.folderId = selectedFolderId;
                      await _cardRepo.updateCard(card);
                      Navigator.pop(context);
                      _loadCards();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(CardModel card) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Card'),
          content: Text('Remove "${card.name}" from this folder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                card.folderId = null;
                await _cardRepo.updateCard(card);
                Navigator.pop(context);
                _loadCards();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showCardOptions(CardModel card) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Card'),
              onTap: () {
                Navigator.pop(context);
                _showEditCardDialog(card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Remove from Folder', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(card);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No cards in this folder',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add cards',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return GestureDetector(
                      onTap: () => _showCardOptions(card),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.network(
                                  card.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 50),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                card.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }