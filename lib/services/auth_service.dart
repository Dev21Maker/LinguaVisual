import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebase;
  static const String _keepLoggedInKey = 'keepLoggedIn';

  AuthService(this._firebase);

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
    return await _firebase.signUp(
      email: email,
      password: password,
    );
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

  // Sign out with check for keep logged in
  Future<void> signOut({bool force = false}) async {
    if (force) {
      await setKeepLoggedIn(false);
      await _firebase.signOut();
    } else {
      final keepLoggedIn = await getKeepLoggedIn();
      if (!keepLoggedIn) {
        await _firebase.signOut();
      }
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
}
