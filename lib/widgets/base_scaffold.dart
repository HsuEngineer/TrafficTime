import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final String title;
  final Widget body;
  final VoidCallback? onClearCache;

  const BaseScaffold({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.title,
    required this.body,
    this.onClearCache,
  });

  static const List<BottomNavigationBarItem> bottomItems = [
    BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: '公車'),
    BottomNavigationBarItem(icon: Icon(Icons.subway), label: '捷運'),
    BottomNavigationBarItem(icon: Icon(Icons.train), label: '火車'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_railway), label: '高鐵'),
    BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '其他'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onClearCache != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_cache') onClearCache!();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'clear_cache', child: Text('清除快取')),
              ],
            ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        items: bottomItems,
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: onTabChanged,
      ),
    );
  }
}
