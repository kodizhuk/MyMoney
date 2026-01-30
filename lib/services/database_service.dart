import '../models/transaction.dart' as model;
import '../models/savings_account.dart';

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TransactionsFields {
  static const String tableName = 'transactions';

  static const String type = 'type';
  static const String id = 'id';
  static const String date = 'date';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String source = 'source';
}

class SavingsAccountsFields {
  static const String tableName = 'savings_accounts';

  static const String id = 'id';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String notes = 'notes';
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _initializeDatabaseFactory();
  }

  void _initializeDatabaseFactory() {
    // Initialize sqflite for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'money_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        source TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create savings_accounts table for version 2
      await db.execute('''
        CREATE TABLE savings_accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          notes TEXT
        )
      ''');
    }
  }

  // Transaction CRUD operations
  Future<int> insertTransaction(model.Transaction transaction) async {
    Database db = await database;
    return await db.insert(TransactionsFields.tableName, transaction.toMap());
  }

  Future<List<model.Transaction>> getTransactions(String type) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      TransactionsFields.tableName,
      where: '${TransactionsFields.type} = ?',
      whereArgs: [type],
      orderBy: '${TransactionsFields.date} DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    Database db = await database;
    return await db.update(
      TransactionsFields.tableName,
      transaction.toMap(),
      where: '${TransactionsFields.id} = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      TransactionsFields.tableName,
      where: '${TransactionsFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalAmount(String type) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(${TransactionsFields.amount}) as total FROM ${TransactionsFields.tableName} WHERE ${TransactionsFields.type} = ?',
      [type],
    );
    return result.first['total'] ?? 0.0;
  }

  // Savings Account CRUD operations
  Future<int> insertSavingsAccount(SavingsAccount savingsAccount) async {
    Database db = await database;
    return await db.insert(SavingsAccountsFields.tableName, savingsAccount.toMap());
  }

  Future<List<SavingsAccount>> getSavingsAccounts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(SavingsAccountsFields.tableName);
    return List.generate(maps.length, (i) => SavingsAccount.fromMap(maps[i]));
  }

  Future<int> updateSavingsAccount(SavingsAccount savingsAccount) async {
    Database db = await database;
    return await db.update(
      SavingsAccountsFields.tableName,
      savingsAccount.toMap(),
      where: '${SavingsAccountsFields.id} = ?',
      whereArgs: [savingsAccount.id],
    );
  }

  Future<int> deleteSavingsAccount(int id) async {
    Database db = await database;
    return await db.delete(
      SavingsAccountsFields.tableName,
      where: '${SavingsAccountsFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalSavings() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(${SavingsAccountsFields.amount}) as total FROM ${SavingsAccountsFields.tableName}',
    );
    return result.first['total'] ?? 0.0;
  }
}
