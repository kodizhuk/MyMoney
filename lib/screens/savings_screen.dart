import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_account.dart';
import '../services/database_service.dart';
import 'add_edit_savings_account_screen.dart';
import '../widgets/savings_account_widget.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'package:flutter_draggable_gridview/flutter_draggable_gridview.dart';

class SavingsScreen extends StatefulWidget {
  final ValueNotifier<int>? navIndexNotifier;
  const SavingsScreen({super.key, this.navIndexNotifier});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final List<SavingsAccount> _savingsAccounts = [];

  bool _isLoading = true;
  String _selectedCurrency = 'All';
  double _settingsUsdRate = 42.0;
  double _settingsEurRate = 51.0;

  late List<DraggableGridItem> _items;

  @override
  void initState() {
    super.initState();
    _loadSavingsAccounts();
    widget.navIndexNotifier?.addListener(_onNavIndexChanged);
    
    _items = List.generate(
      6,
      (index) => DraggableGridItem(
        isDraggable: true,
        child: Container(
          color: Colors.primaries[index % Colors.primaries.length],
          child: Center(
            child: Text(
              'Item $index',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );

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
      _savingsAccounts.clear();
      setState(() {
        for (final acc in savingsAccounts) {
          if (acc.currency == 'UAH' && _selectedCurrency == 'UAH') {
            _savingsAccounts.add(acc);
          } else if (acc.currency == 'USD' && _selectedCurrency == 'USD') {
            _savingsAccounts.add(acc);
          } else if (acc.currency == 'EUR' && _selectedCurrency == 'EUR') {
            _savingsAccounts.add(acc);
          } else if (_selectedCurrency == 'All') {
            _savingsAccounts.add(acc);
          }
        }

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
    // Calculate total depends on the selected currency
    return _savingsAccounts.fold(0.0, (sum, account) {
      if (_selectedCurrency == 'UAH') {
        //count all the account money of the selected currency
        if (account.currency == 'UAH') {
          sum += account.amount;
          //print('curr $amount ${account.currency}');
        }
      } else if (_selectedCurrency == 'USD') {
        if (account.currency == 'USD') {
          sum += account.amount;
          //print('curr $amount ${account.currency}');
        }
      } else if (_selectedCurrency == 'EUR') {
        if (account.currency == 'EUR') {
          sum += account.amount;
        }
      } else {
        // count total
        sum += account.amount;
        //print('curr $amount ${account.currency}');
      }

      return sum;
    });
  }  




  @override
  Widget build(BuildContext context) {
    
    final List<String> items;
    items = List<String>.generate(20, (i) => 'Item ${i + 1}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
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
        padding: EdgeInsets.all(8),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                    label: Text('UAH'),
                    selected: _selectedCurrency == 'UAH',
                    onSelected: (_) => setState(() {
                      _selectedCurrency = 'UAH';
                      _loadSavingsAccounts();
                    }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                    label: const Text('USD'),
                    selected: _selectedCurrency == 'USD',
                    onSelected: (_) => setState(() {
                      _selectedCurrency = 'USD';
                      _loadSavingsAccounts();
                    }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                    label: const Text('EUR'),
                    selected: _selectedCurrency == 'EUR',
                    onSelected: (_) => setState(() {
                      _selectedCurrency = 'EUR';
                      _loadSavingsAccounts();
                    }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCurrency == 'All',
                    onSelected: (_) => setState(() {
                      _selectedCurrency = 'All';
                      _loadSavingsAccounts();
                    }),
                    ),
                  ],
                  ),
                  Container(
                  padding: EdgeInsets.zero,
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
                  Expanded(
                  child: _savingsAccounts.isEmpty
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
                    : GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(8.0),
                      mainAxisSpacing: 2.0,
                      crossAxisSpacing: 2.0,
                      childAspectRatio: 1.6,
                      children: _savingsAccounts.map<Widget>((account) {
                        return SavingsAccountWidget(
                          account: account,
                          onEdit: () => _editSavingsAccount(account),
                          onDelete: () => _deleteSavingsAccount(account),
                        );
                      }).toList(),
                  ),
                  )
                ],
                
              
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSavingsAccount,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTotalSavings() {
    String currencySymbol;
    switch (_selectedCurrency) {
      case 'USD':
        currencySymbol = r'$';
        break;
      case 'EUR':
        currencySymbol = r'€';
        break;
      case 'UAH':
        currencySymbol = r'₴';
        break;
      default:
        currencySymbol = r'$';
    }
    var formatter = NumberFormat('#,##,000');
    String _numberTotal = formatter.format(_totalSavings).trim().replaceAll(',', ' ') ;
    return _totalSavings > 0 ? '$_numberTotal $currencySymbol' : '0 $currencySymbol';
  }
}
