import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';

import 'routes/content_routes.dart';
import 'routes/deploy_routes.dart';
import 'routes/git_routes.dart';
import 'routes/media_routes.dart';
import 'middleware/logging_middleware.dart';

void main() async {
  // Load environment variables
  final env = DotEnv()..load();

  final port = int.parse(env.getOrElse('PORT', () => '8080'));
  final hugoSitePath =
      env.getOrElse('HUGO_SITE_PATH', () => '../hugo_site');

  // Create router
  final app = Router();

  // Health check
  app.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // API routes
  app.mount('/api/content', ContentRoutes(hugoSitePath).router);
  app.mount('/api/git', GitRoutes(hugoSitePath).router);
  app.mount('/api/deploy', DeployRoutes(hugoSitePath).router);
  app.mount('/api/media', MediaRoutes(hugoSitePath).router);

  // Create middleware pipeline
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(loggingMiddleware())
      .addMiddleware(corsHeaders())
      .addHandler(app);

  // Start server
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');
}
