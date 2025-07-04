import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:uber/models/place_suggestion.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});
  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  GoogleMapController? _mapController;
  String _mapStyle = '';
  final pickupController = TextEditingController();
  final destinationController = TextEditingController();

  List<PlaceSuggestion> _suggestions = [];
  bool isExpanded = false;
  bool isPickupActive = true;

  double bottomSheetHeightFraction = 0.3;
  final double minHeight = 0.25;
  final double maxHeight = 0.6;

  final String _apiKey = "AlzaSyAjKvMppyRsPvWPvRlj_KKZRKoYAtp9QnI"; // Replace with GoMap Pro key

  final List<Map<String, String>> recentLocations = [
    {"main": "Home", "sub": "Shivranjani, Ahmedabad"},
    {"main": "Work", "sub": "CG Road, Ahmedabad"},
  ];

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

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

    final url = 'https://maps.gomaps.pro/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_apiKey'
        '&components=country:in';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<PlaceSuggestion> suggestions = (data['predictions'] as List)
              .map((item) => PlaceSuggestion.fromGoMap(item))
              .toList();
          setState(() {
            _suggestions = suggestions;
            isExpanded = true;
            bottomSheetHeightFraction = maxHeight;
          });
        }
      }
    } catch (e) {
      print("Suggestion error: $e");
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
    bool granted = await _handlePermission();
    if (!granted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Share Location"),
        content: const Text("Use your current location as pickup?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Position pos = await Geolocator.getCurrentPosition();
              _pickupLatLng = LatLng(pos.latitude, pos.longitude);
              pickupController.text = "Current Location";
              _mapController?.animateCamera(CameraUpdate.newLatLng(_pickupLatLng!));
              await _checkAndDrawRoute();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePosition() async => await _handlePermission();

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    if (address == "Current Location" && _pickupLatLng != null) return _pickupLatLng;

    final url = 'https://maps.gomaps.pro/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  Future<void> _checkAndDrawRoute() async {
    if (pickupController.text.isNotEmpty && destinationController.text.isNotEmpty) {
      await _drawRoute();
    }
  }

  Future<void> _drawRoute() async {
    final pickup = await _getLatLngFromAddress(pickupController.text);
    final dest = await _getLatLngFromAddress(destinationController.text);
    if (pickup == null || dest == null) return;

    final url = 'https://maps.gomaps.pro/maps/api/directions/json'
        '?origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&alternatives=true&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        Set<Polyline> polySet = {};
        for (int i = 0; i < data['routes'].length && i < 3; i++) {
          final points = data['routes'][i]['overview_polyline']['points'];
          final polylineCoordinates = _decodePolyline(points);
          polySet.add(Polyline(
            polylineId: PolylineId("route_$i"),
            color: i == 0 ? Colors.blue : i == 1 ? Colors.green : Colors.orange,
            width: 5,
            points: polylineCoordinates,
          ));
        }

        setState(() {
          _pickupLatLng = pickup;
          _destinationLatLng = dest;
          _polylines = polySet;
          _markers = {
            Marker(
              markerId: const MarkerId("pickup"),
              position: pickup,
              infoWindow: const InfoWindow(title: "Pickup"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
            Marker(
              markerId: const MarkerId("destination"),
              position: dest,
              infoWindow: const InfoWindow(title: "Destination"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
          _boundsFromLatLngs(pickup, dest),
          80,
        ));
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  LatLngBounds _boundsFromLatLngs(LatLng a, LatLng b) {
    return LatLngBounds(
      southwest: LatLng(a.latitude < b.latitude ? a.latitude : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude),
      northeast: LatLng(a.latitude > b.latitude ? a.latitude : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(23.0225, 72.5714), zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_mapStyle.isNotEmpty) {
                _mapController?.setMapStyle(_mapStyle);
              }
            },
            markers: _markers,
            polylines: _polylines,
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
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _shareLocation,
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text("Use Current Location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: const StadiumBorder(),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _bottomSheet(screenHeight),
          const Positioned(
            bottom: 10,
            right: 10,
            child: Text("Powered by GoMap Pro", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheet(double screenHeight) {
    return Positioned(
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
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  bottomSheetHeightFraction -= details.primaryDelta! / screenHeight;
                  bottomSheetHeightFraction = bottomSheetHeightFraction.clamp(minHeight, maxHeight);
                });
              },
              child: Container(
                width: 40,
                height: 6,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Plan your trip",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
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
                      ...recentLocations.map((loc) => ListTile(
                            leading: const Icon(Icons.history, color: Colors.white70),
                            title: Text(loc["main"]!, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(loc["sub"]!, style: const TextStyle(color: Colors.grey)),
                            onTap: () {
                              pickupController.text = loc["sub"]!;
                              _checkAndDrawRoute();
                              setState(() => isExpanded = true);
                            },
                          )),
                    if (_suggestions.isNotEmpty)
                      ..._suggestions.map((s) => ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: Colors.white70),
                            title: Text(s.mainText, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(s.secondaryText, style: const TextStyle(color: Colors.grey)),
                            onTap: () async {
                              if (isPickupActive) {
                                pickupController.text = s.description;
                              } else {
                                destinationController.text = s.description;
                              }
                              _collapseBottom();
                              await _checkAndDrawRoute();
                            },
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            onTap: () => setState(() {
              isExpanded = true;
              isPickupActive = true;
              bottomSheetHeightFraction = maxHeight;
            }),
            onChanged: (text) {
              _getPlaceSuggestions(text);
              _checkAndDrawRoute();
            },
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
            onTap: () => setState(() {
              isExpanded = true;
              isPickupActive = false;
              bottomSheetHeightFraction = maxHeight;
            }),
            onChanged: (text) {
              _getPlaceSuggestions(text);
              _checkAndDrawRoute();
            },
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
