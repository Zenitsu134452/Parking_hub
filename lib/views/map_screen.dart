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
          'position': position, // Ensure position is a LatLng object
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot['name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Place: $placeName',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coordinates: (${spot['position'].latitude}, ${spot['position'].longitude})',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available Spaces: ${spot['spaces']}',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance: ${distance.toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToParkingSpot(spot['position']),
                  child: const Text('Navigate to Parking Spot'),
                ),
                const SizedBox(height: 16),
                spot['image'] != null
                    ? Image.network(
                  spot['image'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : const Text('No image available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Implement booking logic here
                    ///Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(parkingSpotId:spot['id'],parkingSpotName: spot['name']??'Unnamed Spot', parkingImage: spot['image']??'')));
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ParkingSlotScreen(
                        parkingSpotId: spot['id'], // Pass ID dynamically
                      ),
                    ));
                  },
                  child: const Text('Book Now'),
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
        backgroundColor: Colors.green.shade100,
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