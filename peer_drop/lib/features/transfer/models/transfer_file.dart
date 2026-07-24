class TransferFile {
  final String name;
  final String size;
  final String extension;
  bool completed;

  TransferFile({
    required this.name,
    required this.size,
    required this.extension,
    this.completed = false,
  });
}