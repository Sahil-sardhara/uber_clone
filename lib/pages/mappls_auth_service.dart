
import 'dart:convert';

import 'package:http/http.dart' as http;

class MapplsAuthService {
  static const String _clientId = '96dHZVzsAuvicePllYB4EzswVKWB29kQCprpkOmJJiOKcqWekQqpg9tr5WSPkk8znu5WnaAoE3tG9pq3rKAdQ0BIP-lrskFm';       // <-- paste here
  static const String _clientSecret = 'lrFxI-iSEg97iPLJJPXIoyksHIBazXT5ILLIzNOkyUoR_b13dA_Be_M8YYQ8qQ5gcsIlExOKUPB59lkwwvpaUVxNPrOCh982dWXeRJTWCnQ='; // <-- paste here

  static Future<String> getAccessToken() async {
    final response = await http.post(
      Uri.parse('https://outpost.mappls.com/api/security/oauth/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to get access token: ${response.body}');
    }
  }
}
