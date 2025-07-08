import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class UberAccount extends StatefulWidget {
  const UberAccount({super.key});

  @override
  State<UberAccount> createState() => _UberAccountState();
}

class _UberAccountState extends State<UberAccount>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String name = "Loading...";
  String email = "";
  String phoneNumber = "";
  String gender = "Man";
  String blockedStatus = "";
  String? profileImageUrl;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DatabaseReference ref = FirebaseDatabase.instance.ref("users/${user.uid}");
    DatabaseEvent event = await ref.once();
    final data = event.snapshot.value as Map?;

    if (data != null) {
      setState(() {
        name = data['name'] ?? "Unknown";
        email = data['email'] ?? "";
        phoneNumber = data['phonenumber'] ?? "";
        blockedStatus = data['blockedstatus'] ?? "";
        profileImageUrl = data['profileImage'];
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleImagePick(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleImagePick(ImageSource.gallery);
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.redAccent),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    final permissionStatus =
        source == ImageSource.camera
            ? await Permission.camera.request()
            : await Permission.photos.request();

    if (permissionStatus.isGranted) {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        setState(() {
          _profileImage = File(picked.path);
        });
        await _uploadProfileImage(_profileImage!);
      }
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Permission required',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'To update your profile photo, please allow camera or gallery access in your device settings.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadProfileImage(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storageRef = FirebaseStorage.instance.ref().child(
      "user_profiles/${user.uid}/profile.jpg",
    );

    await storageRef.putFile(image);
    final url = await storageRef.getDownloadURL();

    await FirebaseDatabase.instance
        .ref("users/${user.uid}/profileImage")
        .set(url);

    setState(() {
      profileImageUrl = url;
    });
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Text(
          "Uber Account",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: "Home"),
        Tab(text: "Personal info"),
        Tab(text: "Security"),
        Tab(text: "Privacy & Data"),
      ],
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white12,
          backgroundImage:
              _profileImage != null
                  ? FileImage(_profileImage!)
                  : (profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : null)
                      as ImageProvider?,
          child:
              (_profileImage == null && profileImageUrl == null)
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSquareButton(Icons.person, "Personal info", 1),
            _buildSquareButton(Icons.security, "Security", 2),
            _buildSquareButton(Icons.lock_outline, "Privacy & Data", 3),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          "Suggestions",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildSuggestionCard(),
      ],
    );
  }

  Widget _buildSquareButton(IconData icon, String title, int tabIndex) {
    return GestureDetector(
      onTap: () => _tabController.animateTo(tabIndex),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Complete your account checkup",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Make Uber work better for you and keep you secure.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text(
              "Begin checkup",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              backgroundImage:
                  _profileImage != null
                      ? FileImage(_profileImage!)
                      : (profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null)
                          as ImageProvider?,
              child:
                  (_profileImage == null && profileImageUrl == null)
                      ? const Icon(Icons.camera_alt, color: Colors.white)
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoTile("Name", name),
        _buildInfoTile("Gender", gender),
        _buildInfoTile("Phone number", phoneNumber),
        _buildInfoTile("Email", email),
        _buildInfoTile("Language", "Update device language", isLink: true),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: const [
        ListTile(
          title: Text("Password", style: TextStyle(color: Colors.white)),
          subtitle: Text(
            "Change your password",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ListTile(
          title: Text(
            "Authenticator app",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "Add extra layer of security",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ListTile(
          title: Text(
            "2-step verification",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "Secure your account with 2-step verification",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ListTile(
          title: Text("Recovery phone", style: TextStyle(color: Colors.white)),
          subtitle: Text(
            "Add backup phone number",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: const [
        ListTile(
          title: Text("Privacy Center", style: TextStyle(color: Colors.white)),
          subtitle: Text(
            "Control your privacy and learn how we protect it.",
            style: TextStyle(color: Colors.grey),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.white),
        ),
        Divider(color: Colors.white24),
        ListTile(
          title: Text(
            "Third-party apps with account access",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "You'll see them here once allowed.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, {bool isLink = false}) {
    bool isEditable =
        title == "Name" || title == "Email" || title == "Phone number";

    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white)),
      trailing:
          isLink
              ? const Icon(Icons.open_in_new, color: Colors.white)
              : isEditable
              ? const Icon(Icons.edit, color: Colors.white)
              : null,
      onTap: isEditable ? () => _editField(title, value) : null,
    );
  }

  void _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              "Edit $field",
              style: const TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter $field",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final newValue = controller.text.trim();
                  if (newValue.isNotEmpty && user != null) {
                    final ref = FirebaseDatabase.instance.ref(
                      "users/${user.uid}",
                    );
                    if (field == "Name") {
                      await ref.update({'name': newValue});
                      setState(() => name = newValue);
                    } else if (field == "Email") {
                      await ref.update({'email': newValue});
                      setState(() => email = newValue);
                    } else if (field == "Phone number") {
                      await ref.update({'phonenumber': newValue});
                      setState(() => phoneNumber = newValue);
                    }
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHomeTab(),
                  _buildPersonalInfoTab(),
                  _buildSecurityTab(),
                  _buildPrivacyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
