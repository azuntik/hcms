import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_file.dart';
import '../../providers/media_provider.dart';

class ImagePickerDialog extends StatefulWidget {
  const ImagePickerDialog({super.key});

  @override
  State<ImagePickerDialog> createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<ImagePickerDialog> {
  MediaFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Load media list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().loadMediaList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.photo_library),
                const SizedBox(width: 8),
                const Text(
                  'Insert Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Image grid
            Expanded(
              child: Consumer<MediaProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.files.isEmpty) {
                    return const Center(
                      child: Text('No images available'),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: provider.files.length,
                    itemBuilder: (context, index) {
                      final file = provider.files[index];
                      final isSelected = _selectedImage?.filename == file.filename;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImage = file;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.network(
                              'http://localhost:8080${file.url}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Selected image info
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedImage!.filename,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedImage == null
                      ? null
                      : () => Navigator.pop(context, _selectedImage),
                  child: const Text('Insert Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
