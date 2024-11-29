import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingUpcoming extends StatefulWidget {
  const BookingUpcoming({Key? key}) : super(key: key);

  @override
  State<BookingUpcoming> createState() => _BookingUpcomingState();
}

class _BookingUpcomingState extends State<BookingUpcoming> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String? errorMessage;

  // Fetch user bookings from Firestore
  Future<void> _fetchUserBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not logged in.';
          isLoading = false;
        });
        return;
      }

      // Query spaces where the current user has booked
      QuerySnapshot snapshot = await _firestore
          .collectionGroup('spaces') // Query across all spaces sub-collections
          .where('userId', isEqualTo: user.uid)
          .where('isAvailable', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'No upcoming bookings found.';
          isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> fetchedBookings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'spaceId': doc.id,
          'reservedAt': (data['reservedAt'] as Timestamp).toDate(),
          'userId': data['userId'],
          'vehicleNumber': data['vehicleNumber'], // Fetch vehicle number if added
        };
      }).toList();

      setState(() {
        bookings = fetchedBookings;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch bookings. Error: $e';
        isLoading = false;
      });
    }
  }

  // Calculate time remaining for a booking
  String _getTimeRemaining(DateTime reservedAt, int durationInMinutes) {
    final endTime = reservedAt.add(Duration(minutes: durationInMinutes));
    final remaining = endTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return 'Expired';
    } else {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;

      if (hours > 0) {
        return '$hours hours, $minutes minutes remaining';
      } else {
        return '$minutes minutes remaining';
      }
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchUserBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Bookings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final timeRemaining = _getTimeRemaining(
            booking['reservedAt'],
            1, // Assuming 1 hour booking duration for now
          );

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ListTile(
              title: Text('Space ID: ${booking['spaceId']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reserved At: ${booking['reservedAt']}'),
                  Text('Time Remaining: $timeRemaining'),
                  Text('Vehicle: ${booking['vehicleNumber'] ?? 'Unknown'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
