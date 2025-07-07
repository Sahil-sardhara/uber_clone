// lib/map_search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber/models/place_suggestion.dart';
import 'package:uber/pages/payment_options_screen.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});
  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  GoogleMapController? _mapController;
  String _mapStyle = '';
  String selectedRideTitle = 'Auto'; // default selected ride
  final pickupController = TextEditingController();
  final destinationController = TextEditingController();

  List<PlaceSuggestion> _suggestions = [];
  List<String> _recentLocations = []; // To store simplified recent locations

  bool isExpanded = false;
  bool isPickupActive = true;
  double bottomSheetHeightFraction = 0.4;
  final double minHeight = 0.25;
  final double normalHeight = 0.4;
  final double maxHeight = 0.6;
  // IMPORTANT: Replace with your actual GoMaps or Google Maps Platform API Key
  final String _apiKey =
      "AlzaSyAjKvMppyRsPvWPvRlj_KKZRKoYAtp9QnI"; // Replace with your key
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  bool _isSelectingOnMap = false;

  Marker? _selectedMarker;
  String _selectedAddress = '';
  bool _showConfirmPickupUI = false;
  bool _showRideOptionsUI = false; // New variable for ride options UI

  // --- New state variables for dynamic pricing ---
  Map<String, double> _calculatedPrices = {};
  Map<String, double?> _calculatedOriginalPrices = {};
  // --- End new state variables ---

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _determinePosition();
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Decode the stored JSON strings back into Maps and then extract the subtitle (full address)
      _recentLocations =
          (prefs.getStringList('recent_places') ?? [])
              .map(
                (item) =>
                    Map<String, String>.from(json.decode(item))['subtitle']!,
              )
              .toList();
    });
  }

  Future<void> _saveRecentLocation(String address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentJsonStrings = prefs.getStringList('recent_places') ?? [];

    Map<String, String> place = {
      'title': address.split(',').first.trim(), // Get the first part as title
      'subtitle': address, // Store the full address
    };
    // Convert existing list items to actual Map objects for easier manipulation
    List<Map<String, String>> recentPlaces =
        recentJsonStrings
            .map((item) => Map<String, String>.from(json.decode(item)))
            .toList();
    // Remove if already exists to add it to the top
    recentPlaces.removeWhere((item) => item['subtitle'] == place['subtitle']);
    // Add the new place to the beginning
    recentPlaces.insert(0, place);
    // Keep only the last 5
    if (recentPlaces.length > 5) {
      recentPlaces = recentPlaces.sublist(0, 5);
    }

    // Convert back to JSON strings for SharedPreferences
    await prefs.setStringList(
      'recent_places',
      recentPlaces.map((e) => json.encode(e)).toList(),
    );
    // Also update the in-memory list
    setState(() {
      _recentLocations = recentPlaces.map((e) => e['subtitle']!).toList();
    });
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style_dark.json');
    setState(() {});
  }

  void _getPlaceSuggestions(String input) async {
    if (input.length < 2) {
      setState(() {
        _suggestions.clear();
        isExpanded = true; // Still expand to show recent if input is short
        bottomSheetHeightFraction = normalHeight;
        _showRideOptionsUI = false; // Hide ride options when searching
      });
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
            _showRideOptionsUI = false; // Hide ride options when searching
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
      if (!_showRideOptionsUI) {
        bottomSheetHeightFraction = normalHeight;
      }
    });
  }

  Future<void> _shareLocation() async {
    bool granted = await _handlePermission();
    if (!granted) return;
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _pickupLatLng = LatLng(pos.latitude, pos.longitude);
    final currentAddress = await _getAddressFromLatLng(_pickupLatLng!);
    pickupController.text = currentAddress;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickupLatLng!, 16),
    );
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
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
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
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    }
    return "Selected location";
  }

  Future<void> _checkAndDrawRoute() async {
    if (pickupController.text.isNotEmpty &&
        destinationController.text.isNotEmpty) {
      _pickupLatLng = await _getLatLngFromAddress(pickupController.text);
      _destinationLatLng = await _getLatLngFromAddress(
        destinationController.text,
      );
      if (_pickupLatLng != null && _destinationLatLng != null) {
        await _drawRoute();
        await _saveRecentLocation(pickupController.text);
        await _saveRecentLocation(destinationController.text);
        setState(() {
          _showRideOptionsUI = true; // Show ride options
          _showConfirmPickupUI = false; // Ensure confirm pickup is hidden
          isExpanded = false; // Collapse search suggestions
          bottomSheetHeightFraction =
              maxHeight; // Adjust height for ride options
        });
      }
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
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        // --- Extract distance and duration for dynamic pricing ---
        final leg = data['routes'][0]['legs'][0];
        final int distanceMeters =
            leg['distance']['value']; // distance in meters
        final int durationSeconds =
            leg['duration']['value']; // duration in seconds

        _calculateAndSetRidePrices(
          distanceMeters / 1000.0,
          durationSeconds / 60.0,
        );
        // --- End extraction ---

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

  // --- New function for dynamic pricing calculation ---
  void _calculateAndSetRidePrices(double distanceKm, double durationMinutes) {
    // Define your base rates, per KM, per Minute for each ride type
    // These are example values and can be adjusted as needed.
    const Map<String, double> baseFares = {
      'Auto': 50.0,
      'Courier': 30.0,
      'Uber Go': 60.0,
      'Moto': 20.0,
      'XL Rentals': 400.0, // Rentals might have a package-based price
    };
    const Map<String, double> pricePerKm = {
      'Auto': 12.0,
      'Courier': 10.0,
      'Uber Go': 15.0,
      'Moto': 8.0,
      'XL Rentals': 0.0, // For rentals, KM might be part of the package
    };
    const Map<String, double> pricePerMinute = {
      'Auto': 2.0,
      'Courier': 1.5,
      'Uber Go': 2.5,
      'Moto': 1.0,
      'XL Rentals': 0.0, // For rentals, minutes might be part of the package
    };

    // Simulate a simple surge/discount based on time of day (example)
    // You can make this more sophisticated.
    final int currentHour = DateTime.now().hour;
    double surgeMultiplier = 1.0;
    double discountFactor = 1.0;

    if (currentHour >= 7 && currentHour <= 9 ||
        currentHour >= 17 && currentHour <= 19) {
      // Peak hours (7-9 AM, 5-7 PM)
      surgeMultiplier = 1.2 + (0.3 * (currentHour % 2)); // e.g., 1.2x to 1.5x
    } else if (currentHour >= 22 || currentHour <= 5) {
      // Late night/Early morning
      surgeMultiplier = 1.1 + (0.2 * (currentHour % 2)); // e.g., 1.1x to 1.3x
    } else if (currentHour >= 10 && currentHour <= 16) {
      // Off-peak midday
      discountFactor = 0.9; // 10% discount
    }

    setState(() {
      _calculatedPrices.clear();
      _calculatedOriginalPrices.clear();

      baseFares.keys.forEach((rideType) {
        double base = baseFares[rideType]!;
        double perKm = pricePerKm[rideType]!;
        double perMin = pricePerMinute[rideType]!;

        double calculatedRawPrice;
        if (rideType == 'XL Rentals') {
          // For rentals, assume a fixed price for the package (e.g., 1hr/15km)
          // and add only if distance/time exceed it substantially.
          // For this example, let's keep it simple: just the base fare + a minimal factor for distance/time.
          calculatedRawPrice =
              base + (distanceKm * 0.5) + (durationMinutes * 0.5);
        } else {
          calculatedRawPrice =
              base + (perKm * distanceKm) + (perMin * durationMinutes);
        }

        // Apply surge first
        double finalPrice = calculatedRawPrice * surgeMultiplier;
        double? originalPrice;

        // Apply discount if applicable and if not already surged
        if (discountFactor < 1.0 && surgeMultiplier == 1.0) {
          originalPrice = finalPrice;
          finalPrice = finalPrice * discountFactor;
        }

        _calculatedPrices[rideType] = finalPrice;
        if (originalPrice != null) {
          _calculatedOriginalPrices[rideType] = originalPrice;
        } else if (surgeMultiplier > 1.0) {
          // If surged, the original price before surge could be the base for strikethrough
          _calculatedOriginalPrices[rideType] = calculatedRawPrice;
        } else {
          _calculatedOriginalPrices[rideType] =
              null; // No strikethrough if no discount or surge
        }
      });
    });
  }
  // --- End new function ---

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
              target: LatLng(23.0225, 72.5714), // Default to Ahmedabad
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
                  bottomSheetHeightFraction =
                      normalHeight; // Adjust height for confirm pickup UI
                  _showRideOptionsUI =
                      false; // Hide ride options if selecting on map
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
        child: Column(
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
            Expanded(
              child:
                  _showConfirmPickupUI
                      ? _confirmPickupUI()
                      : _showRideOptionsUI
                      ? _rideOptionsUI()
                      : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  // Display recent locations only if not currently searching (suggestions are empty)
                                  if (!isExpanded || _suggestions.isEmpty)
                                    ..._recentLocations.map(
                                      (address) => ListTile(
                                        leading: const Icon(
                                          Icons.history,
                                          color: Colors.white70,
                                        ),
                                        title: Text(
                                          address,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        onTap: () {
                                          if (isPickupActive) {
                                            pickupController.text = address;
                                          } else {
                                            destinationController.text =
                                                address;
                                          }
                                          _collapseBottom();
                                          _checkAndDrawRoute();
                                        },
                                      ),
                                    ),
                                  // Display suggestions if expanded
                                  if (isExpanded) ...[
                                    ..._suggestions.map(
                                      (s) => ListTile(
                                        leading: const Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white70,
                                        ),
                                        title: Text(
                                          s.mainText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          s.secondaryText,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        onTap: () async {
                                          if (isPickupActive) {
                                            pickupController.text =
                                                s.description;
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
                                        setState(() {
                                          _isSelectingOnMap = true;
                                          _showRideOptionsUI =
                                              false; // Hide ride options
                                          _showConfirmPickupUI =
                                              false; // Hide confirm pickup
                                          _markers
                                              .clear(); // Clear existing markers for map selection
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Confirm location on map",
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
                        // Return to search UI state
                        _markers.clear(); // Clear the single selected marker
                        _polylines.clear(); // Clear polylines
                        bottomSheetHeightFraction = normalHeight;
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
                await _saveRecentLocation(
                  isPickupActive
                      ? pickupController.text
                      : destinationController.text,
                );
                setState(() {
                  _showRideOptionsUI =
                      true; // Show ride options after confirming selection from map
                  bottomSheetHeightFraction = maxHeight;
                });
              } else {
                // If only one point is selected, just update the text field and go back to initial state
                setState(() {
                  bottomSheetHeightFraction = normalHeight;
                  _markers.clear();
                  _polylines.clear();
                });
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
                  _showRideOptionsUI =
                      false; // Hide ride options when editing pickup
                  _showConfirmPickupUI =
                      false; // Hide confirm pickup when editing
                  _markers.clear(); // Clear markers when editing
                  _polylines.clear(); // Clear polylines
                }),
            onChanged: (text) {
              _getPlaceSuggestions(text);
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
                  _showRideOptionsUI =
                      false; // Hide ride options when editing destination
                  _showConfirmPickupUI =
                      false; // Hide confirm pickup when editing
                  _markers.clear(); // Clear markers when editing
                  _polylines.clear(); // Clear polylines
                }),
            onChanged: (text) {
              _getPlaceSuggestions(text);
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

  Widget _rideOptionsUI() {
    return Column(
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Choose a trip",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRideOption(
                  image: 'assets/images/auto.webp',
                  title: 'Auto',
                  capacity: 3,
                  time:
                      'Calculated Time', // Will not dynamically show, but price will
                  price:
                      '₹${_calculatedPrices['Auto']?.toStringAsFixed(2) ?? '0.00'}',
                  originalPrice:
                      _calculatedOriginalPrices['Auto'] != null
                          ? '₹${_calculatedOriginalPrices['Auto']!.toStringAsFixed(2)}'
                          : null,
                  description: 'Pay directly to driver, cash/UPI only',
                  isFaster: true,
                  isRental: false,
                ),
                const SizedBox(height: 12),
                _buildRideOption(
                  image: 'assets/images/courier.png',
                  title: 'Courier',
                  capacity: 0,
                  time: 'Calculated Time',
                  price:
                      '₹${_calculatedPrices['Courier']?.toStringAsFixed(2) ?? '0.00'}',
                  originalPrice:
                      _calculatedOriginalPrices['Courier'] != null
                          ? '₹${_calculatedOriginalPrices['Courier']!.toStringAsFixed(2)}'
                          : null,
                  description: 'Send packages to loved ones',
                  isFaster: false,
                  isRental: false,
                ),
                const SizedBox(height: 12),
                _buildRideOption(
                  image: 'assets/images/suv.webp',
                  title: 'Uber Go',
                  capacity: 4,
                  time: 'Calculated Time',
                  price:
                      '₹${_calculatedPrices['Uber Go']?.toStringAsFixed(2) ?? '0.00'}',
                  originalPrice:
                      _calculatedOriginalPrices['Uber Go'] != null
                          ? '₹${_calculatedOriginalPrices['Uber Go']!.toStringAsFixed(2)}'
                          : null,
                  description: 'Affordable compact rides',
                  isFaster: false,
                  isRental: false,
                ),
                const SizedBox(height: 12),
                _buildRideOption(
                  image: 'assets/images/moto.png',
                  title: 'Moto',
                  capacity: 1,
                  time: 'Calculated Time',
                  price:
                      '₹${_calculatedPrices['Moto']?.toStringAsFixed(2) ?? '0.00'}',
                  originalPrice:
                      _calculatedOriginalPrices['Moto'] != null
                          ? '₹${_calculatedOriginalPrices['Moto']!.toStringAsFixed(2)}'
                          : null,
                  description: 'Affordable, motorcycle rides',
                  isFaster: false,
                  isRental: false,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Economy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRideOption(
                  image: 'assets/images/rental.png',
                  title: 'XL Rentals',
                  capacity: 0,
                  time: 'Calculated Time',
                  price:
                      '₹${_calculatedPrices['XL Rentals']?.toStringAsFixed(2) ?? '0.00'}',
                  originalPrice:
                      _calculatedOriginalPrices['XL Rentals'] != null
                          ? '₹${_calculatedOriginalPrices['XL Rentals']!.toStringAsFixed(2)}'
                          : null,
                  description: '1 hr/15 km',
                  isFaster: false,
                  isRental: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Handle payment method change
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentOptionsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.money, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Cash",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    print("Choose $selectedRideTitle button pressed!");
                  },
                  child: Text(
                    "Choose $selectedRideTitle",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideOption({
    required String image,
    required String title,
    required int capacity,
    required String time,
    required String price,
    String? originalPrice,
    required String description,
    bool isFaster = false,
    bool isRental = false,
  }) {
    final bool isSelected = selectedRideTitle == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRideTitle = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade800 : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.greenAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.asset(image, width: 50, height: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // Added Row for title and capacity/faster
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (capacity > 0 && !isRental)
                        // Only show capacity if not rental and > 0
                        Row(
                          children: [
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 16,
                            ),
                            Text(
                              '$capacity',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      if (isFaster)
                        // Show Faster tag if true
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Faster",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(color: Colors.white70)),
                Row(
                  children: [
                    if (originalPrice != null)
                      Text(
                        originalPrice,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
