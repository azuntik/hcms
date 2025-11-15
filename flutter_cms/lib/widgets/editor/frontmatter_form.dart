import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FrontmatterForm extends StatefulWidget {
  final Map<String, dynamic> frontmatter;
  final Function(Map<String, dynamic>) onChanged;

  const FrontmatterForm({
    super.key,
    required this.frontmatter,
    required this.onChanged,
  });

  @override
  State<FrontmatterForm> createState() => _FrontmatterFormState();
}

class _FrontmatterFormState extends State<FrontmatterForm> {
  late TextEditingController _tagsController;
  late TextEditingController _categoriesController;
  late TextEditingController _descriptionController;
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _tagsController = TextEditingController(
      text: _listToString(widget.frontmatter['tags']),
    );
    _categoriesController = TextEditingController(
      text: _listToString(widget.frontmatter['categories']),
    );
    _descriptionController = TextEditingController(
      text: widget.frontmatter['description'] as String? ?? '',
    );
    _authorController = TextEditingController(
      text: widget.frontmatter['author'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _categoriesController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  String _listToString(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return '';
  }

  List<String> _stringToList(String value) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _updateFrontmatter(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(widget.frontmatter);
    updated[key] = value;
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frontmatter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Date picker
          Row(
            children: [
              Expanded(
                child: Text(
                  'Date: ${_formatDate(widget.frontmatter['date'])}',
                ),
              ),
              TextButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Draft toggle
          SwitchListTile(
            title: const Text('Draft'),
            value: widget.frontmatter['draft'] as bool? ?? true,
            onChanged: (value) {
              _updateFrontmatter('draft', value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
            onChanged: (value) {
              _updateFrontmatter('description', value);
            },
          ),
          const SizedBox(height: 12),

          // Author
          TextField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              _updateFrontmatter('author', value);
            },
          ),
          const SizedBox(height: 12),

          // Tags
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma-separated)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'flutter, dart, web',
            ),
            onChanged: (value) {
              _updateFrontmatter('tags', _stringToList(value));
            },
          ),
          const SizedBox(height: 12),

          // Categories
          TextField(
            controller: _categoriesController,
            decoration: const InputDecoration(
              labelText: 'Categories (comma-separated)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'tutorials, news',
            ),
            onChanged: (value) {
              _updateFrontmatter('categories', _stringToList(value));
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not set';

    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }

    if (dateTime == null) return 'Invalid date';

    return DateFormat('MMM d, y HH:mm').format(dateTime);
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = widget.frontmatter['date'];
    DateTime? initialDate;

    if (currentDate is String) {
      initialDate = DateTime.tryParse(currentDate);
    } else if (currentDate is DateTime) {
      initialDate = currentDate;
    }

    initialDate ??= DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null && mounted) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        _updateFrontmatter('date', dateTime.toIso8601String());
      }
    }
  }
}
