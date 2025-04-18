import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabase;
  static const String _keepLoggedInKey = 'keepLoggedIn';

  AuthService(this._supabase);

  Future<void> setKeepLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepLoggedInKey, value);
  }

  Future<bool> getKeepLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepLoggedInKey) ?? false;
  }

  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.signUp(
      email: email,
      password: password,
    );
  }

  // Sign in with remember me option
  Future<AuthResponse> signIn({
    required String email,
    required String password,
    required bool keepLoggedIn,
  }) async {
    final response = await _supabase.signIn(
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
      await _supabase.signOut();
    } else {
      final keepLoggedIn = await getKeepLoggedIn();
      if (!keepLoggedIn) {
        await _supabase.signOut();
      }
    }
  }

  // Get current user
  User? get currentUser => _supabase.currentUser;

  // Check if user is signed in
  bool get isAuthenticated => _supabase.isAuthenticated;

  // Get the current session
  Session? get currentSession => _supabase.currentSession;

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // Initialize auth state with keep logged in check
  Future<void> initializeAuthState() async {
    try {
      final keepLoggedIn = await getKeepLoggedIn();
      final initialSession = _supabase.currentSession;

      if (initialSession != null && keepLoggedIn) {
        await _supabase.refreshSession();
      } else if (initialSession != null && !keepLoggedIn) {
        await signOut(force: true);
      }
    } catch (e) {
      await signOut(force: true);
    }
  }

  // Get user metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  // Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    return await _supabase.updateUserMetadata(metadata);
  }
}
