import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uber/pages/addstop_page.dart';

class ReserveTripPage extends StatefulWidget {
  const ReserveTripPage({super.key});

  @override
  State<ReserveTripPage> createState() => _ReserveTripPageState();
}

class _ReserveTripPageState extends State<ReserveTripPage> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropoffController = TextEditingController();
  List<dynamic> suggestions = [];

  bool isTypingPickup = true;

  final String goMapApiKey =
      'AlzaSyAjKvMppyRsPvWPvRlj_KKZRKoYAtp9QnI'; // Replace with your GoMap key

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final String url =
        'https://maps.gomaps.pro/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$goMapApiKey&components=country:in';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'OK') {
      setState(() {
        suggestions = data['predictions'];
      });
    } else {
      setState(() => suggestions = []);
    }
  }

  void onSuggestionTap(String description) {
    if (isTypingPickup) {
      pickupController.text = description;
    } else {
      dropoffController.text = description;
    }
    setState(() => suggestions = []);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 80),
                  const Text(
                    'Reserve a trip',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Input fields + centered circular "+" button below them
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputField(
                    "Pickup Location",
                    pickupController,
                    onChanged: (value) {
                      setState(() => isTypingPickup = true);
                      fetchSuggestions(value);
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    "Where to?",
                    dropoffController,
                    onChanged: (value) {
                      setState(() => isTypingPickup = false);
                      fetchSuggestions(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Centered circular "+" button with black background and simple navigation logic
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddStopMapPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Suggestions or Saved Places
            if (suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return ListTile(
                      tileColor: Colors.grey[900],
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                      ),
                      title: Text(
                        suggestion['structured_formatting']['main_text'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        suggestion['structured_formatting']['secondary_text'] ??
                            '',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      onTap: () => onSuggestionTap(suggestion['description']),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        "⭐ Saved places",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    _buildSavedPlace(
                      "Nikol",
                      "Ahmedabad, Gujarat",
                      Icons.access_time,
                    ),
                    _buildSavedPlace(
                      "CEPT University",
                      "University Rd, Navrangpura",
                      Icons.access_time,
                    ),
                    _buildSavedPlace(
                      "Chimanlal Girdharlal Rd",
                      "Ellisbridge, Ahmedabad",
                      Icons.access_time,
                    ),
                    _buildSavedPlace(
                      "Indus University",
                      "Rancharda, Shilaj, Gujarat",
                      Icons.access_time,
                    ),
                    _buildSavedPlace(
                      "Sardar Vallabhbhai Patel International Airport",
                      "Hansol, Ahmedabad",
                      Icons.location_on,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    required Function(String) onChanged,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSavedPlace(String title, String subtitle, IconData icon) {
    return ListTile(
      tileColor: Colors.black,
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      onTap: () => onSuggestionTap(title),
    );
  }
}
