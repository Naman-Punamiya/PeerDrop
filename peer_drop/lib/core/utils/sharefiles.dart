class ShareFile {
  final String name;
  final String size;
  final String extension;
  bool isSelected;

  ShareFile({
    required this.name,
    required this.size,
    required this.extension,
    this.isSelected = false,
  });
}