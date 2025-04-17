import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/srs_service.dart';

final srsProvider = Provider<SRSService>((ref) {
  return SRSService();
});