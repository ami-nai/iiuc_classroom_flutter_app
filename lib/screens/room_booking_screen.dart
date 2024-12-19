import 'package:flutter/material.dart';
import 'package:iiuc_classroom/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  String? selectedDay;
  String? selectedTime;
  String? selectedRoom;

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

  Future<List<Map<String, dynamic>>> fetchRoomStatus() async {
    if (selectedDay != null && selectedTime != null) {
      final snapshot = await _firestore
          .collection('room_bookings')
          .where('day', isEqualTo: selectedDay)
          .where('time', isEqualTo: selectedTime)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    }
    return [];
  }

  Future<void> requestRoom(String room) async {
    try {
      await _firestore.collection('room_bookings').add({
        'day': selectedDay,
        'time': selectedTime,
        'room': room,
        'semester': 'N/A', // Add based on your requirement
        'section': 'N/A',  // Add based on your requirement
        'booked_by': 'user_email@example.com', // Replace with actual user
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room request submitted for $room')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request room: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room Booking')),
      body: Column(
        children: [
          // Day Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedDay,
              hint: Text("Select Day"),
              isExpanded: true,
              onChanged: (newDay) {
                setState(() {
                  selectedDay = newDay;
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
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedTime,
              hint: Text("Select Time Slot"),
              isExpanded: true,
              onChanged: (newTime) {
                setState(() {
                  selectedTime = newTime;
                });
              },
              items: timeSlots.map((slot) {
                return DropdownMenuItem<String>(
                  value: slot,
                  child: Text(slot),
                );
              }).toList(),
            ),
          ),

          // Room List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchRoomStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Failed to fetch room data.'));
                } else if (snapshot.hasData) {
                  final rooms = snapshot.data!;
                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final status = room['status'] == 'pending'
                          ? 'Pending'
                          : room['status'] == 'approved'
                              ? 'Approved'
                              : 'Free';
                      return ListTile(
                        title: Text('Room: ${room['room']}'),
                        subtitle: Text('Status: $status'),
                        trailing: status == 'Free'
                            ? ElevatedButton(
                                onPressed: () => requestRoom(room['room']),
                                child: Text('Request'),
                              )
                            : null,
                      );
                    },
                  );
                }
                return Center(child: Text('No room data available.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
