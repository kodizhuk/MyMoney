import 'package:flutter/material.dart';
import '../services/database_service.dart';

class EditSourcesScreen extends StatefulWidget {
  const EditSourcesScreen({super.key});

  @override
  State<EditSourcesScreen> createState() => _EditSourcesScreenState();
}

class _EditSourcesScreenState extends State<EditSourcesScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _sources = [];
  final TextEditingController _newSourceController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _db.getSources('income');
      setState(() {
        _sources = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading sources: $e')));
    }
  }

  Future<void> _addSource() async {
    final name = _newSourceController.text.trim();
    if (name.isEmpty) return;
    try {
      await _db.insertSource('income', name);
      _newSourceController.clear();
      _loadSources();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding source: $e')));
    }
  }

  Future<void> _deleteSource(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Source'),
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
        _loadSources();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting source: $e')));
      }
    }
  }

  @override
  void dispose() {
    _newSourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sources'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSourceController,
                    decoration: const InputDecoration(labelText: 'New source', hintText: 'e.g. Salary'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addSource, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sources.isEmpty
                      ? const Center(child: Text('No sources yet'))
                      : ListView.separated(
                          itemCount: _sources.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = _sources[index];
                            return ListTile(
                              title: Text(s['name'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSource(s['id'] as int, s['name'] as String),
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
