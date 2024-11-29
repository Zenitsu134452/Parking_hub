import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'timer_screen.dart';

class AdvanceUpcoming extends StatefulWidget {
  final String parkingSpotId;
  final String spaceId;

  const AdvanceUpcoming({
    Key? key,
    required this.parkingSpotId,
    required this.spaceId,
  }) : super(key: key);

  @override
  State<AdvanceUpcoming> createState() => _AdvanceUpcomingState();
}

class _AdvanceUpcomingState extends State<AdvanceUpcoming> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> advanceBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdvanceBookings();
    _checkAdvanceBookingStart();
    _handleBookNowExpiry();
  }

  Future<void> _fetchAdvanceBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('parking_spots')
          .doc(widget.parkingSpotId)
          .collection('spaces')
          .doc(widget.spaceId)
          .collection('advance_bookings')
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'userName': data['userName'],
          'userId': data['userId'], // Ensure userId is fetched
          'startTime': (data['startTime'] as Timestamp).toDate(),
          'endTime': (data['endTime'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        advanceBookings = bookings;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching advance bookings: $e')),
      );
    }
  }

  void _checkAdvanceBookingStart() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;

      for (var booking in advanceBookings) {
        if (currentUser != null &&
            booking['userId'] == currentUser.uid && // Ensure timer is shown to the correct user
            now.isAfter(booking['startTime']) &&
            now.isBefore(booking['endTime'])) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimerScreen(
                parkingSpotId: widget.parkingSpotId,
                spaceId: widget.spaceId,
                startTime: booking['startTime'],
                endTime: booking['endTime'],
              ),
            ),
          );
          break;
        }
      }
    });
  }

  void _handleBookNowExpiry() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final now = DateTime.now();

      // Check and update Firestore for expired "Book Now" bookings
      final spaceDoc = await _firestore
          .collection('parking_spots')
          .doc(widget.parkingSpotId)
          .collection('spaces')
          .doc(widget.spaceId)
          .get();

      if (spaceDoc.exists) {
        final data = spaceDoc.data() as Map<String, dynamic>;
        final isAvailable = data['isAvailable'] ?? true;
        final endTime = data['endTime'] != null
            ? (data['endTime'] as Timestamp).toDate()
            : null;

        if (!isAvailable && endTime != null && now.isAfter(endTime)) {
          await _firestore
              .collection('parking_spots')
              .doc(widget.parkingSpotId)
              .collection('spaces')
              .doc(widget.spaceId)
              .update({'isAvailable': true, 'endTime': null});

          // Update the UI in real-time
          setState(() {});
        }
      }
    });
  }

  Future<void> _addAdvanceBooking(
      String userName, DateTime startTime, DateTime endTime) async {
    try {
      final newBooking = {
        'userName': userName,
        'userId': FirebaseAuth.instance.currentUser?.uid, // Add userId here
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
      };

      final bookingRef = await _firestore
          .collection('parking_spots')
          .doc(widget.parkingSpotId)
          .collection('spaces')
          .doc(widget.spaceId)
          .collection('advance_bookings')
          .add(newBooking);

      setState(() {
        advanceBookings.add({
          ...newBooking,
          'id': bookingRef.id,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advance booking added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding advance booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advance Upcoming Bookings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: advanceBookings.length,
        itemBuilder: (context, index) {
          final booking = advanceBookings[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('User: ${booking['userName']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start: ${booking['startTime']}'),
                  Text('End: ${booking['endTime']}'),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBookingDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBookingDialog() {
    String userName = '';
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Advance Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'User Name'),
                onChanged: (value) {
                  userName = value;
                },
              ),
              ListTile(
                title: const Text('Select Start Time'),
                subtitle: startTime != null ? Text(startTime!.format(context)) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selected != null) {
                      setState(() {
                        startTime = selected;
                      });
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Select End Time'),
                subtitle: endTime != null ? Text(endTime!.format(context)) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selected != null) {
                      setState(() {
                        endTime = selected;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (userName.isNotEmpty && startTime != null && endTime != null) {
                  final now = DateTime.now();
                  final startDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    startTime!.hour,
                    startTime!.minute,
                  );
                  final endDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    endTime!.hour,
                    endTime!.minute,
                  );

                  if (endDateTime.isAfter(startDateTime)) {
                    Navigator.pop(context);
                    _addAdvanceBooking(userName, startDateTime, endDateTime);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('End time must be after start time')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide valid booking details')),
                  );
                }
              },
              child: const Text('Add Booking'),
            ),
          ],
        );
      },
    );
  }
}
