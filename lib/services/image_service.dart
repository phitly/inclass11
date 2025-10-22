import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/card.dart' as card_model;

class ImageService {
  static final ImageService instance = ImageService._init();
  ImageService._init();

  // Cache for loaded images
  final Map<int, Uint8List> _imageCache = {};

  /// Get image for a card, preferring cached data over network
  Future<Widget> getCardImageWidget(card_model.Card card, {double? width, double? height}) async {
    try {
      // First try to get from memory cache
      if (_imageCache.containsKey(card.id)) {
        return Image.memory(
          _imageCache[card.id]!,
          width: width ?? 80,
          height: height ?? 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
        );
      }

      // Then try to get from database
      if (card.imageData != null) {
        final imageBytes = Uint8List.fromList(card.imageData!);
        _imageCache[card.id!] = imageBytes;
        return Image.memory(
          imageBytes,
          width: width ?? 80,
          height: height ?? 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
        );
      }

      // Try to load from assets first, then fall back to network
      final assetPath = _getAssetPath(card);
      return Image.asset(
        assetPath,
        width: width ?? 80,
        height: height ?? 120,
        fit: BoxFit.cover,
        errorBuilder: (context, assetError, stackTrace) {
          // If asset fails, try network image
          return Image.network(
            card.imageUrl,
            width: width ?? 80,
            height: height ?? 120,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingWidget(width, height);
            },
            errorBuilder: (context, networkError, stackTrace) {
              // If both fail, use placeholder card image
              return _buildPlaceholderCard(card, width, height);
            },
          );
        },
      );
    } catch (e) {
      return _buildErrorWidget(width, height);
    }
  }

  /// Download and cache image for a card
  Future<bool> downloadAndCacheImage(card_model.Card card) async {
    try {
      // Note: In a real app, you'd use http package to download
      // For this demo, we'll simulate with placeholder data
      final placeholderData = await _generatePlaceholderImageData(card);
      
      if (placeholderData != null) {
        await DatabaseHelper.instance.updateCardImage(card.id!, placeholderData);
        _imageCache[card.id!] = Uint8List.fromList(placeholderData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate placeholder image data for a card
  Future<List<int>?> _generatePlaceholderImageData(card_model.Card card) async {
    try {
      // In a real implementation, you'd generate or download actual image bytes
      // For demo purposes, we'll create a simple byte array representing the card
      final cardString = '${card.value}_${card.suit}';
      return cardString.codeUnits;
    } catch (e) {
      return null;
    }
  }

  /// Get asset path for a card image
  String _getAssetPath(card_model.Card card) {
    final suitCode = card.suit.substring(0, 1).toLowerCase();
    final valueCode = card.value.toLowerCase();
    return 'assets/cards/$valueCode$suitCode.png';
  }

  /// Build a placeholder card widget with text
  Widget _buildPlaceholderCard(card_model.Card card, double? width, double? height) {
    return Container(
      width: width ?? 80,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: _getCardBackgroundColor(card.suit),
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getSuitIcon(card.suit),
          const SizedBox(height: 4),
          Text(
            card.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getSuitColor(card.suit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(double? width, double? height) {
    return Container(
      width: width ?? 80,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width ?? 80,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getCardBackgroundColor(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
      case 'diamonds':
        return Colors.red.shade50;
      case 'spades':
      case 'clubs':
        return Colors.grey.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getSuitColor(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
      case 'diamonds':
        return Colors.red.shade700;
      case 'spades':
      case 'clubs':
        return Colors.black87;
      default:
        return Colors.grey;
    }
  }

  Widget _getSuitIcon(String suit) {
    IconData icon;
    Color color = _getSuitColor(suit);

    switch (suit.toLowerCase()) {
      case 'hearts':
        icon = Icons.favorite;
        break;
      case 'diamonds':
        icon = Icons.diamond;
        break;
      case 'spades':
        icon = Icons.spa;
        break;
      case 'clubs':
        icon = Icons.local_florist;
        break;
      default:
        icon = Icons.help;
    }

    return Icon(icon, color: color, size: 24);
  }

  /// Download all card images in background
  Future<void> downloadAllCardImages() async {
    try {
      final cards = await DatabaseHelper.instance.getAllCards();
      for (final card in cards) {
        await downloadAndCacheImage(card);
        // Add small delay to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Handle error silently for background operation
    }
  }

  /// Clear all cached images
  void clearImageCache() {
    _imageCache.clear();
  }

  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'cachedImages': _imageCache.length,
      'memoryUsage': _imageCache.values.fold<int>(0, (sum, bytes) => sum + bytes.length),
    };
  }
}