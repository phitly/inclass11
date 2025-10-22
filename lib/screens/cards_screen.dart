import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';
import '../models/card.dart' as card_model;
import '../services/image_service.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<card_model.Card> cardsInFolder = [];
  List<card_model.Card> availableCards = [];
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
      final folderCards = await DatabaseHelper.instance.getCardsInFolder(widget.folder.id!);
      final unassignedCards = await DatabaseHelper.instance.getUnassignedCardsBySuit(widget.folder.suit);

      setState(() {
        cardsInFolder = folderCards;
        availableCards = unassignedCards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  Future<void> _addCardToFolder(card_model.Card card) async {
    // Check folder limit
    if (cardsInFolder.length >= 6) {
      _showErrorDialog('This folder can only hold 6 cards.');
      return;
    }

    try {
      final updatedCard = card.copyWith(folderId: widget.folder.id);
      await DatabaseHelper.instance.updateCard(updatedCard);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${card.displayName} to ${widget.folder.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding card: $e')),
        );
      }
    }
  }

  Future<void> _removeCardFromFolder(card_model.Card card) async {
    try {
      final updatedCard = card.copyWith(folderId: null);
      await DatabaseHelper.instance.updateCard(updatedCard);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${card.displayName} from ${widget.folder.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing card: $e')),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog() {
    if (cardsInFolder.length < 3) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Warning'),
            content: Text('You need at least 3 cards in this folder. Currently you have ${cardsInFolder.length} cards.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildCardItem(card_model.Card card, bool isInFolder) {
    Color cardColor = _getCardColor(card.suit);
    
    return Card(
      elevation: 2,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Card image
            FutureBuilder<Widget>(
              future: ImageService.instance.getCardImageWidget(card, width: 60, height: 80),
              builder: (context, snapshot) {
                return SizedBox(
                  width: 60,
                  height: 80,
                  child: snapshot.hasData 
                      ? snapshot.data!
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Card details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _getSuitIcon(card.suit),
                      const SizedBox(width: 4),
                      Text(
                        card.suit,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action button
            IconButton(
              icon: Icon(
                isInFolder ? Icons.remove_circle : Icons.add_circle,
                color: isInFolder ? Colors.red : Colors.green,
                size: 28,
              ),
              onPressed: () {
                if (isInFolder) {
                  _removeCardFromFolder(card);
                } else {
                  _addCardToFolder(card);
                }
              },
            ),
          ],
        ),
      ),
    );
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
        icon = Icons.help;
    }

    return Icon(icon, color: color);
  }

  Color _getCardColor(String suit) {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _showWarningDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.folder.name} Cards'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Folder status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: cardsInFolder.length >= 3 && cardsInFolder.length <= 6
                            ? Colors.green.shade100
                            : cardsInFolder.length > 6
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${cardsInFolder.length} / 6 cards in folder',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (cardsInFolder.length < 3)
                            Text(
                              'Need ${3 - cardsInFolder.length} more cards (minimum)',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          if (cardsInFolder.length > 6)
                            Text(
                              'Too many cards! Remove ${cardsInFolder.length - 6}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Cards in folder
                    const Text(
                      'Cards in this folder:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (cardsInFolder.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'No cards in this folder yet.\nAdd some cards from below!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: cardsInFolder
                            .map((card) => _buildCardItem(card, true))
                            .toList(),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Available cards to add
                    const Text(
                      'Available cards to add:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (availableCards.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'No more ${widget.folder.suit} cards available to add.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: availableCards
                            .map((card) => _buildCardItem(card, false))
                            .toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}