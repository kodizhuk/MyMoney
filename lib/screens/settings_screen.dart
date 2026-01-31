import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usdController = TextEditingController(text: '42');
  final TextEditingController _eurController = TextEditingController(text: '51');

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
        _usdController.text = rates['usd']!.toString().replaceAll(RegExp(r'\.0+\$'), '');
        _eurController.text = rates['eur']!.toString().replaceAll(RegExp(r'\.0+\$'), '');
      });
    } catch (e) {
      // leave defaults
    }
  }

  void _saveRates() {
    if (!_formKey.currentState!.validate()) return;
    final usd = double.tryParse(_usdController.text) ?? 42.0;
    final eur = double.tryParse(_eurController.text) ?? 51.0;
    DatabaseService().setExchangeRates(usd, eur).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved rates — USD: $usd, EUR: $eur')),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving rates: $e')),
      );
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
                Row(
                  children: [
                    const Expanded(child: Text('USD rate')),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _usdController,
                        decoration: const InputDecoration(hintText: '42', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter USD rate';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('EUR rate')),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _eurController,
                        decoration: const InputDecoration(hintText: '51', contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter EUR rate';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _saveRates, child: const Text('Save')),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings coming soon!')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.new_releases),
                  title: const Text('What\'s New'),
                  subtitle: const Text('Version 1.0.0'),
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
                              Text('Version 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('• Income and expense tracking'),
                              Text('• Multi-currency support (USD, UAH, EUR)'),
                              Text('• Savings accounts management'),
                              Text('• Tithe calculation'),
                              Text('• Swipe to delete transactions'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  subtitle: const Text('Money Tracker v1.0.0'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Money Tracker',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 Money Tracker App',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'A comprehensive money tracking application for managing income, expenses, and savings.',
                          textAlign: TextAlign.center,
                        ),
                      ],
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
