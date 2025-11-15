class FileItem {
  final String path;
  final String name;
  final String? fullPath;
  final DateTime? modified;
  final int? size;

  FileItem({
    required this.path,
    required this.name,
    this.fullPath,
    this.modified,
    this.size,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as String;
    final parts = path.split('/');
    final name = parts.last;

    return FileItem(
      path: path,
      name: name,
      fullPath: json['fullPath'] as String?,
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
      size: json['size'] as int?,
    );
  }

  String get directory {
    final parts = path.split('/');
    if (parts.length > 1) {
      parts.removeLast();
      return parts.join('/');
    }
    return '';
  }

  bool get isInPosts => path.startsWith('posts/');
  bool get isInPages => path.startsWith('pages/');
}
