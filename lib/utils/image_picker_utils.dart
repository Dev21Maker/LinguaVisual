import 'package:flutter/material.dart';
import 'package:Languador/screens/image_picker_screen.dart';

/// Utility functions for picking images using the WebView image picker.
class ImagePickerUtils {
  /// Shows the image picker screen and returns the selected image URL.
  /// 
  /// Returns null if the user cancels the selection.
  static Future<String?> pickImage(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const ImagePickerScreen(),
      ),
    );
    
    return result;
  }
}
