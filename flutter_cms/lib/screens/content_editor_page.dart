import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/content_file.dart';
import '../models/file_item.dart';
import '../providers/content_provider.dart';
import '../widgets/file_browser/file_list.dart';
import '../widgets/editor/frontmatter_form.dart';

class ContentEditorPage extends StatefulWidget {
  const ContentEditorPage({super.key});

  @override
  State<ContentEditorPage> createState() => _ContentEditorPageState();
}

class _ContentEditorPageState extends State<ContentEditorPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  Map<String, dynamic> _frontmatter = {};
  bool _showPreview = false;
  bool _showFrontmatterForm = true;

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _loadFile(FileItem file) async {
    final provider = context.read<ContentProvider>();
    await provider.loadContent(file.path);

    if (provider.currentContent != null) {
      setState(() {
        _frontmatter = Map.from(provider.currentContent!.frontmatter);
        _contentController.text = provider.currentContent!.content;
        _titleController.text = provider.currentContent!.title;
      });
    }
  }

  void _saveContent() async {
    final provider = context.read<ContentProvider>();
    final currentContent = provider.currentContent;

    if (currentContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    // Update title in frontmatter
    _frontmatter['title'] = _titleController.text;

    final success = await provider.updateContent(
      path: currentContent.path,
      frontmatter: _frontmatter,
      content: _contentController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${provider.error}')),
      );
    }
  }

  void _saveAndCommit() async {
    final provider = context.read<ContentProvider>();
    final currentContent = provider.currentContent;

    if (currentContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    // Update title in frontmatter
    _frontmatter['title'] = _titleController.text;

    final success = await provider.saveAndCommit(
      path: currentContent.path,
      frontmatter: _frontmatter,
      content: _contentController.text,
      commitMessage: 'Update ${currentContent.path}',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved and committed')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Editor'),
        actions: [
          IconButton(
            icon: Icon(_showFrontmatterForm ? Icons.code : Icons.article),
            onPressed: () {
              setState(() {
                _showFrontmatterForm = !_showFrontmatterForm;
              });
            },
            tooltip: _showFrontmatterForm ? 'Hide frontmatter' : 'Show frontmatter',
          ),
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
            tooltip: _showPreview ? 'Edit mode' : 'Preview mode',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _saveContent,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _saveAndCommit,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Save & Commit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // File browser sidebar
          SizedBox(
            width: 300,
            child: Card(
              margin: EdgeInsets.zero,
              child: FileList(onFileSelected: _loadFile),
            ),
          ),

          // Main editor area
          Expanded(
            child: Consumer<ContentProvider>(
              builder: (context, provider, child) {
                if (provider.currentContent == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_document, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Select a file to edit'),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Frontmatter section
                    if (_showFrontmatterForm)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: FrontmatterForm(
                            frontmatter: _frontmatter,
                            onChanged: (updatedFrontmatter) {
                              setState(() {
                                _frontmatter = updatedFrontmatter;
                              });
                            },
                          ),
                        ),
                      ),

                    // Content editor/preview
                    Expanded(
                      child: Row(
                        children: [
                          // Editor pane
                          if (!_showPreview || !_showPreview)
                            Expanded(
                              child: _buildEditor(),
                            ),

                          // Preview pane
                          if (_showPreview)
                            Expanded(
                              child: _buildPreview(),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title editor
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Content editor
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Write your content here (Markdown supported)...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),

            // Toolbar
            const SizedBox(height: 8),
            _buildMarkdownToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const Icon(Icons.preview),
                const SizedBox(width: 8),
                const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Markdown(
                data: '# ${_titleController.text}\n\n${_contentController.text}',
                selectable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownToolbar() {
    return Wrap(
      spacing: 4,
      children: [
        _toolbarButton(Icons.format_bold, 'Bold', () => _insertMarkdown('**', '**')),
        _toolbarButton(Icons.format_italic, 'Italic', () => _insertMarkdown('*', '*')),
        _toolbarButton(Icons.format_list_bulleted, 'List', () => _insertMarkdown('- ', '')),
        _toolbarButton(Icons.format_list_numbered, 'Numbered', () => _insertMarkdown('1. ', '')),
        _toolbarButton(Icons.link, 'Link', () => _insertMarkdown('[', '](url)')),
        _toolbarButton(Icons.code, 'Code', () => _insertMarkdown('`', '`')),
        _toolbarButton(Icons.format_quote, 'Quote', () => _insertMarkdown('> ', '')),
      ],
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  void _insertMarkdown(String before, String after) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$before$selectedText$after',
      );

      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + before.length + selectedText.length,
        ),
      );
    }
  }
}
