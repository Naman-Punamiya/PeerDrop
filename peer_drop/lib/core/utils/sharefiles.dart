class ShareFile {
  final String name;
  final String path;
  final int size;
  final String extension;

  bool isSelected;

  ShareFile({
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
    this.isSelected = false,
  });
}