import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Timer? timer;
  Duration? remainingTime;

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

      // Start the timer for the booking
      setState(() {
        remainingTime = endTime!.difference(DateTime.now());
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            remainingTime = remainingTime! - const Duration(seconds: 1);
            if (remainingTime!.inSeconds <= 0) {
              timer.cancel();
              remainingTime = null;
              _handleBookingExpiry();
            }
          });
        });
      });

      widget.onBookingConfirmed();
    } catch (e) {
      print('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleBookingExpiry() async {
    try {
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(widget.parkingSpotId)
          .collection('spaces')
          .doc(widget.spaceId)
          .update({
        'isAvailable': true,
        'userId': null,
        'reservedAt': null,
        'endTime': null,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking expired and space is now available')),
      );
    } catch (e) {
      print('Error updating space after expiry: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Space ${widget.spaceId}')),
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
            if (remainingTime != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Time Remaining: ${remainingTime!.inMinutes}:${(remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
