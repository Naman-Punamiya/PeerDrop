import 'package:flutter/material.dart';
import 'package:peer_drop/core/widgets/navigation_bar.dart';
import 'package:peer_drop/features/transfer/models/transfer_file.dart';
import 'models/transfer_item.dart';
import 'widgets/active_transfer_card.dart';
import 'widgets/completed_transfer_card.dart';

class TransferListPage extends StatelessWidget {
  const TransferListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final active = [
      TransferItem(
        deviceName: "Aman",
        deviceType: "Laptop",
        fileName: "Video.mp4",
        size: "258 MB",
        progress: 45,
        speed: "12.4 MB/s",
        eta: "00:16 left",
        icon: Icons.video_file,
        color: Colors.indigo,
        files: [],
      ),

      TransferItem(
        deviceName: "Hetvi",
        deviceType: "Phone",
        fileName: "Photos.zip",
        size: "120 MB",
        progress: 20,
        speed: "8.6 MB/s",
        eta: "00:12 left",
        icon: Icons.folder_zip,
        color: Colors.orange,
        files: [
          TransferFile(name: "Photos.zip", size: "120 MB", extension: "ZIP"),
        ],
      ),
    ];

    final completed = [
      TransferItem(
        deviceName: "MacBook Air",
        deviceType: "Laptop",
        fileName: "Document.pdf",
        size: "2.4 MB",
        progress: 100,
        speed: "",
        eta: "",
        icon: Icons.picture_as_pdf,
        color: Colors.red,
        completed: true,
        files: [
          TransferFile(name: "Document.pdf", size: "2.4 MB", extension: "PDF"),
        ],
      ),

      TransferItem(
        deviceName: "OnePlus Pad",
        deviceType: "Tablet",
        fileName: "Music.mp3",
        size: "0.6 MB",
        progress: 100,
        speed: "",
        eta: "",
        icon: Icons.music_note,
        color: Colors.deepOrange,
        completed: true,
        files: [
          TransferFile(name: "Music.mp3", size: "0.6 MB", extension: "MP3"),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Active Transfers")),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          const Text(
            "Sending (2)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 16),

          ...active.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActiveTransferCard(item: e),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Completed",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          ...completed.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CompletedTransferCard(item: e),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(context, 1),
    );
  }
}
