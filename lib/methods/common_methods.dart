import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class CommonMethod {
  Future<bool> checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    // Check for network connection (WiFi or Mobile)
    if (connectionResult == ConnectivityResult.none) {
      if (!context.mounted) return false;
      displaySnackbar("No network connection. Please check your settings.", context);
      return false;
    }

    // Check for actual internet access
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Internet is available
      }
    } on SocketException catch (_) {
      if (!context.mounted) return false;
      displaySnackbar("Your Internet is not available. Try again.", context);
      return false;
    }

    return false;
  }

  void displaySnackbar(String messageText, BuildContext context) {
    final snackbar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}
