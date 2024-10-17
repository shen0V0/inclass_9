import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(CardManagerApp());
}

class CardManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FolderScreen(),
    );
  }
}

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Map<String, dynamic>> folders = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final data = await dbHelper.getAllFolders();
    setState(() {
      folders = data;
    });
  }

  void _addFolder() async {
    String newName = await _showInputDialog('Enter folder name');
    if (newName.isNotEmpty) {
      await dbHelper.insertFolder({'name': newName, 'type': 'custom'});
      _loadFolders();
    }
  }

  Future<void> _deleteFolder(int id) async {
    await dbHelper.updateCardsFolderToNull(id);
    await dbHelper.deleteFolder(id);
    _loadFolders();
  }

  Future<String> _showInputDialog(String title) async {
    String input = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          onChanged: (value) {
            input = value;
          },
          decoration: InputDecoration(hintText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
    return input;
  }

  void _navigateToCardScreen(int folderId, String folderName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardScreen(folderId: folderId, folderName: folderName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return GestureDetector(
            onTap: () => _navigateToCardScreen(folder['id'], folder['name']),
            child: Column(
              children: [
                Image.asset(
                  'assets/folder.jpg',
                  width: 80,
                  height: 80,
                ),
                SizedBox(height: 8),
                Text(
                  folder['name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteFolder(folder['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        child: Icon(Icons.add),
      ),
    );
  }
}

class CardScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardScreen({required this.folderId, required this.folderName});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<Map<String, dynamic>> cards = [];
  final dbHelper = DatabaseHelper.instance;
  static const int maxCardsInFolder = 6;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final data = await dbHelper.getCardsInFolder(widget.folderId);
    setState(() {
      cards = data;
    });
  }

  void _addCard() async {
    if (cards.length >= maxCardsInFolder) {
      _showLimitReachedMessage();
      return;
    }

    List<Map<String, dynamic>> availableCards;
    if (['Clubs', 'Diamonds', 'Hearts', 'Spades'].contains(widget.folderName)) {
      availableCards = await dbHelper.getFolderlessCardsOfSuit(widget.folderName);
    } else {
      availableCards = await dbHelper.getFolderlessCards();
    }

    if (availableCards.isEmpty) return;

    final selectedCard = await _showCardSelectionDialog(availableCards);
    if (selectedCard != null) {
      await dbHelper.updateCardFolder(selectedCard['id'], widget.folderId);
      _loadCards();
    }
  }

  Future<void> _showLimitReachedMessage() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limit Reached'),
        content: Text('This folder has reached the maximum number of cards (6).'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCardSelectionDialog(
      List<Map<String, dynamic>> availableCards) async {
    Map<String, dynamic>? selectedCard;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select a Card'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: availableCards.length,
            itemBuilder: (context, index) {
              final card = availableCards[index];
              final cardNumber = (card['id'] - (card['id'] - 1) ~/ 10 * 10);
              return ListTile(
                title: Text('Card $cardNumber of ${card['suit']}'),
                onTap: () {
                  selectedCard = card;
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
    return selectedCard;
  }

  Future<void> _deleteCard(int cardId) async {
    await dbHelper.updateCardFolder(cardId, null);
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cards in ${widget.folderName}')),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Column(
            children: [
              Image.asset(
                card['asset_path'],
                width: 80,
                height: 100,
              ),
              SizedBox(height: 8),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteCard(card['id']),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: Icon(Icons.add),
      ),
    );
  }
}
