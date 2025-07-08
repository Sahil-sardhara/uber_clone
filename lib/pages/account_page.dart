import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uber/pages/uberaccount_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String username = "Loading...";
  String rating = "5.00";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          username = "❌ Not signed in";
        });
        return;
      }

      print("✅ Current Firebase UID: ${user.uid}");

      final ref = FirebaseDatabase.instance.ref("users/${user.uid}/name");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        setState(() {
          username = snapshot.value.toString();
        });
      } else {
        setState(() {
          username = "❌ Name not found";
        });
      }
    } catch (e) {
      print("❌ Realtime DB error: $e");
      setState(() {
        username = "❌ Error loading name";
      });
    }
  }

  Widget _buildIconTile(IconData icon, String title, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UberAccount()),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Shortcuts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShortcut("Help", Icons.help_outline),
                _buildShortcut("Wallet", Icons.account_balance_wallet_outlined),
                _buildShortcut("Activity", Icons.bookmark_border),
              ],
            ),

            const SizedBox(height: 20),

            _buildCardTile(
              title: "Safety check-up",
              subtitle: "Learn ways to make rides safer",
              trailing: _buildProgressRing("1/5"),
            ),
            _buildCardTile(
              title: "Privacy check-up",
              subtitle: "Take an interactive tour of your privacy settings",
              trailing: const Icon(
                Icons.assignment,
                size: 36,
                color: Colors.white,
              ),
            ),
            _buildCardTile(
              title: "Estimated CO₂ saved",
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.eco_outlined, color: Colors.green),
                  SizedBox(width: 4),
                  Text("0 g", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            _buildCardTile(
              title: "Uber for Teens",
              subtitle: "Invite your teenager to set up their own account",
              trailing: const Icon(Icons.celebration, color: Colors.redAccent),
            ),

            const SizedBox(height: 20),

            _buildIconTile(Icons.settings, "Settings"),
            _buildIconTile(
              Icons.umbrella_outlined,
              "Rider insurance",
              trailing: const Text(
                "₹10L cover for ₹3/trip",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            _buildIconTile(Icons.mail_outline, "Messages"),
            _buildIconTile(Icons.card_giftcard_outlined, "Send a gift"),
            _buildIconTile(
              Icons.group_outlined,
              "Saved groups",
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "NEW",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            _buildIconTile(
              Icons.work_outline,
              "Set up your business profile",
              trailing: const Text(
                "Automate work travel & meal expenses",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            _buildIconTile(Icons.person_outline, "Manage Uber account"),
            _buildIconTile(Icons.info_outline, "Legal"),

            const SizedBox(height: 30),
            const Center(
              child: Text(
                "v3.676.10001",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildCardTile({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildProgressRing(String text) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: 0.2,
            strokeWidth: 4,
            backgroundColor: Colors.white12,
            color: Colors.blue,
          ),
        ),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
