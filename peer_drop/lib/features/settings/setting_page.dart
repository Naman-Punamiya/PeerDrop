import 'package:flutter/material.dart';
import 'package:peer_drop/core/widgets/navigation_bar.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Settings Page')),
        bottomNavigationBar: NavBar(context, 3)
      );
    }
}