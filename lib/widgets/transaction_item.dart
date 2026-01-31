import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    String symbol;
    switch (widget.transaction.currency) {
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
    final currencyFormat = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );

    return GestureDetector(
      onHorizontalDragStart: (details) {
        // Drag started
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          // Limit the drag offset
          _dragOffset = _dragOffset.clamp(-100.0, 100.0);
        });
      },
      onHorizontalDragEnd: (details) {
        // Handle swipe actions
        if (_dragOffset > 50) {
          // Swiped right - Edit
          widget.onEdit();
        } else if (_dragOffset < -50) {
          // Swiped left - Delete
          _showDeleteConfirmation();
        }

        // Reset drag offset
        setState(() {
          _dragOffset = 0.0;
        });
      },
      child: Stack(
        children: [
          // Background for edit (right swipe) - only show when dragging right
          if (_dragOffset > 0)
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: Colors.blue,
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
            ),
          // Background for delete (left swipe) - only show when dragging left
          if (_dragOffset < 0)
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
          // Main content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.transaction.type == 'income'
                      ? Colors.green
                      : widget.transaction.type == 'expense'
                      ? Colors.red
                      : Colors.blue,
                  child: Icon(
                    widget.transaction.type == 'income'
                        ? Icons.trending_up
                        : widget.transaction.type == 'expense'
                        ? Icons.trending_down
                        : Icons.savings,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  widget.transaction.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(widget.transaction.date),
                    ),
                    if (widget.transaction.source != null)
                      Text(
                        'Source: ${widget.transaction.source}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: Text(
                  currencyFormat.format(widget.transaction.amount),
                  style: TextStyle(
                    color: widget.transaction.type == 'income'
                        ? Colors.green
                        : widget.transaction.type == 'expense'
                        ? Colors.red
                        : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}