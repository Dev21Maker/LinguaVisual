
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService() : _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Auth state
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => _client.auth.currentUser != null;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> refreshSession() async {
    await _client.auth.refreshSession();
  }

  // User metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    return await _client.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }

  // Database operations
  Future<List<Map<String, dynamic>>> getFlashcards() async {
    try {
      final response = await _client
          .from('flashcards')
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching flashcards: $e');
      return [];
    }
  }

  Future<void> insertFlashcard(Map<String, dynamic> flashcard) async {
    await _client.from('flashcards').insert(flashcard);
  }

  Future<void> updateFlashcard(String id, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('flashcards')
          .update(updates)
          .eq('id', id)
          .eq('user_id', currentUser!.id);
    } catch(e) {
      print('Error updating flashcard: $e');
    }
  }

  Future<void> deleteFlashcard(String id) async {
    try {
    await _client
        .from('flashcards')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id);
    } catch(e) {
      print('Error deleting flashcard: $e');
    }
  }

  Future<List<Flashcard>> fetchDueCards() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    
    final response = await _client
        .from('cards')
        .select()
        .eq('user_id', userId)
        .lte('srs_next_review_date', now)
        .order('srs_next_review_date', ascending: true);

    return (response as List)
        .map((card) => Flashcard.fromMap({
              'id': card['id'],
              'word': card['word'],
              'targetLanguageCode': card['target_language_code'],
              'translation': card['translation'],
              'nativeLanguageCode': card['native_language_code'],
              'imageUrl': card['image_url'],
              'cachedImagePath': card['cached_image_path'],
              'srsInterval': card['srs_interval'].toDouble(),
              'srsEaseFactor': card['srs_ease_factor'].toDouble(),
              'srsNextReviewDate': card['srs_next_review_date'],
              'srsLastReviewDate': card['srs_last_review_date'],
            }))
        .toList();
  }

  Future<void> insertCard(Flashcard card) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final cardData = {
      'user_id': userId,
      'word': card.word,
      'target_language_code': card.targetLanguageCode,
      'translation': card.translation,
      'native_language_code': card.nativeLanguageCode,
      'image_url': card.imageUrl,
      'cached_image_path': card.cachedImagePath,
      'srs_interval': card.srsInterval,
      'srs_ease_factor': card.srsEaseFactor,
      'srs_next_review_date': card.srsNextReviewDate,
      'srs_last_review_date': card.srsLastReviewDate,
    };

    try {
      await _client
          .from('cards')
          .insert(cardData);
    } catch (e) {
      throw Exception('Failed to insert card: $e');
    }
  }

  Future<void> updateCard(Flashcard card) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    if (card.id == null) {
      throw Exception('Card ID is required for update');
    }

    final cardData = {
      'word': card.word,
      'target_language_code': card.targetLanguageCode,
      'translation': card.translation,
      'native_language_code': card.nativeLanguageCode,
      'image_url': card.imageUrl,
      'cached_image_path': card.cachedImagePath,
      'srs_interval': card.srsInterval,
      'srs_ease_factor': card.srsEaseFactor,
      'srs_next_review_date': card.srsNextReviewDate,
      'srs_last_review_date': card.srsLastReviewDate,
    };

    try {
      await _client
          .from('cards')
          .update(cardData)
          .eq('id', card.id!)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  Future<Map<String, dynamic>> fetchNewWordViaFunction({
    required String targetLanguageCode,
    required String nativeLanguageCode,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client.functions.invoke(
        'get-new-word',
        body: {
          'userId': userId,
          'targetLanguageCode': targetLanguageCode,
          'nativeLanguageCode': nativeLanguageCode,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch new word: ${response.data['error']}');
      }

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch new word: $e');
    }
  }
}
