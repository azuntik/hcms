import 'package:shelf/shelf.dart';

/// Logging middleware
Middleware loggingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final watch = Stopwatch()..start();

      try {
        final response = await innerHandler(request);
        watch.stop();

        print(
          '${request.method} ${request.url} - ${response.statusCode} (${watch.elapsedMilliseconds}ms)',
        );

        return response;
      } catch (e, stackTrace) {
        watch.stop();
        print('ERROR: ${request.method} ${request.url} - $e');
        print(stackTrace);
        rethrow;
      }
    };
  };
}
