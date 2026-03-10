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

    return GestureDetector(
      onTap: onEdit,  // ← Tap anywhere → Edit
      onLongPress: onDelete,  // ← Long press → Delete (replaces menu)
      child: InkWell(  // ← Ripple effect on tap
        borderRadius: BorderRadius.circular(12),  // Match Card radius
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          shape: RoundedRectangleBorder(  // Rounded corners
            borderRadius: BorderRadius.circular(12),
          ),
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
                  ],
                ),
                Text(
                  currencyFormat.format(account.amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (account.notes != null && account.notes!.isNotEmpty)
                  Text(
                    '${account.notes}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                Text(
                  'Updated: ${DateFormat.yMMMd().format(account.lastUpdated)}',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}