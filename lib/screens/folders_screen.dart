import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';
import '../models/card.dart' as card_model;
import '../services/image_service.dart';
import 'cards_screen.dart';
import 'folder_management_screen.dart';
import 'image_management_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Folder> folders = [];
  Map<int, int> cardCounts = {};
  Map<int, card_model.Card?> previewCards = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedFolders = await DatabaseHelper.instance.getAllFolders();
      final Map<int, int> counts = {};
      final Map<int, card_model.Card?> previews = {};

      for (Folder folder in loadedFolders) {
        final count = await DatabaseHelper.instance.getCardCountInFolder(folder.id!);
        counts[folder.id!] = count;

        // Get first card as preview
        final cardsInFolder = await DatabaseHelper.instance.getCardsInFolder(folder.id!);
        previews[folder.id!] = cardsInFolder.isNotEmpty ? cardsInFolder.first : null;
      }

      setState(() {
        folders = loadedFolders;
        cardCounts = counts;
        previewCards = previews;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Widget _getSuitIcon(String suit) {
    Color color;
    IconData icon;

    switch (suit.toLowerCase()) {
      case 'hearts':
        color = Colors.red;
        icon = Icons.favorite;
        break;
      case 'diamonds':
        color = Colors.red;
        icon = Icons.diamond;
        break;
      case 'spades':
        color = Colors.black;
        icon = Icons.spa;
        break;
      case 'clubs':
        color = Colors.black;
        icon = Icons.local_florist;
        break;
      default:
        color = Colors.grey;
        icon = Icons.folder;
    }

    return Icon(icon, color: color, size: 48);
  }

  Color _getFolderColor(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
      case 'diamonds':
        return Colors.red.shade50;
      case 'spades':
      case 'clubs':
        return Colors.grey.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Widget _buildFolderCard(Folder folder) {
    final cardCount = cardCounts[folder.id] ?? 0;
    final previewCard = previewCards[folder.id];

    return Card(
      elevation: 4,
      color: _getFolderColor(folder.suit),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardsScreen(folder: folder),
            ),
          );
          if (result == true) {
            _loadData(); // Reload data if changes were made
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show preview card image if available, otherwise suit icon
              if (previewCard != null)
                FutureBuilder<Widget>(
                  future: ImageService.instance.getCardImageWidget(previewCard, width: 80, height: 100),
                  builder: (context, snapshot) {
                    return SizedBox(
                      width: 80,
                      height: 100,
                      child: snapshot.hasData 
                          ? snapshot.data!
                          : _getSuitIcon(folder.suit),
                    );
                  },
                )
              else
                _getSuitIcon(folder.suit),
              const SizedBox(height: 12),
              Text(
                folder.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cardCount >= 3 && cardCount <= 6
                      ? Colors.green.shade100
                      : cardCount > 6
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cardCount cards',
                  style: TextStyle(
                    color: cardCount >= 3 && cardCount <= 6
                        ? Colors.green.shade800
                        : cardCount > 6
                            ? Colors.red.shade800
                            : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (previewCard != null) ...[
                const SizedBox(height: 8),
                Text(
                  previewCard.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (cardCount < 3) ...[
                const SizedBox(height: 4),
                Text(
                  'Need ${3 - cardCount} more cards',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'folder_management') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FolderManagementScreen(),
                  ),
                );
                if (result == true) {
                  _loadData(); // Reload data if changes were made
                }
              } else if (value == 'image_management') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageManagementScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'folder_management',
                child: ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('Manage Folders'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'image_management',
                child: ListTile(
                  leading: Icon(Icons.image),
                  title: Text('Manage Images'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organize your cards by suits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Each folder can hold 3-6 cards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        return _buildFolderCard(folders[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}