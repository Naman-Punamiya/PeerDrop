import 'package:flutter/material.dart';
import 'package:peer_drop/core/services/file_picker_service.dart';
import 'package:peer_drop/core/services/folder_picker_service.dart';
import 'package:peer_drop/core/utils/file_utils.dart';
import 'package:peer_drop/core/utils/sharefiles.dart';
import 'package:peer_drop/core/utils/sharefolder.dart';

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

class _FileSelectPageState extends State<FileSelectPage>
    with SingleTickerProviderStateMixin {
  final FilePickerService _filePickerService = FilePickerService();
  final FolderPickerService _folderPickerService = FolderPickerService();

  bool _isPickingFiles = false;
  bool _isPickingFolders = false;

  int get selectedCount => files.where((file) => file.isSelected).length;
  final TextEditingController textController = TextEditingController();
  late TabController _tabController;

  int get totalSelectedSize {
    int total = 0;

    for (final file in files) {
      if (file.isSelected) {
        total += file.size;
      }
    }

    return total;
  }

  int get selectedFolderCount =>
      folders.where((folder) => folder.isSelected).length;

  int get totalSelectedFolderSize {
    int total = 0;

    for (final folder in folders) {
      if (folder.isSelected) {
        total += folder.size;
      }
    }

    return total;
  }

  List<ShareFile> files = [];
  List<ShareFolder> folders = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });

    textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
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
            controller: _tabController,
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
              controller: _tabController,
              children: [
                files.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            const Icon(
                              Icons.insert_drive_file,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "No files selected",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _pickFiles,
                              child: const Text("Select Files"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final isSelected = file.isSelected;
                          return ListTile(
                            onTap: () {
                              setState(() {
                                file.isSelected = !file.isSelected;
                              });
                            },
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(file.name),
                            subtitle: Text(
                              "${formatBytes(file.size)} • ${file.extension.toUpperCase()}",
                            ),
                            trailing: Icon(
                              file.isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? Colors.grey
                                  : Colors.deepPurple,
                            ),
                          );
                        },
                      ),
                folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            const Icon(
                              Icons.folder_open,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "No Folders selected",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _pickFolders,
                              child: const Text("Select Folders"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: folders.length,

                        itemBuilder: (context, index) {
                          final folder = folders[index];

                          return ListTile(
                            onTap: () {
                              setState(() {
                                folder.isSelected = !folder.isSelected;
                              });
                            },
                            leading: const Icon(Icons.folder),
                            title: Text(folder.name),
                            subtitle: Text(formatBytes(folder.size)),
                            trailing: Icon(
                              folder.isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                            ),
                          );
                        },
                      ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: textController,
                        maxLines: 6,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: "Type your message here...",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Quick Messages",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _quickChip("Hello!"),
                          _quickChip("How are you?"),
                          _quickChip("Check this out!"),
                          _quickChip("Thank you!"),
                          _quickChip("Where are you?"),
                          _quickChip("See you soon!"),
                        ],
                      ),
                    ],
                  ),
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
                    bottomTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  Text(
                    bottomSubtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.05,
              child: ElevatedButton(
                onPressed: canSend
                    ? () {
                        switch (_tabController.index) {
                          case 0:
                            // Send files
                            break;

                          case 1:
                            // Send folder
                            break;

                          case 2:
                            // Send text
                            break;
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  "Send",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    if (_isPickingFiles) return;

    _isPickingFiles = true;

    try {
      final pickedFiles = await _filePickerService.pickFiles();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          files = pickedFiles;
        });
      }
    } finally {
      _isPickingFiles = false;
    }
  }

  Future<void> _pickFolders() async {
    if (_isPickingFolders) return;

    _isPickingFolders = true;

    try {
      final pickedFolders = await _folderPickerService.pickFolders();

      if (pickedFolders.isNotEmpty) {
        setState(() {
          folders = pickedFolders;
        });
      }
    } finally {
      _isPickingFolders = false;
    }
  }

  Widget _quickChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        setState(() {
          textController.text = text;
        });
      },
    );
  }

  String get bottomTitle {
    switch (_tabController.index) {
      case 0:
        return "$selectedCount file${selectedCount == 1 ? "" : "s"} selected";

      case 1:
        return "$selectedFolderCount folder${selectedFolderCount == 1 ? "" : "s"} selected";

      case 2:
        return "Text Message";

      default:
        return "";
    }
  }

  String get bottomSubtitle {
    switch (_tabController.index) {
      case 0:
        return formatBytes(totalSelectedSize);

      case 1:
        return selectedFolderCount == 0
            ? "Select a folder"
            : formatBytes(totalSelectedFolderSize);

      case 2:
        return "${textController.text.length}/1000 characters";

      default:
        return "";
    }
  }

  bool get canSend {
    switch (_tabController.index) {
      case 0:
        return selectedCount > 0;

      case 1:
        return selectedFolderCount > 0;

      case 2:
        return textController.text.trim().isNotEmpty;

      default:
        return false;
    }
  }
}
