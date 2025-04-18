import 'package:supabase_flutter/supabase_flutter.dart';
import 'keep_signed_in_service.dart';

class SessionCleanupService {
  final KeepSignedInService _keepSignedInService = KeepSignedInService();

  Future<void> cleanupSessionIfNeeded() async {
    final keepSignedIn = await _keepSignedInService.getKeepSignedIn();
    if (!keepSignedIn) {
      await Supabase.instance.client.auth.signOut();
    }
  }
}
