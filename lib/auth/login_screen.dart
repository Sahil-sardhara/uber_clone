import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uber/auth/signup_screen.dart';
import 'package:uber/global/global_var.dart';
import 'package:uber/methods/common_methods.dart';
import 'package:uber/pages/home_page.dart';
import 'package:uber/widget/loading_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailTexteditingController = TextEditingController();
  final passwordTexteditingController = TextEditingController();

  CommonMethod cmethod = CommonMethod();

  bool _obscurePassword = true;

  void validateAndLogin() async {
    bool isConnected = await cmethod.checkConnectivity(context);
    if (!isConnected) return;

    if (_formKey.currentState!.validate()) {
      signInuser();
    }
  }

  signInuser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) =>
              LoadingBar(messagetext: "Allowing you to Login..."),
    );

    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailTexteditingController.text.trim(),
            password: passwordTexteditingController.text.trim(),
          );

      final User? userFirebase = credential.user;

      if (!context.mounted) return;
      Navigator.pop(context);

      if (userFirebase != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(userFirebase.uid);

        final snapshot = await userRef.once();

        if (snapshot.snapshot.value != null) {
          final userData = snapshot.snapshot.value as Map;

          if (userData["blockedstatus"] == "No") {
            username = userData["name"];
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 600),
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const HomePage(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  final fade = Tween(begin: 0.0, end: 1.0).animate(animation);
                  return FadeTransition(opacity: fade, child: child);
                },
              ),
            );
          } else {
            await FirebaseAuth.instance.signOut();
            cmethod.displaySnackbar(
              "You are blocked. Please contact the admin.",
              context,
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          cmethod.displaySnackbar("Your record does not exist.", context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);

      print("🔥 FirebaseAuthException code: ${e.code}");

      String errorMessage = "Login failed. Please try again.";

      switch (e.code) {
        case 'invalid-email':
        case 'ERROR_INVALID_EMAIL':
          errorMessage = "The email address is not valid.";
          break;
        case 'user-not-found':
        case 'ERROR_USER_NOT_FOUND':
          errorMessage = "No user found with this email.";
          break;
        case 'wrong-password':
        case 'invalid-credential':
        case 'ERROR_WRONG_PASSWORD':
          errorMessage = "Invalid email or password.";
          break;
        case 'user-disabled':
        case 'ERROR_USER_DISABLED':
          errorMessage = "This user account has been disabled.";
          break;
      }

      cmethod.displaySnackbar(errorMessage, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        margin: EdgeInsets.all(10).copyWith(top: 70),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Image.asset("assets/images/login_photo.png"),
                Text(
                  "Login to Your Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailTexteditingController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(fontSize: 14),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                                ).hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: passwordTexteditingController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(fontSize: 14),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: validateAndLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 15,
                            ),
                          ),
                          child: Text("Login"),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an Account? Register here",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
