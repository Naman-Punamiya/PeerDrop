class TransferFileMetadata {
  final String path;
  final String name;
  final String extension;
  final int size;
  final String mimeType;
  final String? sha256;

  const TransferFileMetadata({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.mimeType,
    this.sha256,
  });

  TransferFileMetadata copyWith({
    String? path,
    String? name,
    String? extension,
    int? size,
    String? mimeType,
    String? sha256,
  }) {
    return TransferFileMetadata(
      path: path ?? this.path,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
    );
  }
}
