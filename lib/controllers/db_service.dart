import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class DbService {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //USER DATA
  // add the user to firestore
//save user data after creating new account
  Future saveUserData({required String name, required String email}) async {
    try {
      Map<String, dynamic> data = {
        "name": name,
        "email": email,
        "phone": "",
        "vehicle_number": "",
        "vehicle_type": "",
      };
      await FirebaseFirestore.instance
          .collection("park_users")
          .doc(user!.uid)
          .set(data);
    } catch (e) {
      print("Error saving user data: $e");
    }
  }


  //update other data in database
  Future updateUserData({required Map<String, dynamic> extraData}) async {
    try {
      await FirebaseFirestore.instance
          .collection("park_users")
          .doc(user!.uid)
          .update(extraData);
    } catch (e) {
      print("Error updating user data: $e");
    }
  }

  //read User current user data
  Stream<DocumentSnapshot> readUserData() {
    return FirebaseFirestore.instance
        .collection("park_users")
        .doc(user!.uid)
        .snapshots();
  }
// parking slots
// Fetch all parking spots
  // Fetch parking spaces for a spot
  Future<List<Map<String, dynamic>>> fetchParkingSpots() async {
    List<Map<String, dynamic>> parkingSpots = [];
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('parking_spots').get();
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        QuerySnapshot spacesSnapshot = await FirebaseFirestore.instance
            .collection('parking_spots')
            .doc(doc.id)
            .collection('spaces')
            .get();

        int totalSpaces = spacesSnapshot.docs.length;
        int availableSpaces = spacesSnapshot.docs
            .where((space) => (space.data() as Map<String, dynamic>)['isAvailable'] == true)
            .length;

        parkingSpots.add({
          'id': doc.id,
          'name': data['name'],
          'image': data['image'],
          'position': data['position'],
          'totalSpaces': totalSpaces,
          'availableSpaces': availableSpaces,
        });
      }
    } catch (e) {
      print('Error fetching parking spots: $e');
    }
    return parkingSpots;
  }

  // Inside DbService class in db_service.dart
  Future<int> getSpacesCount(String parkingSpotId) async {
    try {
      final spacesSnapshot = await _firestore
          .collection('parking_spots')
          .doc(parkingSpotId)
          .collection('spaces')
          .get();
      return spacesSnapshot.docs.length;
    } catch (e) {
      print('Error fetching spaces count: $e');
      return 0;
    }
  }


// Update parking spaces for a spot
  Future<void> updateParkingSpaces(String spotId, int newSpaces) async {
    await FirebaseFirestore.instance.collection('parking_spots').doc(spotId).update({
      'spaces': newSpaces,
    });
  }




}
