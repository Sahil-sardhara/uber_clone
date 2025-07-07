import 'package:flutter/material.dart';
import 'package:uber/pages/intercity_page.dart';
import 'package:uber/pages/rentals_page.dart';
import 'package:uber/pages/reserve_page.dart';
import 'package:uber/pages/services_page.dart';
import 'mapsearch_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> recentPlaces = [
      {
        'title': 'CEPT University',
        'subtitle': 'Kasturbhai Lalbhai Campus, University Rd',
      },
      {
        'title': 'Chimanlal Girdharlal Road',
        'subtitle': 'Ellisbridge, Ahmedabad',
      },
    ];

    final List<Map<String, dynamic>> suggestions = [
      {'icon': Icons.directions_car, 'label': 'Trip', 'promo': true},
      {'icon': Icons.calendar_month, 'label': 'Reserve', 'promo': true},
      {'icon': Icons.car_rental, 'label': 'Rentals', 'promo': false},
      {'icon': Icons.luggage, 'label': 'Intercity', 'promo': false},
    ];

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                "Uber",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Search Bar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapSearchScreen()),
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

            // Recent Places
            ...recentPlaces.map(
              (place) => ListTile(
                leading: const Icon(Icons.access_time, color: Colors.white70),
                title: Text(
                  place['title']!,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  place['subtitle']!,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),

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
                      if (item['label'] == 'Trip') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapSearchScreen(),
                          ),
                        );
                      } else if (item['label'] == 'Rentals') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RentalsScreen(),
                          ),
                        );
                      } else if (item['label'] == 'Reserve') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReserveScreen(),
                          ),
                        );
                      } else if (item['label'] == 'Intercity') {
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
                            item['label'],
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
