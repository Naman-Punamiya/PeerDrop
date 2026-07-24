import 'package:flutter/material.dart';
import 'package:peer_drop/features/transfer/widgets/transfer_progress_page.dart';
import '../models/transfer_item.dart';

class CompletedTransferCard extends StatelessWidget {
  final TransferItem item;

  const CompletedTransferCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransferProgressPage(
              deviceName: item.deviceName,
              deviceType: "Laptop",
              files: item.files,
            ),
          ),
        );
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(item.icon, color: item.color),
        ),

        title: Text(item.fileName),

        subtitle: Text("To ${item.deviceName}\n${item.size} • Completed"),

        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}
