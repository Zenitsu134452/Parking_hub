import 'package:flutter/material.dart';
import '../controllers/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn(); // Check user login state
  }

  Future<void> _checkUserLoggedIn() async {
    try {
      // Simulate a delay for the splash screen
      await Future.delayed(Duration(seconds: 3));

      // Check login state
      bool isLoggedIn = await AuthService().isLoggedIn();
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      // Log the error and stay on the splash screen
      print("Error during navigation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageIcon(
            AssetImage('assets/images/Black.png'),
        size: 300, // Adjust the size as needed
        color: Colors.black, // Optional: apply a color filter
      ),
            CircularProgressIndicator(), // Loading animation
          ],
        ),
      ),
    );
  }
}
