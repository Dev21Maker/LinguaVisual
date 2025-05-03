import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/word_request.dart';
import '../models/word_response.dart';

class ImageApiService {
  static const String _baseUrl = 'https://external.api.recraft.ai/v1';
  final Dio _dio;

  ImageApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

  Future<String> getImage(
    String prompt, {
    String style = 'digital_illustration',
    String size = '1024x1024',
  }) async {
    try {
      Response response = await _dio.post(
        "/images/generations",
        data: {
          "prompt": prompt,
          "style": style,
          "model": "recraftv3",
          "size": size,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${dotenv.env['RECRAFT_TOKEN']}',
          },
        ),
      );
      
      print("RD: ${response.data}");
      
      if (response.data != null && 
          response.data['data'] != null && 
          response.data['data'].isNotEmpty &&
          response.data['data'][0]['url'] != null) {
        return response.data['data'][0]['url'];
      } else {
        print('Invalid response format: ${response.data}');
        return '';
      }
    } catch (e) {
      print('Image Generation Error: $e');
      return '';
    }
  }
}
