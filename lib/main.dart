import 'package:flutter/material.dart';
import 'screens/income_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/savings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier<int>(0);

  List<Widget> get _screens => <Widget>[
        IncomeScreen(navIndexNotifier: _selectedIndexNotifier),
        ExpensesScreen(navIndexNotifier: _selectedIndexNotifier),
        SavingsScreen(navIndexNotifier: _selectedIndexNotifier),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedIndexNotifier.value = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Income'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_down),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
