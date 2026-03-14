import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'edit_sources_screen.dart';
import 'edit_categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usdController = TextEditingController(
    text: '42',
  );
  final TextEditingController _eurController = TextEditingController(
    text: '51',
  );

  @override
  void dispose() {
    _usdController.dispose();
    _eurController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    try {
      final rates = await DatabaseService().getExchangeRates();
      setState(() {
        _usdController.text = rates['usd']!.toString().replaceAll(
          RegExp(r'\.0+\$'),
          '',
        );
        _eurController.text = rates['eur']!.toString().replaceAll(
          RegExp(r'\.0+\$'),
          '',
        );
      });
    } catch (e) {
      // leave defaults
    }
  }

  void _saveRates() {
    if (!_formKey.currentState!.validate()) return;
    final currency = 'UAH';
    final usdRate = double.tryParse(_usdController.text) ?? 42.0;
    DatabaseService()
        .setExchangeRates(currency, usdRate)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved rates — USD: $usdRate')),
          );
        })
        .catchError((e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving rates: $e')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRates),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   children: [
                //     const Expanded(child: Text('USD rate')),
                //     const SizedBox(width: 12),
                //     SizedBox(
                //       width: 120,
                //       child: TextFormField(
                //         controller: _usdController,
                //         decoration: const InputDecoration(hintText: '42', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                //         textAlign: TextAlign.right,
                //         keyboardType: TextInputType.numberWithOptions(decimal: true),
                //         validator: (v) {
                //           if (v == null || v.isEmpty) return 'Enter USD rate';
                //           if (double.tryParse(v) == null) return 'Enter a valid number';
                //           return null;
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),
                // Row(
                //   children: [
                //     const Expanded(child: Text('EUR rate')),
                //     const SizedBox(width: 12),
                //     SizedBox(
                //       width: 120,
                //       child: TextFormField(
                //         controller: _eurController,
                //         decoration: const InputDecoration(hintText: '51', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                //         textAlign: TextAlign.right,
                //         keyboardType: TextInputType.numberWithOptions(decimal: true),
                //         validator: (v) {
                //           if (v == null || v.isEmpty) return 'Enter EUR rate';
                //           if (double.tryParse(v) == null) return 'Enter a valid number';
                //           return null;
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 24),
                // ElevatedButton(onPressed: _saveRates, child: const Text('Save')),
                // const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language settings coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: const Text('Light'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme settings coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export All'),
                  subtitle: const Text('to CSV file'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting database...')),
                    );
                    try {
                      // final path = await DatabaseService().exportDatabase();
                      final path = await DatabaseService().exportDBToCsv();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Database exported to $path')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error exporting database: $e')),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Import All'),
                  subtitle: const Text('from CSV file'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );
                      if (result == null || result.files.isEmpty) return;
                      final path = result.files.single.path;
                      if (path == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Importing CSV...')),
                      );
                      final file = File(path);
                      final csvContent = await file.readAsString();
                      await DatabaseService().importFromCsv(csvContent);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV imported successfully'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error importing CSV: $e')),
                      );
                    }
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Income Sources'),
                  subtitle: const Text('Manage income sources and categories'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditSourcesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear Database'),
                  subtitle: const Text(
                    'Delete all transactions, savings, and sources',
                  ),
                  trailing: const Icon(Icons.warning, color: Colors.red),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Database'),
                        content: const Text(
                          'This will permanently delete all your transactions, savings accounts, and sources. This action cannot be undone. Are you sure?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await DatabaseService().clearDatabase();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Database cleared successfully'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error clearing database: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Expance Categories'),
                  subtitle: const Text('Manage expense categories'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditCategoriesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  subtitle: const Text('Money Tracker v0.0.1'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Money Tracker',
                      applicationVersion: '0.0.1',
                      applicationLegalese: '© 2026 Money Tracker App',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          '\tIncomeTracker is a financial tracker that simplifies managing your income, expenses, and long-term savings in one place.\n \tIt features detailed visual statistics to break down earnings by category and includes a built-in calculator to automatically determine your church tithe.\n \t No AD, no tracking, all data are saved in local database on your device.',
                          textAlign: TextAlign.left,
                        ),
                      ],
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.new_releases),
                  title: const Text('What\'s New'),
                  subtitle: const Text('Version 0.0.1'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('What\'s New'),
                        content: const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('• TBD'),
                              Text('• TBD'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
