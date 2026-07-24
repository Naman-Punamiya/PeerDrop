import 'package:flutter/material.dart';
import 'package:peer_drop/features/home/pages/home_page.dart';
import 'package:peer_drop/features/settings/setting_page.dart';
import 'package:peer_drop/features/transfer/transfer_list_page.dart';
import 'package:peer_drop/features/history/history_page.dart';

Widget NavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner),
        label: 'Transfers',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
    ],
    currentIndex: currentIndex,
    selectedItemColor: Colors.blue,
    unselectedItemColor: Colors.grey[700],
    type: BottomNavigationBarType.fixed,
    onTap: (index) {
      if (index == currentIndex) return;

      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
          break;

        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TransferListPage()),
          );
          break;

        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HistoryPage()),
          );
          break;

        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SettingPage()),
          );
          break;
      }
    },
  );
}
