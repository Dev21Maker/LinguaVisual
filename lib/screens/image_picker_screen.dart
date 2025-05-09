import 'package:flutter/material.dart';
import 'package:Languador/widgets/image_picker_web_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A screen that demonstrates the ImagePickerWebView component.
class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  String? _selectedImageUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.imagePickerAppBarTitle),
        actions: [
          if (_selectedImageUrl != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // Return the selected image URL to the previous screen
                Navigator.of(context).pop(_selectedImageUrl);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview of the selected image
          if (_selectedImageUrl != null)
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.black12,
              child: Image.network(_selectedImageUrl!, fit: BoxFit.contain),
            ),

          // WebView for picking images
          Expanded(
            child: ImagePickerWebView(
              onImageSelected: (imageUrl) {
                setState(() {
                  _selectedImageUrl = imageUrl;
                });

                // Show a snackbar to indicate that an image was selected
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.imagePickerSelectedSnackbar),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: l10n.imagePickerUseButton,
                      onPressed: () {
                        Navigator.of(context).pop(_selectedImageUrl);
                      },
                    ),
                  ),
                );
              },
              initialUrl: 'https://www.google.com/search?tbm=isch',
            ),
          ),
        ],
      ),
    );
  }
}
