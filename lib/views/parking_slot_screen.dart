import 'dart:async';
import 'dart:typed_data'; // For handling byte data
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'advance_upcoming.dart';
import 'booking_page.dart';

class ParkingSlotScreen extends StatefulWidget {
  final String parkingSpotId;

  const ParkingSlotScreen({Key? key, required this.parkingSpotId}) : super(key: key);

  @override
  State<ParkingSlotScreen> createState() => _ParkingSlotScreenState();
}

class _ParkingSlotScreenState extends State<ParkingSlotScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<QuerySnapshot> _spaceSubscription;
  List<Map<String, dynamic>> parkingSpaces = [];
  Uint8List? parkingImage; // To store the image data from the Flask server

  @override
  void initState() {
    super.initState();
    _startListeningToSpaces();
    _fetchParkingImage(); // Fetch the parking lot image on screen load
  }

  void _startListeningToSpaces() {
    // Real-time listener for Firestore changes
    _spaceSubscription = FirebaseFirestore.instance
        .collection('parking_spots')
        .doc(widget.parkingSpotId)
        .collection('spaces')
        .snapshots()
        .listen((snapshot) {
      // Extracting data from Firestore snapshot
      final spaces = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'isAvailable': data['isAvailable'] ?? true,
          'endTime': data['endTime'],
        };
      }).toList();

      // Updating state to reflect changes in real time
      setState(() {
        parkingSpaces = spaces;
      });
    });
  }

  Future<void> _fetchParkingImage() async {
    const String imageUrl = 'https://3ceb-14-139-239-130.ngrok-free.app/parking_image'; // Replace with your Flask server URL
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          parkingImage = response.bodyBytes; // Store the image data
        });
      } else {
        throw 'Failed to load image';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching parking lot image: $e')),
      );
    }
  }

  @override
  void dispose() {
    _spaceSubscription.cancel();
    super.dispose();
  }

  void _showBottomSheet(BuildContext context, Map<String, dynamic> space) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Book Now'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                _handleBookNow(space); // Handle booking
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Advance Booking'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvanceUpcoming(
                      parkingSpotId: widget.parkingSpotId,
                      spaceId: space['id'],
                    ),
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Advance Booking feature coming soon!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleBookNow(Map<String, dynamic> space) async {
    final isAvailable = space['isAvailable'];
    if (isAvailable) {
      // Navigate to the booking page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingPage(
            parkingSpotId: widget.parkingSpotId,
            spaceId: space['id'],
            onBookingConfirmed: () async {
              // Update Firestore to mark the space as unavailable
              await FirebaseFirestore.instance
                  .collection('parking_spots')
                  .doc(widget.parkingSpotId)
                  .collection('spaces')
                  .doc(space['id'])
                  .update({'isAvailable': false});
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This space is already booked.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Slots')),
      body: Column(
        children: [
          if (parkingImage != null)
            Image.memory(parkingImage!), // Display the image if loaded
          if (parkingImage == null)
            const Center(child: CircularProgressIndicator()), // Show loader until image is loaded
          Expanded(
            child: parkingSpaces.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: parkingSpaces.length,
              itemBuilder: (context, index) {
                final space = parkingSpaces[index];
                final isAvailable = space['isAvailable'];

                return GestureDetector(
                  onTap: () => _showBottomSheet(context, space),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      'Space ${space['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
