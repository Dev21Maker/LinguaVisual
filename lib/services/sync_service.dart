// import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:lingua_visual/services/database_helper.dart';
// import 'package:lingua_visual/services/firebase_service.dart';
// import '../models/online_flashcard.dart';
// import '../providers/database_provider.dart';
// import '../providers/firebase_provider.dart'; // Add this import

// // No need to import firebase_provider.dart, use supabase_provider.dart which exports firebaseServiceProvider

// class SyncService {
//   final FirebaseService firebaseService;
//   // final DatabaseHelper databaseHelper;

//   SyncService(this.firebaseService, );

//   Future<void> syncOfflineData() async {
//     // Get all offline flashcards
//     // final offlineCards = await databaseHelper.getAllFlashcards();
    
//     // For each offline card, try to sync with Firebase
//     for (final card in offlineCards) {
//       try {
//         await firebaseService.insertCard(card);
//         // After successful sync, mark as synced in local DB
//         await databaseHelper.markAsSynced(card.id);
//       } catch (e) {
//         print('Failed to sync card ${card.id}: $e');
//         // Continue with next card if one fails
//         continue;
//       }
//     }
//   }
// }

// final syncServiceProvider = Provider((ref) {
//   final firebaseService = ref.watch(firebaseServiceProvider);
//   // final databaseHelper = ref.watch(databaseProvider);
//   return SyncService(firebaseService, databaseHelper);
// });