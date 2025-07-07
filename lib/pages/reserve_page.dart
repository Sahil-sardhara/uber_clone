import 'package:flutter/material.dart';
import 'package:uber/pages/reserve_trip.dart';

class ReserveScreen extends StatelessWidget {
  const ReserveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 280,
                color: Colors.white,
                child: Image.asset(
                  'assets/images/reserve.jpg', // ← Use your uploaded image here
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 45,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Uber Reserve',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ReserveFeature(
                  icon: Icons.schedule,
                  text: 'Choose your pick-up time days in advance',
                ),
                Divider(color: Colors.white24, height: 32),
                ReserveFeature(
                  icon: Icons.hourglass_empty,
                  text: 'Extra wait time included to meet your ride',
                ),
                Divider(color: Colors.white24, height: 32),
                ReserveFeature(
                  icon: Icons.menu,
                  text: 'Cancel at no charge up to 60 minutes in advance',
                ),
              ],
            ),
          ),

          const Spacer(),

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReserveTripPage()),
                );
              },
              child: const Text(
                'Reserve a trip',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReserveFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const ReserveFeature({super.key, required this.icon, required this.text});

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
