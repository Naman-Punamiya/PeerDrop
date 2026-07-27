import 'package:peer_drop/core/utils/sharefiles.dart';

class ShareFolder {
  final String name;
  final String path;
  final int size;
  List<ShareFile> files;
  bool isSelected;

  ShareFolder({
    required this.name,
    required this.path,
    required this.size,
    required this.files,
    this.isSelected = false,
  });
}