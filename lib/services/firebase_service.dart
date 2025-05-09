import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Languador/models/flashcard_stack.dart';
import '../models/online_flashcard.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User cancelled the sign-in process
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Log or handle Firebase specific errors
      print('FirebaseService: FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      // Log or handle other errors (e.g., network, Google Play services issues)
      print('FirebaseService: Generic error during Google Sign-In: $e');
      rethrow;
    }
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
  Future<List<OnlineFlashcard>> getFlashcards() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cards')
        .orderBy('created_at')
        .get();
    return snapshot.docs.map((doc) {
      final data = {...doc.data(), 'id': doc.id};
      return OnlineFlashcard.fromMap(data);
    }).toList();
  }

  Future<void> insertCard(OnlineFlashcard card) async {
    if (currentUser == null) throw Exception('User not authenticated');
    final cardData = card.toMap();
    cardData['created_at'] = FieldValue.serverTimestamp();
    cardData.remove('id');
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cards')
        .add(cardData);
  }

  Future<void> updateCard(OnlineFlashcard card) async {
    if (currentUser == null) throw Exception('User not authenticated');
    final cardData = card.toMap();
    cardData.remove('id');
    cardData.remove('created_at');
    cardData.remove('updated_at');
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cards')
        .doc(card.id)
        .update(cardData);
  }

  Future<void> deleteCard(String id) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cards')
        .doc(id)
        .delete();
  }

  Future<List<OnlineFlashcard>> fetchDueCards() async {
    if (currentUser == null) throw Exception('User not authenticated');
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cards')
        .where('srs_next_review_date', isLessThanOrEqualTo: now)
        .orderBy('srs_next_review_date')
        .get();
    return snapshot.docs.map((doc) {
      final data = {...doc.data(), 'id': doc.id};
      return OnlineFlashcard.fromMap(data);
    }).toList();
  }

  Future<List<FlashcardStack>> getStacks() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('stacks')
        .orderBy('created_at')
        .get();
    return snapshot.docs.map((doc) {
      final data = {...doc.data(), 'id': doc.id};
      return FlashcardStack.fromMap(data);
    }).toList();
  }

  Future<void> createStack(FlashcardStack stack) async {
    if (currentUser == null) throw Exception('User not authenticated');
    final cardData = stack.toMap();
    cardData['created_at'] = FieldValue.serverTimestamp();
    cardData.remove('id');
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('stacks')
        .add(cardData);
  }

  Future<void> updateStack(FlashcardStack stack) async {
    if (currentUser == null) throw Exception('User not authenticated');
    final cardData = stack.toMap();
    cardData.remove('id');
    cardData.remove('created_at');
    cardData.remove('updated_at');
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('stacks')
        .doc(stack.id)
        .update(cardData);
  }

  Future<void> deleteStack(String id) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('stacks')
        .doc(id)
        .delete();
  }

  // Example: If you need to call a cloud function, use Firebase Functions package (not included here)
}
