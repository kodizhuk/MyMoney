import 'package:flutter/material.dart';
import '../services/database_service.dart';

class EditCategoriesScreen extends StatefulWidget {
  const EditCategoriesScreen({super.key});

  @override
  State<EditCategoriesScreen> createState() => _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends State<EditCategoriesScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _categories = [];
  final TextEditingController _newController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _db.getSources('expense');
      setState(() {
        _categories = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
    }
  }

  Future<void> _addCategory() async {
    final name = _newController.text.trim();
    if (name.isEmpty) return;
    try {
      await _db.insertSource('expense', name);
      _newController.clear();
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteSource(id);
        _loadCategories();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting category: $e')));
      }
    }
  }

  @override
  void dispose() {
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newController,
                    decoration: const InputDecoration(labelText: 'New category', hintText: 'e.g. Bills'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addCategory, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? const Center(child: Text('No categories yet'))
                      : ListView.separated(
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = _categories[index];
                            return ListTile(
                              title: Text(s['name'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(s['id'] as int, s['name'] as String),
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
