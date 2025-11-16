class MediaFile {
  final String filename;
  final String path;
  final String url;
  final int size;
  final DateTime modified;

  MediaFile({
    required this.filename,
    required this.path,
    required this.url,
    required this.size,
    required this.modified,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      filename: json['filename'] as String,
      path: json['path'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      modified: DateTime.parse(json['modified'] as String),
    );
  }

  String get extension => filename.split('.').last.toLowerCase();

  bool get isImage {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp']
        .contains(extension);
  }

  String formatSize() {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
