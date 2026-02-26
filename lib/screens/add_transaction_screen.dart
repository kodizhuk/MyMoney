import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type; // 'income', 'expense', or 'saving'
  final Transaction? existingTransaction;
  final List<String> defaultCategories;

  AddTransactionScreen({
    super.key,
    required this.type,
    required this.defaultCategories,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedSource;
  String _selectedCurrency = 'UAH';
  List<String> _sources = [];


  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      // load existing transaction data into form
      
      _amountController.text = widget.existingTransaction!.amount.toString();
      _selectedDate = widget.existingTransaction!.date;
      _selectedCurrency = widget.existingTransaction!.currency;
      _selectedSource = widget.existingTransaction!.source ?? widget.existingTransaction!.name;
      if(widget.type == 'income') {
        _loadIncomeSources();
      } else if (widget.type == 'expense') {
        _loadExpenseCategories();
      }
      
    }else {
      // load default sources for new transaction
      // String _default_source = widget.defaultCategories.first;
      // _selectedSource = widget.defaultCategories.first;

      if(widget.type == 'income') {
        _loadIncomeSources();
      } else if (widget.type == 'expense') {
        _loadExpenseCategories();
      }

      // setState(() {
      //   _selectedSource  = _default_source;
      // });
    }
  }
  Future<void> _loadIncomeSources() async {
    try {
      final rows = await DatabaseService().getSources('income');
      final names = rows.map((r) => (r['name'] as Object).toString()).toList();
      setState(() {
        // _sources = names.isNotEmpty ? names.cast<String>() : widget.defaultCategories;
        _sources = names.isNotEmpty ? names : widget.defaultCategories;
        _selectedSource ??= _sources.first;
      });
    } catch (e) {
      setState(() {
        _sources = widget.defaultCategories;
        // _selectedSource ??= _sources.first;
      });
    }
  }
  
  Future<void> _loadExpenseCategories() async {
    try {
      final rows = await DatabaseService().getSources('expense');
      final names = rows.map((r) => (r['name'] as Object).toString()).toList();
      setState(() {
        _sources = names.isNotEmpty ? names : widget.defaultCategories;
        _selectedSource ??= _sources.first;
      });
    } catch (e) {
      setState(() {
        _sources = widget.defaultCategories;
        // _selectedSource ??= _sources.first;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? 'Edit ${widget.type == 'income' ? 'Income' : widget.type == 'expense' ? 'Expense' : 'Saving'}'
            : 'Add ${widget.type == 'income' ? 'Income' : widget.type == 'expense' ? 'Expense' : 'Saving'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      items: ['UAH', 'USD', 'EUR'].map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField <String>(
                initialValue: _selectedSource,
                items: _sources.map((source) {
                  return DropdownMenuItem(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSource = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final rates = await DatabaseService().getExchangeRates();
        final usdRate = rates['usd'] ?? 42.0;
        final transaction = Transaction(
          id: widget.existingTransaction?.id,
          type: widget.type,
          date: _selectedDate,
          name: _selectedSource!,
          amount: double.parse(_amountController.text),
          source: _selectedSource,
          currency: _selectedCurrency,
          usdRate: usdRate,
        );

        Navigator.pop(context, transaction);
      } catch (e) {
        // fallback to default rate
        final transaction = Transaction(
          id: widget.existingTransaction?.id,
          type: widget.type,
          date: _selectedDate,
          name: _selectedSource!,
          amount: double.parse(_amountController.text),
          source: _selectedSource,
          currency: _selectedCurrency,
          usdRate: 42.0,
        );

        Navigator.pop(context, transaction);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}