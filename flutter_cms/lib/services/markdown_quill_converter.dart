import 'package:flutter_quill/flutter_quill.dart';

/// Service for converting between Markdown and Quill Delta format
class MarkdownQuillConverter {
  /// Convert Markdown text to Quill Delta
  static Document markdownToQuill(String markdown) {
    final delta = Delta();

    if (markdown.isEmpty) {
      delta.insert('\n');
      return Document.fromDelta(delta);
    }

    final lines = markdown.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Headers
      if (line.startsWith('# ')) {
        delta.insert(line.substring(2));
        delta.insert('\n', {'header': 1});
      } else if (line.startsWith('## ')) {
        delta.insert(line.substring(3));
        delta.insert('\n', {'header': 2});
      } else if (line.startsWith('### ')) {
        delta.insert(line.substring(4));
        delta.insert('\n', {'header': 3});
      } else if (line.startsWith('#### ')) {
        delta.insert(line.substring(5));
        delta.insert('\n', {'header': 4});
      } else if (line.startsWith('##### ')) {
        delta.insert(line.substring(6));
        delta.insert('\n', {'header': 5});
      } else if (line.startsWith('###### ')) {
        delta.insert(line.substring(7));
        delta.insert('\n', {'header': 6});
      }
      // Blockquote
      else if (line.startsWith('> ')) {
        _processInlineFormats(delta, line.substring(2));
        delta.insert('\n', {'blockquote': true});
      }
      // Unordered list
      else if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) {
        _processInlineFormats(delta, line.substring(2));
        delta.insert('\n', {'list': 'bullet'});
      }
      // Ordered list
      else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s').firstMatch(line);
        _processInlineFormats(delta, line.substring(match!.end));
        delta.insert('\n', {'list': 'ordered'});
      }
      // Code block
      else if (line.startsWith('```')) {
        // Handle code blocks
        final codeLines = <String>[];
        i++; // Skip opening ```
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        delta.insert(codeLines.join('\n'));
        delta.insert('\n', {'code-block': true});
      }
      // Horizontal rule
      else if (line.trim() == '---' || line.trim() == '***' || line.trim() == '___') {
        delta.insert('\n');
      }
      // Regular paragraph
      else {
        if (line.trim().isEmpty) {
          delta.insert('\n');
        } else {
          _processInlineFormats(delta, line);
          delta.insert('\n');
        }
      }
    }

    return Document.fromDelta(delta);
  }

  /// Process inline markdown formats (bold, italic, code, links)
  static void _processInlineFormats(Delta delta, String text) {
    if (text.isEmpty) return;

    // Simple regex patterns for inline formatting
    var remaining = text;
    var position = 0;

    while (position < remaining.length) {
      // Bold with **
      final boldMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(remaining.substring(position));
      // Italic with *
      final italicMatch = RegExp(r'\*(.*?)\*').firstMatch(remaining.substring(position));
      // Inline code with `
      final codeMatch = RegExp(r'`([^`]+)`').firstMatch(remaining.substring(position));
      // Links [text](url)
      final linkMatch = RegExp(r'\[([^\]]+)\]\(([^)]+)\)').firstMatch(remaining.substring(position));

      // Find the earliest match
      final matches = <MapEntry<int?, Match>>[
        MapEntry(boldMatch?.start, boldMatch),
        MapEntry(italicMatch?.start, italicMatch),
        MapEntry(codeMatch?.start, codeMatch),
        MapEntry(linkMatch?.start, linkMatch),
      ].where((e) => e.key != null).toList()
        ..sort((a, b) => a.key!.compareTo(b.key!));

      if (matches.isEmpty) {
        // No more formatting, insert remaining text
        delta.insert(remaining.substring(position));
        break;
      }

      final firstMatch = matches.first.value!;
      final matchStart = position + firstMatch.start;

      // Insert text before the match
      if (matchStart > position) {
        delta.insert(remaining.substring(position, matchStart));
      }

      // Insert formatted text
      if (firstMatch == boldMatch) {
        delta.insert(firstMatch.group(1), {'bold': true});
        position = matchStart + firstMatch.group(0)!.length;
      } else if (firstMatch == italicMatch && firstMatch != boldMatch) {
        delta.insert(firstMatch.group(1), {'italic': true});
        position = matchStart + firstMatch.group(0)!.length;
      } else if (firstMatch == codeMatch) {
        delta.insert(firstMatch.group(1), {'code': true});
        position = matchStart + firstMatch.group(0)!.length;
      } else if (firstMatch == linkMatch) {
        delta.insert(firstMatch.group(1), {'link': firstMatch.group(2)});
        position = matchStart + firstMatch.group(0)!.length;
      }
    }
  }

  /// Convert Quill Delta to Markdown text
  static String quillToMarkdown(Document document) {
    final buffer = StringBuffer();
    final delta = document.toDelta();

    for (var i = 0; i < delta.length; i++) {
      final op = delta.elementAt(i);
      final text = op.data is String ? op.data as String : '';
      final attrs = op.attributes ?? {};

      // Handle newlines with block attributes
      if (text.contains('\n')) {
        final lines = text.split('\n');
        for (var j = 0; j < lines.length; j++) {
          if (lines[j].isNotEmpty) {
            _writeInlineFormats(buffer, lines[j], attrs);
          }

          // Add block formatting on newline
          if (j < lines.length - 1 || i == delta.length - 1) {
            if (attrs.containsKey('header')) {
              final level = attrs['header'] as int;
              final prefix = '#' * level;
              final line = buffer.toString().split('\n').last;
              // Replace last line with header format
              final lines = buffer.toString().split('\n');
              if (lines.isNotEmpty) {
                lines[lines.length - 1] = '$prefix ${lines.last}';
                buffer.clear();
                buffer.write(lines.join('\n'));
              }
            } else if (attrs.containsKey('list')) {
              final listType = attrs['list'];
              final line = buffer.toString().split('\n').last;
              final lines = buffer.toString().split('\n');
              if (lines.isNotEmpty) {
                if (listType == 'bullet') {
                  lines[lines.length - 1] = '- ${lines.last}';
                } else if (listType == 'ordered') {
                  lines[lines.length - 1] = '1. ${lines.last}';
                }
                buffer.clear();
                buffer.write(lines.join('\n'));
              }
            } else if (attrs.containsKey('blockquote')) {
              final line = buffer.toString().split('\n').last;
              final lines = buffer.toString().split('\n');
              if (lines.isNotEmpty) {
                lines[lines.length - 1] = '> ${lines.last}';
                buffer.clear();
                buffer.write(lines.join('\n'));
              }
            } else if (attrs.containsKey('code-block')) {
              final line = buffer.toString().split('\n').last;
              final lines = buffer.toString().split('\n');
              if (lines.isNotEmpty && j == 0) {
                lines.insert(lines.length - 1, '```');
                buffer.clear();
                buffer.write(lines.join('\n'));
              }
              if (j == lines.length - 2) {
                buffer.write('\n```');
              }
            }

            buffer.write('\n');
          }
        }
      } else {
        // Regular text without newlines
        _writeInlineFormats(buffer, text, attrs);
      }
    }

    return buffer.toString().trim();
  }

  /// Write text with inline formatting
  static void _writeInlineFormats(StringBuffer buffer, String text, Map<String, dynamic> attrs) {
    if (text.isEmpty) return;

    var formatted = text;

    // Apply inline formats
    if (attrs.containsKey('bold')) {
      formatted = '**$formatted**';
    }
    if (attrs.containsKey('italic')) {
      formatted = '*$formatted*';
    }
    if (attrs.containsKey('code')) {
      formatted = '`$formatted`';
    }
    if (attrs.containsKey('link')) {
      final url = attrs['link'];
      formatted = '[$formatted]($url)';
    }
    if (attrs.containsKey('strike')) {
      formatted = '~~$formatted~~';
    }

    buffer.write(formatted);
  }
}
