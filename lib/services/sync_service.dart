import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiuc_classroom/services/database_service.dart';
import 'package:iiuc_classroom/services/firebase_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncFromFirebaseToSQLite() async {
    try {
      // Fetch all routines from Firebase
      final querySnapshot = await _firestore.collection('routines').get();
      final db = await DatabaseService.initializeDB();

      // Clear the local database
      await db.delete('routine');
      print('SQLite database cleared.');

      // Insert Firebase data into SQLite
      for (final doc in querySnapshot.docs) {
        await db.insert('routine', doc.data());
      }

      print('Local database synced with Firebase!');
    } catch (e) {
      print('Failed to sync data from Firebase: $e');
    }
  }

}
