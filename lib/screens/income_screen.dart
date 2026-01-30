import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _incomeTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _dbService.getTransactions('income');
      setState(() {
        _incomeTransactions = transactions;
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
    return 'Total Income: \$${_totalIncome.toStringAsFixed(2)}';
  }

  String _calculateTithe() {
    // Calculate tithe as 10% of total income
    final tithe = _totalIncome * 0.1; // 10% tithe
    return '${tithe.toStringAsFixed(2)} USD';
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
              _formatTotal(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
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