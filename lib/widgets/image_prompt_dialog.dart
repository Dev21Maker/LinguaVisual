import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/image_picker_web_view.dart';

class ImagePromptDialog extends StatefulWidget {
  final String word;
  final Function(String) onImageSelected;
  final bool barrierDismissible;

  const ImagePromptDialog({
    super.key,
    required this.word,
    required this.onImageSelected,
    this.barrierDismissible = false,
  });

  @override
  State<ImagePromptDialog> createState() => _ImagePromptDialogState();
}

class _ImagePromptDialogState extends State<ImagePromptDialog> {
  final _promptController = TextEditingController();
  final _imageApiService = ImageApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with empty text instead of the word
    _promptController.text = '';
  }

  Future<void> _generateImage() async {
    setState(() => _isLoading = true);

    final imageUrl = await _imageApiService.getImage(_promptController.text);

    setState(() => _isLoading = false);

    if (imageUrl.isNotEmpty) {
      widget.onImageSelected(imageUrl);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickFromDevice() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Device image picking is not available yet')));
  }

  Future<void> _pickFromGoogle() async {
    final imageUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: const Text('Pick from Google')),
              body: ImagePickerWebView(
                initialUrl: buildGoogleImagesSearchUrl(widget.word),
                onImageSelected: (url) {
                  Navigator.pop(context, url);
                },
              ),
            ),
      ),
    );

    if (imageUrl != null) {
      widget.onImageSelected(imageUrl);
      if (mounted) Navigator.of(context).pop();
    }
  }

  String buildGoogleImagesSearchUrl(String query) {
    final encodedQuery = Uri.encodeComponent(query);
    return 'https://www.google.com/search?tbm=isch&q=$encodedQuery';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Image to Flashcard'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.word, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Help us generate a meaningful image for your flashcard!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe what this word means to you or how you visualize it.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: 'Image Description',
              hintText: 'E.g., "A red apple on a wooden table"',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _pickFromDevice, child: const Text('FROM DEVICE')),
        TextButton(onPressed: _pickFromGoogle, child: const Text('FROM GOOGLE')),
        ElevatedButton(
          onPressed: _isLoading ? null : _generateImage,
          child:
              _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('GENERATE AI IMAGE'),
        ),
      ],
    );
  }
}
