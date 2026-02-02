# MyMoney



## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Folder Structure
- models/ - Data models and classes
    - transaction.dart - Transaction model (income/expense)
    - category.dart - Category model for transaction types
- screens/ - UI screens/pages
    - home_screen.dart - Main dashboard showing balance and recent transactions
    - add_transaction_screen.dart - Screen to add new income/expense
    - transaction_list_screen.dart - List of all transactions with filters
    - statistics_screen.dart - Charts and analytics
- widgets/ - Reusable UI components
    - transaction_item.dart - Individual transaction list item
    - balance_card.dart - Balance display widget
    - category_selector.dart - Dropdown/selector for categories
- services/ - Business logic and data handling
    - database_service.dart - SQLite database operations
    - transaction_service.dart - Transaction CRUD operations
- utils/ - Helper functions and constants
    - constants.dart - App constants (colors, categories, etc.)
    - date_formatter.dart - Date formatting utilities

## Screenshots

## Features
1. Icome Screen - you can add income and choose income source. 
2. Expences Screen - to add Donatinon, Tithe or another from category
3. Savings - to have all your savings in one place
4. Statistics - show the icome by month or years. Alsi could be filtered by income source