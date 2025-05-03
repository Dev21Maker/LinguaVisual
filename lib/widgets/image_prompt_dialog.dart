import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unsplash_client/unsplash_client.dart';
import '../services/api_service.dart';
import '../providers/unsplash_provider.dart';

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
  bool _isPickingUnsplash = false;

  @override
  void initState() {
    super.initState();
    _promptController.text = '';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Device image picking is not available yet')));
  }

  Future<void> _pickFromUnsplash() async {
    final unsplashClientAsyncValue = ProviderScope.containerOf(context).read(unsplashClientProvider);

    if (!mounted) return;
    setState(() => _isPickingUnsplash = true);

    try {
      final query = _promptController.text.trim().isNotEmpty ? _promptController.text.trim() : widget.word;

      final photos = await unsplashClientAsyncValue.search.photos(query, page: 1, perPage: 10).goAndGet();

      if (photos.results.isNotEmpty) {
        final photo = photos.results.first;
        final imageUrl = photo.urls.small.toString();
        widget.onImageSelected(imageUrl);
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No images found on Unsplash for "$query"')));
        }
      }
    } on Exception catch (e) {
      print('Unsplash API Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching from Unsplash: $e.')));
      }
    } catch (e) {
      print('Error picking from Unsplash: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An unexpected error occurred.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingUnsplash = false);
      }
    }
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
        TextButton(
          onPressed: _isPickingUnsplash ? null : _pickFromUnsplash,
          child:
              _isPickingUnsplash
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('FROM UNSPLASH'),
        ),
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
