import 'package:firebase_auth/firebase_auth.dart';
import 'keep_signed_in_service.dart';

class SessionCleanupService {
  final KeepSignedInService _keepSignedInService = KeepSignedInService();

  Future<void> cleanupSessionIfNeeded() async {
    final keepSignedIn = await _keepSignedInService.getKeepSignedIn();
    if (!keepSignedIn) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
