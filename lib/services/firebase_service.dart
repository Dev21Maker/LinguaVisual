import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/flashcard.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth methods
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User profile (metadata)
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(metadata['displayName']);
      // Add more fields as needed
    }
  }

  // Database operations (Firestore)
  Future<List<Map<String, dynamic>>> getFlashcards() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('flashcards')
        .where('user_id', isEqualTo: currentUser!.uid)
        .orderBy('created_at')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> insertFlashcard(Map<String, dynamic> flashcard) async {
    await _firestore.collection('flashcards').add(flashcard);
  }

  Future<void> updateFlashcard(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('flashcards').doc(id).update(updates);
  }

  Future<void> deleteFlashcard(String id) async {
    await _firestore.collection('flashcards').doc(id).delete();
  }

  Future<List<Flashcard>> fetchDueCards() async {
    if (currentUser == null) throw Exception('User not authenticated');
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _firestore
        .collection('cards')
        .where('user_id', isEqualTo: currentUser!.uid)
        .where('srs_next_review_date', isLessThanOrEqualTo: now)
        .orderBy('srs_next_review_date')
        .get();
    return snapshot.docs.map((doc) => Flashcard.fromMap(doc.data())).toList();
  }

  Future<void> insertCard(Flashcard card) async {
    if (currentUser == null) throw Exception('User not authenticated');
    final cardData = {
      'user_id': currentUser!.uid,
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
      'created_at': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('cards').add(cardData);
  }

  Future<void> updateCard(Flashcard card) async {
    if (currentUser == null) throw Exception('User not authenticated');
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
    // You must know the Firestore document ID for update
    // This assumes card.id is the Firestore doc ID
    await _firestore.collection('cards').doc(card.id).update(cardData);
  }

  // Example: If you need to call a cloud function, use Firebase Functions package (not included here)
}
