import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/git_service.dart';

class GitRoutes {
  final String hugoSitePath;
  late final GitService _gitService;
  late final Router router;

  GitRoutes(this.hugoSitePath) {
    _gitService = GitService(hugoSitePath);
    router = _createRouter();
  }

  Router _createRouter() {
    final router = Router();

    // Get Git status
    router.get('/status', (Request request) async {
      try {
        final status = await _gitService.getStatus();
        return Response.ok(
          jsonEncode(status),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Commit changes
    router.post('/commit', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final message = data['message'] as String;
        final files = (data['files'] as List?)?.cast<String>() ?? [];

        await _gitService.commit(message, files);

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Push to remote
    router.post('/push', (Request request) async {
      try {
        await _gitService.push();

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Get file history
    router.get('/history/<path|.*>', (Request request, String path) async {
      try {
        final history = await _gitService.getFileHistory(path);
        return Response.ok(
          jsonEncode({'history': history}),
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
