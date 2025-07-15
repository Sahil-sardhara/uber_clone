import 'package:flutter/material.dart';
import 'package:uber/pages/account_page.dart';
import 'package:uber/pages/activity_page.dart';
import 'package:uber/pages/home_page.dart';
import 'package:uber/pages/services_page.dart';

class MainHomeWrapper extends StatefulWidget {
  const MainHomeWrapper({super.key});

  @override
  State<MainHomeWrapper> createState() => _MainHomeWrapperState();
}

class _MainHomeWrapperState extends State<MainHomeWrapper> {
  int _selectedIndex = 0;
  String _selectedMode = "Driver"; // Track the selected toggle mode

  void _changeMode(String mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(initialMode: _selectedMode, onModeChange: _changeMode),
      const ServicesPage(),
      const ActivityPage(),
      const AccountPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: "Services",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Account",
          ),
        ],
      ),
    );
  }
}
