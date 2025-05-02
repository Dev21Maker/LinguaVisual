import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A widget that displays a WebView for picking images from Google Images.
///
/// This component loads Google Images search page and allows users to select
/// images for their flashcards.
class ImagePickerWebView extends StatefulWidget {
  /// The URL to load in the WebView. Defaults to Google Images.
  final String initialUrl;

  /// Callback that is called when an image URL is selected.
  final Function(String)? onImageSelected;

  const ImagePickerWebView({super.key, required this.initialUrl, this.onImageSelected});

  @override
  State<ImagePickerWebView> createState() => _ImagePickerWebViewState();
}

class _ImagePickerWebViewState extends State<ImagePickerWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize the WebViewController
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                _injectImageSelectionScript();
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.initialUrl));
  }

  /// Injects JavaScript to detect when an image is clicked in Google Images
  void _injectImageSelectionScript() {
    _controller.runJavaScript('''
      function handleImageClick(event) {
        const img = event.target;
        if (img.tagName === 'IMG') {
          // Try to get the highest quality image URL
          let imageUrl = img.getAttribute('data-src') || // Check for data-src first
                        img.src || // Then regular src
                        img.getAttribute('srcset')?.split(',')[0]?.trim()?.split(' ')[0]; // Finally check srcset
          
          if (imageUrl) {
            // If the URL is relative, make it absolute
            if (imageUrl.startsWith('/')) {
              imageUrl = window.location.origin + imageUrl;
            }
            
            // For Google Images, try to get the actual image URL
            if (img.closest('a')) {
              const link = img.closest('a').href;
              const urlParams = new URLSearchParams(link);
              const actualImage = urlParams.get('imgurl');
              if (actualImage) {
                imageUrl = actualImage;
              }
            }
            
            window.flutter_inappwebview.callHandler('onImageClicked', imageUrl);
          }
        }
      }

      // Remove any existing click listeners
      document.removeEventListener('click', handleImageClick, true);
      
      // Add the click listener
      document.addEventListener('click', handleImageClick, true);
    ''');

    // Add JavaScript channel to receive messages
    _controller.addJavaScriptChannel(
      'ImageSelected',
      onMessageReceived: (JavaScriptMessage message) {
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(message.message);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
