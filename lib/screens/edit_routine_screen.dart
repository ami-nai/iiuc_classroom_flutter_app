import 'package:flutter/material.dart';
import 'package:iiuc_classroom/services/database_service.dart';
import 'package:iiuc_classroom/services/sync_service.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  String? selectedDay;
  String? selectedSemester;
  String? selectedSection;

  final List<String> days = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday"];
  final List<String> semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];
  List<String> sections = [];

  Future<List<Map<String, dynamic>>> fetchRoutines() async {
    if (selectedDay != null && selectedSection != null) {
      return await DatabaseService.fetchRoutines(selectedDay!, selectedSection!);
    }
    return [];
  }

  Future<void> syncAndRefresh() async {
    await SyncService().syncFromFirebaseToSQLite();
    setState(() {}); // Refresh UI
  }

  void updateSections() {
    if (selectedSemester != null) {
      sections = ["AM", "BM", "CM", "DM", "EM", "FM", "GM", "HM"]
          .map((suffix) => "$selectedSemester$suffix")
          .toList();
    } else {
      sections = [];
    }
    selectedSection = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routine Viewer')),
      body: RefreshIndicator(
        onRefresh: syncAndRefresh,
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedDay,
              hint: const Text("Select Day"),
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
            // Semester and Section Dropdowns...
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchRoutines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                    return const Center(child: Text('No routines available.'));
                  } else if (snapshot.hasData) {
                    final routines = snapshot.data!;
                    return ListView.builder(
                      itemCount: routines.length,
                      itemBuilder: (context, index) {
                        final routine = routines[index];
                        return ListTile(
                          title: Text('${routine['subject']} (${routine['instructor']})'),
                          subtitle: Text('${routine['time']} - Room: ${routine['room']}'),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Unexpected error.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
