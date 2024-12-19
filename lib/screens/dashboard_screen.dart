import 'package:flutter/material.dart';
import 'package:iiuc_classroom/screens/approval_requests_screen.dart';
import 'package:iiuc_classroom/screens/free_room_boking_screen.dart';
import 'package:iiuc_classroom/screens/mark_room_free_screen.dart';
import 'package:iiuc_classroom/screens/my_requests_screen.dart';
import 'routine_screen.dart';
import 'routine_comparison_screen.dart';
import 'room_booking_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String role = userData['role'];
    final String section = userData['section'] ?? "N/A";
    final String sid = userData['sid'];

    // Define available actions based on roles
    final actions = <Map<String, dynamic>>[
      if (role == "Student" || role == "CR" || role == "ACR")
        {"title": "View Routine", "icon": Icons.schedule, "screen": RoutineScreen()},
      if (role == "Student")
        {"title": "Compare Routines", "icon": Icons.compare_arrows, "screen": RoutineComparisonScreen()},
      if (role == "CR" || role == "ACR")
        {"title": "Book Room", "icon": Icons.room_outlined, "screen": FreeRoomBookingScreen()},
      if (role == "CR" || role == "ACR")
        {"title": "Free a Room", "icon": Icons.meeting_room_outlined, "screen": MarkRoomFreeScreen()},
      if (role == "CR" || role == "ACR")
        {"title": "Requests", "icon": Icons.approval_outlined, "screen": ApprovalRequestsScreen()},
      if (role == "CR" || role == "ACR")
        {"title": "My Requests", "icon": Icons.history, "screen": MyRequestsScreen()},
      if (role == "Teacher")
        {"title": "Manage Routine", "icon": Icons.edit, "screen": null},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // User Profile Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome, $role",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("ID: $sid", style: TextStyle(fontSize: 16)),
                        Text("Section: $section", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Features Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 3 / 2,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return GestureDetector(
                  onTap: () {
                    if (action["screen"] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => action["screen"]),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${action['title']} coming soon!")),
                      );
                    }
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action["icon"], size: 40, color: Colors.green),
                        const SizedBox(height: 8.0),
                        Text(
                          action["title"],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
