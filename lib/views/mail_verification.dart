
import 'dart:async';
import 'package:flutter/material.dart';

import '../controllers/auth_service.dart';
import 'home_nav.dart';

class MailVerification extends StatefulWidget {
  const MailVerification({super.key});

  @override
  State<MailVerification> createState() => _MailVerificationState();
}

class _MailVerificationState extends State<MailVerification> {
  bool isEmailVerified = false;
  bool isLoading = false;
  Timer? verificationTimer;

  @override
  void initState() {
    super.initState();
    sendEmailVerification(); // Send verification email on screen load
    startVerificationCheck(); // Start timer to check email verification status
  }

  Future<void> sendEmailVerification() async {
    setState(() => isLoading = true);
    try {
      await AuthService().sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent. Please check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void startVerificationCheck() {
    verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool verified = await AuthService().isEmailVerified();
      if (verified) {
        setState(() {
          isEmailVerified = true;
        });
        verificationTimer?.cancel(); // Stop the timer once verified
      }
    });
  }

  @override
  void dispose() {
    verificationTimer?.cancel(); // Dispose the timer when widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Verify Your Email",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "We've sent a verification email to your address. "
                    "Please check your inbox and follow the instructions to verify your email.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : sendEmailVerification,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Resend Verification Email"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isEmailVerified
                    ? () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) =>const HomeNav()),
                  );
                }
                    : null,
                child: const Text("Proceed Once Verified"),
              ),
              if (!isEmailVerified)
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    "Note: This button will activate once your email is verified.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
