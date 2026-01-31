import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_account.dart';

class SavingsAccountWidget extends StatelessWidget {
  final SavingsAccount account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SavingsAccountWidget({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String symbol;
    switch (account.currency) {
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
    final currencyFormat = NumberFormat.currency(symbol: symbol);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(account.amount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (account.notes != null && account.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${account.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}