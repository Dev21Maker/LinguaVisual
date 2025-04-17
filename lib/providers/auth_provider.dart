import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'supabase_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthService(supabaseService);
});