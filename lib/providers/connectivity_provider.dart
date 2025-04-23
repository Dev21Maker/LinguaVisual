import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isOnlineProvider = StateProvider<bool>((ref) => false);

// Optional: Create a service to handle connectivity
class ConnectivityService {
  static Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}