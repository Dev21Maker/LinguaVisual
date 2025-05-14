import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model class for Pixabay images
class PixabayImage {
  final int id;
  final String pageURL;
  final String type;
  final String tags;
  final String previewURL;
  final int previewWidth;
  final int previewHeight;
  final String webformatURL;
  final int webformatWidth;
  final int webformatHeight;
  final String largeImageURL;
  final int imageWidth;
  final int imageHeight;
  final int imageSize;
  final int views;
  final int downloads;
  final int collections;
  final int likes;
  final int comments;
  final int userId;
  final String user;
  final String userImageURL;

  PixabayImage({
    required this.id,
    required this.pageURL,
    required this.type,
    required this.tags,
    required this.previewURL,
    required this.previewWidth,
    required this.previewHeight,
    required this.webformatURL,
    required this.webformatWidth,
    required this.webformatHeight,
    required this.largeImageURL,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageSize,
    required this.views,
    required this.downloads,
    required this.collections,
    required this.likes,
    required this.comments,
    required this.userId,
    required this.user,
    required this.userImageURL,
  });

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    return PixabayImage(
      id: json['id'],
      pageURL: json['pageURL'],
      type: json['type'],
      tags: json['tags'],
      previewURL: json['previewURL'],
      previewWidth: json['previewWidth'],
      previewHeight: json['previewHeight'],
      webformatURL: json['webformatURL'],
      webformatWidth: json['webformatWidth'],
      webformatHeight: json['webformatHeight'],
      largeImageURL: json['largeImageURL'],
      imageWidth: json['imageWidth'],
      imageHeight: json['imageHeight'],
      imageSize: json['imageSize'],
      views: json['views'],
      downloads: json['downloads'],
      collections: json['collections'],
      likes: json['likes'],
      comments: json['comments'],
      userId: json['user_id'],
      user: json['user'],
      userImageURL: json['userImageURL'],
    );
  }
}

// Singleton class to manage the Pixabay API
class PixabayService {
  // Private constructor
  PixabayService._();

  // Static instance variable
  static final PixabayService _instance = PixabayService._();

  // Static getter for the instance
  static PixabayService get instance => _instance;

  String? _apiKey;
  final String _baseUrl = 'https://pixabay.com/api/';

  // Initialize the service
  void initialize() {
    _apiKey = dotenv.env['PIXABAY_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('Warning: PIXABAY_API_KEY is not set in the .env file.');
    }
  }

  // Search for images using the Pixabay API
  Future<List<PixabayImage>> searchImages(String query, {int perPage = 30, String languageCode = 'en'}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('PIXABAY_API_KEY is not set. Call initialize() first.');
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl?key=$_apiKey&q=$encodedQuery&lang=$languageCode&per_page=$perPage';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('hits')) {
          final List<dynamic> hits = data['hits'];
          return hits.map((hit) => PixabayImage.fromJson(hit)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to search images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching Pixabay images: $e');
      throw Exception('Failed to search images: $e');
    }
  }
}

// Provider for the Pixabay service
final pixabayServiceProvider = Provider<PixabayService>((ref) {
  final service = PixabayService.instance;
  service.initialize();
  
  return service;
});
