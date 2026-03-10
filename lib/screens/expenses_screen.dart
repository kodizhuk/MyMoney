import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  final List<String> expenseCategoriesDefault = [
    'Tithe',
    'Donateions',
    'Rent',
  ];

  // methods for the current view
  DateTime _selectedDate = DateTime.now();
  String _getDate(){
    return DateFormat('MMMM yyyy').format(_selectedDate);

  }
  void _nextDate() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    _loadTransactions(); // Reload transactions for the new month
    setState(() {});
  }
  void _previousDate() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    _loadTransactions(); // Reload transactions for the new month
    setState(() {});
  }

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
          _expenseTransactions = transactions.where((tx) {
          return tx.date.year == _selectedDate.year && tx.date.month == _selectedDate.month;
        }).toList();
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
        builder: (context) => AddTransactionScreen(
          type: 'expense',
          defaultCategories: expenseCategoriesDefault,
          ),
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
          defaultCategories: expenseCategoriesDefault,
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
      ),
      
      body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              // Date selector row (fixed height)
              SizedBox(
                height: 50,  // Fixed height for buttons + padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_left),
                      iconSize: 48.0,
                      tooltip: 'Previous Date',
                      onPressed: _previousDate,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _getDate(),
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right),
                      iconSize: 48.0,
                      tooltip: 'Next Date',
                      onPressed: _nextDate,
                    ),
                  ],
                ),
              ),
              // Income transactions list (takes remaining space)
              _expenseTransactions.isEmpty
              ? const Text(
                'No income transactions yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              )
              :Expanded(
                child: ListView.builder(
                  itemCount: _expenseTransactions.length,
                  itemBuilder: (context, index) {
                    return TransactionItem(
                      transaction: _expenseTransactions[index],
                      onDelete: () => _deleteTransaction(index),
                      onEdit: () => _editTransaction(index),
                    );
                  },
                ),
              ),
            ],
          )
      ),
      // body: _isLoading
      //     ? const Center(child: CircularProgressIndicator())
      //     : _expenseTransactions.isEmpty
      //     ? const Center(
      //         child: Text('No expense transactions yet'),
      //       )
      //     : ListView.builder(
      //         itemCount: _expenseTransactions.length,
      //         itemBuilder: (context, index) {
      //           return TransactionItem(
      //             transaction: _expenseTransactions[index],
      //             onDelete: () => _deleteTransaction(index),
      //             onEdit: () => _editTransaction(index),
      //           );
      //         },
      //       ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}