import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FolderScreen(),
    );
  }
}

// Screen displaying folders
class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() async {
    final data = await dbHelper.getFolders();
    setState(() {
      folders = data;
    });
  }

  void _addFolder(String name, int limit) async {
    await dbHelper.insertFolder({'name': name, 'max_limit': limit});
    _loadFolders();
  }

  void _deleteFolder(int id) async {
    await dbHelper.deleteFolder(id);
    _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Folders")),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(folders[index]['name']),
            subtitle: Text('Limit: ${folders[index]['max_limit']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CardScreen(folderId: folders[index]['id'], folderName: folders[index]['name'])),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteFolder(folders[index]['id']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFolderDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _addFolderDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Folder'),
          content: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Folder Name'),
              ),
              TextField(
                controller: limitController,
                decoration: InputDecoration(labelText: 'Limit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final limit = int.tryParse(limitController.text) ?? 5;
                _addFolder(name, limit);
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// Screen to manage cards in a folder
class CardScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardScreen({required this.folderId, required this.folderName});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() async {
    final data = await dbHelper.getCards(widget.folderId);
    setState(() {
      cards = data;
    });
  }

  void _addCard(int cardNumber, String imagePath) async {
    await dbHelper.insertCard({
      'folder_id': widget.folderId,
      'card_number': cardNumber,
      'image_path': imagePath,
    });
    _loadCards();
  }

  void _deleteCard(int id) async {
    await dbHelper.deleteCard(id);
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderName)),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(cards[index]['image_path'], width: 50, height: 50),
                Text('Card ${cards[index]['card_number']}'),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteCard(cards[index]['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCardDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _addCardDialog() {
    TextEditingController cardNumberController = TextEditingController();
    TextEditingController imagePathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Card'),
          content: Column(
            children: [
              TextField(
                controller: cardNumberController,
                decoration: InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imagePathController,
                decoration: InputDecoration(labelText: 'Image Path (e.g., assets/2_of_hearts.png)'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final cardNumber = int.tryParse(cardNumberController.text) ?? 0;
                final imagePath = imagePathController.text;
                _addCard(cardNumber, imagePath);
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
