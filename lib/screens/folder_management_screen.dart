import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  List<Folder> folders = [];
  bool isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _suitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _suitController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedFolders = await DatabaseHelper.instance.getAllFolders();
      setState(() {
        folders = loadedFolders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading folders: $e')),
        );
      }
    }
  }

  Future<void> _showCreateFolderDialog() async {
    _nameController.clear();
    _suitController.clear();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'e.g., Custom Hearts',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _suitController,
                decoration: const InputDecoration(
                  labelText: 'Suit',
                  hintText: 'Hearts, Spades, Diamonds, or Clubs',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty && _suitController.text.isNotEmpty) {
                  await _createFolder();
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFolder() async {
    try {
      final folder = Folder(
        name: _nameController.text.trim(),
        suit: _suitController.text.trim(),
        timestamp: DateTime.now(),
      );
      
      await DatabaseHelper.instance.insertFolder(folder);
      await _loadFolders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created folder: ${folder.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating folder: $e')),
        );
      }
    }
  }

  Future<void> _showEditFolderDialog(Folder folder) async {
    _nameController.text = folder.name;
    _suitController.text = folder.suit;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _suitController,
                decoration: const InputDecoration(
                  labelText: 'Suit',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty && _suitController.text.isNotEmpty) {
                  await _updateFolder(folder);
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateFolder(Folder folder) async {
    try {
      final updatedFolder = folder.copyWith(
        name: _nameController.text.trim(),
        suit: _suitController.text.trim(),
      );
      
      await DatabaseHelper.instance.updateFolder(updatedFolder);
      await _loadFolders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated folder: ${updatedFolder.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating folder: $e')),
        );
      }
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text('Are you sure you want to delete "${folder.name}"?\n\nAll cards in this folder will be moved back to the unassigned pile.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteFolder(folder.id!);
        await _loadFolders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted folder: ${folder.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting folder: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Folders'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFolderDialog,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Folder Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create, edit, or delete custom folders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: folders.isEmpty
                        ? const Center(
                            child: Text(
                              'No folders created yet.\nTap + to create your first folder!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: folders.length,
                            itemBuilder: (context, index) {
                              final folder = folders[index];
                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  title: Text(
                                    folder.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text('Suit: ${folder.suit}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditFolderDialog(folder),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteFolder(folder),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}