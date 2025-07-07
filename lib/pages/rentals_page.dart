import 'package:flutter/material.dart';

class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top Back Arrow and Illustration
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.white,
                child: Image.asset(
                  'assets/images/car_rent.jpg', // Replace with your actual image asset
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 45,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black,

                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Uber Rentals Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Uber Rentals',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Features List
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                RentalFeature(
                  icon: Icons.hourglass_empty,
                  text: 'Keep a car and driver for up to 12 hours',
                ),
                SizedBox(height: 16),
                RentalFeature(
                  icon: Icons.business_center,
                  text:
                      'Ideal for business meetings, tourist travel and multiple stop trips',
                ),
                SizedBox(height: 16),
                RentalFeature(
                  icon: Icons.schedule,
                  text: 'Book for now or reserve for later',
                ),
              ],
            ),
          ),

          const Spacer(),

          // Get Started Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Get started',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RentalFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const RentalFeature({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
