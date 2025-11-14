import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ContentService {
  final String hugoSitePath;

  ContentService(this.hugoSitePath);

  /// List all content files
  Future<List<Map<String, dynamic>>> listContent() async {
    final contentDir = Directory(p.join(hugoSitePath, 'content'));
    final files = <Map<String, dynamic>>[];

    if (!await contentDir.exists()) {
      return files;
    }

    await for (final entity
        in contentDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final relativePath =
            p.relative(entity.path, from: p.join(hugoSitePath, 'content'));
        final stat = await entity.stat();

        files.add({
          'path': relativePath,
          'fullPath': entity.path,
          'modified': stat.modified.toIso8601String(),
          'size': stat.size,
        });
      }
    }

    return files;
  }

  /// Get content of a specific file
  Future<Map<String, dynamic>> getContent(String relativePath) async {
    final filePath = p.join(hugoSitePath, 'content', relativePath);
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $relativePath');
    }

    final content = await file.readAsString();
    final parsed = _parseMarkdownFile(content);

    return {
      'path': relativePath,
      'frontmatter': parsed['frontmatter'],
      'content': parsed['content'],
    };
  }

  /// Create new content file
  Future<void> createContent(
    String relativePath,
    Map<String, dynamic> frontmatter,
    String content,
  ) async {
    final filePath = p.join(hugoSitePath, 'content', relativePath);
    final file = File(filePath);

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    // Check if file already exists
    if (await file.exists()) {
      throw Exception('File already exists: $relativePath');
    }

    // Write file
    final fileContent = _buildMarkdownFile(frontmatter, content);
    await file.writeAsString(fileContent);
  }

  /// Update existing content file
  Future<void> updateContent(
    String relativePath,
    Map<String, dynamic> frontmatter,
    String content,
  ) async {
    final filePath = p.join(hugoSitePath, 'content', relativePath);
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $relativePath');
    }

    final fileContent = _buildMarkdownFile(frontmatter, content);
    await file.writeAsString(fileContent);
  }

  /// Delete content file
  Future<void> deleteContent(String relativePath) async {
    final filePath = p.join(hugoSitePath, 'content', relativePath);
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $relativePath');
    }

    await file.delete();
  }

  /// Parse markdown file into frontmatter and content
  Map<String, dynamic> _parseMarkdownFile(String fileContent) {
    final lines = fileContent.split('\n');

    if (lines.isEmpty || lines.first.trim() != '---') {
      return {
        'frontmatter': {},
        'content': fileContent,
      };
    }

    // Find end of frontmatter
    var endIndex = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      return {
        'frontmatter': {},
        'content': fileContent,
      };
    }

    // Extract frontmatter
    final frontmatterLines = lines.sublist(1, endIndex);
    final frontmatterYaml = frontmatterLines.join('\n');

    Map<String, dynamic> frontmatter;
    try {
      final yaml = loadYaml(frontmatterYaml);
      frontmatter = Map<String, dynamic>.from(yaml as Map);
    } catch (e) {
      frontmatter = {};
    }

    // Extract content
    final contentLines = lines.sublist(endIndex + 1);
    final content = contentLines.join('\n').trim();

    return {
      'frontmatter': frontmatter,
      'content': content,
    };
  }

  /// Build markdown file from frontmatter and content
  String _buildMarkdownFile(
    Map<String, dynamic> frontmatter,
    String content,
  ) {
    final buffer = StringBuffer();

    // Write frontmatter
    buffer.writeln('---');
    frontmatter.forEach((key, value) {
      if (value is String) {
        // Quote strings
        buffer.writeln('$key: "${value.replaceAll('"', '\\"')}"');
      } else if (value is List) {
        buffer.writeln('$key: ${value.toString()}');
      } else {
        buffer.writeln('$key: $value');
      }
    });
    buffer.writeln('---');

    // Write content
    buffer.writeln();
    buffer.write(content);

    return buffer.toString();
  }
}
