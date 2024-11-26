import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class UserProvider extends ChangeNotifier {
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  String name = "User";
  String email = "";
  String address = "";
  String phone = "";
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
        .collection("shop_users")
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        name = data["name"] ?? "User";
        email = data["email"] ?? "";
        address = data["address"] ?? "";
        phone = data["phone"] ?? "";
      } else {
        resetUserData();
      }
      notifyListeners();
    });
  }

  // Reset user data (used during logout)
  void resetUserData() {
    name = "User";
    email = "";
    address = "";
    phone = "";
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
