import 'package:Languador/models/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/pixabay_provider.dart';
import '../services/groq_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ImagePromptDialog extends ConsumerStatefulWidget {
  final String word;
  final String translation;
  final Function(String) onImageSelected;
  final bool barrierDismissible;
  final bool hasConnection;
  final Language targetLanguage;

  const ImagePromptDialog({
    super.key,
    required this.word,
    required this.translation,
    required this.onImageSelected,
    this.barrierDismissible = false,
    this.hasConnection = true,
    required this.targetLanguage,
  });

  @override
  ConsumerState<ImagePromptDialog> createState() => _ImagePromptDialogState();
}

class _ImagePromptDialogState extends ConsumerState<ImagePromptDialog> {
  final _promptController = TextEditingController();
  final _searchController = TextEditingController();
  final _suggestedQueryController = TextEditingController();
  final _imageApiService = ImageApiService();
  final _groqService = GroqService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isPickingPixabay = false;
  List<PixabayImage>? _pixabayImages;
  bool _isLoadingPhotos = true;
  bool _isLoadingMorePhotos = false;
  bool _isGeneratingSuggestion = false;
  String? _error;
  String? _selectedPixabayUrl;
  bool _isGeneratingMode = false;
  String? _generatedImageUrl;
  String? _pickedImagePath;
  List<String> _improvedQueries = [];
  int _currentQueryIndex = 0;
  bool _allQueriesExhausted = false;

  @override
  void initState() {
    super.initState();
    _promptController.text = widget.word;
    _loadPixabayImages();

    // Add scroll listener to detect when user reaches the bottom
    _scrollController.addListener(_scrollListener);
  }
  
