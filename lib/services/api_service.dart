import 'package:dio/dio.dart';
import '../models/word_request.dart';
import '../models/word_response.dart';

class ImageApiService {
  static const String _baseUrl = 'YOUR_BACKEND_API_URL'; // Replace with actual API URL
  final Dio _dio;

  ImageApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 3),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) {
              return status != null && status >= 200 && status < 300;
            },
          ),
        );

  Future<Map<String, dynamic>> translateWord({
    required String word,
    required String fromLanguageCode,
    required String toLanguageCode,
  }) async {
    try {
      final response = await _dio.post('/translate', data: {
        'text': word,
        'from': fromLanguageCode,
        'to': toLanguageCode,
      });
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> getImageForWord(String word) async {
    try {
      final response = await _dio.get('/images/search', queryParameters: {
        'query': word,
        'limit': 1,
      });
      
      return response.data['urls'][0] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<WordResponse> getWorkspaceNewWords({
    required String targetLanguageCode,
    required String nativeLanguageCode,
  }) async {
    try {
      final request = WordRequest(
        targetLanguageCode: targetLanguageCode,
        nativeLanguageCode: nativeLanguageCode,
      );
      
      final response = await _dio.post(
        '/api/v1/words',
        data: request.toJson(),
      );
      
      return WordResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateReviewStatus({
    required int cardId,
    required String rating,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/cards/$cardId/review',
        data: {
          'rating': rating,
          'reviewedAt': DateTime.now().toIso8601String(),
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timed out');
      case DioExceptionType.badResponse:
        return Exception('Server error: ${error.response?.statusCode}');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      default:
        return Exception('Network error occurred');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
