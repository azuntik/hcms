import 'dart:io';

class GitService {
  final String repoPath;

  GitService(this.repoPath);

  /// Get Git status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final result = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: repoPath,
      );

      final output = result.stdout.toString();
      final lines = output.split('\n').where((line) => line.isNotEmpty).toList();

      return {
        'hasChanges': lines.isNotEmpty,
        'files': lines,
        'rawOutput': output,
      };
    } catch (e) {
      throw Exception('Failed to get Git status: $e');
    }
  }

  /// Commit changes
  Future<void> commit(String message, List<String> files) async {
    try {
      // Add files
      if (files.isEmpty) {
        // Add all changes
        await _runGit(['add', '-A']);
      } else {
        // Add specific files
        await _runGit(['add', ...files]);
      }

      // Commit
      await _runGit(['commit', '-m', message]);
    } catch (e) {
      throw Exception('Failed to commit changes: $e');
    }
  }

  /// Push to remote
  Future<void> push() async {
    try {
      await _runGit(['push']);
    } catch (e) {
      throw Exception('Failed to push to remote: $e');
    }
  }

  /// Get file history
  Future<List<Map<String, dynamic>>> getFileHistory(String filePath) async {
    try {
      final result = await Process.run(
        'git',
        [
          'log',
          '--pretty=format:%H|%an|%ae|%ad|%s',
          '--date=iso',
          '--',
          filePath,
        ],
        workingDirectory: repoPath,
      );

      final output = result.stdout.toString();
      final lines = output.split('\n').where((line) => line.isNotEmpty).toList();

      return lines.map((line) {
        final parts = line.split('|');
        return {
          'hash': parts[0],
          'author': parts[1],
          'email': parts[2],
          'date': parts[3],
          'message': parts[4],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get file history: $e');
    }
  }

  /// Run Git command
  Future<ProcessResult> _runGit(List<String> args) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: repoPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Git command failed: ${result.stderr}');
    }

    return result;
  }
}
