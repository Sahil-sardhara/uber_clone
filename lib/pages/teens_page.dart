import 'package:flutter/material.dart';

class AddTeenPage extends StatelessWidget {
  const AddTeenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add a teenager",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Image.asset('assets/images/teenager.jpg', fit: BoxFit.cover),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Invite your teenager to Uber",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Now you can let your teenager (ages 13–17) request trips with:",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                FeatureItem("Top-rated drivers only"),
                FeatureItem("Unexpected event sensing"),
                FeatureItem("Live trip tracking"),
                FeatureItem("PIN verification"),
                FeatureItem("Audio recording"),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                // TODO: Implement choose contact
              },
              child: const Text(
                "Choose contact",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;
  const FeatureItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 12, top: 12, bottom: 12),
          child: Icon(Icons.radio_button_unchecked, color: Colors.white),
        ),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
