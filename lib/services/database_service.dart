import '../models/transaction.dart' as model;
import '../models/savings_account.dart';

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' as io;

class TransactionsFields {
  static const String tableName = 'transactions';

  static const String type = 'type';
  static const String id = 'id';
  static const String date = 'date';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String source = 'source';
  static const String currency = 'currency';
  static const String usdRate = 'usd_rate';
}

class SavingsAccountsFields {
  static const String tableName = 'savings_accounts';

  static const String id = 'id';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String notes = 'notes';
  static const String currency = 'currency';
  static const String usdRate = 'usd_rate';
}

class SettingsFields {
  static const String tableName = 'settings';
  static const String usdRate = 'usd_rate';
  static const String eurRate = 'eur_rate';
}

class SourcesFields {
  static const String tableName = 'sources';
  static const String id = 'id';
  static const String type = 'type';
  static const String name = 'name';
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
        source TEXT,
        currency TEXT NOT NULL DEFAULT 'UAH'
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        currency TEXT NOT NULL DEFAULT 'UAH'
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        usd_rate REAL NOT NULL DEFAULT 42,
        eur_rate REAL NOT NULL DEFAULT 51
      )
    ''');
    await db.execute('''
      CREATE TABLE sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL
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
      oldVersion = 2;
    }

    if (oldVersion < 3) {
      // Add currency column to transactions and savings_accounts for version 3
      await db.execute('ALTER TABLE ${TransactionsFields.tableName} ADD COLUMN ${TransactionsFields.currency} TEXT NOT NULL DEFAULT "UAH"');
      await db.execute('ALTER TABLE ${SavingsAccountsFields.tableName} ADD COLUMN ${SavingsAccountsFields.currency} TEXT NOT NULL DEFAULT "UAH"');
      oldVersion = 3;
    }

    if (oldVersion < 4) {
      // Create settings table for version 4
      await db.execute('''
        CREATE TABLE settings (
          usd_rate REAL NOT NULL DEFAULT 42,
          eur_rate REAL NOT NULL DEFAULT 51
        )
      ''');
      // Create sources table as well
      await db.execute('''
        CREATE TABLE sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          name TEXT NOT NULL
        )
      ''');
    }
  }

  // Settings operations
  Future<Map<String, double>> getExchangeRates() async {
    Database db = await database;
    try {
      final rows = await db.query(SettingsFields.tableName, limit: 1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        return {
          'usd': (row[SettingsFields.usdRate] as num).toDouble(),
          'eur': (row[SettingsFields.eurRate] as num).toDouble(),
        };
      }
    } catch (_) {
      // table may not exist yet
    }
    return {'usd': 42.0, 'eur': 51.0};
  }

  Future<void> setExchangeRates(double usdRate, double eurRate) async {
    Database db = await database;
    try {
      final rows = await db.query(SettingsFields.tableName, limit: 1);
      final data = {SettingsFields.usdRate: usdRate, SettingsFields.eurRate: eurRate};
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
    try {
      return await db.insert(TransactionsFields.tableName, transaction.toMap());
    } catch (e) {
      // If insert fails (e.g., column doesn't exist), try without usd_rate
      final map = transaction.toMap();
      map.remove('usd_rate');
      return await db.insert(TransactionsFields.tableName, map);
    }
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
    try {
      return await db.update(
        TransactionsFields.tableName,
        transaction.toMap(),
        where: '${TransactionsFields.id} = ?',
        whereArgs: [transaction.id],
      );
    } catch (e) {
      // If update fails, try without usd_rate
      final map = transaction.toMap();
      map.remove('usd_rate');
      return await db.update(
        TransactionsFields.tableName,
        map,
        where: '${TransactionsFields.id} = ?',
        whereArgs: [transaction.id],
      );
    }
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
    try {
      return await db.insert(SavingsAccountsFields.tableName, savingsAccount.toMap());
    } catch (e) {
      // If insert fails (e.g., column doesn't exist), try without usd_rate
      final map = savingsAccount.toMap();
      map.remove('usd_rate');
      return await db.insert(SavingsAccountsFields.tableName, map);
    }
  }

  Future<List<SavingsAccount>> getSavingsAccounts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(SavingsAccountsFields.tableName);
    return List.generate(maps.length, (i) => SavingsAccount.fromMap(maps[i]));
  }

  Future<int> updateSavingsAccount(SavingsAccount savingsAccount) async {
    Database db = await database;
    try {
      return await db.update(
        SavingsAccountsFields.tableName,
        savingsAccount.toMap(),
        where: '${SavingsAccountsFields.id} = ?',
        whereArgs: [savingsAccount.id],
      );
    } catch (e) {
      // If update fails, try without usd_rate
      final map = savingsAccount.toMap();
      map.remove('usd_rate');
      return await db.update(
        SavingsAccountsFields.tableName,
        map,
        where: '${SavingsAccountsFields.id} = ?',
        whereArgs: [savingsAccount.id],
      );
    }
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
    final dbPath = join(await getDatabasesPath(), 'money_tracker.db');
    final src = io.File(dbPath);
    if (!await src.exists()) {
      throw Exception('Database file not found at $dbPath');
    }

    // Determine user's home/downloads directory
    String home = io.Platform.isWindows
        ? (io.Platform.environment['USERPROFILE'] ?? '.')
        : (io.Platform.environment['HOME'] ?? '.');
    final downloadsDir = join(home, 'Downloads');
    try {
      await io.Directory(downloadsDir).create(recursive: true);
    } catch (_) {}

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final destPath = join(downloadsDir, 'money_tracker_$timestamp.db');

    await src.copy(destPath);
    return destPath;
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

  /// Import a database file from [sourcePath], replacing the current database.
  /// Returns the destination path where the DB was written.
  Future<String> importDatabase(String sourcePath) async {
    final srcFile = io.File(sourcePath);
    if (!await srcFile.exists()) throw Exception('Source file not found: $sourcePath');

    // Close existing DB connection so file can be replaced
    await closeDatabase();

    final dbPath = join(await getDatabasesPath(), 'money_tracker.db');
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
      final rows = await db.query(SourcesFields.tableName,
          where: '${SourcesFields.type} = ?', whereArgs: [type], orderBy: '${SourcesFields.name} ASC');
      return rows;
    } catch (e) {
      // Table might not exist; attempt to create and return empty
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            name TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      return [];
    }
  }

  Future<int> insertSource(String type, String name) async {
    Database db = await database;
    try {
      return await db.insert(SourcesFields.tableName, {SourcesFields.type: type, SourcesFields.name: name});
    } catch (e) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            name TEXT NOT NULL
          )
        ''');
        return await db.insert(SourcesFields.tableName, {SourcesFields.type: type, SourcesFields.name: name});
      } catch (e2) {
        rethrow;
      }
    }
  }

  Future<int> deleteSource(int id) async {
    Database db = await database;
    return await db.delete(SourcesFields.tableName, where: '${SourcesFields.id} = ?', whereArgs: [id]);
  }
}
