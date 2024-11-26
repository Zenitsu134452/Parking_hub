import 'package:easy_map/views/home_nav.dart';
import 'package:easy_map/views/login.dart';
import 'package:easy_map/views/signup.dart';
import 'package:easy_map/views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'controllers/auth_service.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Parking',
      debugShowCheckedModeBanner:false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
        routes: {
          "/":(context)=> SplashScreen(),
          "/login":(context)=>const LoginPage(),
          "/home":(context)=>const HomeNav(),
          "/signup":(context)=>const SignupPage(),
        }
    );
  }
}





