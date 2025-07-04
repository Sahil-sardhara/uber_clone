import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:uber/global/global_var.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  String _mapStyle = '';
  final pickupController = TextEditingController();
  final destinationController = TextEditingController();

  List<dynamic> _suggestions = [];
  bool isExpanded = false;

  double bottomSheetHeightFraction = 0.3;
  final double minHeight = 0.25;
  final double maxHeight = 0.6;

  final String _apiKey = placeapikey;

  final List<Map<String, String>> recentLocations = [
    {"main": "Home", "sub": "Shivranjani, Ahmedabad"},
    {"main": "Work", "sub": "CG Road, Ahmedabad"},
  ];

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _determinePosition();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style_dark.json');
    setState(() {});
  }

  void _getPlaceSuggestions(String input) async {
    if (input.length < 2) {
      setState(() => _suggestions.clear());
      return;
    }

    setState(() => isExpanded = true);

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_apiKey'
        '&components=country:in';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = data['predictions'];
          });
        } else {
          print("Google API error: ${data['error_message']}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void _collapseBottom() {
    FocusScope.of(context).unfocus();
    setState(() {
      isExpanded = false;
      _suggestions.clear();
      bottomSheetHeightFraction = 0.3;
    });
  }

  Future<void> _shareLocation() async {
    bool permissionGranted = await _handlePermission();
    if (!permissionGranted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Share Location"),
        content: const Text("Do you want to share your current location?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Position pos = await Geolocator.getCurrentPosition();
              LatLng latLng = LatLng(pos.latitude, pos.longitude);
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(latLng),
              );
              pickupController.text = "Current Location";
              setState(() {});
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePosition() async {
    await _handlePermission();
  }

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(23.0225, 72.5714),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_mapStyle.isNotEmpty) {
                _mapController?.setMapStyle(_mapStyle);
              }
            },
            onTap: (_) => _collapseBottom(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _shareLocation,
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text("Share Location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Custom animated bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: screenHeight * bottomSheetHeightFraction,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        bottomSheetHeightFraction -=
                            details.primaryDelta! / screenHeight;
                        bottomSheetHeightFraction = bottomSheetHeightFraction
                            .clamp(minHeight, maxHeight);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 6,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Plan your trip",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _pickupField(),
                                const Divider(color: Colors.grey),
                                _locationField("Where to?", Icons.square_outlined),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!isExpanded)
                            Column(
                              children: recentLocations
                                  .map(
                                    (loc) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.history,
                                          color: Colors.white70),
                                      title: Text(
                                        loc["main"]!,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        loc["sub"]!,
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),
                                      onTap: () {
                                        pickupController.text = loc["sub"]!;
                                        setState(() => isExpanded = true);
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          if (isExpanded && _suggestions.isNotEmpty)
                            ..._suggestions.map(
                              (s) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.location_on_outlined,
                                    color: Colors.white70),
                                title: Text(
                                  s['structured_formatting']['main_text'],
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  s['structured_formatting']
                                          ['secondary_text'] ??
                                      '',
                                  style:
                                      const TextStyle(color: Colors.grey),
                                ),
                                onTap: () {
                                  pickupController.text = s['description'];
                                  _collapseBottom();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickupField() {
    return Row(
      children: [
        const Icon(Icons.circle_outlined, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: pickupController,
            onTap: () => setState(() => isExpanded = true),
            onChanged: _getPlaceSuggestions,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter pick-up",
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationField(String hint, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: destinationController,
            onTap: () => setState(() => isExpanded = true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
