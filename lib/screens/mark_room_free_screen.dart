import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkRoomFreeScreen extends StatefulWidget {
  const MarkRoomFreeScreen({Key? key}) : super(key: key);

  @override
  _MarkRoomFreeScreenState createState() => _MarkRoomFreeScreenState();
}

class _MarkRoomFreeScreenState extends State<MarkRoomFreeScreen> {
  String? selectedDay;
  String? selectedTime;
  String? detectedSection;
  String? detectedRoom;
  String? detectedInstructor;
  String? detectedSubject;

  bool isLoading = false; // For loading state
  final List<String> days = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday"];
  final List<String> timeSlots = [
    "10:30–11:20",
    "11:20–12:10",
    "12:10–01:00",
    "01:00–01:40",
    "01:40–02:30",
    "02:30–03:20",
    "03:20–04:10",
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> fetchRoomFromFirebase() async {
    if (selectedDay != null && selectedTime != null) {
      setState(() {
        isLoading = true;
      });

      try {
        // Get the current user's section
        final User? user = auth.currentUser;
        final uid = user!.uid;
        final userQuerySnapshot = await _firestore
            .collection("users")
            .where('uid', isEqualTo: uid)
            .get();

        if (userQuerySnapshot.docs.isNotEmpty) {
          detectedSection = userQuerySnapshot.docs.first['section'];
        } else {
          setState(() {
            detectedRoom = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Your section is not registered. Contact admin.")),
          );
          return;
        }

        // Query Firestore for matching routine
        final querySnapshot = await _firestore
            .collection('routines')
            .where('day', isEqualTo: selectedDay)
            .where('time', isEqualTo: selectedTime)
            .where('section', isEqualTo: detectedSection)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            detectedRoom = querySnapshot.docs.first['room'];
            detectedInstructor = querySnapshot.docs.first['instructor'];
            detectedSubject = querySnapshot.docs.first['subject'];
          });
        } else {
          setState(() {
            detectedRoom = null; // No room found
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No room found for the selected day, time, and section.")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch room details: $e")),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> markRoomAsFreeInFirebase() async {
    if (selectedDay != null && selectedTime != null && detectedRoom != null) {
      setState(() {
        isLoading = true;
      });

      try {
        // Update Firestore to mark the room as free
        final querySnapshot = await _firestore
            .collection('routines')
            .where('day', isEqualTo: selectedDay)
            .where('time', isEqualTo: selectedTime)
            .where('room', isEqualTo: detectedRoom)
            .get();

        for (final doc in querySnapshot.docs) {
          await doc.reference.update({'is_free': true});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Room $detectedRoom marked as free for $selectedDay at $selectedTime!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to mark room as free: $e")),
        );
      }

      setState(() {
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select day, time, and ensure room is detected.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mark Room as Free", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Selector
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: InputDecoration(
                      labelText: "Select Day",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (newDay) {
                      setState(() {
                        selectedDay = newDay;
                        detectedRoom = null; // Reset room
                      });
                    },
                    items: days.map((day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.0),

                  // Time Slot Selector
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: InputDecoration(
                      labelText: "Select Time Slot",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (newTime) async {
                      setState(() {
                        selectedTime = newTime;
                        detectedRoom = null; // Reset room
                      });
                      await fetchRoomFromFirebase();
                    },
                    items: timeSlots.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24.0),

                  // Detected Room Details
                  if (detectedRoom != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Room Details",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Divider(),
                            Text(
                              "Room: $detectedRoom",
                              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              "Instructor: ${detectedInstructor ?? "N/A"}",
                              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              "Subject: ${detectedSubject ?? "N/A"}",
                              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      "No Room Detected",
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  SizedBox(height: 24.0),

                  // Mark as Free Button
                  Center(
                    child: ElevatedButton(
                      onPressed: detectedRoom != null ? markRoomAsFreeInFirebase : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      ),
                      child: Text("Mark as Free"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
