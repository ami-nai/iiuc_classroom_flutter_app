import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiuc_classroom/screens/dashboard_screen.dart';
import 'package:iiuc_classroom/screens/login_screen.dart';
import 'package:iiuc_classroom/screens/registration_screen.dart';
import 'package:iiuc_classroom/screens/room_booking_screen.dart';
import 'package:iiuc_classroom/screens/routine_comparison_screen.dart';
import 'package:iiuc_classroom/services/auth_service.dart';
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
  dynamic user;
  dynamic userData;
  dynamic userRole;

  final List<String> days = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday"];
  final List<String> semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];
  List<String> sections = [];

  Future<List<Map<String, dynamic>>> fetchRoutines() async {
    if (selectedDay != null && selectedSection != null) {
      final rawRoutines = await DatabaseService.fetchRoutines(selectedDay!, selectedSection!);
      final routines = List<Map<String, dynamic>>.from(rawRoutines);
      routines.sort((a, b) => customTimeOrder(a['time']).compareTo(customTimeOrder(b['time'])));
      return routines;
    }
    return [];
  }

  int customTimeOrder(String time) {
    const timeOrder = {
      "10:30–11:20": 1,
      "11:20–12:10": 2,
      "12:10–01:00": 3,
      "01:00–01:40": 4,
      "01:40–02:30": 5,
      "02:30–03:20": 6,
      "03:20–04:10": 7,
    };
    return timeOrder[time.trim()] ?? 999;
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

  Future<void> syncAndRefresh() async {
    await SyncService().syncFromFirebaseToSQLite();
    setState(() {});
  }

  Future<Map<String, dynamic>?> fetchUserData(String? uid) async {
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<bool> checkAccessibility() async {
    user = auth.currentUser;
    Future<bool> loggedIn = AuthService().checkIfLogedIn(user);
    if (await loggedIn) {
      final uid = user.uid;
      userData = await fetchUserData(uid);
      userRole = userData['role'];
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Routine Viewer'),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 94, 212, 98),
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.green.shade100,
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.green),
                  child: Center(
                    child: Text(
                      "IIUC Classroom",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Dashboard'),
                  onTap: () async {
                    if (await checkAccessibility()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DashboardScreen(userData: userData)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please login first.")),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.compare),
                  title: Text('Compare Routines'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RoutineComparisonScreen()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.app_registration),
                  title: Text('Register'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegistrationScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.login),
                  title: Text('Login'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () async {
                    await AuthService().logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => RoutineScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: syncAndRefresh,
          child: Column(

            children: [
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    )
                  ),
                  value: selectedDay,
                  hint: const Text("  Select Day"),
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
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    )
                  ),
                  value: selectedSemester,
                  hint: const Text(" Select Semester"),
                  isExpanded: true,
                  onChanged: (newSemester) {
                    setState(() {
                      selectedSemester = newSemester;
                      updateSections();
                    });
                  },
                  items: semesters.map((semester) {
                    return DropdownMenuItem<String>(
                      value: semester,
                      child: Text("Semester $semester"),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 5),
              if (sections.isNotEmpty)
              
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    )
                  ),
                    value: selectedSection,
                    hint: const Text("  Select Section"),
                    isExpanded: true,
                    onChanged: (newSection) {
                      setState(() {
                        selectedSection = newSection;
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
              SizedBox(height: 5),
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
                          if(routine['instructor'] == ""){
                            return Card(
                              elevation: 2,
                            margin: const EdgeInsets.all(8.0),
                            color: const Color.fromARGB(110, 255, 82, 82),
                            //shadowColor: Colors.redAccent,
                            child: ListTile(
                              title: Text(
                                'No Class',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Time: ${routine['time']}",
                              ),
                              leading: Icon(Icons.schedule, color: Colors.green),
                            ),
                          );
                          }
                          else{
                            return Card(
                              elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            child: ListTile(
                              title: Text(
                                routine['subject'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Instructor: ${routine['instructor']}\nTime: ${routine['time']} - Room: ${routine['room']}",
                              ),
                              leading: Icon(Icons.schedule, color: Colors.green),
                            ),
                          );
                          }
                          
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
      ),
    );
  }
}
