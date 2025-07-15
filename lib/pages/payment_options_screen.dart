// lib/payment_options_screen.dart
import 'package:flutter/material.dart';
import 'package:uber/pages/add_payment_method_screen.dart';
import 'package:uber/pages/add_voucher_screen.dart';
import 'package:uber/pages/vouchers_screen.dart';

class PaymentOptionsScreen extends StatelessWidget {
  const PaymentOptionsScreen({super.key, required String rideTitle, required double price, required String selectedRideType, required String pickupLocation, required String destinationLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), // 'X' icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          "Payment options",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal/Business buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person, color: Colors.black),
                    label: const Text(
                      "Personal",
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.business_center,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Business",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Uber balances section
            Row(
              children: [
                const Text(
                  "Uber balances:",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  "₹0.00",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: false, // You'll manage this state in a StatefulWidget
                  onChanged: (bool value) {
                    // Handle switch toggle
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.grey,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade700,
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Payment methods section
            const Text(
              "Payment methods",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildPaymentOption(
              icon: Icons.money,
              iconColor: Colors.green,
              title: "Cash",
              showCheck: true,
            ),
            const Divider(color: Colors.white12, height: 1),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPaymentMethodScreen(),
                  ),
                );
              },
              child: _buildPaymentOption(
                icon: Icons.add,
                iconColor: Colors.white,
                title: "Add payment method",
                showCheck: false,
              ),
            ),
            const SizedBox(height: 30),
            // Vouchers section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Vouchers",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      // <--- Added Navigation here
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VouchersScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "See details",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVoucherScreen(),
                  ),
                );
              },
              child: _buildPaymentOption(
                icon: Icons.add,
                iconColor: Colors.white,
                title: "Add voucher code",
                showCheck: false,
              ),
            ),
            const SizedBox(height: 30),
            // Unavailable section
            const Text(
              "Unavailable",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildPaymentOption(
              icon: Icons.qr_code_scanner, // Changed icon for UPI Scan
              iconColor: Colors.white54,
              title: "UPI Scan and Pay",
              showCheck: false,
              isUnavailable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    bool showCheck = false,
    bool isUnavailable = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: isUnavailable ? Colors.white54 : iconColor),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: isUnavailable ? Colors.white54 : Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (showCheck) const Icon(Icons.check, color: Colors.white),
        ],
      ),
    );
  }
}
