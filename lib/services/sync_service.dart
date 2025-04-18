import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_visual/services/database_helper.dart';
import 'package:lingua_visual/services/supabase_service.dart';
import '../models/flashcard.dart';
import '../providers/supabase_provider.dart';
import '../providers/database_provider.dart';

class SyncService {
  final SupabaseService supabaseService;
  final DatabaseHelper databaseHelper;

  SyncService(this.supabaseService, this.databaseHelper);

  Future<void> syncOfflineData() async {
    // Get all offline flashcards
    final offlineCards = await databaseHelper.getAllFlashcards();
    
    // For each offline card, try to sync with Supabase
    for (final card in offlineCards) {
      try {
        await supabaseService.insertCard(card);
        // After successful sync, mark as synced in local DB
        await databaseHelper.markAsSynced(card.id);
      } catch (e) {
        print('Failed to sync card ${card.id}: $e');
        // Continue with next card if one fails
        continue;
      }
    }
  }
}

final syncServiceProvider = Provider((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final databaseHelper = ref.watch(databaseProvider);
  return SyncService(supabaseService, databaseHelper);
});