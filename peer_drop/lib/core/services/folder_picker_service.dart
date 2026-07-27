import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:peer_drop/core/utils/sharefolder.dart';
import 'package:path/path.dart' as p;

class FolderPickerService {
  Future<List<ShareFolder>> pickFolders() async {
    
    final path = await FilePicker.getDirectoryPath();
    
    if (path == null) return [];
    
    final directory = Directory(path);
    int totalSize = 0;
    
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }

    return [ShareFolder(name: p.basename(directory.path), path: directory.path, size: totalSize, files: [])];
  }
}
