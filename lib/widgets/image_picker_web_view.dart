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

  const ImagePickerWebView({
    super.key,
    this.initialUrl = 'https://www.google.com/imghp',
    this.onImageSelected,
  });

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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Inject JavaScript to detect image clicks
            _injectImageSelectionScript();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  /// Injects JavaScript to detect when an image is clicked in Google Images
  void _injectImageSelectionScript() {
    // Add a JavaScript channel to receive messages from the WebView
    _controller.addJavaScriptChannel(
      'ImageSelected',
      onMessageReceived: (JavaScriptMessage message) {
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(message.message);
        }
      },
    );

    _controller.runJavaScript('''
      document.addEventListener('click', function(e) {
        if (e.target.tagName === 'IMG') {
          // Send the image URL to Flutter
          ImageSelected.postMessage(e.target.src);
        }
      }, true);
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
