import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineDataLoader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadRoutineToFirebase() async {
    try {
      // Load the JSON file
      final String response = await rootBundle.loadString('assets/routine.json');
      final List<dynamic> data = json.decode(response);

      // Start a batch write
      final batch = _firestore.batch();
      for (final routine in data) {
        final docRef = _firestore.collection('routines').doc(); // Auto-generate doc ID
        batch.set(docRef, routine);
      }

      await batch.commit();
      print('Routine uploaded successfully!');
    } catch (e) {
      print('Failed to upload routine: $e');
    }
  }
}
