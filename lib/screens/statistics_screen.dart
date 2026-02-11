import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart' as model;

class DateSelector extends ChangeNotifier {
  int _currentDate;

  /// Initializes the [_currentYear] with the current year from [DateTime.now()].
  DateSelector() : _currentDate = DateTime.now().year;

  /// Getter for the current year.
  int get currentYear => _currentDate;

  /// Increments the current year by 1 and notifies all registered listeners.
  void incrementDate() {
    _currentDate++;
    notifyListeners();
  }

  /// Decrements the current year by 1 and notifies all registered listeners.
  void decrementDate() {
    _currentDate--;
    notifyListeners();
  }
}

//Buttons to select time range for graphs
enum TimeRange { month, year }

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

  final List<String> _yearsList = <String>['2024', '2025', '2026'];
  String? _selectedYear;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading income: $e')));
    }
  }

  // Set the time range for graphs and refresh the data
  void _setRange(TimeRange r) {
    setState(() {
      _range = r;
    });
  }

  double _toUAH(model.Transaction tx) {
    if (tx.currency == 'UAH') return tx.amount;
    if (tx.currency == 'USD')
      return tx.amount * (tx.usdRate > 0 ? tx.usdRate : _usdRate);
    if (tx.currency == 'EUR') return tx.amount * _eurRate;
    return tx.amount;
  }

  // Returns list of (label, value) pairs ordered by time
  List<MapEntry<String, double>> _aggregate() {
    final now = DateTime.now();
    if (_range == TimeRange.month) {
      // get the numbers of days to display based on current month
      //final int daysInMonth = getDaysInMonth(now.year, now.month);
      final daysInMonth = DateTime(
        now.year,
        now.month + 1,
        0,
      ).day; // Gets last day number [web:6][web:16]
      // last 30 days grouped by day
      final days = List.generate(
        daysInMonth,
        (i) => DateTime(now.year, now.month, i + 1),
      );

      final map = <String, double>{};
      // go through all days
      for (final d in days) {
        map[DateFormat('yyyy-MM-dd').format(d)] = 0.0;
      }

      // go through all income
      for (final tx in _income) {
        final key = DateFormat('yyyy-MM-dd').format(tx.date);
        if (map.containsKey(key)) {
          map[key] = map[key]! + _toUAH(tx);
        }
      }

      return map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    } else if (_range == TimeRange.year) {
      // Current year months grouped by month
      final months = List.generate(12, (i) => DateTime(now.year, i + 1, 1));
      final map = <String, double>{};
      for (final m in months) {
        map[DateFormat('yyyy-MM').format(m)] = 0.0;
      }
      for (final tx in _income) {
        if (tx.date.year == now.year) {
          final key = DateFormat('yyyy-MM').format(tx.date);
          if (map.containsKey(key)) map[key] = map[key]! + _toUAH(tx);
        }
      }
      return map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    } else {
      // All time grouped by year
      final map = <String, double>{};
      for (final tx in _income) {
        final key = tx.date.year.toString();
        map[key] = (map[key] ?? 0.0) + _toUAH(tx);
      }
      return map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _aggregate();
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }

    double maxY = 0;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    double interval = maxY > 0 ? (maxY * 1.1) / 5 : 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      //Buttons
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
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        iconSize: 48.0,
                        tooltip: 'Previous Year',
                        onPressed: null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '2024', // Uses yearData from context.watch
                          style: const TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        iconSize: 48.0,
                        tooltip: 'Next Year',
                        onPressed: null,
                      ),
                    ],
                  ),
                  //const SizedBox(height: 16),
                  Text(
                    'Income (${_range == TimeRange.month ? 'UAH - month' : 'UAH - year'})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  //const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: data.isEmpty
                        ? const Center(child: Text('No data'))
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: maxY > 0 ? maxY * 1.1 : 100,
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= data.length)
                                        return const SizedBox.shrink();
                                      final label = data[idx].key;
                                      String display;
                                      if (_range == TimeRange.month) {
                                        display = DateFormat(
                                          'dd',
                                        ).format(DateTime.parse(label));
                                      } else if (_range == TimeRange.year) {
                                        display = DateFormat(
                                          'MMM yyyy',
                                        ).format(DateTime.parse('$label-01'));
                                      } else {
                                        display = label;
                                      }
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          display,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    interval: interval,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  dotData: FlDotData(show: false),
                                  color: Colors.green,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  //const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: data.isEmpty
                        ? const Center(child: Text('No data'))
                        : BarChart(
                            BarChartData(
                              minY: 0,
                              maxY: maxY > 0 ? maxY * 1.1 : 100,
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= data.length)
                                        return const SizedBox.shrink();

                                      final entry = data[idx];
                                      final valueY = entry.value;

                                      if (valueY == 0)
                                        return const SizedBox.shrink(); // Hide zero

                                      final label = entry.key;

                                      String display;
                                      if (_range == TimeRange.month) {
                                        display = DateFormat(
                                          'dd',
                                        ).format(DateTime.parse(label));
                                      } else if (_range == TimeRange.year) {
                                        display = DateFormat(
                                          'MMM yyyy',
                                        ).format(DateTime.parse('$label-01'));
                                      } else {
                                        display = label;
                                      }
                                      //String display = DateFormat('dd').format(DateTime.parse(label));

                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          display,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                    reservedSize: 50,
                                    interval: interval,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),

                              // show Bars
                              borderData: FlBorderData(show: false),
                              barGroups: spots.asMap().entries.map((entry) {
                                final index = entry.key;
                                final spot = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: spot.y,
                                      color: Colors.green,
                                      width: 20,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
      ), // Added closing parenthesis for Padding
    );
  } // Added closing brace for build method
}
