import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPermissionGranted = false;
  LatLng _currentPosition = const LatLng(
    23.0225,
    72.5714,
  ); // Default: Ahmedabad
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isPermissionGranted = true;
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });

      // Move camera after a short delay (ensure map is created)
      Future.delayed(const Duration(milliseconds: 500), () {
        _moveCameraToCurrentLocation();
      });
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Uber",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
        ),
      ),
      drawer: Drawer(),
      body:
          _isPermissionGranted
              ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Optional: move camera immediately if location is known
                  _moveCameraToCurrentLocation();
                },
              )
              : const Center(child: Text("Waiting for location permission...")),
    );
  }
}
