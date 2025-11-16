import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class MediaService {
  final String hugoSitePath;

  MediaService(this.hugoSitePath);

  String get _mediaPath => p.join(hugoSitePath, 'static', 'images');

  /// List all media files
  Future<List<Map<String, dynamic>>> listMedia() async {
    final mediaDir = Directory(_mediaPath);
    final files = <Map<String, dynamic>>[];

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
      return files;
    }

    await for (final entity in mediaDir.list(recursive: true, followLinks: false)) {
      if (entity is File && _isImageFile(entity.path)) {
        final stat = await entity.stat();
        final relativePath = p.relative(entity.path, from: _mediaPath);

        files.add({
          'filename': p.basename(entity.path),
          'path': relativePath,
          'fullPath': entity.path,
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
          'url': '/images/$relativePath',
        });
      }
    }

    // Sort by modified date, newest first
    files.sort((a, b) {
      final aDate = DateTime.parse(a['modified'] as String);
      final bDate = DateTime.parse(b['modified'] as String);
      return bDate.compareTo(aDate);
    });

    return files;
  }

  /// Upload a media file
  Future<Map<String, dynamic>> uploadMedia(
    String filename,
    Uint8List bytes,
  ) async {
    final mediaDir = Directory(_mediaPath);
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    // Sanitize filename
    final sanitizedFilename = _sanitizeFilename(filename);

    // Check if file already exists and generate unique name if needed
    var finalFilename = sanitizedFilename;
    var counter = 1;
    while (await File(p.join(_mediaPath, finalFilename)).exists()) {
      final nameWithoutExt = p.basenameWithoutExtension(sanitizedFilename);
      final ext = p.extension(sanitizedFilename);
      finalFilename = '${nameWithoutExt}_$counter$ext';
      counter++;
    }

    // Write file
    final filePath = p.join(_mediaPath, finalFilename);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    final stat = await file.stat();

    return {
      'filename': finalFilename,
      'path': finalFilename,
      'fullPath': filePath,
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
      'url': '/images/$finalFilename',
    };
  }

  /// Delete a media file
  Future<void> deleteMedia(String filename) async {
    final filePath = p.join(_mediaPath, filename);
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filename');
    }

    await file.delete();
  }

  /// Get media file info
  Future<Map<String, dynamic>?> getMediaInfo(String filename) async {
    final filePath = p.join(_mediaPath, filename);
    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    final stat = await file.stat();

    return {
      'filename': filename,
      'path': filename,
      'fullPath': filePath,
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
      'url': '/images/$filename',
    };
  }

  /// Check if file is an image
  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp']
        .contains(ext);
  }

  /// Sanitize filename to remove unsafe characters
  String _sanitizeFilename(String filename) {
    // Replace spaces with hyphens
    var sanitized = filename.replaceAll(' ', '-');

    // Remove special characters except alphanumeric, hyphens, underscores, and dots
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.]'), '');

    // Convert to lowercase
    sanitized = sanitized.toLowerCase();

    return sanitized;
  }
}
