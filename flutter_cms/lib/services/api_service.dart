import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_file.dart';
import '../models/file_item.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:8080'});

  // Content endpoints
  Future<List<FileItem>> listContent() async {
    final response = await http.get(Uri.parse('$baseUrl/api/content'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final files = data['files'] as List;
      return files.map((f) => FileItem.fromJson(f as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load content list: ${response.statusCode}');
    }
  }

  Future<ContentFile> getContent(String path) async {
    final encodedPath = Uri.encodeComponent(path);
    final response = await http.get(Uri.parse('$baseUrl/api/content/$encodedPath'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ContentFile.fromJson(data);
    } else {
      throw Exception('Failed to load content: ${response.statusCode}');
    }
  }

  Future<void> createContent({
    required String path,
    required Map<String, dynamic> frontmatter,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/content'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': path,
        'frontmatter': frontmatter,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create content: ${response.statusCode}');
    }
  }

  Future<void> updateContent({
    required String path,
    required Map<String, dynamic> frontmatter,
    required String content,
  }) async {
    final encodedPath = Uri.encodeComponent(path);
    final response = await http.put(
      Uri.parse('$baseUrl/api/content/$encodedPath'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'frontmatter': frontmatter,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update content: ${response.statusCode}');
    }
  }

  Future<void> deleteContent(String path) async {
    final encodedPath = Uri.encodeComponent(path);
    final response = await http.delete(Uri.parse('$baseUrl/api/content/$encodedPath'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete content: ${response.statusCode}');
    }
  }

  // Git endpoints
  Future<Map<String, dynamic>> getGitStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/git/status'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get git status: ${response.statusCode}');
    }
  }

  Future<void> gitCommit({
    required String message,
    List<String>? files,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/git/commit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'files': files ?? [],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to commit: ${response.statusCode}');
    }
  }

  Future<void> gitPush() async {
    final response = await http.post(Uri.parse('$baseUrl/api/git/push'));

    if (response.statusCode != 200) {
      throw Exception('Failed to push: ${response.statusCode}');
    }
  }

  // Deployment endpoints
  Future<Map<String, dynamic>> getDeploymentStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/deploy/status'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get deployment status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> triggerDeployment() async {
    final response = await http.post(Uri.parse('$baseUrl/api/deploy/trigger'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Deployment failed: ${error['error']}');
    }
  }

  Future<List<Map<String, dynamic>>> getDeploymentHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/api/deploy/history'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['history'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get deployment history: ${response.statusCode}');
    }
  }

  // Media endpoints
  Future<List<Map<String, dynamic>>> listMedia() async {
    final response = await http.get(Uri.parse('$baseUrl/api/media'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['files'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load media list: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadMedia(String filename, List<int> bytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/media/upload'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to upload media: ${response.statusCode}');
    }
  }

  Future<void> deleteMedia(String filename) async {
    final encodedFilename = Uri.encodeComponent(filename);
    final response = await http.delete(Uri.parse('$baseUrl/api/media/$encodedFilename'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete media: ${response.statusCode}');
    }
  }
}
