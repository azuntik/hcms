import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../services/api_service.dart';

class MediaProvider extends ChangeNotifier {
  final ApiService _apiService;

  MediaProvider(this._apiService);

  List<MediaFile> _files = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  List<MediaFile> get files => _files;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;

  /// Load list of all media files
  Future<void> loadMediaList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filesJson = await _apiService.listMedia();
      _files = filesJson.map((json) => MediaFile.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _files = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a media file
  Future<MediaFile?> uploadMedia(String filename, Uint8List bytes) async {
    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.uploadMedia(filename, bytes);
      final mediaFile = MediaFile.fromJson(result);

      // Add to list
      _files.insert(0, mediaFile);

      _error = null;
      return mediaFile;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Delete a media file
  Future<bool> deleteMedia(String filename) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteMedia(filename);

      // Remove from list
      _files.removeWhere((f) => f.filename == filename);

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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
