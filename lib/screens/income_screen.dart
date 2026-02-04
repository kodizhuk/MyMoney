import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class IncomeScreen extends StatefulWidget {
  final ValueNotifier<int>? navIndexNotifier;
  const IncomeScreen({super.key, this.navIndexNotifier});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _incomeTransactions = [];
  List<Transaction> _expenseTransactions = [];
  bool _isLoading = true;
  double _settingsUsdRate = 42.0;
  double _settingsEurRate = 51.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    widget.navIndexNotifier?.addListener(_onNavIndexChanged);
  }

  void _onNavIndexChanged() {
    if (widget.navIndexNotifier?.value == 0) {
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    widget.navIndexNotifier?.removeListener(_onNavIndexChanged);
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _dbService.getTransactions('income');
      final expenses = await _dbService.getTransactions('expense');
      final rates = await _dbService.getExchangeRates();
      setState(() {
        _incomeTransactions = transactions;
        _expenseTransactions = expenses;
        _settingsUsdRate = rates['usd'] ?? _settingsUsdRate;
        _settingsEurRate = rates['eur'] ?? _settingsEurRate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    }
  }

  void _addTransaction() async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(type: 'income'),
      ),
    );

    if (result != null) {
      try {
        await _dbService.insertTransaction(result);
        _loadTransactions(); // Reload to get the updated list with IDs
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  void _deleteTransaction(int index) async {
    final transaction = _incomeTransactions[index];
    if (transaction.id != null) {
      try {
        await _dbService.deleteTransaction(transaction.id!);
        _loadTransactions(); // Reload to get the updated list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  void _editTransaction(int index) async {
    final transaction = _incomeTransactions[index];
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          type: 'income',
          existingTransaction: transaction,
        ),
      ),
    );

    if (result != null) {
      try {
        await _dbService.updateTransaction(result);
        _loadTransactions(); // Reload to get the updated list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  double get _totalIncome {
    return _incomeTransactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }
  String _formatTotal() {
    String symbol = '₴';
    if (_incomeTransactions.isNotEmpty) {
      switch (_incomeTransactions.first.currency) {
        case 'USD':
          symbol = r'$';
          break;
        case 'EUR':
          symbol = '€';
          break;
        case 'UAH':
        default:
          symbol = '₴';
      }
    }
    return 'Total Income: $symbol${_totalIncome.toStringAsFixed(2)}';
  }

  String _calculateTithe() {
    // Convert all income to UAH
    double totalIncomeUAH = _incomeTransactions.fold(0.0, (sum, tx) {
      double amt = tx.amount;
      if (tx.currency == 'USD') {
        final rate = tx.usdRate > 0 ? tx.usdRate : _settingsUsdRate;
        amt = tx.amount * rate;
      } else if (tx.currency == 'EUR') {
        final eurRate = _settingsEurRate > 0 ? _settingsEurRate : 1.0;
        amt = tx.amount * eurRate;
      }
      return sum + amt;
    });

    // Sum expenses whose source/category equals 'Tithes' (case-insensitive), in UAH
    double titheExpensesUAH = _expenseTransactions.fold(0.0, (sum, tx) {
      if ((tx.source ?? '').toString().toLowerCase() != 'tithes') return sum;
      double amt = tx.amount;
      if (tx.currency == 'USD') {
        final rate = tx.usdRate > 0 ? tx.usdRate : _settingsUsdRate;
        amt = tx.amount * rate;
      } else if (tx.currency == 'EUR') {
        final eurRate = _settingsEurRate > 0 ? _settingsEurRate : 1.0;
        amt = tx.amount * eurRate;
      }
      return sum + amt;
    });

    final titheUAH = totalIncomeUAH * 0.1;
    final resultUAH = titheUAH - titheExpensesUAH;
    return '₴${resultUAH.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tithe: ${_calculateTithe()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
              );
            },
          ),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incomeTransactions.isEmpty
          ? const Center(
              child: Text('No income transactions yet'),
            )
          : ListView.builder(
              itemCount: _incomeTransactions.length,
              itemBuilder: (context, index) {
                return TransactionItem(
                  transaction: _incomeTransactions[index],
                  onDelete: () => _deleteTransaction(index),
                  onEdit: () => _editTransaction(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}