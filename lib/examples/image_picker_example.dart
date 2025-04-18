import 'package:flutter/material.dart';
import 'package:lingua_visual/utils/image_picker_utils.dart';

/// An example screen that demonstrates how to use the ImagePickerWebView.
class ImagePickerExample extends StatefulWidget {
  const ImagePickerExample({super.key});

  @override
  State<ImagePickerExample> createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  String? _selectedImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Picker Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImageUrl != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _selectedImageUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Selected Image URL: $_selectedImageUrl'),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image from Google'),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the image picker and updates the selected image URL.
  Future<void> _pickImage() async {
    final imageUrl = await ImagePickerUtils.pickImage(context);
    if (imageUrl != null) {
      setState(() {
        _selectedImageUrl = imageUrl;
      });
    }
  }
}
