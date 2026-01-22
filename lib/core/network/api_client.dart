import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base API client for making HTTP requests
/// Provides a reusable architecture for REST API calls throughout the app
class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    Map<String, String>? headers,
    Duration? timeout,
  })  : defaultHeaders = headers ?? {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        timeout = timeout ?? const Duration(seconds: 30);

  /// Base URL for the API
  String get _baseUrl => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  /// Make a GET request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final requestHeaders = {...defaultHeaders, ...?headers};

      print('🌐 [API] GET Request: $uri');
      print('🌐 [API] Headers: $requestHeaders');

      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(timeout);

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('🌐 [API ERROR] GET Request failed: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Make a POST request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Object? bodyObject,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final requestHeaders = {...defaultHeaders, ...?headers};

      final bodyJson = bodyObject != null
          ? jsonEncode(bodyObject)
          : body != null
              ? jsonEncode(body)
              : null;

      print('🌐 [API] POST Request: $uri');
      print('🌐 [API] Headers: $requestHeaders');
      print('🌐 [API] Body: $bodyJson');

      final response = await http
          .post(uri, headers: requestHeaders, body: bodyJson)
          .timeout(timeout);

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('🌐 [API ERROR] POST Request failed: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Make a PUT request
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Object? bodyObject,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final requestHeaders = {...defaultHeaders, ...?headers};

      final bodyJson = bodyObject != null
          ? jsonEncode(bodyObject)
          : body != null
              ? jsonEncode(body)
              : null;

      print('🌐 [API] PUT Request: $uri');
      print('🌐 [API] Headers: $requestHeaders');
      print('🌐 [API] Body: $bodyJson');

      final response = await http
          .put(uri, headers: requestHeaders, body: bodyJson)
          .timeout(timeout);

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('🌐 [API ERROR] PUT Request failed: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Make a DELETE request
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final requestHeaders = {...defaultHeaders, ...?headers};

      print('🌐 [API] DELETE Request: $uri');
      print('🌐 [API] Headers: $requestHeaders');

      final response = await http
          .delete(uri, headers: requestHeaders)
          .timeout(timeout);

      print('🌐 [API] Response Status: ${response.statusCode}');
      print('🌐 [API] Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('🌐 [API ERROR] DELETE Request failed: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$_baseUrl$path');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ));
    }

    return uri;
  }

  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    try {
      final statusCode = response.statusCode;
      final body = response.body;

      if (statusCode >= 200 && statusCode < 300) {
        if (body.isEmpty) {
          return ApiResponse.success(null);
        }

        try {
          // Trim the body in case there's leading/trailing whitespace
          final trimmedBody = body.trim();
          final jsonData = jsonDecode(trimmedBody);
          return ApiResponse.success(jsonData);
        } catch (e) {
          // If response is not JSON, log the error and return as string
          print('🌐 [API WARNING] Failed to parse JSON, returning as String: $e');
          print('🌐 [API WARNING] Response body (first 500 chars): ${body.length > 500 ? body.substring(0, 500) : body}');
          // If response is not JSON, return as string (caller will handle)
          return ApiResponse.success(body);
        }
      } else {
        String errorMessage = 'Request failed with status code: $statusCode';
        try {
          final errorJson = jsonDecode(body);
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'].toString();
          } else if (errorJson is Map && errorJson.containsKey('error')) {
            errorMessage = errorJson['error'].toString();
          }
        } catch (_) {
          // Use default error message
        }
        return ApiResponse.error(errorMessage, statusCode: statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }
}

/// API Response wrapper
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }
}
