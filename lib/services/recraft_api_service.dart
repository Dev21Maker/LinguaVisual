import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecraftApiService {
  static const String _baseUrl = 'https://external.api.recraft.ai';
  final Dio _dio;

  RecraftApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 3),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${dotenv.env['RECRAFT_API_KEY']}',
            },
            validateStatus: (status) {
              return status != null && status >= 200 && status < 300;
            },
          ),
        );

  Future<String?> getImageUrl(String prompt) async {
    try {
      final response = await _dio.post(
        '/v1/images/generations',
        data: {'prompt': prompt},
      );

      final imageUrl = response.data?['data']?[0]['url'] as String?;
      if (imageUrl == null) {
        throw Exception('No image URL in response');
      }
      
      return imageUrl;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timed out');
      case DioExceptionType.badResponse:
        final message = error.response?.data?['error']?['message'] ?? 'Server error: ${error.response?.statusCode}';
        return Exception(message);
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
