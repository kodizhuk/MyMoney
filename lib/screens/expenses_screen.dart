import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final ValueNotifier<int>? navIndexNotifier;
  const ExpensesScreen({super.key, this.navIndexNotifier});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _expenseTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    widget.navIndexNotifier?.addListener(_onNavIndexChanged);
  }

  void _onNavIndexChanged() {
    if (widget.navIndexNotifier?.value == 1) {
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
      final transactions = await _dbService.getTransactions('expense');
      setState(() {
        _expenseTransactions = transactions;
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
        builder: (context) => const AddTransactionScreen(type: 'expense'),
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
    final transaction = _expenseTransactions[index];
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
    final transaction = _expenseTransactions[index];
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          type: 'expense',
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

  double get _totalExpenses {
    return _expenseTransactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }
  String _formatTotal() {
    String symbol = '₴';
    if (_expenseTransactions.isNotEmpty) {
      switch (_expenseTransactions.first.currency) {
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
    return 'Total Expenses: $symbol${_totalExpenses.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
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
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenseTransactions.isEmpty
          ? const Center(
              child: Text('No expense transactions yet'),
            )
          : ListView.builder(
              itemCount: _expenseTransactions.length,
              itemBuilder: (context, index) {
                return TransactionItem(
                  transaction: _expenseTransactions[index],
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