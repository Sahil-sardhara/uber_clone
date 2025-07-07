// lib/add_payment_method_screen.dart
import 'package:flutter/material.dart';
import 'package:uber/pages/add_password_screen.dart';
// <--- Add this import

class AddPaymentMethodScreen extends StatelessWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Back arrow icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          "Add payment method",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildPaymentOptionTile(
            icon: Icons.card_giftcard, // Placeholder icon
            title: "Gift card",
            onTap: () {
              Navigator.push(
                // <--- Added Navigation here
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPasswordScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildPaymentOptionTile(
            icon: Icons.credit_card,
            title: "Credit or debit card",
            onTap: () {
              Navigator.push(
                // <--- Added Navigation here
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPasswordScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildPaymentOptionTile(
            icon: Icons.payment, // Placeholder icon
            title: "Amazon Pay balance",
            subtitle: "5% back as Uber Cash for Amazon Prime members",
            onTap: () {
              Navigator.push(
                // <--- Added Navigation here
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPasswordScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: const TextStyle(color: Colors.green, fontSize: 12),
              )
              : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
