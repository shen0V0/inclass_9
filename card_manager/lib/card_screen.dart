import 'package:flutter/material.dart';
import 'database_helper.dart';

class CardScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardScreen({required this.folderId, required this.folderName});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late DatabaseHelper dbHelper;
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper.instance;
    _fetchCards();
  }

  void _fetchCards() async {
    final cardData = await dbHelper.fetchCards(widget.folderId);
    setState(() {
      cards = cardData;
    });
  }

  void _createCard() async {
    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNameController,
                decoration: InputDecoration(hintText: 'Enter card name'),
              ),
              TextField(
                controller: cardSuitController,
                decoration: InputDecoration(hintText: 'Enter card suit'),
              ),
              TextField(
                controller: cardImageUrlController,
                decoration: InputDecoration(hintText: 'Enter card image URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () async {
                try {
                  await dbHelper.createCard(
                    cardNameController.text,
                    cardSuitController.text,
                    cardImageUrlController.text,
                    widget.folderId,
                  );
                  _fetchCards();
                  Navigator.of(context).pop();
                } catch (e) {
                  print(e);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCard(int id) async {
    await dbHelper.deleteCard(id);
    _fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cards in ${widget.folderName}'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            child: Column(
              children: [
                Image.asset(card['image_url'], fit: BoxFit.cover),
                Text(card['name']),
                Text(card['suit']),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCard(card['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCard,
        child: Icon(Icons.add),
      ),
    );
  }
}
