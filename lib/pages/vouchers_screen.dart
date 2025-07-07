// lib/vouchers_screen.dart
import 'package:flutter/material.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back arrow icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          "Vouchers",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for the voucher icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long, // A more suitable icon for vouchers
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "You currently have no vouchers",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Organisations can send you vouchers to pay for trips or meals.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              OutlinedButton.icon(
                onPressed: () {
                  // Handle "Learn more about vouchers" tap
                  print("Learn more about vouchers tapped");
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text("Learn more about vouchers"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}