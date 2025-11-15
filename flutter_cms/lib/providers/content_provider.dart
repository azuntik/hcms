import 'package:flutter/foundation.dart';
import '../models/content_file.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';

class ContentProvider extends ChangeNotifier {
  final ApiService _apiService;

  ContentProvider(this._apiService);

  List<FileItem> _files = [];
  ContentFile? _currentContent;
  bool _isLoading = false;
  String? _error;

  List<FileItem> get files => _files;
  ContentFile? get currentContent => _currentContent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load list of all content files
  Future<void> loadContentList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _files = await _apiService.listContent();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _files = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load specific content file
  Future<void> loadContent(String path) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentContent = await _apiService.getContent(path);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentContent = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new content
  Future<bool> createContent({
    required String path,
    required Map<String, dynamic> frontmatter,
    required String content,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createContent(
        path: path,
        frontmatter: frontmatter,
        content: content,
      );

      // Reload content list
      await loadContentList();

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing content
  Future<bool> updateContent({
    required String path,
    required Map<String, dynamic> frontmatter,
    required String content,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateContent(
        path: path,
        frontmatter: frontmatter,
        content: content,
      );

      // Update current content if it's the same file
      if (_currentContent?.path == path) {
        _currentContent = ContentFile(
          path: path,
          frontmatter: frontmatter,
          content: content,
        );
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete content
  Future<bool> deleteContent(String path) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteContent(path);

      // Clear current content if it was deleted
      if (_currentContent?.path == path) {
        _currentContent = null;
      }

      // Reload content list
      await loadContentList();

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save and commit content
  Future<bool> saveAndCommit({
    required String path,
    required Map<String, dynamic> frontmatter,
    required String content,
    String? commitMessage,
  }) async {
    // First save the content
    final saved = await updateContent(
      path: path,
      frontmatter: frontmatter,
      content: content,
    );

    if (!saved) return false;

    // Then commit to git
    try {
      final message = commitMessage ?? 'Update $path';
      await _apiService.gitCommit(
        message: message,
        files: [path],
      );
      return true;
    } catch (e) {
      _error = 'Saved but failed to commit: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear current content
  void clearCurrentContent() {
    _currentContent = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
