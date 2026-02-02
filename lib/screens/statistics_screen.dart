import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart' as model;

enum TimeRange { month, year, all }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseService _db = DatabaseService();
  List<model.Transaction> _income = [];
  bool _isLoading = true;
  TimeRange _range = TimeRange.month;
  double _usdRate = 42.0;
  double _eurRate = 51.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tx = await _db.getTransactions('income');
      final rates = await _db.getExchangeRates();
      setState(() {
        _income = tx;
        _usdRate = rates['usd'] ?? _usdRate;
        _eurRate = rates['eur'] ?? _eurRate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading income: $e')));
    }
  }

  void _setRange(TimeRange r) {
    setState(() {
      _range = r;
    });
  }

  double _toUAH(model.Transaction tx) {
    if (tx.currency == 'UAH') return tx.amount;
    if (tx.currency == 'USD') return tx.amount * (tx.usdRate > 0 ? tx.usdRate : _usdRate);
    if (tx.currency == 'EUR') return tx.amount * _eurRate;
    return tx.amount;
  }

  // Returns list of (label, value) pairs ordered by time
  List<MapEntry<String, double>> _aggregate() {
    final now = DateTime.now();
    if (_range == TimeRange.month) {
      // last 30 days grouped by day
      final days = List.generate(30, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i)));
      final map = <String, double>{};
      for (final d in days) {
        map[DateFormat('yyyy-MM-dd').format(d)] = 0.0;
      }
      for (final tx in _income) {
        final key = DateFormat('yyyy-MM-dd').format(tx.date);
        if (map.containsKey(key)) map[key] = map[key]! + _toUAH(tx);
      }
      return map.entries.map((e) => MapEntry(e.key, e.value)).toList();
    } else if (_range == TimeRange.year) {
      // last 12 months grouped by month
      final months = List.generate(12, (i) {
        final dt = DateTime(now.year, now.month, 1).subtract(Duration(days: (11 - i) * 30));
        return DateTime(dt.year, dt.month);
      });
      final map = <String, double>{};
      for (final m in months) {
        map[DateFormat('MM').format(m)] = 0.0;
      }
      for (final tx in _income) {
        final key = DateFormat('MM').format(tx.date);
        if (map.containsKey(key)) map[key] = map[key]! + _toUAH(tx);
      }
      return map.entries.map((e) => MapEntry(e.key, e.value)).toList();
    } else {
      // All time grouped by year
      final years = <int>{};
      for (final tx in _income) {
        years.add(tx.date.year);
      }
      final sorted = years.toList()..sort();
      final map = <String, double>{};
      for (final y in sorted) {
        map[y.toString()] = 0.0;
      }
      for (final tx in _income) {
        final key = tx.date.year.toString();
        map[key] = (map[key] ?? 0.0) + _toUAH(tx);
      }
      return map.entries.map((e) => MapEntry(e.key, e.value)).toList();
    }
  }

  @override
Widget build(BuildContext context) {
  final data = _aggregate();
  final spots = <FlSpot>[];
  for (var i = 0; i < data.length; i++) {
    spots.add(FlSpot(i.toDouble(), data[i].value));
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Statistics'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Month'),
                      selected: _range == TimeRange.month,
                      onSelected: (_) => _setRange(TimeRange.month),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Year'),
                      selected: _range == TimeRange.year,
                      onSelected: (_) => _setRange(TimeRange.year),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _range == TimeRange.all,
                      onSelected: (_) => _setRange(TimeRange.all),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Income (${_range == TimeRange.month ? 'UAH - last 30 days' : _range == TimeRange.year ? 'UAH - last 12 months' : 'UAH - all time'})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: data.isEmpty
                      ? const Center(child: Text('No data'))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                                    final label = data[idx].key;
                                    String display;
                                    if (_range == TimeRange.month) {
                                      display = DateFormat('dd').format(DateTime.parse(label));
                                    } else if (_range == TimeRange.year) {
                                      final parts = label.split('-');
                                      display = parts.length >= 2 ? '${parts[0]}-${parts[1]}' : label;
                                    } else {
                                      display = label;
                                    }
                                    return SideTitleWidget(axisSide: meta.axisSide, child: Text(display, style: const TextStyle(fontSize: 10)));
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                dotData: FlDotData(show: false),
                                color: Colors.green,
                                belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.2)),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    ), // Added closing parenthesis for Padding
  ); // Added closing parenthesis for Scaffold
} // Added closing brace for build method
}
