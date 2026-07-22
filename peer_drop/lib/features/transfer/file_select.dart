import 'package:flutter/material.dart';

class FileSelectPage extends StatefulWidget {
  final String deviceName;
  final String deviceType;
  const FileSelectPage({
    super.key,
    required this.deviceName,
    required this.deviceType,
  });

  @override
  State<FileSelectPage> createState() => _FileSelectPageState();
}

class _FileSelectPageState extends State<FileSelectPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.desktop_windows_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Send To",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${widget.deviceName}'s ${widget.deviceType}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const TabBar(
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 16),
              tabs: [
                Tab(text: "Files"),
                Tab(text: "Folders"),
                Tab(text: "Text"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text("File $index"),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            // Handle file selection
                          },
                        ),
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text("Folder $index"),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            // Handle folder selection
                          },
                        ),
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text("Text $index"),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            // Handle text selection
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
