import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart' as model;


//Buttons to select time range for graphs
enum TimeRange { month, year }

class IncomeEntry {
  final DateTime date;
  final double amount;      // Amount
  final String category;    // "Salary", "Freelance", etc.
  final Color color;        // Category color

  IncomeEntry({
    required this.date,
    required this.amount,
    required this.category,
    required this.color,
  });
}


class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseService _db = DatabaseService();
  List<model.Transaction> _income = [];
  List<Map<String, Color>> _categories = [];
  bool _isLoading = true;
  TimeRange _range = TimeRange.month;
  double _usdRate = 42.0;
  double _eurRate = 51.0;

  // methods for the current view
  DateTime _selectedDate = DateTime.now();
  String _getDate(){
    if (_range == TimeRange.month) {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    } else {
      return DateFormat('yyyy').format(_selectedDate);
    }
  }
  void _nextDate() {
    if (_range == TimeRange.month) {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    } else if (_range == TimeRange.year) {
      _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month);
    }
    setState(() {});
  }
  void _previousDate() {
    if (_range == TimeRange.month) {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    } else if (_range == TimeRange.year) {
      _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month);
    }
    setState(() {});
  }

  String _getTotal(currency) {
    double total = 0;
    for (final tx in _income) {
      if (_range == TimeRange.month) {
        if (tx.date.year == _selectedDate.year && tx.date.month == _selectedDate.month) {
          currency == 'UAH' ? total += _toUAH(tx) : total += tx.amount_usd;
        }
      } else {
        if (tx.date.year == _selectedDate.year) {
          // total += _toUAH(tx);
          currency == 'UAH' ? total += _toUAH(tx) : total += tx.amount_usd;
        }
      }
    }

    var formatter = NumberFormat('#,##,000');
    String numberTotal = formatter.format(total).trim().replaceAll(',', ' ') ;
    return '$numberTotal ' + '$currency';
  }

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
      final categories = await _db.getSources('income');
      setState(() {
        _income = tx;
        _categories = categories.map((c) => {c['name'] as String: Color(int.parse(c['color'] as String, radix: 16))}).toList();
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
    return tx.amount;
  }

  // Returns list of (label, value) pairs ordered by time
  Map<String, IncomeEntry> _aggregate() {
    if (_range == TimeRange.month) {
      // get the numbers of days to display based on current month
      final daysInMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
      ).day; // Gets last day number 

      // last 30 days grouped by day
      final days = List.generate(
        daysInMonth,
        (i) => DateTime(_selectedDate.year, _selectedDate.month, i + 1),
      );

      final map = <String, IncomeEntry>{};
      // go through all days
      for (final d in days) {
        map[DateFormat('yyyy-MM-dd').format(d)] = IncomeEntry(
          date: d,
          amount: 0.0,
          category: '',
          color: Colors.transparent,
        );
      }

      // go through all income
      for (final tx in _income) {
        final key = DateFormat('yyyy-MM-dd').format(tx.date);

        Color color = _categories.firstWhere(
          (c) => c.containsKey(tx.source),
          orElse: () => {'': Colors.green},
        )[tx.source] ?? Colors.green;

        if (map.containsKey(key)) {
          map[key] = IncomeEntry(
            date: map[key]!.date,
            amount: map[key]!.amount + _toUAH(tx),
            category: map[key]!.category,
            color: color,
          );
        }
      }
      return map;

    } else if (_range == TimeRange.year) {
      // Current year months grouped by month
      final months = List.generate(12, (i) => DateTime(_selectedDate.year, i + 1, 1));
      final map = <String, IncomeEntry>{};
      for (final m in months) {
        map[DateFormat('yyyy-MM').format(m)] = IncomeEntry(
          date: m,
          amount: 0.0 ,
          category: '',
          color: Colors.transparent,
        );
      }
      for (final tx in _income) {
        if (tx.date.year == _selectedDate.year) {
          final key = DateFormat('yyyy-MM').format(tx.date);

          Color color = _categories.firstWhere(
            (c) => c.containsKey(tx.source),
            orElse: () => {'': Colors.green},
          )[tx.source] ?? Colors.green;

          if (map.containsKey(key)) {
            map[key] = IncomeEntry(
              date: map[key]!.date,
              amount: map[key]!.amount + _toUAH(tx),
              category: map[key]!.category,
              color: color,
            );
          }
        }
      }
      return map;
    } else {
      // All time grouped by year
      final map = <String, IncomeEntry>{};
      for (final tx in _income) {
        final key = tx.date.year.toString();
        map[key] = (map[key] ?? IncomeEntry(
          date: DateTime.parse(key),
          amount: 0.0,
          category: '',
          color: Colors.transparent,
        ));
      }
      return map;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final data = _aggregate();
    // final data = _aggregate();
    final data = _aggregate().entries
      .map((e) => MapEntry(e.key, e.value.amount))
      .toList();
    
    final colors = _aggregate().entries
      .map((e) => e.value.color)
      .toList();

    final spots = <FlSpot>[];
    List<Color> spotColors = []; 
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
      spotColors.add(colors[i]); // Use category color or transparent for zero values
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
      // TODO: add total Tithes calculation
      // TODO: filter by category
      // TODO: add graph/pie chart for income categories
      // 
      //Buttons
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Month/Year selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ChoiceChip(
                        label: const Text('Month'),
                        selected: _range == TimeRange.month,
                        onSelected: (_) => _setRange(TimeRange.month),
                      ),
                      ChoiceChip(
                        label: const Text('Year'),
                        selected: _range == TimeRange.year,
                        onSelected: (_) => _setRange(TimeRange.year),
                      ),
                    ],
                  ),
                  // Date selector with arrows left and right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        iconSize: 48.0,
                        tooltip: 'Previous Date',
                        onPressed: _previousDate,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _getDate(),
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        iconSize: 48.0,
                        tooltip: 'Next Date',
                        onPressed: _nextDate,
                      ),
                    ],
                  ),
                  
                  Text(
                    'Income Total: ${_getTotal('UAH')} (${_getTotal('USD')})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(
                    height: 300,
                    child: data.isEmpty
                        ? const Center(child: Text('No data'))
                        : BarChart(
                            BarChartData(
                              minY: 0,
                              maxY: maxY > 0 ? maxY * 1.1 : 100,
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= data.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final entry = data[idx];
                                      final valueY = entry.value;
                                      if (valueY == 0) {
                                        return const SizedBox.shrink(); // Hide zero
                                      }
                                      final label = entry.key;

                                      String display;
                                      if (_range == TimeRange.month) {
                                        display = DateFormat(
                                          'dd',
                                        ).format(DateTime.parse(label));
                                      } else if (_range == TimeRange.year) {
                                        display = DateFormat(
                                          'MMM',
                                        ).format(DateTime.parse('$label-01'));
                                      } else {
                                        display = label;
                                      }
                                      //String display = DateFormat('dd').format(DateTime.parse(label));

                                      return SideTitleWidget(
                                        // axisSide: meta.axisSide,
                                        meta: meta,
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
                              // borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (BarChartGroupData group) => Colors.transparent, 
                                  tooltipPadding: EdgeInsets.zero,
                                  tooltipMargin: 0,
                                  tooltipBorderRadius: BorderRadius.zero,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      //the actual value to show in tooltip 
                                      rod.toY.toInt() > 1000 ? '${(rod.toY / 1000).toStringAsFixed(0)}k' : '${rod.toY.toInt()}',
                                      const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              barGroups: spots.asMap().entries.map((entry) {
                                final spot = entry.value;
                                final index = entry.key;
                                if (spot.y == 0) {
                                  // Show empty bar for zero values to keep spacing, but make it invisible
                                  return BarChartGroupData(x: entry.key, barRods: []);  // Empty bars
                                }
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: spot.y,
                                      color: spotColors[index],
                                      width: 20,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],

                                  showingTooltipIndicators: [0],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
      ), 
    );
  }
}
