# LinguaVisual

A Flutter application for language learning with flashcards.

## Features

- Flashcard-based learning
- Spaced repetition system (SRS)
- Image support for flashcards
- Online and offline modes

## ImagePickerWebView Component

The app includes a shared `ImagePickerWebView` component that allows users to select images from Google Images for their flashcards.

### How to Use ImagePickerWebView

1. **Add the dependency**

   The component requires the `webview_flutter` package. Make sure it's added to your `pubspec.yaml`:

   ```yaml
   dependencies:
     webview_flutter: ^4.7.0
   ```

2. **Using the ImagePickerUtils**

   The simplest way to use the image picker is through the `ImagePickerUtils` class:

   ```dart
   import 'package:lingua_visual/utils/image_picker_utils.dart';

   // Inside your widget:
   Future<void> pickImage() async {
     final imageUrl = await ImagePickerUtils.pickImage(context);
     if (imageUrl != null) {
       // Use the selected image URL
       print('Selected image URL: $imageUrl');
     }
   }
   ```

3. **Direct usage of ImagePickerWebView**

   You can also use the `ImagePickerWebView` widget directly in your UI:

   ```dart
   import 'package:lingua_visual/widgets/image_picker_web_view.dart';

   // Inside your build method:
   ImagePickerWebView(
     onImageSelected: (imageUrl) {
       print('Selected image URL: $imageUrl');
     },
   )
   ```

4. **Running the example**

   To see the image picker in action, run the example app:

   ```bash
   flutter run -t lib/main_example.dart
   ```

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app
