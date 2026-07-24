import 'package:flutter/material.dart';
import 'package:peer_drop/core/widgets/navigation_bar.dart';
import 'package:peer_drop/features/transfer/models/transfer_file.dart';

class TransferProgressPage extends StatefulWidget {
  final String deviceName;
  final String deviceType;
  final List<TransferFile> files;

  const TransferProgressPage({
    super.key,
    required this.deviceName,
    required this.deviceType,
    required this.files,
  });

  @override
  State<TransferProgressPage> createState() => _TransferProgressPageState();
}

class _TransferProgressPageState extends State<TransferProgressPage> {
  double progress = 0.75;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sending to", style: TextStyle(fontSize: 13)),
            Text(
              "${widget.deviceName}'s ${widget.deviceType}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            /// Folder Animation
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder, color: Colors.amber, size: 70),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: widget.files.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final file = widget.files[index];

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.blue,
                                ),
                              ),

                              title: Text(
                                file.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              subtitle: Text(file.size),

                              trailing: Icon(
                                file.completed
                                    ? Icons.check_circle
                                    : Icons.sync,
                                color: file.completed
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),

                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Overall Progress",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text("${(progress * 100).round()}%"),
                              ],
                            ),

                            const SizedBox(height: 10),

                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(10),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "4.2 MB / 6.0 MB • 12.4 MB/s",
                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text("Cancel"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavBar(context, 1),
    );
  }
}
