import 'package:flutter/material.dart';
import '../models/savings_account.dart';
import '../services/database_service.dart';

class AddEditSavingsAccountScreen extends StatefulWidget {
  final SavingsAccount? account;

  const AddEditSavingsAccountScreen({super.key, this.account});

  @override
  State<AddEditSavingsAccountScreen> createState() => _AddEditSavingsAccountScreenState();
}

class _AddEditSavingsAccountScreenState extends State<AddEditSavingsAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCurrency = 'UAH';

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _amountController.text = widget.account!.amount.toString();
      _notesController.text = widget.account!.notes ?? '';
      _selectedCurrency = widget.account!.currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Savings Account' : 'Add Savings Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., Emergency Fund, Vacation Savings',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  child: Text(isEditing ? 'Update Account' : 'Save Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        final rates = await DatabaseService().getExchangeRates();
        final usdRate = rates['usd'] ?? 42.0;
        final account = SavingsAccount(
          id: widget.account?.id,
          name: _nameController.text,
          amount: double.parse(_amountController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          currency: _selectedCurrency,
          usdRate: usdRate,
        );

        Navigator.pop(context, account);
      } catch (e) {
        // fallback to default rate
        final account = SavingsAccount(
          id: widget.account?.id,
          name: _nameController.text,
          amount: double.parse(_amountController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          currency: _selectedCurrency,
          usdRate: 42.0,
        );

        Navigator.pop(context, account);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}