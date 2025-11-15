import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/file_item.dart';
import '../../providers/content_provider.dart';

class FileList extends StatefulWidget {
  final Function(FileItem) onFileSelected;

  const FileList({
    super.key,
    required this.onFileSelected,
  });

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  String _filterText = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    // Load content list when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadContentList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
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
                  onPressed: () => provider.loadContentList(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final files = _filterFiles(provider.files);

        return Column(
          children: [
            _buildHeader(provider),
            _buildFilterBar(),
            Expanded(
              child: files.isEmpty
                  ? _buildEmptyState()
                  : _buildFileList(files),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ContentProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open),
          const SizedBox(width: 8),
          Text(
            'Content Files (${provider.files.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadContentList(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search files...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _filterText = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.folder)),
              ButtonSegment(value: 'posts', label: Text('Posts'), icon: Icon(Icons.article)),
              ButtonSegment(value: 'pages', label: Text('Pages'), icon: Icon(Icons.description)),
            ],
            selected: {_selectedCategory},
            onSelectionChanged: (Set<String> selected) {
              setState(() {
                _selectedCategory = selected.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No content files found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Create your first post to get started'),
        ],
      ),
    );
  }

  Widget _buildFileList(List<FileItem> files) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileListItem(file);
      },
    );
  }

  Widget _buildFileListItem(FileItem file) {
    final dateFormat = DateFormat('MMM d, y');

    return ListTile(
      leading: Icon(
        file.isInPosts ? Icons.article : Icons.description,
        color: file.isInPosts ? Colors.blue : Colors.green,
      ),
      title: Text(file.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(file.directory, style: const TextStyle(fontSize: 12)),
          if (file.modified != null)
            Text(
              'Modified: ${dateFormat.format(file.modified!)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
      trailing: file.size != null
          ? Text(
              _formatBytes(file.size!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      onTap: () => widget.onFileSelected(file),
    );
  }

  List<FileItem> _filterFiles(List<FileItem> files) {
    var filtered = files;

    // Filter by category
    if (_selectedCategory == 'posts') {
      filtered = filtered.where((f) => f.isInPosts).toList();
    } else if (_selectedCategory == 'pages') {
      filtered = filtered.where((f) => f.isInPages).toList();
    }

    // Filter by search text
    if (_filterText.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.name.toLowerCase().contains(_filterText) ||
            f.path.toLowerCase().contains(_filterText);
      }).toList();
    }

    return filtered;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
