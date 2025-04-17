import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabase;

  AuthService(this._supabase);

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

  // Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.signIn(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.signOut();
  }

  // Get current user
  User? get currentUser => _supabase.currentUser;

  // Check if user is signed in
  bool get isAuthenticated => _supabase.isAuthenticated;

  // Get the current session
  Session? get currentSession => _supabase.currentSession;

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // Initialize auth state
  Future<void> initializeAuthState() async {
    try {
      // Check if there's a stored session
      final initialSession = _supabase.currentSession;
      if (initialSession != null) {
        // Verify the session is still valid
        await _supabase.refreshSession();
      }
    } catch (e) {
      // If session refresh fails, sign out
      await signOut();
    }
  }

  // Get user metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  // Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    return await _supabase.updateUserMetadata(metadata);
  }
}
