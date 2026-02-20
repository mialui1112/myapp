import 'package:flutter/material.dart';

class ComicsSourceDetailScreen extends StatelessWidget {
  final String sourceName;

  const ComicsSourceDetailScreen({super.key, required this.sourceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sourceName)),
      body: Center(child: Text('Details for $sourceName')),
    );
  }
}