  void _scrollListener() {
    // If we've reached the bottom and not already loading more photos
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMorePhotos &&
        !_allQueriesExhausted) {
      _loadNextQuery();
    }
  }
  
  void _loadNextQuery() {
    if (_currentQueryIndex < _improvedQueries.length - 1) {
      setState(() {
        _isLoadingMorePhotos = true;
        _currentQueryIndex++;
      });
      _loadPixabayImages();
    } else {
      setState(() {
        _allQueriesExhausted = true;
      });
    }
  }
  
  /// Handles custom search queries entered by the user
  void _handleCustomSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Generate a suggestion for the query
    _generateQuerySuggestion(query);
  }
  
  /// Generates a query suggestion using Groq API
  Future<void> _generateQuerySuggestion(String userQuery) async {
    if (userQuery.trim().isEmpty) return;
    
    setState(() {
      _isGeneratingSuggestion = true;
    });
    
    try {
      // Get a single improved query from Groq
      final List<String> suggestions = await _groqService.improveQuery(userQuery, widget.targetLanguage.name);
      
      if (mounted && suggestions.isNotEmpty) {
        final suggestion = suggestions.first;
        
        // Update the suggested query controller
        _suggestedQueryController.text = suggestion;
        
        // Process the suggested query
        _processImprovedQuery(suggestion);
      } else {
        // If no suggestions, use the original query
        _processImprovedQuery(userQuery);
      }
    } catch (e) {
      print('Error generating suggestion: $e');
      // Fall back to the original query
      _processImprovedQuery(userQuery);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSuggestion = false;
        });
      }
    }
  }
  
  /// Process the improved query
  void _processImprovedQuery(String query) {
    if (query.trim().isEmpty) return;
    
    // Add the query to the list if not already present
    if (!_improvedQueries.contains(query)) {
      setState(() {
        // Reset existing state
        _pixabayImages = null;
        _isLoadingPhotos = true;
        _isLoadingMorePhotos = false;
        _allQueriesExhausted = false;
        
        // Add the new query and set as current
        _improvedQueries.add(query);
        _currentQueryIndex = _improvedQueries.length - 1;
      });
      
      // Load images with the new query
      _loadPixabayWithQuery(query);
    } else {
      // If query already exists in our list, just switch to it
      final index = _improvedQueries.indexOf(query);
      setState(() {
        _currentQueryIndex = index;
        _isLoadingPhotos = true;
      });
      _loadPixabayImages();
    }
  }
  
  /// Load Pixabay images with a specific query
  Future<void> _loadPixabayWithQuery(String query) async {
    setState(() {
      _isLoadingPhotos = true;
      _error = null;
    });
    
    try {
      final images = await _pickFromPixabay(query);
      
      if (mounted) {
        setState(() {
          _pixabayImages = images;
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

  Future<void> _loadPixabayImages() async {
    // Initial load - show the loading indicator for the entire section
    if (!_isLoadingMorePhotos) {
      setState(() {
        _isLoadingPhotos = true;
        _error = null;
        _isPickingPixabay = true;
      });
    }
    
    try {
      // First, improve the query using Groq
      if (_improvedQueries.isEmpty) {
        _improvedQueries = await _groqService.improveQuery(widget.translation, widget.targetLanguage.name);
        _currentQueryIndex = 0;
        
        // Always add the original query as a fallback option
        if (!_improvedQueries.contains(widget.translation)) {
          _improvedQueries.add(widget.translation);
        }
      }
      
      // Try to get images with the current improved query
      if (_improvedQueries.isNotEmpty) {
        final images = await _pickFromPixabay(_improvedQueries[_currentQueryIndex]);
        
        if (mounted) {
          setState(() {
            // If loading more photos, add to existing list
            if (_isLoadingMorePhotos) {
              if (_pixabayImages != null) {
                if (images != null && images.isNotEmpty) {
                  _pixabayImages = [..._pixabayImages!, ...images];
                }
              } else {
                _pixabayImages = images;
              }
              _isLoadingMorePhotos = false;
            } else {
              // Initial load, replace the list
              _pixabayImages = images;
            }
            
            _isLoadingPhotos = false;
          });
          
          // If no images found and we have more queries to try
          if ((images == null || images.isEmpty) && _currentQueryIndex < _improvedQueries.length - 1) {
            _currentQueryIndex++;
            _loadPixabayImages(); // Try the next query
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingPhotos = false;
          _isLoadingMorePhotos = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _searchController.dispose();
    _suggestedQueryController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    setState(() => _isLoading = true);

    final imageUrl = await _imageApiService.getImage(_getFlashcardPrompt(_promptController.text));

    if (_isGeneratingMode) {
      setState(() {
        _isLoading = false;
        _generatedImageUrl = imageUrl.isNotEmpty ? imageUrl : null;
      });
    } else {
      setState(() => _isLoading = false);

      if (imageUrl.isNotEmpty) {
        widget.onImageSelected(imageUrl);
      }
    }
  }

  Future<void> _pickFromDevice() async {
    if (!mounted) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = p.basename(pickedFile.path);
        final String savePath = p.join(appDir.path, fileName);

        final File imageFile = File(pickedFile.path);
        await imageFile.copy(savePath);

        if (!mounted) return;
        setState(() {
          _pickedImagePath = savePath;
          _selectedPixabayUrl = null;
          _generatedImageUrl = null;
          _isGeneratingMode = false;
        });
        widget.onImageSelected(savePath);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selection cancelled.')),
        );
      }
    } catch (e) {
      print("Error picking/saving image: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<List<PixabayImage>?> _pickFromPixabay(String query) async {
    if (!mounted) return null;

    try {
      final service = ref.read(pixabayServiceProvider);
      return await service.searchImages(query, languageCode: widget.targetLanguage.code);
    } catch (e) {
      print('Pixabay API Error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    bool canSelectImage = _selectedPixabayUrl != null || _generatedImageUrl != null || _pickedImagePath != null;
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: const Text('Add Image to Flashcard'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
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

              Visibility(
                visible: _isGeneratingMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        hintText: 'Describe what do you want the image to be',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _generatedImageUrl != null
                          ? ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 300),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _generatedImageUrl!,
                                  height: 200,
                                  fit: BoxFit.fitHeight,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          : _isLoading
                              ? Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: CircularProgressIndicator()),
                                )
                              : Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('No image generated yet', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                    const SizedBox(height: 16),
                    // Buttons for Generate/Regenerate/Use Generated Image
                    if (_isGeneratingMode)
                      Center(
                        child: _generatedImageUrl == null
                            // --- Generate Button --- 
                            ? SizedBox()
                            // --- Regenerate and Use Buttons --- 
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Regenerate Button
                                  TextButton(
                                    onPressed: null,//(!widget.hasConnection || _isLoading) ? null : _generateImage, // Call _generateImage
                                    child: _isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('REGENERATE'),
                                  ),
                                  // Use This Image button is now handled by the main action button
                                ],
                              ),
                      ),
                    const SizedBox(height: 16), // Added padding after generate buttons
                  ],
                ),
              ),

              Visibility(
                visible: !_isGeneratingMode,
                child: _buildPixabayImagesSection(),
              ),

              if (_pickedImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selected from Device:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Center(
                        child: Image.file(
                          File(_pickedImagePath!),
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _isGeneratingMode = !_isGeneratingMode;
            });
          },
          child: Text(_isGeneratingMode ? 'BROWSE IMAGES' : 'ENTER PROMPT'),
        ),

        // Device button
        TextButton(onPressed: _pickFromDevice, child: const Text('FROM DEVICE')),

        // Use selected button (only in Pixabay mode)
        if (_isPickingPixabay && !_isLoading) Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: canSelectImage ? () {
                _selectedPixabayUrl != null
                    ? widget.onImageSelected(_selectedPixabayUrl!)
                    : null;

                } : null,
                child: const Text('USE SELECTED IMAGE'),
              ),
            ],
          ),
        ),

        // Generate/Use Generated button (only in generation mode)
        Visibility(
          visible: _isGeneratingMode,
          child: _generatedImageUrl == null
              // --- Generate Button --- 
              ? Tooltip(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                triggerMode: TooltipTriggerMode.tap,
                message: 'Soon be added',
                child: ElevatedButton(
                    onPressed: null,//(!widget.hasConnection || _isLoading) ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey,
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('GENERATE AI IMAGE'),
                  ),
              )
              // --- Regenerate and Use Buttons --- 
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Regenerate Button
                    TextButton(
                      onPressed: (!widget.hasConnection || _isLoading) ? null : _generateImage,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('REGENERATE'),
                    ),
                    const SizedBox(width: 8),
                    // Use This Image Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : () { // Disable while regenerating
                        widget.onImageSelected(_generatedImageUrl!); 
                      },
                      child: const Text('USE THIS IMAGE'),
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  String _getFlashcardPrompt(String text) {
    if (text.trim() == widget.translation.trim()) {
      return """An educational, child-friendly illustration depicting the concept of without showing the word itself. 
      The image should convey the meaning ${widget.word} through context, actions, or associated objects,
      using a simple and colorful style suitable for young learners. The background should be minimalistic to keep the focus on the main concept.
      The illustration should be vector-based, with clean lines and vibrant colors, making it ideal for educational flashcards""";
    } else if(text.isEmpty) {
      return widget.word;
    }
    return text;
  }

  Widget _buildPixabayImagesSection() {
    if (_isLoadingPhotos && _pixabayImages == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_pixabayImages == null || _pixabayImages!.isEmpty) {
      return const Center(child: Text('No images found'));
    }

    // Show the current query being used
    final currentQuery = _improvedQueries.isNotEmpty ? _improvedQueries[_currentQueryIndex] : '';

    return Column(
      children: [
        // Custom search input field with suggestion
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter search term',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        // Show a loading indicator in the suffix when generating a suggestion
                        suffixIcon: _isGeneratingSuggestion 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      ),
                      onSubmitted: (value) => _handleCustomSearch(value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _handleCustomSearch(_searchController.text),
                  ),
                ],
              ),
              // Show the suggested query if available
              if (_suggestedQueryController.text.isNotEmpty && _suggestedQueryController.text != _searchController.text)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                  child: Row(
                    children: [
                      const Text('Suggested: ', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      InkWell(
                        onTap: () {
                          // Update the search controller with the suggested query
                          setState(() {
                            _searchController.text = _suggestedQueryController.text;
                          });
                          // Focus the search field
                          FocusScope.of(context).requestFocus(FocusNode());
                        },
                        child: Text(
                          _suggestedQueryController.text, 
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            fontStyle: FontStyle.italic,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (currentQuery.isNotEmpty) Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text('Search: "$currentQuery"', style: const TextStyle(fontStyle: FontStyle.italic)),
        ),
        SizedBox(
          height: 300,
          width: 260,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                MasonryGridView.count(
                  crossAxisCount: 2,
                  itemCount: _pixabayImages!.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    double ht = index % 2 == 0 ? 200 : 100;
                    final photo = _pixabayImages![index];
                    final imageUrl = photo.webformatURL;
                    final isSelected = imageUrl == _selectedPixabayUrl;

                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedPixabayUrl == imageUrl) {
                              _selectedPixabayUrl = null;
                              _pickedImagePath = null;
                              _generatedImageUrl = null;
                              _isGeneratingMode = false;
                            } else {
                              _selectedPixabayUrl = imageUrl;
                              _pickedImagePath = null;
                              _generatedImageUrl = null;
                              _isGeneratingMode = false;
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(imageUrl, fit: BoxFit.cover, height: ht),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Show loading indicator if loading more images
                if (_isLoadingMorePhotos) 
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                // Show a message when all queries have been exhausted
                if (_allQueriesExhausted && !_isLoadingMorePhotos)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('すべてのクエリが試されました。'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
