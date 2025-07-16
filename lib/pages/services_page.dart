import 'package:flutter/material.dart';
import 'package:uber/pages/intercity_page.dart';
import 'package:uber/pages/main_home_wrapper.dart';
import 'package:uber/pages/rentals_page.dart';
import 'package:uber/pages/reserve_page.dart';
import 'package:uber/pages/mapsearch_page.dart';
import 'package:uber/pages/teens_page.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'label': 'Trip',
        'icon': Icons.directions_car,
        'promo': true,
        'page': const MapSearchScreen(mode: '',),
      },
      {
        'label': 'Rentals',
        'icon': Icons.car_rental,
        'promo': false,
        'page': const RentalsScreen(),
      },
      {
        'label': 'Reserve',
        'icon': Icons.calendar_month,
        'promo': true,
        'page': const ReserveScreen(),
      },
      {
        'label': 'Intercity',
        'icon': Icons.luggage,
        'promo': false,
        'page': const IntercityTripPage(),
      },
      {
        'label': 'Teens',
        'icon': Icons.school,
        'promo': false,
        'page': const AddTeenPage(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Services',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Go anywhere, get anything',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => service['page']),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (service['promo'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              margin: const EdgeInsets.only(bottom: 6),
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
                          Icon(service['icon'], size: 32, color: Colors.white),
                          const SizedBox(height: 6),
                          Text(
                            service['label'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
