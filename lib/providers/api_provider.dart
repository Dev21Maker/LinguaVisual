import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiImageProvider = Provider<ImageApiService>((ref) {
  return ImageApiService();
});