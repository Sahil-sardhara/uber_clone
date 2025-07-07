import 'package:flutter/material.dart';

class IntercityTripPage extends StatefulWidget {
  const IntercityTripPage({super.key});

  @override
  State<IntercityTripPage> createState() => _IntercityTripPageState();
}

class _IntercityTripPageState extends State<IntercityTripPage> {
  bool isOneWay = true;
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController pickupDateTimeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFF121212);
    final Color fieldColor = const Color(0xFF2C2C2C);
    final Color promoBgColor = const Color(0xFF0F4A0F);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Plan your intercity trip',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Promo banner
            Container(
              decoration: BoxDecoration(
                color: promoBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: const [
                  Icon(Icons.local_offer, color: Colors.greenAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Get 3% OFF up to ₹500 on your next trip!',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Trip type toggle buttons
            Container(
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildTripTypeButton('One way', isOneWay, () {
                    setState(() {
                      isOneWay = true;
                    });
                  }),
                  _buildTripTypeButton('Round trip', !isOneWay, () {
                    setState(() {
                      isOneWay = false;
                    });
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Destination input
            _buildInputField(
              icon: Icons.location_on_outlined,
              hint: 'Enter destination',
              controller: destinationController,
              fieldColor: fieldColor,
            ),

            const SizedBox(height: 12),

            // Pickup date & time input
            _buildInputField(
              icon: Icons.arrow_upward_outlined,
              hint: 'Pick-up date and time',
              controller: pickupDateTimeController,
              fieldColor: fieldColor,
              readOnly: true,
              onTap: () async {
                // DateTime picker logic here (optional)
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1),
                );

                if (pickedDate != null) {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {
                    final combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                    pickupDateTimeController.text = combined.toString().substring(0, 16);
                  }
                }
              },
            ),

            const SizedBox(height: 24),

            // Find trips button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Your find trips logic here
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Find trips',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.black87),
                ],
              ),
            ),

            // No footer/banner as requested
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeButton(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.transparent : Colors.grey[850],
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 1.8,
            ),
            borderRadius: selected
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required Color fieldColor,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
