import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';
import '../providers/flashcard_provider.dart';
import '../providers/stack_provider.dart';

class AuthService {
  final FirebaseService _firebase;
  final Ref _ref;
  static const String _keepLoggedInKey = 'keepLoggedIn';

  AuthService(this._firebase, this._ref);

  Future<void> setKeepLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepLoggedInKey, value);
  }

  Future<bool> getKeepLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepLoggedInKey) ?? false;
  }

  // Sign up
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebase.signUp(
      email: email,
      password: password,
    );

    // Save the user ID to SharedPreferences
    if (userCredential.user != null) {
      final prefs = await SharedPreferences.getInstance();
      const key = 'loggedInUserIds'; // Define a key for the list
      final List<String> userIds = prefs.getStringList(key) ?? [];
      if (!userIds.contains(userCredential.user!.uid)) {
        userIds.add(userCredential.user!.uid);
        await prefs.setStringList(key, userIds);
      }
    }

    return userCredential;
  }

  // Sign in with remember me option
  Future<UserCredential> signIn({
    required String email,
    required String password,
    required bool keepLoggedIn,
  }) async {
    final response = await _firebase.signIn(
      email: email,
      password: password,
    );
    await setKeepLoggedIn(keepLoggedIn);
    return response;
  }

  // ADDED: Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final UserCredential? userCredential = await _firebase.signInWithGoogle();
      if (userCredential?.user != null) {
        // For consistency with email/password, mark as 'keep logged in'
        await setKeepLoggedIn(true);

        // Save the user ID to SharedPreferences, similar to signUp
        final prefs = await SharedPreferences.getInstance();
        const key = 'loggedInUserIds'; 
        final List<String> userIds = prefs.getStringList(key) ?? [];
        if (!userIds.contains(userCredential!.user!.uid)) {
          userIds.add(userCredential.user!.uid);
          await prefs.setStringList(key, userIds);
        }
      }
      return userCredential;
    } catch (e) {
      print('AuthService: Google Sign-In failed: $e');
      rethrow; 
    }
  }

  // Sign out with check for keep logged in
  Future<void> signOut({bool force = false}) async {
    // Store the current userId *before* signing out
    final currentUserId = currentUser?.uid;

    if (force) {
      await setKeepLoggedIn(false);
      await _firebase.signOut();
    } else {
      final keepLoggedIn = await getKeepLoggedIn();
      if (!keepLoggedIn) {
        await _firebase.signOut();
      }
    }

    // Clear offline data for the user who just logged out
    if (currentUserId != null) {
      // Directly use the stored ID in case currentUser is now null
      // Clear data from the synced providers' caches
      await _ref.read(flashcardStateProvider.notifier).clearOfflineFlashcardData();
      await _ref.read(stacksProvider.notifier).clearOfflineStackData();
    }
  }

  // Get current user
  User? get currentUser => _firebase.currentUser;

  // Check if user is signed in
  bool get isAuthenticated => _firebase.currentUser != null;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _firebase.authStateChanges;

  // Initialize auth state with keep logged in check
  Future<void> initializeAuthState() async {
    try {
      final keepLoggedIn = await getKeepLoggedIn();
      final user = _firebase.currentUser;
      if (user != null && !keepLoggedIn) {
        await signOut(force: true);
      }
    } catch (e) {
      await signOut(force: true);
    }
  }

  // Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _firebase.updateUserMetadata(metadata);
  }
  
  // Delete user account and all associated data
  Future<void> deleteAccount() async {
    try {
      // Store the current userId *before* deletion for cleanup
      final currentUserId = currentUser?.uid;
      
      // First clear local data
      if (currentUserId != null) {
        await _ref.read(flashcardStateProvider.notifier).clearOfflineFlashcardData();
        await _ref.read(stacksProvider.notifier).clearOfflineStackData();
      }
      
      // Ensure keep logged in is set to false before deletion
      await setKeepLoggedIn(false);
      
      // Clear any remaining local preferences related to the user
      final prefs = await SharedPreferences.getInstance();
      const key = 'loggedInUserIds';
      final List<String> userIds = prefs.getStringList(key) ?? [];
      if (currentUserId != null && userIds.contains(currentUserId)) {
        userIds.remove(currentUserId);
        await prefs.setStringList(key, userIds);
      }
      
      // Then proceed with account deletion - this will delete all Firestore data
      // and sign out the user automatically
      await _firebase.deleteAccount();
      
      // Note: We don't need to explicitly call signOut here because:
      // 1. The FirebaseService.deleteAccount method already calls signOut
      // 2. Firebase will automatically sign out when the user is deleted
      
    } catch (e) {
      // If there's an error during deletion, attempt to sign out anyway
      // to ensure we don't have an invalid auth state
      try {
        await signOut(force: true);
      } catch (signOutError) {
        print('Error during forced sign out after deletion failure: $signOutError');
      }
      
      // Propagate the original error so the UI can handle it
      print('Error during account deletion: $e');
      rethrow;
    }
  }
}
