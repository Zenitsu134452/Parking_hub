import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimerScreen extends StatefulWidget {
  final String parkingSpotId;
  final String spaceId;
  final DateTime startTime;
  final DateTime endTime;

  const TimerScreen({
    Key? key,
    required this.parkingSpotId,
    required this.spaceId,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.endTime.difference(DateTime.now());
    _startTimer();

    FirebaseFirestore.instance
        .collection('parking_spots')
        .doc(widget.parkingSpotId)
        .collection('spaces')
        .doc(widget.spaceId)
        .update({'isAvailable': false});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _remainingTime - const Duration(seconds: 1);
      });

      if (_remainingTime.isNegative) {
        _timer.cancel();
        _endTimer();
      }
    });
  }

  Future<void> _endTimer() async {
    await FirebaseFirestore.instance
        .collection('parking_spots')
        .doc(widget.parkingSpotId)
        .collection('spaces')
        .doc(widget.spaceId)
        .update({'isAvailable': true});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your advance booking has ended')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Timer')),
      body: Center(
        child: _remainingTime.isNegative
            ? const Text('Booking has ended')
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your advance booking is active!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Time Remaining: ${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
