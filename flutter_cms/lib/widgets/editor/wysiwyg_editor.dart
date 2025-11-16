import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../services/markdown_quill_converter.dart';

class WysiwygEditor extends StatefulWidget {
  final String initialMarkdown;
  final Function(String) onChanged;

  const WysiwygEditor({
    super.key,
    required this.initialMarkdown,
    required this.onChanged,
  });

  @override
  State<WysiwygEditor> createState() => _WysiwygEditorState();
}

class _WysiwygEditorState extends State<WysiwygEditor> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // Convert markdown to Quill document
    final document = MarkdownQuillConverter.markdownToQuill(widget.initialMarkdown);
    _controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen for changes
    _controller.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    // Convert Quill document back to markdown
    final markdown = MarkdownQuillConverter.quillToMarkdown(_controller.document);
    widget.onChanged(markdown);
  }

  @override
  void didUpdateWidget(WysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller if markdown changed externally
    if (oldWidget.initialMarkdown != widget.initialMarkdown) {
      final currentMarkdown = MarkdownQuillConverter.quillToMarkdown(_controller.document);

      // Only update if the markdown is actually different
      if (currentMarkdown != widget.initialMarkdown) {
        _controller.removeListener(_onContentChanged);
        final document = MarkdownQuillConverter.markdownToQuill(widget.initialMarkdown);
        _controller.document = document;
        _controller.addListener(_onContentChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: _controller,
              sharedConfigurations: const quill.QuillSharedConfigurations(),
              showAlignmentButtons: true,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showCodeBlock: true,
              showColorButton: false,
              showDirection: false,
              showDividers: true,
              showFontFamily: false,
              showFontSize: false,
              showHeaderStyle: true,
              showInlineCode: true,
              showLink: true,
              showListBullets: true,
              showListCheck: true,
              showListNumbers: true,
              showQuote: true,
              showIndent: true,
              showSearchButton: false,
              showStrikeThrough: true,
              showSubscript: false,
              showSuperscript: false,
              showUnderLineButton: false,
            ),
          ),
        ),

        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: quill.QuillEditor.basic(
              configurations: quill.QuillEditorConfigurations(
                controller: _controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(),
                scrollable: true,
                autoFocus: false,
                expands: false,
                padding: EdgeInsets.zero,
                placeholder: 'Start writing your content...',
              ),
              focusNode: _focusNode,
              scrollController: _scrollController,
            ),
          ),
        ),
      ],
    );
  }
}
