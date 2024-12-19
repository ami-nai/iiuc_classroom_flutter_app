import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class FreeRoomBookingScreen extends StatefulWidget {
  const FreeRoomBookingScreen({Key? key}) : super(key: key);

  @override
  _FreeRoomBookingScreenState createState() => _FreeRoomBookingScreenState();
}

class _FreeRoomBookingScreenState extends State<FreeRoomBookingScreen> {
  String? selectedDay;
  String? selectedTime;
  bool isLoading = false; // For loading state
  List<Map<String, dynamic>> freeRooms = [];

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

  Future<void> fetchFreeRooms() async {
    setState(() {
      isLoading = true;
    });

    final User? user = auth.currentUser;
    final userData = await _firestore.collection('users').doc(user!.uid).get();
    final userSection = userData['section'];

    if (selectedDay != null && selectedTime != null) {
      try {
        final querySnapshot = await _firestore
            .collection('routines')
            .where('day', isEqualTo: selectedDay)
            .where('time', isEqualTo: selectedTime)
            .where('is_free', isEqualTo: true)
            .where('section', isNotEqualTo: userSection)
            .get();

        setState(() {
          freeRooms = querySnapshot.docs.map((doc) => doc.data()).toList();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch free rooms: $e")),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> requestBooking(String room) async {
    setState(() {
      isLoading = true;
    });

    final User? user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be signed in to request a booking.")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _firestore.collection('routines')
          .where('day', isEqualTo: selectedDay)
          .where('time', isEqualTo: selectedTime)
          .where('room', isEqualTo: room).get();

      final data = snapshot.docs.first['section'];

      await _firestore.collection('booking_requests').add({
        'requested_by': user.uid,
        'requested_section': data,
        'day': selectedDay,
        'time': selectedTime,
        'room': room,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking request for room $room submitted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit booking request: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Free Room Booking",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day Selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: InputDecoration(
                      labelText: "Select Day",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (newDay) {
                      setState(() {
                        selectedDay = newDay;
                        freeRooms = [];
                      });
                    },
                    items: days.map((day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                  ),
                ),

                // Time Slot Selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: InputDecoration(
                      labelText: "Select Time Slot",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (newTime) async {
                      setState(() {
                        selectedTime = newTime;
                        freeRooms = [];
                      });
                      await fetchFreeRooms();
                    },
                    items: timeSlots.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                  ),
                ),

                // Free Rooms List
                Expanded(
                  child: freeRooms.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: freeRooms.length,
                          itemBuilder: (context, index) {
                            final room = freeRooms[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  "Room: ${room['room']}",
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  "Instructor: ${room['instructor']}\nSubject: ${room['subject']}",
                                  style: GoogleFonts.roboto(fontSize: 14),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => requestBooking(room['room']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Text("Request"),
                                ),
                              ),
                            );
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "No free rooms found for the selected day and time.",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
