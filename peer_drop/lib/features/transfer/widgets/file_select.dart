import 'package:flutter/material.dart';
import 'package:peer_drop/core/utils/sharefiles.dart';

class FileSelectPage extends StatefulWidget {
  final IconData deviceIcon;
  final String deviceName;
  final String deviceType;
  final String deviceIP;
  const FileSelectPage({
    super.key,
    required this.deviceName,
    required this.deviceType, 
    required this.deviceIP, 
    required this.deviceIcon,
  });

  @override
  State<FileSelectPage> createState() => _FileSelectPageState();
}

class _FileSelectPageState extends State<FileSelectPage> {
  int get selectedCount => files.where((file) => file.isSelected).length;

  String get totalSelectedSize {
    double total = 0;

    for (final file in files) {
      if (file.isSelected) {
        total += double.parse(file.size.split(' ')[0]);
      }
    }

    return "${total.toStringAsFixed(1)} MB";
  }

  final files = [
    ShareFile(name: "Project Report.pdf", size: "2.4 MB", extension: "PDF"),
    ShareFile(name: "Design.png", size: "3.6 MB", extension: "PNG"),
  ];
  Set<int> selectedFiles = {};
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

            TabBar(
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.grey.shade300,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: "Files"),
                Tab(text: "Folders"),
                Tab(text: "Text"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isSelected = selectedFiles.contains(index);
                      return ListTile(
                        onTap: () {
                          setState(() {
                            file.isSelected = !file.isSelected;
                          });
                        },
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.name),
                        subtitle: Text("${file.size} • ${file.extension}"),
                        trailing: Icon(
                          file.isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.grey : Colors.deepPurple,
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
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$selectedCount file${selectedCount == 1 ? '' : 's'} selected",
                      style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                    ),
                    Text(
                      totalSelectedSize,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.05,
                child: ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    "Send",
                    style: TextStyle(color: Colors.white,fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
