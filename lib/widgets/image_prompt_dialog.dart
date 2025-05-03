import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unsplash_client/unsplash_client.dart';
import '../services/api_service.dart';
import '../providers/unsplash_provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImagePromptDialog extends ConsumerStatefulWidget {
  final String word;
  final Function(String) onImageSelected;
  final bool barrierDismissible;
  final bool hasConnection;

  const ImagePromptDialog({
    super.key,
    required this.word,
    required this.onImageSelected,
    this.barrierDismissible = false,
    this.hasConnection = true,
  });

  @override
  ConsumerState<ImagePromptDialog> createState() => _ImagePromptDialogState();
}

class _ImagePromptDialogState extends ConsumerState<ImagePromptDialog> {
  final _promptController = TextEditingController();
  final _imageApiService = ImageApiService();
  bool _isLoading = false;
  bool _isPickingUnsplash = false;
  List<Photo>? _unsplashPhotos;
  bool _isLoadingPhotos = true;
  String? _error;
  String? _selectedUnsplashUrl;

  @override
  void initState() {
    super.initState();
    _promptController.text = '';
    _loadUnsplashPhotos();
  }

  Future<void> _loadUnsplashPhotos() async {
    try {
      final photos = await _pickFromUnsplash();
      if (mounted) {
        setState(() {
          _unsplashPhotos = photos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingPhotos = false;
        });
      }
    }
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

  Future<List<Photo>?> _pickFromUnsplash() async {
    if (!mounted) return null;
    
    try {
      final query = _promptController.text.isEmpty? widget.word : _promptController.text;

      final client = ref.read(unsplashClientProvider);

      final data = await client!.search.photos(query, page: 1, perPage: 10).goAndGet();
      
      final photos = data.results;

      return photos;
    } on Exception catch (e) {
      print('Unsplash API Error: $e');
      throw e;
    } catch (e) {
      print('Error picking from Unsplash: $e');
      throw e;
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
          _buildUnsplashImagesSection(),
        ],
      ),
      actions: [
        TextButton(onPressed: _pickFromDevice, child: const Text('FROM DEVICE')),
        TextButton(
          onPressed: _selectedUnsplashUrl != null
              ? () {
                  widget.onImageSelected(_selectedUnsplashUrl!);
                  // Navigator.of(context).pop(_selectedUnsplashUrl);
                }
              : null,
          child: const Text('USE SELECTED'),
        ),
        ElevatedButton(
          onPressed: (!widget.hasConnection || _isLoading) ? null : _generateImage,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey,
            disabledForegroundColor: Colors.white70,
          ),
          child:
              _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('GENERATE AI IMAGE'),
        ),
      ],
    );
  }
  
  Widget _buildUnsplashImagesSection() {
    if (_isLoadingPhotos) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    
    if (_unsplashPhotos == null || _unsplashPhotos!.isEmpty) {
      return const Center(child: Text('No images available'));
    }
    
    return SizedBox(
      height: 300, 
      width: 260,
      child: SingleChildScrollView(
        child: MasonryGridView.count(
          crossAxisCount: 2,
          itemCount: _unsplashPhotos!.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            double ht = index % 2 == 0 ? 200 : 100;
            final photo = _unsplashPhotos![index];
            final imageUrl = photo.urls.small.toString();
            final isSelected = imageUrl == _selectedUnsplashUrl;

            return Padding(
              padding: const EdgeInsets.all(4), 
              child: GestureDetector( 
                onTap: () {
                  setState(() {
                    if(_selectedUnsplashUrl == imageUrl) {
                      _selectedUnsplashUrl = null;
                    } else {
                      _selectedUnsplashUrl = imageUrl;
                    }
                  });
                },
                child: Container( 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14), 
                  ),
                  child: Stack(
                    children: [
                      // InstaImageViewer(
                        // child: 
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12), 
                          child: Image.network(imageUrl, fit: BoxFit.cover, height: ht), 
                        ),
                      // ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      )
    );
  }
}
