import 'package:flutter/material.dart';
import 'package:iiuc_classroom/services/database_service.dart';

class RoutineComparisonScreen extends StatefulWidget {
  const RoutineComparisonScreen({super.key});

  @override
  State<RoutineComparisonScreen> createState() => _RoutineComparisonScreenState();
}

class _RoutineComparisonScreenState extends State<RoutineComparisonScreen> {
  String? selectedDay;
  String? selectedSection1;
  String? selectedSection2;

  final List<String> days = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday"];
  final List<String> sections = [
    "1AM", "1BM", "2AM", "2BM", "3AM", "3BM", "4AM", "4BM", 
    "5AM", "5BM", "6AM", "6BM", "7AM", "7BM", "8AM", "8BM"
  ];

  final List<String> timeSlots = [
    "10:30-11:20",
    "11:20-12:10",
    "12:10-01:00",
    "01:00-01:40",
    "01:40-02:30",
    "02:30-03:20",
    "03:20-04:10",
  ];

  /// Normalize the time strings to ensure consistent comparison
  String normalizeTime(String time) {
    return time
        .replaceAll('–', '-') // Replace en dash with hyphen
        .replaceAll('.', ':') // Replace periods with colons
        .trim();              // Remove extra spaces
  }

  /// Provide custom ordering for time slots
  int customTimeOrder(String time) {
    const timeOrder = {
      "10:30-11:20": 1,
      "11:20-12:10": 2,
      "12:10-01:00": 3,
      "01:00-01:40": 4,
      "01:40-02:30": 5,
      "02:30-03:20": 6,
      "03:20-04:10": 7,
    };
    return timeOrder[normalizeTime(time)] ?? 999;
  }

  /// Fetch routines for a specific section
  Future<List<Map<String, dynamic>>> fetchRoutineForSection(String? section) async {
    if (selectedDay != null && section != null) {
      final rawRoutines = await DatabaseService.fetchRoutines(selectedDay!, section);
      print("Raw Routines for Section $section on $selectedDay: $rawRoutines");

      // Sort by time
      final routines = List<Map<String, dynamic>>.from(rawRoutines);
      routines.sort((a, b) => customTimeOrder(normalizeTime(a['time'])).compareTo(customTimeOrder(normalizeTime(b['time']))));
      print("Sorted Routines for Section $section: $routines");
      return routines;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compare Routines')),
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

          // Section 1 Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedSection1,
              hint: Text("Select Section 1"),
              isExpanded: true,
              onChanged: (newSection) {
                setState(() {
                  selectedSection1 = newSection;
                });
              },
              items: sections.map((section) {
                return DropdownMenuItem<String>(
                  value: section,
                  child: Text(section),
                );
              }).toList(),
            ),
          ),

          // Section 2 Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedSection2,
              hint: Text("Select Section 2"),
              isExpanded: true,
              onChanged: (newSection) {
                setState(() {
                  selectedSection2 = newSection;
                });
              },
              items: sections.map((section) {
                return DropdownMenuItem<String>(
                  value: section,
                  child: Text(section),
                );
              }).toList(),
            ),
          ),

          // Compare Routines Viewer with Time Slot Labels
          Expanded(
            child: FutureBuilder<List<List<Map<String, dynamic>>>>(
              future: Future.wait([
                fetchRoutineForSection(selectedSection1),
                fetchRoutineForSection(selectedSection2),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Failed to load routines.'));
                } else if (snapshot.hasData) {
                  final section1Routines = snapshot.data![0];
                  final section2Routines = snapshot.data![1];

                  return ListView.builder(
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final time = timeSlots[index];

                      final routine1 = section1Routines.firstWhere(
                        (r) => normalizeTime(r['time']) == normalizeTime(time),
                        orElse: () => {'subject': 'No Class', 'instructor': '', 'room': ''},
                      );

                      final routine2 = section2Routines.firstWhere(
                        (r) => normalizeTime(r['time']) == normalizeTime(time),
                        orElse: () => {'subject': 'No Class', 'instructor': '', 'room': ''},
                      );

                      return Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Text(
                                time,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Card(
                              color: Colors.green.shade100,
                              child: ListTile(
                                title: Text('${routine1['subject']}'),
                                subtitle: Text('${routine1['instructor']}\nRoom: ${routine1['room']}'),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Card(
                              color: Colors.yellow.shade100,
                              child: ListTile(
                                title: Text('${routine2['subject']}'),
                                subtitle: Text('${routine2['instructor']}\nRoom: ${routine2['room']}'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
                return Center(child: Text('Unexpected error occurred.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
