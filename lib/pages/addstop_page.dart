import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uber/pages/reserve_page.dart';

class AddStopMapPage extends StatefulWidget {
  const AddStopMapPage({super.key});

  @override
  State<AddStopMapPage> createState() => _AddStopMapPageState();
}

class _AddStopMapPageState extends State<AddStopMapPage> {
  late GoogleMapController mapController;
  LatLng center = const LatLng(23.0225, 72.5714); // Ahmedabad
  final String goMapApiKey = 'AlzaSyAjKvMppyRsPvWPvRlj_KKZRKoYAtp9QnI';

  final TextEditingController stop1Controller = TextEditingController(
    text: "Ahmedabad",
  );
  final TextEditingController stop2Controller = TextEditingController();
  final TextEditingController stop3Controller = TextEditingController();

  List<dynamic> suggestions = [];
  int activeFieldIndex = 1;

  bool showStop3 = true; // control whether 3rd stop is visible

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final url =
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
    if (activeFieldIndex == 1) {
      stop1Controller.text = description;
    } else if (activeFieldIndex == 2) {
      stop2Controller.text = description;
    } else {
      stop3Controller.text = description;
    }
    FocusScope.of(context).unfocus();
    setState(() => suggestions = []);
  }

  void _setMapStyle() async {
    String style = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style_dark.json');
    mapController.setMapStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top container with fields
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    padding: EdgeInsets.zero,

                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => ReserveScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // All fields inside one black container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildStopField("Pickup Location", stop1Controller, 1),
                        const SizedBox(height: 10),
                        _buildStopField("Add a stop", stop2Controller, 2),
                        const SizedBox(height: 10),
                        if (showStop3)
                          _buildStopFieldWithRemove(
                            "Add a stop",
                            stop3Controller,
                            3,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Map and suggestion list
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: center,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                      _setMapStyle();
                    },
                    onCameraMove: (position) {
                      center = position.target;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                  ),

                  const Center(
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.redAccent,
                    ),
                  ),

                  if (suggestions.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.black87,
                        child: ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            return ListTile(
                              tileColor: Colors.grey[850],
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
                              onTap:
                                  () => onSuggestionTap(
                                    suggestion['description'],
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopField(
    String hint,
    TextEditingController controller,
    int fieldIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        onTap: () {
          setState(() => activeFieldIndex = fieldIndex);
        },
        onChanged: (value) {
          setState(() => activeFieldIndex = fieldIndex);
          fetchSuggestions(value);
        },
      ),
    );
  }

  Widget _buildStopFieldWithRemove(
    String hint,
    TextEditingController controller,
    int fieldIndex,
  ) {
    return Row(
      children: [
        Expanded(child: _buildStopField(hint, controller, fieldIndex)),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            setState(() {
              showStop3 = false;
              stop3Controller.clear();
            });
          },
        ),
      ],
    );
  }
}
