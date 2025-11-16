import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/media_file.dart';
import '../providers/media_provider.dart';

class MediaLibraryPage extends StatefulWidget {
  const MediaLibraryPage({super.key});

  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  MediaFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    // Load media list when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().loadMediaList();
    });
  }

  Future<void> _pickAndUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && mounted) {
      final provider = context.read<MediaProvider>();

      for (final file in result.files) {
        if (file.bytes != null) {
          await provider.uploadMedia(file.name, file.bytes!);
        }
      }

      if (provider.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded ${result.files.length} file(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(MediaFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to delete "${file.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<MediaProvider>();
      final success = await provider.deleteMedia(file.filename);

      if (success && mounted) {
        setState(() {
          if (_selectedFile?.filename == file.filename) {
            _selectedFile = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _copyUrlToClipboard(String url) {
    // In a real app, would use clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('URL: $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Library'),
        actions: [
          Consumer<MediaProvider>(
            builder: (context, provider, child) {
              return provider.isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickAndUploadFiles,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Images'),
                    );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MediaProvider>().loadMediaList(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadMediaList(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No images yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Upload your first image to get started'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadFiles,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Images'),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Image grid
              Expanded(
                flex: _selectedFile == null ? 1 : 2,
                child: _buildImageGrid(provider.files),
              ),

              // Details panel
              if (_selectedFile != null)
                SizedBox(
                  width: 350,
                  child: _buildDetailsPanel(_selectedFile!),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageGrid(List<MediaFile> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = _selectedFile?.filename == file.filename;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedFile = isSelected ? null : file;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                    child: Image.network(
                      'http://localhost:8080${file.url}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file.formatSize(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsPanel(MediaFile file) {
    final dateFormat = DateFormat('MMM d, y \'at\' h:mm a');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                const Text(
                  'Image Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'http://localhost:8080${file.url}',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _detailRow('Filename', file.filename),
                  _detailRow('Size', file.formatSize()),
                  _detailRow('Uploaded', dateFormat.format(file.modified)),
                  const SizedBox(height: 16),

                  // URL
                  const Text(
                    'URL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      file.url,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyUrlToClipboard(file.url),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy URL'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteFile(file),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
