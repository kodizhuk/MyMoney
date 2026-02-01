import 'package:flutter/material.dart';
import '../models/savings_account.dart';
import '../services/database_service.dart';
import '../widgets/savings_account_widget.dart';
import 'add_edit_savings_account_screen.dart';
import 'settings_screen.dart';

class SavingsScreen extends StatefulWidget {
  final ValueNotifier<int>? navIndexNotifier;
  const SavingsScreen({super.key, this.navIndexNotifier});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<SavingsAccount> _savingsAccounts = [];
  bool _isLoading = true;
  double _settingsUsdRate = 42.0;
  double _settingsEurRate = 51.0;

  @override
  void initState() {
    super.initState();
    _loadSavingsAccounts();
    widget.navIndexNotifier?.addListener(_onNavIndexChanged);
  }

  void _onNavIndexChanged() {
    if (widget.navIndexNotifier?.value == 2) {
      _loadSavingsAccounts();
    }
  }

  @override
  void dispose() {
    widget.navIndexNotifier?.removeListener(_onNavIndexChanged);
    super.dispose();
  }

  Future<void> _loadSavingsAccounts() async {
    setState(() => _isLoading = true);
    try {
      final savingsAccounts = await _dbService.getSavingsAccounts();
      final rates = await _dbService.getExchangeRates();
      setState(() {
        _savingsAccounts = savingsAccounts;
        _settingsUsdRate = rates['usd'] ?? _settingsUsdRate;
        _settingsEurRate = rates['eur'] ?? _settingsEurRate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading savings accounts: $e')),
      );
    }
  }

  void _addSavingsAccount() async {
    final result = await Navigator.push<SavingsAccount>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditSavingsAccountScreen(),
      ),
    );

    if (result != null) {
      try {
        await _dbService.insertSavingsAccount(result);
        _loadSavingsAccounts(); // Reload to get the updated list with IDs
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving savings account: $e')),
        );
      }
    }
  }

  void _editSavingsAccount(SavingsAccount account) async {
    final result = await Navigator.push<SavingsAccount>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSavingsAccountScreen(account: account),
      ),
    );

    if (result != null) {
      try {
        await _dbService.updateSavingsAccount(result);
        _loadSavingsAccounts(); // Reload to get the updated list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating savings account: $e')),
        );
      }
    }
  }

  void _deleteSavingsAccount(SavingsAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Savings Account'),
        content: Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && account.id != null) {
      try {
        await _dbService.deleteSavingsAccount(account.id!);
        _loadSavingsAccounts(); // Reload to get the updated list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting savings account: $e')),
        );
      }
    }
  }

  double get _totalSavings {
    // Calculate total in USD
    return _savingsAccounts.fold(0.0, (sum, account) {
      double usdAmount = 0.0;
      if (account.currency == 'USD') {
        usdAmount = account.amount;
      } else if (account.currency == 'UAH') {
        // Convert UAH -> USD using the account's stored USD rate (USD->UAH)
        final rate = account.usdRate > 0 ? account.usdRate : _settingsUsdRate;
        usdAmount = rate > 0 ? (account.amount / rate) : 0.0;
      } else if (account.currency == 'EUR') {
        // Convert EUR -> UAH using settings eur rate, then UAH -> USD using settings usd rate
        final eurRate = _settingsEurRate > 0 ? _settingsEurRate : 1.0;
        final usdRate = _settingsUsdRate > 0 ? _settingsUsdRate : 1.0;
        usdAmount = (account.amount * eurRate) / usdRate;
      } else {
        // Fallback: treat as USD
        usdAmount = account.amount;
      }
      return sum + usdAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Total Savings: ${_formatTotalSavings()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savingsAccounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No savings accounts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first savings account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _savingsAccounts.length,
              itemBuilder: (context, index) {
                final account = _savingsAccounts[index];
                return SavingsAccountWidget(
                  account: account,
                  onEdit: () => _editSavingsAccount(account),
                  onDelete: () => _deleteSavingsAccount(account),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSavingsAccount,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTotalSavings() {
    return r'$' + _totalSavings.toStringAsFixed(2);
  }
}