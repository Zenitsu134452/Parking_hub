import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_stream.dart';

class BookingPage extends StatefulWidget {
  final String parkingSpotId;
  final String spaceId;
  final VoidCallback onBookingConfirmed;

  const BookingPage({
    Key? key,
    required this.parkingSpotId,
    required this.spaceId,
    required this.onBookingConfirmed,
  }) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? startTime;
  DateTime? endTime;

  Future<void> _confirmBooking() async {
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }

    if (endTime!.isBefore(startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(widget.parkingSpotId)
          .collection('spaces')
          .doc(widget.spaceId)
          .update({
        'isAvailable': false,
        'reservedAt': Timestamp.fromDate(startTime!),
        'endTime': Timestamp.fromDate(endTime!),
        'userId': user.uid,
      });

      // Trigger the callback
      widget.onBookingConfirmed();

      // Navigate to ViewStream page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewStream(
            parkingSpotId: widget.parkingSpotId,
            spaceId: widget.spaceId,
          ),
        ),
      );
    } catch (e) {
      print('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text('Book Space ${widget.spaceId}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Select Start Time'),
              subtitle: startTime != null ? Text('$startTime') : null,
              trailing: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selected != null) {
                    setState(() {
                      startTime = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        selected.hour,
                        selected.minute,
                      );
                    });
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Select End Time'),
              subtitle: endTime != null ? Text('$endTime') : null,
              trailing: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selected != null) {
                    setState(() {
                      endTime = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        selected.hour,
                        selected.minute,
                      );
                    });
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: _confirmBooking,
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
