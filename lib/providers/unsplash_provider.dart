import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unsplash_client/unsplash_client.dart';

// Singleton class to manage the UnsplashClient instance
class UnsplashService {
  // Private constructor
  UnsplashService._();

  // Static instance variable
  static final UnsplashService _instance = UnsplashService._();

  // Static getter for the instance
  static UnsplashService get instance => _instance;

  late UnsplashClient? _client;

  // Asynchronously initialize the client
  UnsplashClient? initialize() {
    // If already initializing or initialized, return the future/client
    if (_client != null) {
      return _client!;
    }

    try {
      // Load .env - Consider doing this once in main.dart

      final apiKey = dotenv.env['UNSPLASH_API_KEY'];
      final secretKey = dotenv.env['UNSPLASH_API_SECRET'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('UNSPLASH_API_KEY is not set in the .env file.');
      }
      // Note: Secret key is often not needed for read-only operations like search
      // If it's required for your use case, ensure it's set.
      if (secretKey == null || secretKey.isEmpty) {
        print('Warning: UNSPLASH_API_SECRET is not set in the .env file.');
        // Depending on API usage, this might be okay or might cause errors later.
      }

      // Initialize client using AppCredentials
      _client = UnsplashClient(
        settings: ClientSettings(
          credentials: AppCredentials(
            accessKey: apiKey,
            // Use secretKey, default to empty string if null/empty but provide warning
            secretKey: secretKey,
          ),
        ),
      );
      return _client!;
    } catch (e) {
      print('Error initializing UnsplashService: $e'); // Re-throw the exception so the FutureProvider can handle it
    }
  }

  // Get the initialized client (throws if not initialized)
  UnsplashClient getClient() {
    if (_client == null) {
      throw StateError('UnsplashService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Close the client
  void close() {
    _client?.close();
    _client = null; // Allow re-initialization if needed
    print('UnsplashService closed.');
  }
}

// FutureProvider that uses the Singleton's initialize method
final unsplashClientProvider = Provider<UnsplashClient>((ref) {
  final client = UnsplashService.instance.initialize();

  ref.onDispose(() {
    UnsplashService.instance.close();
  });

  return client!;
});
