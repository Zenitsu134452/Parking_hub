import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  String name = "User";
  String email = "";
  String phone = "";
  String vehicleNumber = "";
  String vehicleType = "";

  UserProvider() {
    _initializeUser();
  }

  // Initialize user data when the provider is created
  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadUserData(user.uid);
    }
  }

  // Load user profile data for the current user
  void loadUserData(String userId) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection("park_users")
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        name = data["name"] ?? "User";
        email = data["email"] ?? "";
        phone = data["phone"] ?? "";
        vehicleNumber = data["vehicle_number"] ?? "";
        vehicleType = data["vehicle_type"] ?? "";
      } else {
        resetUserData();
      }
      notifyListeners();
    });
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection("park_users").doc(user.uid);

      try {
        // Check if the document exists
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          // If document exists, update it
          await docRef.update(updatedData);
        } else {
          // If document doesn't exist, create it with the updated data
          await docRef.set(updatedData);
        }
      } catch (e) {
        print("Error updating user data: $e");
        throw e;
      }
    }
  }


  // Reset user data (used during logout)
  void resetUserData() {
    name = "User";
    email = "";
    phone = "";
    vehicleNumber = "";
    vehicleType = "";
    notifyListeners();
  }

  // Clear the Firestore subscription
  void cancelProvider() {
    _userSubscription?.cancel();
  }

  @override
  void dispose() {
    cancelProvider();
    super.dispose();
  }
}
