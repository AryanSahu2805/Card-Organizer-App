import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({Key? key, required this.folder}) : super(key: key);

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<CardModel> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    List<Map<String, dynamic>> cardMaps = await _dbHelper.getCardsByFolder(widget.folder.id!);
    List<CardModel> cards = cardMaps.map((map) => CardModel.fromMap(map)).toList();
    
    setState(() {
      _cards = cards;
    });

    await _dbHelper.updateFolderPreviewImage(widget.folder.id!);
  }

  void _showAddCardDialog() async {
    int currentCount = _cards.length;
    
    if (currentCount >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This folder can only hold 6 cards.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> unassignedMaps = await _dbHelper.getUnassignedCards();
    List<CardModel> unassignedCards = unassignedMaps
        .map((map) => CardModel.fromMap(map))
        .where((card) => card.suit == widget.folder.name)
        .toList();

    if (unassignedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more cards available for this suit.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Card to ${widget.folder.name}'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: unassignedCards.length,
              itemBuilder: (context, index) {
                CardModel card = unassignedCards[index];
                return ListTile(
                  leading: Image.network(
                    card.imageUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image_not_supported);
                    },
                  ),
                  title: Text(card.name),
                  onTap: () async {
                    card.folderId = widget.folder.id;
                    await _dbHelper.updateCard(card.toMap());
                    Navigator.of(context).pop();
                    _loadCards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Card added successfully')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showEditCardDialog(CardModel card) {
    TextEditingController nameController = TextEditingController(text: card.name);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Card Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  card.name = nameController.text.trim();
                  await _dbHelper.updateCard(card.toMap());
                  Navigator.of(context).pop();
                  _loadCards();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Card updated successfully')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMoveCardDialog(CardModel card) async {
    List<Map<String, dynamic>> folderMaps = await _dbHelper.getAllFolders();
    List<Folder> folders = folderMaps
        .map((map) => Folder.fromMap(map))
        .where((f) => f.id != widget.folder.id)
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Move Card to Another Folder'),
          content: Container(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                Folder folder = folders[index];
                return ListTile(
                  title: Text(folder.name),
                  onTap: () async {
                    int targetCount = await _dbHelper.getCardCountInFolder(folder.id!);
                    if (targetCount >= 6) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Target folder is full (6 cards max).'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    card.folderId = folder.id;
                    await _dbHelper.updateCard(card.toMap());
                    Navigator.of(context).pop();
                    _loadCards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Card moved to ${folder.name}')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(CardModel card) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Card'),
          content: Text('Are you sure you want to remove this card from the folder?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Remove'),
              onPressed: () async {
                card.folderId = null;
                await _dbHelper.updateCard(card.toMap());
                Navigator.of(context).pop();
                _loadCards();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Card removed from folder')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showCardOptionsDialog(CardModel card) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Card'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCardDialog(card);
                },
              ),
              ListTile(
                leading: Icon(Icons.move_to_inbox, color: Colors.green),
                title: Text('Move to Another Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveCardDialog(card);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove from Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(card);
                },
              ),
              SizedBox(height: 8),
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasWarning = _cards.length < 3;
    bool hasError = _cards.length >= 6;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.name} Cards'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddCardDialog,
            tooltip: 'Add Card',
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasWarning && _cards.isNotEmpty)
            Container(
              color: Colors.orange[100],
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[900]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You need at least 3 cards in this folder.',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          if (hasError)
            Container(
              color: Colors.red[100],
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[900]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This folder is full (6 cards maximum).',
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No cards in this folder',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Card'),
                          onPressed: _showAddCardDialog,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        CardModel card = _cards[index];
                        return GestureDetector(
                          onTap: () => _showCardOptionsDialog(card),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    child: Image.network(
                                      card.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Text(
                                    card.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11),
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
          ),
        ],
      ),
    );
  }
}