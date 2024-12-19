import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadRoutine(List<Map<String, dynamic>> routineData) async {
    for (final routine in routineData) {
      await _firestore.collection('routines').add(routine);
    }
    print('Routines uploaded successfully!');
  }

  Future<List<Map<String, dynamic>>> fetchRoutines() async {
  final List<Map<String, dynamic>> routines = [];
  try {
    final querySnapshot = await _firestore.collection('routines').get();

    if (querySnapshot.docs.isEmpty) {
      print('No routines found in Firebase!');
    } else {
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        print('Fetched Firebase Document: $data');
        routines.add(Map<String, dynamic>.from(data));
      }
    }
  } catch (e) {
    print('Error fetching routines from Firebase: $e');
  }
  return routines;
}

}
