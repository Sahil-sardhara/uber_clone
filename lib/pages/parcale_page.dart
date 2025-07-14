import 'package:flutter/material.dart';

class ParcelHomePage extends StatelessWidget {
  const ParcelHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Closes the screen
          },
        ),
      ),
      body: const Center(
        child: Text(
          'Parcel Home Page',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
