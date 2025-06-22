import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title 功能尚未建置',
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}
