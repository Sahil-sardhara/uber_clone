import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uber/pages/slapsh_page.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isPermissionGranted
        ? const SplashScreen()
        : const Scaffold(
            body: Center(
              child: Text("Waiting for location permission..."),
            ),
          );
  }
}
