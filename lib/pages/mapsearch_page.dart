// lib/map_search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber/models/place_suggestion.dart';
import 'package:uber/pages/ConfirmPickupMapPage.dart';
import 'package:uber/pages/mappls_auth_service.dart';
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
  // This key is used for Autocomplete and Geocoding requests.
  final String _apiKey =
      "AlzaSyQ8QdX0RwC6B2e66rP52F4vYURp1NjAVXM"; // <<< REPLACE THIS

  // Mappls Access Token obtained from MapplsAuthService for Routing and Reverse Geocoding
  String? _accessToken;
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
  Map<String, String> _calculatedTravelTimes = {};
  // --- End new state variables ---

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _determinePosition();
    _loadRecentLocations();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    print("Attempting to initialize Mappls access token...");
    _accessToken = await MapplsAuthService.getAccessToken();
    if (_accessToken != null) {
      print("Mappls Access Token obtained successfully.");
    } else {
      print(
        "Failed to obtain Mappls Access Token. Check MapplsAuthService.dart implementation and Mappls credentials.",
      );
    }
    setState(() {}); // Rebuild to update UI if token affects anything
  }

  Future<void> _loadRecentLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentLocations =
          (prefs.getStringList('recent_places') ?? [])
              .map(
                (item) =>
                    Map<String, String>.from(json.decode(item))['subtitle']!,
              )
              .toList();
      print("Loaded recent locations: $_recentLocations");
    });
  }

  Future<void> _saveRecentLocation(String address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recentJsonStrings = prefs.getStringList('recent_places') ?? [];

    Map<String, String> place = {
      'title': address.split(',').first.trim(), // Get the first part as title
      'subtitle': address, // Store the full address
    };
    List<Map<String, String>> recentPlaces =
        recentJsonStrings
            .map((item) => Map<String, String>.from(json.decode(item)))
            .toList();
    recentPlaces.removeWhere((item) => item['subtitle'] == place['subtitle']);
    recentPlaces.insert(0, place);
    if (recentPlaces.length > 5) {
      recentPlaces = recentPlaces.sublist(0, 5);
    }

    await prefs.setStringList(
      'recent_places',
      recentPlaces.map((e) => json.encode(e)).toList(),
    );
    setState(() {
      _recentLocations = recentPlaces.map((e) => e['subtitle']!).toList();
    });
    print("Saved and updated recent locations: $_recentLocations");
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style_dark.json');
      setState(() {});
      print("Map style loaded.");
    } catch (e) {
      print("Error loading map style: $e");
    }
  }

  void _getPlaceSuggestions(String input) async {
    if (input.length < 2) {
      setState(() {
        _suggestions.clear();
        isExpanded = true;
        bottomSheetHeightFraction = normalHeight;
        _showRideOptionsUI = false;
      });
      print(
        "Input too short for suggestions. Showing recent locations if available.",
      );
      return;
    }

    // Ensure the correct base URL for your API key (GoMaps or Google Maps)
    // If using Google Maps Platform, replace 'https://maps.gomaps.pro' with 'https://maps.googleapis.com'
    final url =
        'https://maps.gomaps.pro/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&components=country:in';
    print("Fetching suggestions from: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Suggestions API response: $data");
        if (data['status'] == 'OK') {
          List<PlaceSuggestion> suggestions =
              (data['predictions'] as List)
                  .map((item) => PlaceSuggestion.fromGoMap(item))
                  .toList();
          setState(() {
            _suggestions = suggestions;
            isExpanded = true;
            bottomSheetHeightFraction = maxHeight;
            _showRideOptionsUI = false;
          });
          print("Found ${suggestions.length} suggestions.");
        } else {
          print("Suggestions API status not OK: ${data['status']}");
          if (data['error_message'] != null) {
            print("Error message: ${data['error_message']}");
          }
        }
      } else {
        print(
          "Failed to fetch suggestions. Status code: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Suggestion API error: $e");
    }
  }

  void _collapseBottom() {
    FocusScope.of(context).unfocus();
    setState(() {
      isExpanded = false;
      _suggestions.clear();
      // Only set to normalHeight if ride options are NOT showing
      if (!_showRideOptionsUI && !_showConfirmPickupUI) {
        bottomSheetHeightFraction = normalHeight;
      }
      print("Bottom sheet collapsed.");
    });
  }

  Future<void> _shareLocation() async {
    print("Attempting to share current location.");
    bool granted = await _handlePermission();
    if (!granted) {
      print("Location permission not granted. Cannot share location.");
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _pickupLatLng = LatLng(pos.latitude, pos.longitude);
      print(
        "Current location obtained: ${_pickupLatLng!.latitude}, ${_pickupLatLng!.longitude}",
      );
      final currentAddress = await _getAddressFromLatLng(_pickupLatLng!);
      pickupController.text = currentAddress;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLatLng!, 16),
      );
      print("Set pickup to current location: $currentAddress");
      // After setting current location, if destination is also set, draw route
      if (destinationController.text.isNotEmpty) {
        await _checkAndDrawRoute();
      }
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Future<void> _determinePosition() async {
    print("Determining position and handling permissions.");
    await _handlePermission();
  }

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    print("Current location permission status: $permission");
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      print("Requested location permission. New status: $permission");
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    if (address == "Current Location" && _pickupLatLng != null) {
      print("Using existing current location for: $address");
      return _pickupLatLng;
    }
    if (_apiKey.isEmpty || _apiKey == "YOUR_GOMAPS_OR_Maps_API_KEY") {
      print(
        "API Key for Geocoding is not set. Cannot get LatLng from address.",
      );
      return null;
    }

    // Ensure the correct base URL for your API key (GoMaps or Google Maps)
    // If using Google Maps Platform, replace 'https://maps.gomaps.pro' with 'https://maps.googleapis.com'
    final url =
        'https://maps.gomaps.pro/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey';
    print("Geocoding address from: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Geocode API response for '$address': $data");
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final latLng = LatLng(location['lat'], location['lng']);
          print(
            "Geocoded '$address' to: ${latLng.latitude}, ${latLng.longitude}",
          );
          return latLng;
        } else {
          print("Geocode API status not OK for '$address': ${data['status']}");
          if (data['error_message'] != null) {
            print("Error message from geocode API: ${data['error_message']}");
          }
        }
      } else {
        print(
          "Failed to geocode address: '$address'. Status code: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Geocoding network/parsing error for '$address': $e");
    }
    return null;
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    if (_accessToken == null) {
      print("Mappls Access Token is null. Cannot reverse geocode.");
      return "Address Not Found (Token Missing)";
    }

    final url = 'https://atlas.mappls.com/api/places/geo-location';
    print("Reverse geocoding LatLng: ${latLng.latitude}, ${latLng.longitude}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Reverse Geocode API response: $data");
        if (data['suggestedLocations'] != null &&
            data['suggestedLocations'].isNotEmpty) {
          final address = data['suggestedLocations'][0]['placeName'];
          print("Reverse geocoded to: $address");
          return address;
        } else {
          print("No suggested locations found in reverse geocode response.");
        }
      } else {
        print("Failed to reverse geocode. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Reverse geocoding network/parsing error: $e");
    }

    return "Address Not Found";
  }

  Future<void> _checkAndDrawRoute() async {
    print(
      "Initiating _checkAndDrawRoute: Pickup='${pickupController.text}', Destination='${destinationController.text}'",
    );
    if (pickupController.text.isNotEmpty &&
        destinationController.text.isNotEmpty) {
      _pickupLatLng = await _getLatLngFromAddress(pickupController.text);
      _destinationLatLng = await _getLatLngFromAddress(
        destinationController.text,
      );
      if (_pickupLatLng != null && _destinationLatLng != null) {
        print(
          "Both pickup and destination LatLngs obtained. Proceeding to _drawRoute.",
        );
        await _drawRoute();
        await _saveRecentLocation(pickupController.text);
        await _saveRecentLocation(destinationController.text);
        setState(() {
          _showRideOptionsUI = true; // Show ride options
          _showConfirmPickupUI = false; // Ensure confirm pickup is hidden
          isExpanded = false; // Collapse search suggestions
          bottomSheetHeightFraction =
              maxHeight; // Adjust height for ride options
          print(
            "UI state updated: _showRideOptionsUI=true, bottomSheetHeightFraction=maxHeight.",
          );
        });
      } else {
        print("One or both LatLngs are null. Cannot draw route.");
        if (_pickupLatLng == null) print("  Pickup LatLng is null.");
        if (_destinationLatLng == null) print("  Destination LatLng is null.");
        // If not successful, revert UI to initial search state or keep previous state
        setState(() {
          _showRideOptionsUI = false;
          _showConfirmPickupUI = false;
          bottomSheetHeightFraction = normalHeight; // Revert height
        });
      }
    } else {
      print("Pickup or Destination text is empty. Cannot draw route yet.");
      setState(() {
        _showRideOptionsUI =
            false; // Hide ride options if inputs are incomplete
        _showConfirmPickupUI = false;
        bottomSheetHeightFraction = normalHeight; // Revert height
      });
    }
  }

  Future<void> _drawRoute() async {
    print("Attempting to draw route...");
    final pickup = _pickupLatLng; // Use already fetched LatLngs
    final dest = _destinationLatLng; // Use already fetched LatLngs

    if (pickup == null || dest == null) {
      print(
        "Pickup or Destination LatLng is null, cannot draw route. Exiting _drawRoute.",
      );
      return;
    }

    final token =
        await MapplsAuthService.getAccessToken(); // Re-fetch for safety, but usually cached
    if (token == null) {
      print(
        "Mappls Access Token is null. Cannot draw route. Exiting _drawRoute.",
      );
      return;
    }
    print("Using Mappls Token for routing.");

    final url =
        'https://apis.mappls.com/advancedmaps/v1/$token/route_adv/driving/${pickup.longitude},${pickup.latitude};${dest.longitude},${dest.latitude}?geometries=polyline';
    print("Fetching route from: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Route API response received. Checking for routes...");
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']; // polyline
          final distance =
              (route['distance'] as num).toDouble(); // distance in meters
          final duration =
              (route['duration'] as num).toDouble(); // duration in seconds

          final polylinePoints = _decodePolyline(geometry);
          print("Route polyline decoded with ${polylinePoints.length} points.");

          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId("route"),
                color: Colors.blue,
                width: 5,
                points: polylinePoints,
              ),
            };

            _markers = {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                infoWindow: InfoWindow(title: pickupController.text),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: dest,
                infoWindow: InfoWindow(title: destinationController.text),
              ),
            };
            print("Markers and Polylines updated on map.");
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(_boundsFromLatLngs(pickup, dest), 80),
          );

          _calculateAndSetRidePrices(
            distance / 1000,
            duration / 60,
          ); // Convert to km and minutes
          print(
            "Calculated ride prices for distance: ${distance / 1000}km, duration: ${duration / 60}min.",
          );
        } else {
          print("No route found in response data. Clearing map elements.");
          setState(() {
            _polylines.clear();
            _markers.clear();
          });
        }
      } else {
        print(
          "Failed to fetch route. Status code: ${response.statusCode}. Response body: ${response.body}",
        );
        setState(() {
          _polylines.clear();
          _markers.clear();
        });
      }
    } catch (e) {
      print("Route drawing network/parsing error: $e");
      setState(() {
        _polylines.clear();
        _markers.clear();
      });
    }
  }

  void _calculateAndSetRidePrices(double distanceKm, double durationMinutes) {
    const Map<String, double> baseFares = {
      'Auto': 50.0,
      'Courier': 30.0,
      'Uber Go': 60.0,
      'Moto': 20.0,
      'XL Rentals': 400.0,
    };
    const Map<String, double> pricePerKm = {
      'Auto': 12.0,
      'Courier': 10.0,
      'Uber Go': 15.0,
      'Moto': 8.0,
      'XL Rentals':
          0.0, // XL Rentals might have a different pricing structure, adjusting here
    };
    const Map<String, double> pricePerMinute = {
      'Auto': 2.0,
      'Courier': 1.5,
      'Uber Go': 2.5,
      'Moto': 1.0,
      'XL Rentals':
          0.0, // XL Rentals might have a different pricing structure, adjusting here
    };
    // NEW: Time in minutes per kilometer
    const Map<String, double> timePerKm = {
      'Auto': 2.5, // 2.5 minutes per km (approx 24 km/hr avg speed)
      'Courier': 2.0, // 2 minutes per km (approx 30 km/hr avg speed)
      'Uber Go': 2.0, // 2 minutes per km (approx 30 km/hr avg speed)
      'Moto': 1.5, // 1.5 minutes per km (approx 40 km/hr avg speed)
      'XL Rentals': 2.0, // 2 minutes per km
    };

    final int currentHour = DateTime.now().hour;
    double surgeMultiplier = 1.0;
    double discountFactor = 1.0;

    if (currentHour >= 7 && currentHour <= 9 ||
        currentHour >= 17 && currentHour <= 19) {
      surgeMultiplier = 1.2 + (0.3 * (currentHour % 2));
    } else if (currentHour >= 22 || currentHour <= 5) {
      surgeMultiplier = 1.1 + (0.2 * (currentHour % 2));
    } else if (currentHour >= 10 && currentHour <= 16) {
      discountFactor = 0.9;
    }

    setState(() {
      _calculatedPrices.clear();
      _calculatedOriginalPrices.clear();
      _calculatedTravelTimes.clear(); // Clear previous travel times

      baseFares.keys.forEach((rideType) {
        double base = baseFares[rideType]!;
        double perKm = pricePerKm[rideType]!;
        double perMin = pricePerMinute[rideType]!;
        double tPerKm =
            timePerKm[rideType]!; // Get time per km for this ride type

        // Calculate duration based on distanceKm and timePerKm
        final double calculatedDurationMinutes = distanceKm * tPerKm;

        double calculatedRawPrice;
        if (rideType == 'XL Rentals') {
          // XL Rentals often have a base rate for some distance/time, then additional charges
          // For a simple example, let's make it a higher base plus a small per km/min
          calculatedRawPrice =
              base + (distanceKm * 0.5) + (calculatedDurationMinutes * 0.5);
        } else {
          calculatedRawPrice =
              base +
              (perKm * distanceKm) +
              (perMin * calculatedDurationMinutes);
        }

        double finalPrice = calculatedRawPrice * surgeMultiplier;
        double? originalPrice;

        if (discountFactor < 1.0 && surgeMultiplier == 1.0) {
          originalPrice = finalPrice;
          finalPrice = finalPrice * discountFactor;
        } else if (surgeMultiplier > 1.0) {
          originalPrice = calculatedRawPrice;
        }

        _calculatedPrices[rideType] = finalPrice;
        _calculatedOriginalPrices[rideType] = originalPrice;

        // Convert calculatedDurationMinutes to a human-readable format (e.g., "30 min", "1 hr 15 min")
        final int totalMinutes = calculatedDurationMinutes.round();
        final int hours = totalMinutes ~/ 60;
        final int remainingMinutes = totalMinutes % 60;
        String timeString;
        if (hours > 0) {
          timeString = '${hours} hr ${remainingMinutes} min';
        } else {
          timeString = '${remainingMinutes} min';
        }
        _calculatedTravelTimes[rideType] = timeString; // Store formatted time

        print(
          "Price for $rideType: Final=${finalPrice.toStringAsFixed(2)}, Original=${originalPrice?.toStringAsFixed(2) ?? 'N/A'}, Est. Time: $timeString",
        );
      });
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

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
              print("Google Map created and style applied.");
            },
            markers: _markers,
            polylines: _polylines,
            onTap: (latLng) async {
              print("Map tapped at: ${latLng.latitude}, ${latLng.longitude}");
              if (_isSelectingOnMap) {
                final address = await _getAddressFromLatLng(latLng);
                final marker = Marker(
                  markerId: const MarkerId("selected_location"),
                  position: latLng,
                  draggable: true,
                  onDragEnd: (newPosition) async {
                    print(
                      "Selected marker dragged to: ${newPosition.latitude}, ${newPosition.longitude}",
                    );
                    final newAddress = await _getAddressFromLatLng(newPosition);
                    setState(() {
                      _selectedAddress = newAddress;
                      _selectedMarker = _selectedMarker!.copyWith(
                        positionParam: newPosition,
                      );
                      _markers = {_selectedMarker!};
                    });
                    print(
                      "Updated selected address on drag: $_selectedAddress",
                    );
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
                  print("Showing confirm pickup UI for: $_selectedAddress");
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
                                          print(
                                            "Selected recent location: $address",
                                          );
                                          _checkAndDrawRoute(); // Re-evaluate and draw route
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
                                          print(
                                            "Selected suggestion: ${s.description}",
                                          );
                                          if (isPickupActive) {
                                            pickupController.text =
                                                s.description;
                                          } else {
                                            destinationController.text =
                                                s.description;
                                          }
                                          _collapseBottom();
                                          await _checkAndDrawRoute(); // Re-evaluate and draw route
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
                                        print("Tapped 'Set location on map'.");
                                        _collapseBottom();
                                        setState(() {
                                          _isSelectingOnMap = true;
                                          _showRideOptionsUI = false;
                                          _showConfirmPickupUI = false;
                                          _markers.clear();
                                          _polylines.clear();
                                          bottomSheetHeightFraction =
                                              maxHeight; // Make space for map selection UI
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8), // Added spacing
                  ElevatedButton(
                    onPressed: () {
                      print("Tapped 'Search' from confirm pickup.");
                      setState(() {
                        _showConfirmPickupUI = false;
                        _isSelectingOnMap = false;
                        _markers.clear();
                        _polylines.clear();
                        bottomSheetHeightFraction =
                            normalHeight; // Revert to search height
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
              print("Tapped 'Confirm pick-up'.");
              setState(() {
                if (isPickupActive) {
                  pickupController.text = _selectedAddress;
                  _pickupLatLng = _selectedMarker?.position;
                  print("Confirmed pickup from map: ${pickupController.text}");
                } else {
                  destinationController.text = _selectedAddress;
                  _destinationLatLng = _selectedMarker?.position;
                  print(
                    "Confirmed destination from map: ${destinationController.text}",
                  );
                }

                _showConfirmPickupUI = false;
                _isSelectingOnMap = false;
              });

              // After confirming a point from map, check if both are ready to draw route
              if (_pickupLatLng != null && _destinationLatLng != null) {
                print("Both LatLngs confirmed. Drawing route...");
                await _drawRoute();
                await _saveRecentLocation(
                  isPickupActive
                      ? pickupController.text
                      : destinationController.text,
                );
                setState(() {
                  _showRideOptionsUI = true; // Show ride options
                  bottomSheetHeightFraction = maxHeight;
                });
              } else {
                // If only one point is selected from map, just update the text field
                // and return to the main search state for the user to select the other point.
                print(
                  "Only one point set via map. Returning to search fields.",
                );
                setState(() {
                  bottomSheetHeightFraction =
                      normalHeight; // Go back to search height
                  _markers.clear(); // Clear the single marker for a fresh start
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
                  print("Pickup field tapped. Setting active.");
                  isExpanded = true;
                  isPickupActive = true;
                  bottomSheetHeightFraction = normalHeight;
                  _showRideOptionsUI = false;
                  _showConfirmPickupUI = false;
                  _markers.clear();
                  _polylines.clear();
                }),
            onChanged: (text) {
              print("Pickup text changed: $text");
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
                  print("Destination field tapped. Setting active.");
                  isExpanded = true;
                  isPickupActive = false; // Set to false for destination
                  bottomSheetHeightFraction = normalHeight;
                  _showRideOptionsUI = false;
                  _showConfirmPickupUI = false;
                  _markers.clear();
                  _polylines.clear();
                }),
            onChanged: (text) {
              print("Destination text changed: $text");
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
    print("Building ride options UI.");
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
                "Choose your ride",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickupController.text,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey),
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            destinationController.text,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildRideOption('Auto', 'assets/images/auto.webp', ''),
              _buildRideOption('Courier', 'assets/images/courier.png', ''),
              _buildRideOption('Uber Go', 'assets/images/suv.webp', ''),
              _buildRideOption('Moto', 'assets/images/moto.png', ''),
              _buildRideOption('XL Rentals', 'assets/images/rental.png', ''),
            ],
          ),
        ),

        // Cash Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PaymentOptionsScreen(
                          rideTitle: selectedRideTitle,
                          price: _calculatedPrices[selectedRideTitle] ?? 0.0,
                          selectedRideType: selectedRideTitle,
                          pickupLocation: pickupController.text,
                          destinationLocation: destinationController.text,
                        ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Cash',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Choose Ride Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              print("Proceeding with $selectedRideTitle ride.");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PaymentOptionsScreen(
                        rideTitle: selectedRideTitle,
                        price: _calculatedPrices[selectedRideTitle] ?? 0.0,
                        selectedRideType: selectedRideTitle,
                        pickupLocation: pickupController.text,
                        destinationLocation: destinationController.text,
                      ),
                ),
              );
            },
            child: Text("Choose $selectedRideTitle"),
          ),
        ),
      ],
    );
  }

  Widget _buildRideOption(String title, String imagePath, String description) {
    double? originalPrice = _calculatedOriginalPrices[title];
    double? currentPrice = _calculatedPrices[title];
    String? travelTime = _calculatedTravelTimes[title]; // Example: "6 min"

    if (currentPrice == null || travelTime == null) {
      return const SizedBox.shrink();
    }

    // Calculate ETA
    final now = DateTime.now();
    final eta = now.add(
      Duration(
        minutes:
            int.tryParse(
              RegExp(r'\d+').firstMatch(travelTime)?.group(0) ?? '0',
            ) ??
            0,
      ),
    );
    final etaFormatted = TimeOfDay.fromDateTime(
      eta,
    ).format(context); // e.g., 2:32 PM

    return Card(
      color:
          selectedRideTitle == title
              ? Colors.blue.shade900
              : Colors.grey.shade900,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedRideTitle = title;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Image.asset(imagePath, width: 50, height: 50),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$etaFormatted · $travelTime',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (originalPrice != null && originalPrice > currentPrice)
                    Text(
                      '₹${originalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '₹${currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
