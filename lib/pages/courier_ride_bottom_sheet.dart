import 'package:flutter/material.dart';

class CourierRideBottomSheet extends StatelessWidget {
  final String pickupAddress;
  final String dropAddress;
  final double price;
  final String timeEstimate;

  const CourierRideBottomSheet({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.price,
    required this.timeEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 50,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Courier",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              Text(
                "₹${price.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                "$timeEstimate arrival",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Courier ride confirmed")),
              );
              Navigator.pop(context);
            },
            child: const Text("Confirm Pickup"),
          ),
        ],
      ),
    );
  }
}
