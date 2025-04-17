import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recraft_api_service.dart';

final recraftApiProvider = Provider<RecraftApiService>((ref) {
  return RecraftApiService();
});