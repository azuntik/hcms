import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/deployment_service.dart';

class DeployRoutes {
  final String hugoSitePath;
  late final DeploymentService _deploymentService;
  late final Router router;

  DeployRoutes(this.hugoSitePath) {
    _deploymentService = DeploymentService(hugoSitePath);
    router = _createRouter();
  }

  Router _createRouter() {
    final router = Router();

    // Get deployment status
    router.get('/status', (Request request) {
      final status = _deploymentService.getStatus();
      return Response.ok(
        jsonEncode(status),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Trigger deployment
    router.post('/trigger', (Request request) async {
      try {
        final result = await _deploymentService.deploy();

        if (result['success']) {
          return Response.ok(
            jsonEncode(result),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          return Response.internalServerError(
            body: jsonEncode(result),
          );
        }
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': e.toString(),
          }),
        );
      }
    });

    // Get deployment history
    router.get('/history', (Request request) {
      final history = _deploymentService.getHistory();
      return Response.ok(
        jsonEncode({'history': history}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    return router;
  }
}
