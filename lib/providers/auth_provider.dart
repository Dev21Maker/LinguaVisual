import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'firebase_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthService(firebaseService);
});