import 'package:shared_preferences/shared_preferences.dart';

class KeepSignedInService {
  static const String _key = 'keep_signed_in';

  Future<void> setKeepSignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<bool> getKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // Default: true
  }

  Future<void> clearKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
