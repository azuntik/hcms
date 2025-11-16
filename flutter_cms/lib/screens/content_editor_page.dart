import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/content_file.dart';
import '../models/file_item.dart';
import '../providers/content_provider.dart';
import '../widgets/file_browser/file_list.dart';
import '../widgets/editor/frontmatter_form.dart';
import '../widgets/editor/wysiwyg_editor.dart';

enum EditorMode { wysiwyg, markdown }

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
  EditorMode _editorMode = EditorMode.wysiwyg;

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
        const SnackBar(
          content: Text('Content saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
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
        const SnackBar(
          content: Text('Content saved and committed to Git'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Editor'),
        actions: [
          // Editor mode toggle
          SegmentedButton<EditorMode>(
            segments: const [
              ButtonSegment(
                value: EditorMode.wysiwyg,
                label: Text('WYSIWYG'),
                icon: Icon(Icons.edit_note),
              ),
              ButtonSegment(
                value: EditorMode.markdown,
                label: Text('Markdown'),
                icon: Icon(Icons.code),
              ),
            ],
            selected: {_editorMode},
            onSelectionChanged: (Set<EditorMode> selected) {
              setState(() {
                _editorMode = selected.first;
              });
            },
          ),
          const SizedBox(width: 16),

          // Frontmatter toggle
          IconButton(
            icon: Icon(_showFrontmatterForm ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showFrontmatterForm = !_showFrontmatterForm;
              });
            },
            tooltip: _showFrontmatterForm ? 'Hide metadata' : 'Show metadata',
          ),

          // Preview toggle
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
            tooltip: _showPreview ? 'Hide preview' : 'Show preview',
          ),
          const SizedBox(width: 8),

          // Save button
          ElevatedButton.icon(
            onPressed: _saveContent,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),

          // Save & Commit button
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
                        Text(
                          'Select a file to edit',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
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
                          if (!_showPreview)
                            Expanded(
                              child: _buildEditorPane(),
                            )
                          else
                            Expanded(
                              flex: _showPreview ? 1 : 2,
                              child: _buildEditorPane(),
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

  Widget _buildEditorPane() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Post Title',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          // Editor content
          Expanded(
            child: _editorMode == EditorMode.wysiwyg
                ? _buildWysiwygEditor()
                : _buildMarkdownEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildWysiwygEditor() {
    return WysiwygEditor(
      initialMarkdown: _contentController.text,
      onChanged: (markdown) {
        // Update the controller without triggering rebuild
        if (_contentController.text != markdown) {
          _contentController.text = markdown;
        }
      },
    );
  }

  Widget _buildMarkdownEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Markdown toolbar
          _buildMarkdownToolbar(),
          const SizedBox(height: 8),

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
        ],
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
            child: const Row(
              children: [
                Icon(Icons.preview),
                SizedBox(width: 8),
                Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
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
        _toolbarButton(Icons.title, 'Heading', () => _insertMarkdown('## ', '')),
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
