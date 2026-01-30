import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type; // 'income', 'expense', or 'saving'
  final Transaction? existingTransaction;

  const AddTransactionScreen({
    super.key,
    required this.type,
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

  final List<String> _incomeSources = [
    'Renesas',
    'Company2',
    'Other',
  ];

  final List<String> _expenseCategories = [
    'Tithes',
    'Donations',
    'Bills',
    'Other'
  ];

  final List<String> _savingCategories = [
    'Emergency Fund',
    'Vacation',
    'Investment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _selectedSource = widget.existingTransaction!.name;
      _amountController.text = widget.existingTransaction!.amount.toString();
      _selectedDate = widget.existingTransaction!.date;
    }
  }

  List<String> get _availableSources {
    switch (widget.type) {
      case 'income':
        return _incomeSources;
      case 'expense':
        return _expenseCategories;
      case 'saving':
        return _savingCategories;
      default:
        return ['Other'];
    }
  }

  String get _sourceLabel {
    switch (widget.type) {
      case 'income':
        return 'Source';
      case 'expense':
        return 'Category';
      case 'saving':
        return 'Category';
      default:
        return 'Source';
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
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSource,
                decoration: InputDecoration(
                  labelText: _sourceLabel,
                ),
                items: _availableSources.map((source) {
                  return DropdownMenuItem(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a $_sourceLabel';
                  }
                  return null;
                },
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

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: widget.existingTransaction?.id,
        type: widget.type,
        date: _selectedDate,
        name: _selectedSource!,
        amount: double.parse(_amountController.text),
        source: null, // No longer needed since we use name for the category/source
      );

      Navigator.pop(context, transaction);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}