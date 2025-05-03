import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A service class for handling API calls to AI language models.
class AiApiService {
  /// Base URL for the OpenAI API endpoint
  static const String _openAiBaseUrl = 'https://api.openai.com/v1';
  
  /// Base URL for the Groq API endpoint
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';
  
  final Dio _openAiDio;
  final Dio _groqDio;

  /// Constructor that initializes the Dio HTTP clients with base configurations
  AiApiService()
      : _openAiDio = Dio(
          BaseOptions(
            baseUrl: _openAiBaseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ),
        _groqDio = Dio(
          BaseOptions(
            baseUrl: _groqBaseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  /// Gets the OpenAI API key from environment variables
  /// 
  /// Returns the API key as a String or throws an exception if not found
  String _getOpenAiApiKey() {
    final apiKey = dotenv.env['AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('AI_API_KEY not found in environment variables. '
          'Please add it to your .env file or provide it through --dart-define.');
    }
    return apiKey;
  }
  
  /// Gets the Groq API key from environment variables
  /// 
  /// Returns the API key as a String or throws an exception if not found
  String _getGroqApiKey() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not found in environment variables. '
          'Please add it to your .env file or provide it through --dart-define.');
    }
    return apiKey;
  }

  /// Sends a prompt to the OpenAI model and returns the generated response
  /// 
  /// [prompt] - The user's input text to send to the AI
  /// [model] - Optional parameter to specify which AI model to use (defaults to "gpt-3.5-turbo")
  /// 
  /// Returns a Future containing the AI's text response
  /// Throws exceptions for network errors, API errors, or invalid responses
  Future<String> generateResponse(
    String prompt, {
    String model = "gpt-3.5-turbo",
  }) async {
    try {
      // Prepare the request body according to the OpenAI API format
      final requestData = {
        "model": model,
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
      };

      // Make the API call with proper authorization header
      final response = await _openAiDio.post(
        "/chat/completions",
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_getOpenAiApiKey()}',
          },
        ),
      );
      
      // Log response for debugging (consider removing in production)
      print("OpenAI API Response Status: ${response.statusCode}");
      
      // Extract and validate the response
      if (response.statusCode == 200 && 
          response.data != null && 
          response.data['choices'] != null && 
          response.data['choices'].isNotEmpty &&
          response.data['choices'][0]['message'] != null &&
          response.data['choices'][0]['message']['content'] != null) {
        
        return response.data['choices'][0]['message']['content'];
      } else {
        throw FormatException('Invalid response format: ${response.data}');
      }
    } on DioException catch (e) {
      // Handle Dio-specific exceptions
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      } else if (e.response != null) {
        // Handle API errors with status codes
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 401) {
          throw Exception('Authentication error: Invalid API key');
        } else if (statusCode == 429) {
          throw Exception('Rate limit exceeded: Too many requests');
        } else {
          throw Exception('API error (${statusCode}): ${responseData?['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      // Handle all other exceptions
      throw Exception('Error generating AI response: $e');
    }
  }
  
  /// Sends a prompt to the Groq API and returns the generated response
  /// Groq offers faster inference times and some free tier usage
  /// 
  /// [prompt] - The user's input text to send to the AI
  /// [model] - Optional parameter to specify which Groq model to use (defaults to "llama3-8b-8192")
  /// 
  /// Returns a Future containing the AI's text response
  /// Throws exceptions for network errors, API errors, or invalid responses
  Future<String> generateResponseFree(
    String prompt, {
    String model = "llama3-8b-8192",
  }) async {
    try {
      // Prepare the request body according to the Groq API format
      // Groq uses the OpenAI-compatible API format
      final requestData = {
        "model": model,
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": 1024,
      };

      // Make the API call with proper authorization header
      final response = await _groqDio.post(
        "/chat/completions",
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_getGroqApiKey()}',
          },
        ),
      );
      
      // Log response for debugging (consider removing in production)
      print("Groq API Response Status: ${response.statusCode}");
      
      // Extract and validate the response
      if (response.statusCode == 200 && 
          response.data != null && 
          response.data['choices'] != null && 
          response.data['choices'].isNotEmpty &&
          response.data['choices'][0]['message'] != null &&
          response.data['choices'][0]['message']['content'] != null) {
        
        return response.data['choices'][0]['message']['content'];
      } else {
        throw FormatException('Invalid response format: ${response.data}');
      }
    } on DioException catch (e) {
      // Handle Dio-specific exceptions
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      } else if (e.response != null) {
        // Handle API errors with status codes
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 401) {
          throw Exception('Authentication error: Invalid Groq API key');
        } else if (statusCode == 429) {
          throw Exception('Rate limit exceeded: Too many requests to Groq API');
        } else {
          throw Exception('Groq API error (${statusCode}): ${responseData?['error']?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Network error with Groq API: ${e.message}');
      }
    } catch (e) {
      // Handle all other exceptions
      throw Exception('Error generating Groq AI response: $e');
    }
  }
}
