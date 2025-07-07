import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uber/auth/login_screen.dart';
import 'package:uber/auth/signup_screen.dart';
import 'package:uber/pages/home_page.dart';
import 'package:uber/pages/permission.dart';
import 'package:uber/pages/slapsh_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uber Clone',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: Colors.black),
      home: const SplashScreen(),
    );
  }
}
