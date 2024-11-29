import 'dart:async';
import 'package:easy_map/views/booking_page.dart';
import 'package:easy_map/views/parking_slot_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as user_location; // Alias for user location package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart' as geocoding; // Alias for geocoding package
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

import '../controllers/db_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  user_location.LocationData? _currentLocation;
  final user_location.Location _locationService = user_location.Location();
  List<Map<String, dynamic>> parkingSpots = [];

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.61360707246554, 77.2127014771071),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _fetchParkingSpots();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) return;
      }

      user_location.PermissionStatus permissionGranted =
      await _locationService.hasPermission();
      if (permissionGranted == user_location.PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != user_location.PermissionStatus.granted) return;
      }

      _currentLocation = await _locationService.getLocation();

      // Move the map's camera to the current location
      if (_currentLocation != null) {
        final GoogleMapController mapController = await _controller.future;
        mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          ),
        );
      }

      setState(() {}); // Refresh the UI
    } catch (e) {
      print('Error fetching location: $e');
    }
  }


// Fetch parking spots and their spaces count
  Future<void> _fetchParkingSpots() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('parking_spots').get();
      List<Map<String, dynamic>> spotsWithSpaces = [];

      for (var doc in snapshot.docs) {
        int spacesCount = await DbService().getSpacesCount(doc.id);

        // Convert position to LatLng
        final positionMap = doc['position'];
        LatLng position = LatLng(positionMap['latitude'], positionMap['longitude']);

        spotsWithSpaces.add({
          'id': doc.id,
          'name': doc['name'],
          'spaces': spacesCount,
          'position': position,
          'image': doc['image'],// Ensure position is a LatLng object
        });
      }

      setState(() {
        parkingSpots = spotsWithSpaces;
      });
    } catch (e) {
      print('Error fetching parking spots: $e');
    }
  }



  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Radius of the Earth in km
    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLon = _degreesToRadians(end.longitude - start.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // Distance in km
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  Future<String> _getPlaceName(LatLng position) async {
    try {
      final List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final geocoding.Placemark place = placemarks.first;
        return "${place.name}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print('Error fetching place name: $e');
    }
    return "Unknown Location";
  }

  void _showBottomSheet(Map<String, dynamic> spot) async {
    final String placeName = await _getPlaceName(spot['position']);

    print('Spot Data: $spot');
    print('Image URL: ${spot['image']}');
    final LatLng currentLatLng = LatLng(
      _currentLocation?.latitude ?? 0.0,
      _currentLocation?.longitude ?? 0.0,
    );
    final double distance = _calculateDistance(currentLatLng, spot['position']);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spot Name
                Center(
                  child: Text(
                    spot['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Spot Details
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Place: $placeName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.map, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordinates: (${spot['position'].latitude.toStringAsFixed(4)}, ${spot['position'].longitude.toStringAsFixed(4)})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_seat, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Available Spaces: ${spot['spaces']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Distance: ${distance.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Spot Image
            Center(
              child: spot['image'] != null && spot['image'].toString().isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  Uri.encodeFull(spot['image']), // Ensure proper URL encoding
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error'); // Debugging print
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Error loading image',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
                  : Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No image available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
                // Buttons
                ElevatedButton.icon(
                  onPressed: () => _navigateToParkingSpot(spot['position']),
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 13),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParkingSlotScreen(
                          parkingSpotId: spot['id'], // Pass ID dynamically
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.book_online, color: Colors.white),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 13),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _navigateToParkingSpot(LatLng destination) async {
    final String googleMapsUrl = 'google.navigation:q=${destination.latitude},${destination.longitude}';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng currentLatLng = LatLng(
      _currentLocation?.latitude ?? 0.0,
      _currentLocation?.longitude ?? 0.0,
    );

    // Sort parkingSpots by distance
    parkingSpots.sort((a, b) {
      final double distanceA = _calculateDistance(currentLatLng, a['position']);
      final double distanceB = _calculateDistance(currentLatLng, b['position']);
      return distanceA.compareTo(distanceB);
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        backgroundColor: Colors.lightBlueAccent.shade100,
        title: Center(
          child: ImageIcon(
            AssetImage('assets/images/Black.png'),
            size: 200, // Adjust the size as needed
            color: Colors.black, // Optional: apply a color filter
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.lightBlue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GoogleMap(
                initialCameraPosition: _currentLocation != null
                    ? CameraPosition(
                  target: LatLng(
                    _currentLocation!.latitude!,
                    _currentLocation!.longitude!,
                  ),
                  zoom: 14,
                )
                    : _defaultPosition,
                myLocationEnabled: true,
                markers: {
                  if (_currentLocation != null)
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                  ...parkingSpots.map((spot) {
                    return Marker(
                      markerId: MarkerId(spot['id']),
                      position: spot['position'],
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      onTap: () => _showBottomSheet(spot),
                    );
                  }),
                },
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          itemCount: parkingSpots.length,
          itemBuilder: (context, index) {
            final spot = parkingSpots[index];
            final double distance = _calculateDistance(
              currentLatLng,
              spot['position'],
            );

            // StreamBuilder for real-time updates
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('parking_spots')
                    .doc(spot['id'])
                    .collection('spaces')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ListTile(
                      title: Text('Loading...'),
                      subtitle: Text('Fetching data...'),
                    );
                  }

                  final documents = snapshot.data!.docs;
                  final int totalSpaces = documents.length; // Total spaces
                  final int occupiedSpaces = documents
                      .where((doc) =>
                  (doc['isAvailable'] != null && !doc['isAvailable']))
                      .length; // Count where isAvailable is false
                  final int unoccupiedSpaces = totalSpaces - occupiedSpaces;

                  return ListTile(
                    title: Text(spot['name']),
                    subtitle: Text(
                      'Total Spaces: $totalSpaces | Occupied: $occupiedSpaces | Unoccupied: $unoccupiedSpaces | Distance: ${distance.toStringAsFixed(2)} km',
                      style: const TextStyle(color: Colors.green),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _showBottomSheet(spot),
                  );
                },
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