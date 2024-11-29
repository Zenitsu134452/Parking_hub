import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewStream extends StatefulWidget {
  final String parkingSpotId;
  final String spaceId;

  const ViewStream({
    Key? key,
    required this.parkingSpotId,
    required this.spaceId,
  }) : super(key: key);

  @override
  State<ViewStream> createState() => _ViewStreamState();
}

class _ViewStreamState extends State<ViewStream> {
  bool isAvailable = false;
  Timer? timer;
  Duration? remainingTime;

  // Store the URL for real-time parking space image
  String? parkingImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchSpaceDetails();
    _fetchRealTimeImage();
  }

  Future<void> _fetchSpaceDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('parking_spots')
        .doc(widget.parkingSpotId)
        .collection('spaces')
        .doc(widget.spaceId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        final endTime = (data['endTime'] as Timestamp?)?.toDate();
        if (endTime != null) {
          setState(() {
            isAvailable = false;
            remainingTime = endTime.difference(DateTime.now());
          });
          _startTimer();
        } else {
          setState(() {
            isAvailable = true;
          });
        }
      }
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (remainingTime != null) {
          remainingTime = remainingTime! - const Duration(seconds: 1);
          if (remainingTime!.inSeconds <= 0) {
            timer?.cancel();
            _makeSpaceAvailable();
          }
        }
      });
    });
  }

  Future<void> _makeSpaceAvailable() async {
    await FirebaseFirestore.instance
        .collection('parking_spots')
        .doc(widget.parkingSpotId)
        .collection('spaces')
        .doc(widget.spaceId)
        .update({'isAvailable': true});

    setState(() {
      isAvailable = true;
    });
  }

  Future<void> _fetchRealTimeImage() async {
    // Construct the URL for the Flask API with a unique timestamp query parameter
    String url =
        'https://1b44-14-139-239-130.ngrok-free.app/stream_spot/${widget.spaceId}?t=${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      parkingImageUrl = url; // Update the image URL with the timestamp
    });
  }

  Future<void> _endBooking() async {
    try {
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(widget.parkingSpotId)
          .collection('spaces')
          .doc(widget.spaceId)
          .update({
        'isAvailable': true,
        'endTime': null,
        'reservedAt': null,
        'userId': null,
      });
      setState(() {
        isAvailable = true;
        remainingTime = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking ended successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending booking: $e')),
      );
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
      appBar: AppBar(title: const Text('View Stream')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              color: isAvailable ? Colors.green : Colors.red,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAvailable ? 'Space Available' : 'Space Occupied',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  if (!isAvailable && remainingTime != null)
                    Text(
                      'Time Remaining: ${remainingTime!.inMinutes}:${(remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (parkingImageUrl != null)
              Image.network(
                parkingImageUrl!,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Error loading stream.');
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchRealTimeImage,
              child: const Text('Refresh Image'),
            ),
            const SizedBox(height: 10),
            if (!isAvailable)
              ElevatedButton(
                onPressed: _endBooking,
                child: const Text('End Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
