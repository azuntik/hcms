import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as p;
import '../services/content_service.dart';

class ContentRoutes {
  final String hugoSitePath;
  late final ContentService _contentService;
  late final Router router;

  ContentRoutes(this.hugoSitePath) {
    _contentService = ContentService(hugoSitePath);
    router = _createRouter();
  }

  Router _createRouter() {
    final router = Router();

    // List all content files
    router.get('/', (Request request) async {
      try {
        final files = await _contentService.listContent();
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

    // Get specific content file
    router.get('/<path|.*>', (Request request, String path) async {
      try {
        final content = await _contentService.getContent(path);
        return Response.ok(
          jsonEncode(content),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.notFound(
          jsonEncode({'error': 'File not found: $path'}),
        );
      }
    });

    // Create new content
    router.post('/', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final path = data['path'] as String;
        final frontmatter = data['frontmatter'] as Map<String, dynamic>;
        final content = data['content'] as String;

        await _contentService.createContent(path, frontmatter, content);

        return Response.ok(
          jsonEncode({'success': true, 'path': path}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Update content
    router.put('/<path|.*>', (Request request, String path) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final frontmatter = data['frontmatter'] as Map<String, dynamic>;
        final content = data['content'] as String;

        await _contentService.updateContent(path, frontmatter, content);

        return Response.ok(
          jsonEncode({'success': true, 'path': path}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Delete content
    router.delete('/<path|.*>', (Request request, String path) async {
      try {
        await _contentService.deleteContent(path);

        return Response.ok(
          jsonEncode({'success': true, 'path': path}),
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
}
