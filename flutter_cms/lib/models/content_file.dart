class ContentFile {
  final String path;
  final Map<String, dynamic> frontmatter;
  final String content;
  final String? fullPath;
  final DateTime? modified;
  final int? size;

  ContentFile({
    required this.path,
    required this.frontmatter,
    required this.content,
    this.fullPath,
    this.modified,
    this.size,
  });

  factory ContentFile.fromJson(Map<String, dynamic> json) {
    return ContentFile(
      path: json['path'] as String,
      frontmatter: Map<String, dynamic>.from(json['frontmatter'] as Map),
      content: json['content'] as String,
      fullPath: json['fullPath'] as String?,
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'frontmatter': frontmatter,
      'content': content,
      if (fullPath != null) 'fullPath': fullPath,
      if (modified != null) 'modified': modified!.toIso8601String(),
      if (size != null) 'size': size,
    };
  }

  ContentFile copyWith({
    String? path,
    Map<String, dynamic>? frontmatter,
    String? content,
    String? fullPath,
    DateTime? modified,
    int? size,
  }) {
    return ContentFile(
      path: path ?? this.path,
      frontmatter: frontmatter ?? this.frontmatter,
      content: content ?? this.content,
      fullPath: fullPath ?? this.fullPath,
      modified: modified ?? this.modified,
      size: size ?? this.size,
    );
  }

  // Helper getters for common frontmatter fields
  String get title => frontmatter['title'] as String? ?? 'Untitled';
  DateTime? get date {
    final dateStr = frontmatter['date'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  bool get isDraft => frontmatter['draft'] as bool? ?? true;
  List<String> get tags {
    final tagData = frontmatter['tags'];
    if (tagData is List) {
      return tagData.cast<String>();
    }
    return [];
  }

  List<String> get categories {
    final catData = frontmatter['categories'];
    if (catData is List) {
      return catData.cast<String>();
    }
    return [];
  }

  String get description => frontmatter['description'] as String? ?? '';
  String get author => frontmatter['author'] as String? ?? '';
}
