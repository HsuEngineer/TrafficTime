import 'package:flutter/material.dart';
import 'pages/bus_page.dart';
import 'pages/placeholder_page.dart';

void main() {
  
  runApp(BusTimeApp());
}

class BusTimeApp extends StatelessWidget {
  const BusTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusTime',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BusPage(),
    PlaceholderPage(title: '捷運'),
    PlaceholderPage(title: '火車'),
    PlaceholderPage(title: '高鐵'),
    PlaceholderPage(title: '其他'),
  ];

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: '公車'),
    BottomNavigationBarItem(icon: Icon(Icons.subway), label: '捷運'),
    BottomNavigationBarItem(icon: Icon(Icons.train), label: '火車'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_railway), label: '高鐵'),
    BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '其他'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.directions_bus),
        title: Text(_bottomItems[_selectedIndex].label!),
        actions: [IconButton(icon: Icon(Icons.menu), onPressed: () {})],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
