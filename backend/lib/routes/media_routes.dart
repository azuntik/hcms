import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/media_service.dart';

class MediaRoutes {
  final String hugoSitePath;
  late final MediaService _mediaService;
  late final Router router;

  MediaRoutes(this.hugoSitePath) {
    _mediaService = MediaService(hugoSitePath);
    router = _createRouter();
  }

  Router _createRouter() {
    final router = Router();

    // List all media files
    router.get('/', (Request request) async {
      try {
        final files = await _mediaService.listMedia();
        return Response.ok(
          jsonEncode({'files': files}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Upload media file
    router.post('/upload', (Request request) async {
      try {
        final contentType = request.headers['content-type'] ?? '';

        if (!contentType.startsWith('multipart/form-data')) {
          return Response.badRequest(
            body: jsonEncode({
              'error': 'Content-Type must be multipart/form-data',
            }),
          );
        }

        // Read the entire request body
        final bytes = await request.read().expand((chunk) => chunk).toList();
        final bodyBytes = Uint8List.fromList(bytes);

        // Parse multipart form data
        final boundary = _extractBoundary(contentType);
        if (boundary == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid multipart boundary'}),
          );
        }

        final parts = _parseMultipart(bodyBytes, boundary);

        if (parts.isEmpty) {
          return Response.badRequest(
            body: jsonEncode({'error': 'No file in request'}),
          );
        }

        // Get the first file part
        final filePart = parts.first;
        final filename = filePart['filename'] as String? ?? 'unnamed.jpg';
        final fileBytes = filePart['data'] as Uint8List;

        // Upload the file
        final result = await _mediaService.uploadMedia(filename, fileBytes);

        return Response.ok(
          jsonEncode(result),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Get specific media info
    router.get('/<filename>', (Request request, String filename) async {
      try {
        final info = await _mediaService.getMediaInfo(filename);

        if (info == null) {
          return Response.notFound(
            jsonEncode({'error': 'File not found'}),
          );
        }

        return Response.ok(
          jsonEncode(info),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Delete media file
    router.delete('/<filename>', (Request request, String filename) async {
      try {
        await _mediaService.deleteMedia(filename);

        return Response.ok(
          jsonEncode({'success': true, 'filename': filename}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    return router;
  }

  /// Extract boundary from Content-Type header
  String? _extractBoundary(String contentType) {
    final parts = contentType.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('boundary=')) {
        return trimmed.substring('boundary='.length);
      }
    }
    return null;
  }

  /// Parse multipart form data
  List<Map<String, dynamic>> _parseMultipart(
    Uint8List bytes,
    String boundary,
  ) {
    final parts = <Map<String, dynamic>>[];
    final boundaryBytes = utf8.encode('--$boundary');
    final crlfBytes = utf8.encode('\r\n');

    var position = 0;

    while (position < bytes.length) {
      // Find next boundary
      final boundaryIndex = _indexOf(bytes, boundaryBytes, position);
      if (boundaryIndex == -1) break;

      position = boundaryIndex + boundaryBytes.length;

      // Check for end boundary
      if (position + 2 < bytes.length &&
          bytes[position] == 45 &&
          bytes[position + 1] == 45) {
        break;
      }

      // Skip CRLF after boundary
      if (position + 2 <= bytes.length &&
          bytes[position] == 13 &&
          bytes[position + 1] == 10) {
        position += 2;
      }

      // Find end of headers (double CRLF)
      final doubleCrlf = utf8.encode('\r\n\r\n');
      final headersEnd = _indexOf(bytes, doubleCrlf, position);
      if (headersEnd == -1) break;

      // Parse headers
      final headersBytes = bytes.sublist(position, headersEnd);
      final headersText = utf8.decode(headersBytes);
      final headers = _parseHeaders(headersText);

      position = headersEnd + doubleCrlf.length;

      // Find next boundary to get content
      final nextBoundary = _indexOf(bytes, boundaryBytes, position);
      if (nextBoundary == -1) break;

      // Extract content (minus trailing CRLF)
      var contentEnd = nextBoundary - 2;
      if (contentEnd > position) {
        final content = bytes.sublist(position, contentEnd);

        parts.add({
          'filename': headers['filename'],
          'contentType': headers['contentType'],
          'data': content,
        });
      }

      position = nextBoundary;
    }

    return parts;
  }

  /// Find byte sequence in array
  int _indexOf(Uint8List bytes, List<int> pattern, int start) {
    for (var i = start; i <= bytes.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  /// Parse multipart headers
  Map<String, String?> _parseHeaders(String headersText) {
    final result = <String, String?>{};
    final lines = headersText.split('\r\n');

    for (final line in lines) {
      if (line.toLowerCase().startsWith('content-disposition:')) {
        final match = RegExp(r'filename="([^"]+)"').firstMatch(line);
        if (match != null) {
          result['filename'] = match.group(1);
        }
      } else if (line.toLowerCase().startsWith('content-type:')) {
        result['contentType'] = line.substring('content-type:'.length).trim();
      }
    }

    return result;
  }
}
