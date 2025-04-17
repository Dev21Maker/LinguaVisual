import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});