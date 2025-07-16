import 'package:flutter/material.dart';
import 'package:uber/pages/home_page.dart';
import 'package:uber/pages/intercity_page.dart';
import 'package:uber/pages/rentals_page.dart';
import 'package:uber/pages/reserve_page.dart';
import 'package:uber/pages/services_page.dart';
import 'courier_ride_bottom_sheet.dart';
import 'mapsearch_page.dart';

class ParcelHomePage extends StatefulWidget {
  const ParcelHomePage({super.key});

  @override
  State<ParcelHomePage> createState() => _ParcelHomePageState();
}

class _ParcelHomePageState extends State<ParcelHomePage> {
  String selectedMode = "Parcel";

  void onToggle(String mode) {
    if (mode == "Driver") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(initialMode: "Driver"),
        ),
      );
    }
  }

  final List<Map<String, dynamic>> suggestions = [
    {'icon': Icons.directions_car, 'label': 'Trip', 'promo': true},
    {'icon': Icons.calendar_month, 'label': 'Reserve', 'promo': true},
    {'icon': Icons.car_rental, 'label': 'Rentals', 'promo': false},
    {'icon': Icons.luggage, 'label': 'Intercity', 'promo': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                "Movana",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Toggle Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children:
                    ["Driver", "Parcel"].map((mode) {
                      final bool isSelected = selectedMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onToggle(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.white : Colors.grey[900],
                              borderRadius: BorderRadius.circular(30),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : [],
                            ),
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              child: Text(mode),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Search Bar
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapSearchScreen(mode: 'Parcel'),
                  ),
                );
              },

              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Enter pick-up location",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Suggestions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Suggestions",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ServicesPage()),
                      );
                    },
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Suggestions Scroll
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return GestureDetector(
                    onTap: () {
                      final label = item['label'];
                      if (label == 'Trip') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapSearchScreen(mode: ''),
                          ),
                        );
                      } else if (label == 'Rentals') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RentalsScreen(),
                          ),
                        );
                      } else if (label == 'Reserve') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReserveScreen(),
                          ),
                        );
                      } else if (label == 'Intercity') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IntercityTripPage(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item['promo'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Promo",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Icon(item['icon'], color: Colors.white),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
