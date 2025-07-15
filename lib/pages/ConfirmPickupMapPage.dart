import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';

class ConfirmPickupMapPage extends StatefulWidget {
  final LatLng pickupLatLng;
  final LatLng destinationLatLng;
  final String selectedRideType;
  final double estimatedPrice;
  final String estimatedTime;

  const ConfirmPickupMapPage({
    super.key,
    required this.pickupLatLng,
    required this.destinationLatLng,
    required this.selectedRideType,
    required this.estimatedPrice,
    required this.estimatedTime,
  });

  @override
  State<ConfirmPickupMapPage> createState() => _ConfirmPickupMapPageState();
}

class _ConfirmPickupMapPageState extends State<ConfirmPickupMapPage> {
  late MapplsMapController mapController;

  @override
  void initState() {
    super.initState();
    _drawRoute();
  }

  Future<void> _drawRoute() async {
    if (mapController == null) return;

    mapController.clearLines();
    await mapController.addLine(LineOptions(
      geometry: [widget.pickupLatLng, widget.destinationLatLng],
      lineColor: "#3b9def",
      lineWidth: 5.0,
    ));

    await mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            widget.pickupLatLng.latitude <= widget.destinationLatLng.latitude
                ? widget.pickupLatLng.latitude
                : widget.destinationLatLng.latitude,
            widget.pickupLatLng.longitude <= widget.destinationLatLng.longitude
                ? widget.pickupLatLng.longitude
                : widget.destinationLatLng.longitude,
          ),
          northeast: LatLng(
            widget.pickupLatLng.latitude >= widget.destinationLatLng.latitude
                ? widget.pickupLatLng.latitude
                : widget.destinationLatLng.latitude,
            widget.pickupLatLng.longitude >= widget.destinationLatLng.longitude
                ? widget.pickupLatLng.longitude
                : widget.destinationLatLng.longitude,
          ),
        ),
        
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MapplsMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLatLng,
              zoom: 14,
            ),
            onMapCreated: (MapplsMapController controller) {
              mapController = controller;
              _drawRoute();
            },
          ),
          Positioned(
            top: 60,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedRideType,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${widget.estimatedTime}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Price: ₹${widget.estimatedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        // You can return this to previous screen or start ride logic
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm Pick-up'),
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
}
