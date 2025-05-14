import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class GroqService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'llama3-70b-8192';

  GroqService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );
        
  // Generate a sentence for a flashcard word that's grammatically correct
  Future<String> generateSentence(String word, String targetLanguageCode) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('GROQ_API_KEY is not set in the .env file.');
        return "Fill in the blank: ____"; // Default fallback
      }

      // Construct prompt for sentence generation
      final String prompt = '''
      Create a single, simple example sentence in $targetLanguageCode using the word "$word".
      The sentence should be grammatically correct and illustrate the word's usage naturally.
      Make the sentence easy to understand for language learners.
      Return only the sentence, nothing else.
      ''';

      Response response = await _dio.post(
        "/chat/completions",
        data: {
          "model": _model,
          "messages": [
            {"role": "system", "content": "You are a helpful language tutor that creates example sentences."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
          "max_tokens": 100,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && 
          response.data != null && 
          response.data['choices'] != null && 
          response.data['choices'].isNotEmpty &&
          response.data['choices'][0]['message'] != null &&
          response.data['choices'][0]['message']['content'] != null) {
        
        final String content = response.data['choices'][0]['message']['content'].trim();
        return content;
      } else {
        print('Invalid response format: ${response.data}');
        return "Example: $word"; // Simple fallback
      }
    } catch (e) {
      print('Sentence Generation Error: $e');
      return "Example: $word"; // Simple fallback on error
    }
  }

  // Improve user query using Groq LLM API
  Future<List<String>> improveQuery(String userInput, String targetLanguage) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('GROQ_API_KEY is not set in the .env file.');
        return [userInput]; // Fallback to original input
      }

      // Construct prompt for query improvement
      final String prompt = '''
You are a helpful assistant that converts vague or emotional $targetLanguage search terms into specific, image-relevant $targetLanguage search terms.
Convert the following input into 3-5 specific $targetLanguage search terms that would yield good image results on Pixabay.
Format your response as a JSON array of strings, with only $targetLanguage characters.
For example, if input is "なれ", you might respond with: ["練習", "習慣", "初心者"]

Input: "$userInput"
''';

      Response response = await _dio.post(
        "/chat/completions",
        data: {
          "model": _model,
          "messages": [
            {"role": "system", "content": "You are a helpful assistant that returns specific $targetLanguage search terms in JSON format."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.5,
          "max_tokens": 150,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && 
          response.data != null && 
          response.data['choices'] != null && 
          response.data['choices'].isNotEmpty &&
          response.data['choices'][0]['message'] != null &&
          response.data['choices'][0]['message']['content'] != null) {
        
        final String content = response.data['choices'][0]['message']['content'];
        
        // Extract JSON array from content (may be wrapped in markdown code blocks)
        final RegExp jsonRegex = RegExp(r'\[.*?\]', dotAll: true);
        final match = jsonRegex.firstMatch(content);
        
        if (match != null) {
          final jsonString = match.group(0);
          try {
            final List<dynamic> terms = jsonDecode(jsonString!);
            return terms.map((term) => term.toString()).toList();
          } catch (e) {
            print('Error parsing JSON response: $e');
            return [userInput]; // Fallback to original input on parse error
          }
        } else {
          print('No JSON array found in response: $content');
          return [userInput]; // Fallback to original input if no JSON found
        }
      } else {
        print('Invalid response format: ${response.data}');
        return [userInput]; // Fallback to original input on invalid response
      }
    } catch (e) {
      print('Query Improvement Error: $e');
      return [userInput]; // Fallback to original input on error
    }
  }
}
