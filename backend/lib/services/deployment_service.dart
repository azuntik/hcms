import 'dart:io';
import 'package:path/path.dart' as p;

class DeploymentService {
  final String hugoSitePath;
  final List<Map<String, dynamic>> _history = [];
  bool _isDeploying = false;

  DeploymentService(this.hugoSitePath);

  /// Get current deployment status
  Map<String, dynamic> getStatus() {
    return {
      'isDeploying': _isDeploying,
      'lastDeployment': _history.isNotEmpty ? _history.first : null,
    };
  }

  /// Trigger deployment
  Future<Map<String, dynamic>> deploy() async {
    if (_isDeploying) {
      return {
        'success': false,
        'error': 'Deployment already in progress',
      };
    }

    _isDeploying = true;
    final startTime = DateTime.now();

    try {
      // Run deployment script
      final deployScript = p.join(hugoSitePath, 'deploy.sh');
      final deployFile = File(deployScript);

      if (!await deployFile.exists()) {
        throw Exception('Deployment script not found: $deployScript');
      }

      final result = await Process.run(
        'bash',
        [deployScript],
        workingDirectory: hugoSitePath,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final deploymentResult = {
        'success': result.exitCode == 0,
        'timestamp': startTime.toIso8601String(),
        'duration': duration.inMilliseconds,
        'output': result.stdout.toString(),
        'errors': result.stderr.toString(),
        'exitCode': result.exitCode,
      };

      // Add to history
      _history.insert(0, deploymentResult);

      // Keep only last 20 deployments
      if (_history.length > 20) {
        _history.removeRange(20, _history.length);
      }

      return deploymentResult;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } finally {
      _isDeploying = false;
    }
  }

  /// Get deployment history
  List<Map<String, dynamic>> getHistory() {
    return List.from(_history);
  }
}
