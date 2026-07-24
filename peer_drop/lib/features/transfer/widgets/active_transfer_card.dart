import 'package:flutter/material.dart';
import 'package:peer_drop/features/transfer/widgets/transfer_progress_page.dart';
import '../models/transfer_item.dart';

class ActiveTransferCard extends StatelessWidget {
  final TransferItem item;

  const ActiveTransferCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransferProgressPage(
              deviceName: item.deviceName,
              deviceType: item.deviceType,
              files: item.files,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Row(
            children: [
              Container(
                width: 5,
                height: 65,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "To ${item.deviceName}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    Text(
                      item.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 3),

                    Text("${item.size} • ${item.progress}%"),

                    Text(
                      "${item.speed} • ${item.eta}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.pause_circle,
                  color: Colors.deepPurple,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
