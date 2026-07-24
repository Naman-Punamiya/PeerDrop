import 'package:flutter/material.dart';
import 'package:peer_drop/core/widgets/navigation_bar.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('History Page')),
      bottomNavigationBar: NavBar(context, 2),
    );
  }
}