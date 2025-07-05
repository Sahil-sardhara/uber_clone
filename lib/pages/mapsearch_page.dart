// All same imports
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

  double bottomSheetHeightFraction = 0.4;
  final double minHeight = 0.25;
  final double normalHeight = 0.4;
  final double maxHeight = 0.6;

  final String _apiKey = "AlzaSyAjKvMppyRsPvWPvRlj_KKZRKoYAtp9QnI";

  final List<Map<String, String>> recentLocations = [
  {"main": "Home", "sub": "Karmabhumi Soc, Gopal Chowk Rd, Parishram Park, Nava Naroda, Ahmedabad, Gujarat 382345"},
  {"main": "collage", "sub": "Rancharda, Via, Shilaj, Gujarat 382115"},
  {"main": "Friend's House", "sub": "Prahladnagar, Ahmedabad"},
  {"main": "Restaurant", "sub": "THE HILLOCK AHMEDABAD, Opp. The CBD, 200 ft, Ring Road, nr. Vaishnodevi Circle, Ahmedabad, Gujarat 382421"},
  {"main": "Gym", "sub": "1st Floor, Radheshyam Residency, Opp ship 2 Bunglows, Dmart Rd, Nikol, Ahmedabad, Gujarat 382346"},
];


  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  bool _isSelectingOnMap = false;

  Marker? _selectedMarker;
  String _selectedAddress = '';
  bool _showConfirmPickupUI = false;

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

    final url =
        'https://maps.gomaps.pro/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&components=country:in';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<PlaceSuggestion> suggestions =
              (data['predictions'] as List)
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
      bottomSheetHeightFraction = normalHeight;
    });
  }

  Future<void> _shareLocation() async {
    bool granted = await _handlePermission();
    if (!granted) return;

    Position pos = await Geolocator.getCurrentPosition();
    _pickupLatLng = LatLng(pos.latitude, pos.longitude);
    pickupController.text = "Current Location";
    _mapController?.animateCamera(CameraUpdate.newLatLng(_pickupLatLng!));
    await _checkAndDrawRoute();
  }

  Future<void> _determinePosition() async => await _handlePermission();

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    if (address == "Current Location" && _pickupLatLng != null) {
      return _pickupLatLng;
    }

    final url =
        'https://maps.gomaps.pro/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey';

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

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    final url =
        'https://maps.gomaps.pro/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['results'][0]['formatted_address'];
      }
    }
    return "Selected location";
  }

  Future<void> _checkAndDrawRoute() async {
    if (pickupController.text.isNotEmpty &&
        destinationController.text.isNotEmpty) {
      await _drawRoute();
    }
  }

  Future<void> _drawRoute() async {
    final pickup = await _getLatLngFromAddress(pickupController.text);
    final dest = await _getLatLngFromAddress(destinationController.text);
    if (pickup == null || dest == null) return;

    final url =
        'https://maps.gomaps.pro/maps/api/directions/json?origin=${pickup.latitude},${pickup.longitude}&destination=${dest.latitude},${dest.longitude}&alternatives=true&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        Set<Polyline> polySet = {};
        for (int i = 0; i < data['routes'].length && i < 3; i++) {
          final points = data['routes'][i]['overview_polyline']['points'];
          final polylineCoordinates = _decodePolyline(points);
          polySet.add(
            Polyline(
              polylineId: PolylineId("route_$i"),
              color:
                  i == 0
                      ? Colors.blue
                      : i == 1
                      ? Colors.green
                      : Colors.orange,
              width: 5,
              points: polylineCoordinates,
            ),
          );
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
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
            Marker(
              markerId: const MarkerId("destination"),
              position: dest,
              infoWindow: const InfoWindow(title: "Destination"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          };
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromLatLngs(pickup, dest), 80),
        );
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
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
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
            markers: _markers,
            polylines: _polylines,
            onTap: (latLng) async {
              if (_isSelectingOnMap) {
                final address = await _getAddressFromLatLng(latLng);
                final marker = Marker(
                  markerId: const MarkerId("selected_location"),
                  position: latLng,
                  draggable: true,
                  onDragEnd: (newPosition) async {
                    final newAddress = await _getAddressFromLatLng(newPosition);
                    setState(() {
                      _selectedAddress = newAddress;
                      _selectedMarker = _selectedMarker!.copyWith(
                        positionParam: newPosition,
                      );
                      _markers = {_selectedMarker!};
                    });
                  },
                );

                setState(() {
                  _selectedAddress = address;
                  _selectedMarker = marker;
                  _markers = {marker};
                  _showConfirmPickupUI = true;
                });
              } else {
                _collapseBottom();
              }
            },
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
                  label: const Text("Share Current Location"),
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
        child:
            _showConfirmPickupUI
                ? _confirmPickupUI()
                : Column(
                  children: [
                    Container(
                      width: 40,
                      height: 6,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                _locationField(
                                  "Where to?",
                                  Icons.square_outlined,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            if (!isExpanded)
                              ...recentLocations.map(
                                (loc) => ListTile(
                                  leading: const Icon(
                                    Icons.add_location,
                                    color: Colors.white70,
                                  ),
                                  title: Text(
                                    loc["main"]!,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    loc["sub"]!,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  onTap: () {
                                    pickupController.text = loc["sub"]!;
                                    _checkAndDrawRoute();
                                    setState(() => isExpanded = true);
                                  },
                                ),
                              ),
                            if (isExpanded) ...[
                              ..._suggestions.map(
                                (s) => ListTile(
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white70,
                                  ),
                                  title: Text(
                                    s.mainText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    s.secondaryText,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  onTap: () async {
                                    if (isPickupActive) {
                                      pickupController.text = s.description;
                                    } else {
                                      destinationController.text =
                                          s.description;
                                    }
                                    _collapseBottom();
                                    await _checkAndDrawRoute();
                                  },
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.map_outlined,
                                  color: Colors.white70,
                                ),
                                title: const Text(
                                  "Set location on map",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  _collapseBottom();
                                  setState(() => _isSelectingOnMap = true);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _confirmPickupUI() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Plan your trip",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedAddress,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showConfirmPickupUI = false;
                        _isSelectingOnMap = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Search"),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              setState(() {
                if (isPickupActive) {
                  pickupController.text = _selectedAddress;
                  _pickupLatLng = _selectedMarker?.position;
                } else {
                  destinationController.text = _selectedAddress;
                  _destinationLatLng = _selectedMarker?.position;
                }
                _showConfirmPickupUI = false;
                _isSelectingOnMap = false;
              });

              if (_pickupLatLng != null && _destinationLatLng != null) {
                await _drawRoute();
              }
            },

            child: const Text("Confirm pick-up"),
          ),
        ),
      ],
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
            onTap:
                () => setState(() {
                  isExpanded = true;
                  isPickupActive = true;
                  bottomSheetHeightFraction = normalHeight;
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
            onTap:
                () => setState(() {
                  isExpanded = true;
                  isPickupActive = false;
                  bottomSheetHeightFraction = normalHeight;
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
