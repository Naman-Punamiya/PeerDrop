import 'package:flutter/material.dart';

Widget dialog(BuildContext context, int selectedCount, String totalSelectedSize, String deviceName, String deviceType, IconData deviceIcon, String deviceIP) {
  return AlertDialog(
    title: const Text("Incoming file request"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.file_present, size: 48, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          "$selectedCount file${selectedCount == 1 ? '' : 's'} selected",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(totalSelectedSize),
        const SizedBox(height: 12),
        Text("From"),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(deviceIcon, size: 32, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              "$deviceName's $deviceType",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(deviceIP),
      ],
    ),
    actions: [
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.325,
        child: TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: const Text(
              "Decline",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.325,
        child: TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () {},
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: const Text(
              "Accept",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    ],
  );
}
