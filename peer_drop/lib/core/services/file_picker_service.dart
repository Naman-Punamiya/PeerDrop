import 'package:file_picker/file_picker.dart';
import 'package:peer_drop/core/utils/sharefiles.dart';

class FilePickerService {
  Future<List<ShareFile>> pickFiles() async {
    List<ShareFile> files = [];
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null) return [];  
    for (final file in result.files) {
      if (file.path == null) continue;
      files.add(
        ShareFile(
          name: file.name,
          path: file.path!,
          size: file.size,
          extension: file.extension ?? "",
        ),
      );
    }
    return files;
  }
}
