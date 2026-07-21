import 'package:flutter/material.dart';
import 'package:peer_drop/app/theme/app_theme.dart';
import 'package:peer_drop/features/home/pages/home_page.dart';

class PeerDropApp extends StatelessWidget {
  const PeerDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeerDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}