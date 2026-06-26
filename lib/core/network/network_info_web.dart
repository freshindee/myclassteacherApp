import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';
import 'network_info.dart';

/// Reachability check for web (no dart:socket / [InternetAddress]).
///
/// Uses the same exam API host the app already calls so CORS should match real usage.
class NetworkInfoWeb implements NetworkInfo {
  static final Uri _probeUri = Uri.parse('${ApiEndpoints.examApiBaseUrl}/');

  @override
  Future<bool> get isConnected async {
    try {
      final response = await http
          .head(_probeUri)
          .timeout(const Duration(seconds: 8));
      // Any HTTP response means the browser reached the host; 405 etc. still counts as online.
      return response.statusCode < 600;
    } catch (_) {
      try {
        final r = await http.get(_probeUri).timeout(const Duration(seconds: 8));
        return r.statusCode < 600;
      } catch (_) {
        // Probe may fail (offline, CORS, blocked HEAD). Let API calls decide; avoid false "offline" wall.
        return true;
      }
    }
  }
}
