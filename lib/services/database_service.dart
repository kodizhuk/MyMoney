import 'package:path_provider/path_provider.dart';

import '../models/transaction.dart' as model;
import '../models/savings_account.dart';

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:csv/csv.dart';
import 'dart:io' as io;
import 'package:share_plus/share_plus.dart';

class TransactionsFields {
  static const String tableName = 'transactions';

  static const String type = 'type';
  static const String id = 'id';
  static const String date = 'date';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String amountUsd = 'amount_usd';
  static const String source = 'source';
  static const String currency = 'currency';
}

class SavingsAccountsFields {
  static const String tableName = 'savings_accounts';

  static const String id = 'id';
  static const String lastUpdated = 'last_updated';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String amountUsd = 'amount_usd';
  static const String currency = 'currency';
  static const String notes = 'notes';
}

class SettingsFields {
  static const String tableName = 'settings';
  static const String currency = 'currency';
  static const String usdRate = 'usd_rate';
}

class SourcesFields {
  static const String tableName = 'sources';
  static const String id = 'id';
  static const String type = 'type';
  static const String name = 'name';
  static const String color = 'color';
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
    String path = p.join(await getDatabasesPath(), 'money_tracker.db');
    return await openDatabase(
      path,
      version: 5,
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
        amount_usd REAL NOT NULL,
        source TEXT,
        currency TEXT NOT NULL DEFAULT 'UAH'
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        amount_usd REAL NOT NULL,
        notes TEXT,
        currency TEXT NOT NULL DEFAULT 'UAH',
        last_updated TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        currency TEXT NOT NULL DEFAULT 'UAH',
        usd_rate REAL NOT NULL DEFAULT 43
      )
    ''');
    await db.execute('''
      CREATE TABLE sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL
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
          amount_usd REAL NOT NULL,
          notes TEXT,
          currency TEXT NOT NULL DEFAULT 'UAH',
          last_updated TEXT
        )
      ''');
      oldVersion = 2;
    }

    if (oldVersion < 3) {
      // Add columns needed for version 3
      // If columns already exist, ignore errors.
      try {
        await db.execute(
          'ALTER TABLE ${TransactionsFields.tableName} ADD COLUMN ${TransactionsFields.currency} TEXT NOT NULL DEFAULT "UAH"',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${SavingsAccountsFields.tableName} ADD COLUMN ${SavingsAccountsFields.currency} TEXT NOT NULL DEFAULT "UAH"',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${SavingsAccountsFields.tableName} ADD COLUMN amount_usd REAL NOT NULL DEFAULT 0',
        );
      } catch (_) {}

      try {
        await db.execute(
          "ALTER TABLE ${SavingsAccountsFields.tableName} ADD COLUMN last_updated TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000'",
        );
      } catch (_) {}

      oldVersion = 3;
    }

    if (oldVersion < 4) {
      // Create settings table for version 4
      await db.execute('''
        CREATE TABLE settings (
          currency TEXT NOT NULL DEFAULT 'UAH',
          usd_rate REAL NOT NULL DEFAULT 43
        )
      ''');
      // Create sources table as well
      await db.execute('''
        CREATE TABLE sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          color TEXT NOT NULL
        )
      ''');
    }
  }

  // Settings operations
  Future<Map<String, dynamic>> getExchangeRates() async {
    final db = await database;
    try {
      final rows = await db.query(SettingsFields.tableName, limit: 1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        return {
          'currency': row[SettingsFields.currency] as String,
          'usd_rate': (row[SettingsFields.usdRate] as num).toDouble(),
        };
      }
    } catch (_) {}
    return {'currency': 'UAH', 'usd_rate': 43.0};
  }

  Future<void> setExchangeRates(String currency, double usdRate) async {
    Database db = await database;
    try {
      final rows = await db.query(SettingsFields.tableName, limit: 1);
      final data = {
        SettingsFields.currency: currency,
        SettingsFields.usdRate: usdRate,
      };
      if (rows.isNotEmpty) {
        await db.update(SettingsFields.tableName, data);
      } else {
        await db.insert(SettingsFields.tableName, data);
      }
    } catch (_) {
      // table may not exist yet, skip
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
    return List.generate(
      maps.length,
      (i) => model.Transaction.fromMap(maps[i]),
    );
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
    return await db.insert(
      SavingsAccountsFields.tableName,
      savingsAccount.toMap(),
    );
  }

  Future<List<SavingsAccount>> getSavingsAccounts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      SavingsAccountsFields.tableName,
    );
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

  /// Exports the database file to the user's Downloads folder and returns the new path.
  Future<String> exportDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), 'money_tracker.db');
    final src = io.File(dbPath);
    if (!await src.exists()) {
      throw Exception('Database file not found at $dbPath');
    }

    // Determine user's home/downloads directory
    String home = io.Platform.isWindows
        ? (io.Platform.environment['USERPROFILE'] ?? '.')
        : (io.Platform.environment['HOME'] ?? '.');
    final downloadsDir = p.join(home, 'Downloads');
    try {
      await io.Directory(downloadsDir).create(recursive: true);
    } catch (_) {}

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final destPath = p.join(downloadsDir, 'money_tracker_$timestamp.db');

    await src.copy(destPath);
    return destPath;
  }

  Future<String> exportDBToCsv() async {
    // 1) Query all transactions (income and expenses)
    final transactionRows = await _database!.query('transactions');

    // 2) Query savings accounts
    final savingsRows = await _database!.query('savings_accounts');

    if (transactionRows.isEmpty && savingsRows.isEmpty) return '';

    // 3) Define common headers for the CSV
    final headers = [
      'type', // 'income', 'expense', or 'savings'
      'id',
      'date', // For transactions: date; for savings: last_updated
      'name',
      'amount',
      'amount_usd',
      'source', // For transactions: source; for savings: empty
      'currency',
      'notes', // For transactions: empty; for savings: notes
    ];

    // 4) Map transaction rows to common format
    final mappedTransactions = transactionRows
        .map(
          (row) => [
            row[TransactionsFields.type] ?? '',
            row[TransactionsFields.id] ?? '',
            row[TransactionsFields.date] ?? '',
            row[TransactionsFields.name] ?? '',
            row[TransactionsFields.amount] ?? '',
            row[TransactionsFields.amountUsd] ?? '',
            row[TransactionsFields.source] ?? '',
            row[TransactionsFields.currency] ?? '',
            '', // Notes (empty for transactions)
          ],
        )
        .toList();

    // 5) Map savings rows to common format
    final mappedSavings = savingsRows
        .map(
          (row) => [
            'savings',
            row[SavingsAccountsFields.id] ?? '',
            row[SavingsAccountsFields.lastUpdated] ?? '',
            row[SavingsAccountsFields.name] ?? '',
            row[SavingsAccountsFields.amount] ?? '',
            row[SavingsAccountsFields.amountUsd] ?? '',
            '', // Source (empty for savings)
            row[SavingsAccountsFields.currency] ?? '',
            row[SavingsAccountsFields.notes] ?? '',
          ],
        )
        .toList();

    // 6) Combine data
    final data = <List<dynamic>>[
      headers,
      ...mappedTransactions,
      ...mappedSavings,
    ];

    // 7) Convert to CSV string
    final csvString = const ListToCsvConverter().convert(data);

    // 8) Save to app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/all_data_export_$timestamp.csv';

    final file = File(filePath);
    await file.writeAsString(csvString);

    // 9) Share the file (user can save to Downloads)
    if (!Platform.isLinux) {
      final XFile csvFile = XFile(
        filePath,
        name: 'all_data_export_$timestamp.csv',
      );
      await Share.shareXFiles([
        csvFile,
      ], text: 'Your income, expenses, and savings CSV export');
    } else {
      // Linux fallback: print path
    }

    return filePath;
  }

  Future<void> importFromCsv(String csvContent) async {
    // normalize line endings to \n for consistent parsing
    //csvData - a list of rows
    // csvContent - the raw CSV string to parse and import

    //fix csv

    final csvData = const CsvToListConverter().convert(csvContent, eol: '\n');

    if (csvData.isNotEmpty) {
      final headers = csvData[0].map((e) => e.toString().trim()).toList();
      print('Headers: $headers');
      print('Header count: ${headers.length}');
    } else {
      print('No data');
    }

    if (csvData.isEmpty) return;

    //normalize headers, delete \r if present
    csvData[0] = csvData[0]
        .map((e) => e.toString().replaceAll('\r', ''))
        .toList();

    final headers = csvData.first.map((e) => e.toString()).toList();
    final expectedHeaders = [
      'type',
      'id',
      'date',
      'name',
      'amount',
      'amount_usd',
      'source',
      'currency',
      'notes',
    ];

    // if (headers != expectedHeaders) {
    //   throw Exception('Invalid CSV format. Expected headers: $expectedHeaders');
    // }

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      final type = row[0]?.toString() ?? '';
      if (type == 'income' || type == 'expense') {
        // Insert transaction
        final transaction = model.Transaction(
          id: null, // Let DB assign ID
          type: type,
          date: DateTime.parse(row[2]?.toString() ?? ''),
          name: row[3]?.toString() ?? '',
          amount: double.tryParse(row[4]?.toString() ?? '0') ?? 0.0,
          amount_usd: double.tryParse(row[5]?.toString() ?? '0') ?? 0.0,
          source: row[6]?.toString(),
          currency: row[7]?.toString() ?? 'UAH',
        );
        await insertTransaction(transaction);
      } else if (type == 'savings') {
        // Insert savings account
        final savingsAccount = SavingsAccount(
          id: null,
          name: row[3]?.toString() ?? '',
          amount: double.tryParse(row[4]?.toString() ?? '0') ?? 0.0,
          amountUSD: double.tryParse(row[5]?.toString() ?? '0') ?? 0.0,
          notes: row[8]?.toString(),
          currency: row[7]?.toString() ?? 'UAH',
          lastUpdated: DateTime.parse(row[2]?.toString() ?? ''),
        );
        await insertSavingsAccount(savingsAccount);
      }
      // Skip unknown types
    }
  }

  /// Close the open database connection if any.
  Future<void> closeDatabase() async {
    if (_database != null) {
      try {
        await _database!.close();
      } catch (_) {}
      _database = null;
    }
  }

  Future<void> clearDatabase() async {
    Database db = await database;
    // Clear all data tables (keep settings if desired)
    await db.delete(TransactionsFields.tableName);
    await db.delete(SavingsAccountsFields.tableName);
    await db.delete(SourcesFields.tableName);
    // Optionally clear settings: await db.delete(SettingsFields.tableName);
  }

  /// Import a database file from [sourcePath], replacing the current database.
  /// Returns the destination path where the DB was written.
  Future<String> importDatabase(String sourcePath) async {
    final srcFile = io.File(sourcePath);
    if (!await srcFile.exists()) {
      throw Exception('Source file not found: $sourcePath');
    }

    // Close existing DB connection so file can be replaced
    await closeDatabase();

    final dbPath = p.join(await getDatabasesPath(), 'money_tracker.db');
    final destFile = io.File(dbPath);

    // Ensure parent directory exists
    final parent = destFile.parent;
    try {
      await parent.create(recursive: true);
    } catch (_) {}

    // Replace destination
    if (await destFile.exists()) {
      try {
        await destFile.delete();
      } catch (_) {}
    }

    await srcFile.copy(dbPath);

    return dbPath;
  }

  // Sources CRUD
  Future<List<Map<String, dynamic>>> getSources(String type) async {
    Database db = await database;
    try {
      final rows = await db.query(
        SourcesFields.tableName,
        where: '${SourcesFields.type} = ?',
        whereArgs: [type],
        orderBy: '${SourcesFields.name} ASC',
      );
      return rows;
    } catch (e) {
      // Table might not exist; attempt to create and return empty
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            color TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      return [];
    }
  }

  Future<int> insertSource(String type, String name, String color) async {
    Database db = await database;
    try {
      return await db.insert(SourcesFields.tableName, {
        SourcesFields.type: type,
        SourcesFields.name: name,
        SourcesFields.color: color,
      });
    } catch (e) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            color TEXT NOT NULL
          )
        ''');
        return await db.insert(SourcesFields.tableName, {
          SourcesFields.type: type,
          SourcesFields.name: name,
        });
      } catch (e2) {
        rethrow;
      }
    }
  }

  Future<int> deleteSource(int id) async {
    Database db = await database;
    return await db.delete(
      SourcesFields.tableName,
      where: '${SourcesFields.id} = ?',
      whereArgs: [id],
    );
  }
}
