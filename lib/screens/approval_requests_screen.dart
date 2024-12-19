import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? userRole;
  List<Map<String, dynamic>> bookingRequests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchBookingRequests();
  }

  Future<void> fetchUserRole() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userRole = userDoc.data()?['role'];
        });
      }
    }
  }

  Future<void> fetchBookingRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      final userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final querySnapshot = await _firestore
          .collection('booking_requests')
          .where('requested_section', isEqualTo: userData['section'])
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        bookingRequests = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'requested_by': data['requested_by'],
            'day': data['day'],
            'time': data['time'],
            'room': data['room'],
            'status': data['status'],
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch booking requests: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> approveRequest(String requestId, String room, String day, String time) async {
    try {
      // Approve the request in the booking_requests collection
      await _firestore.collection('booking_requests').doc(requestId).update({
        'status': 'approved',
        'approved_by': _auth.currentUser?.uid,
        'approved_timestamp': FieldValue.serverTimestamp(),
      });

      // Mark the room as not free in the routines collection
      final querySnapshot = await _firestore
          .collection('routines')
          .where('day', isEqualTo: day)
          .where('time', isEqualTo: time)
          .where('room', isEqualTo: room)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({'is_free': false});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request approved successfully!")));

      // Refresh the booking requests
      fetchBookingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to approve request: $e")),
      );
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      // Reject the request in the booking_requests collection
      await _firestore.collection('booking_requests').doc(requestId).update({
        'status': 'rejected',
        'rejected_by': _auth.currentUser?.uid,
        'rejected_timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request rejected successfully!")));

      // Refresh the booking requests
      fetchBookingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reject request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Approve Booking Requests", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.greenAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : bookingRequests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "No pending requests at the moment.",
                      style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: bookingRequests.length,
                  itemBuilder: (context, index) {
                    final request = bookingRequests[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Room: ${request['room']}",
                              style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              "Day: ${request['day']} | Time: ${request['time']}",
                              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => approveRequest(
                                    request['id'],
                                    request['room'],
                                    request['day'],
                                    request['time'],
                                  ),
                                  icon: Icon(Icons.check, color: Colors.white),
                                  label: Text("Approve"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => rejectRequest(request['id']),
                                  icon: Icon(Icons.close, color: Colors.white),
                                  label: Text("Reject"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
