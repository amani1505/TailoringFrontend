import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/measurement_model.dart';
import '../models/tailor_model.dart';

/// Comprehensive API client for the Tailoring Backend
/// Base URL: http://localhost:3000/api/v1
///
/// Platform-specific URLs:
/// - Android Emulator: http://10.0.2.2:3000/api/v1
/// - iOS Simulator: http://localhost:3000/api/v1
/// - Physical Device: http://<your-computer-ip>:3000/api/v1
class TailoringApiClient {
  // Change this based on your environment
  // Using your computer's actual IP address (192.168.0.55)
  // because 10.0.2.2 is being blocked by firewall
  static const String baseUrl = 'http://192.168.0.29:3003/api/v1';
  static const Duration timeout = Duration(seconds: 30);

  // ============ HEALTH CHECK ============

  /// Check server health and availability
  static Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return ApiResponse.success(jsonDecode(response.body));
      } else {
        return ApiResponse.error('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Health check error: $e');
    }
  }

  // ============ USER ENDPOINTS ============

  /// Create a new user
  static Future<ApiResponse<User>> createUser({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? gender,
    double? height,
    double? weight,
  }) async {
    try {
      final body = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (gender != null) 'gender': gender,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend returns { success: true, data: {...}, message: "..." }
        // Extract the actual user data from the 'data' field
        final userData = responseData['data'] ?? responseData;
        return ApiResponse.success(User.fromJson(userData));
      } else {
        return ApiResponse.error('Failed to create user: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Create user error: $e');
    }
  }

  /// Get all users
  static Future<ApiResponse<List<User>>> getAllUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users);
      } else {
        return ApiResponse.error('Failed to get users: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get users error: $e');
    }
  }

  /// Get user by ID
  static Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/$userId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(User.fromJson(data));
      } else {
        return ApiResponse.error('Failed to get user: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get user error: $e');
    }
  }

  /// Update user
  static Future<ApiResponse<User>> updateUser(
      String userId, Map<String, dynamic> updates) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updates),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(User.fromJson(data));
      } else {
        return ApiResponse.error('Failed to update user: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Update user error: $e');
    }
  }

  /// Delete user
  static Future<ApiResponse<void>> deleteUser(String userId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/users/$userId'))
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Delete user error: $e');
    }
  }

  // ============ MEASUREMENT ENDPOINTS ============

  /// Process and save measurement from images
  static Future<ApiResponse<Measurement>> processMeasurement({
    required String frontImagePath,
    required String sideImagePath,
    required String userId,
    required double height,
    required String gender,
    String? notes,
  }) async {
    try {
      // Create multipart/form-data request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/measurements/process'),
      );

      // Explicitly set headers (MultipartRequest sets Content-Type automatically)
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add images as multipart files with explicit MIME types
      // Determine MIME type from file extension
      final frontExtension = frontImagePath.split('.').last.toLowerCase();
      final sideExtension = sideImagePath.split('.').last.toLowerCase();

      final frontMimeType = _getMimeType(frontExtension);
      final sideMimeType = _getMimeType(sideExtension);

      final frontFile = await http.MultipartFile.fromPath(
        'frontImage',
        frontImagePath,
        contentType: frontMimeType,
      );
      final sideFile = await http.MultipartFile.fromPath(
        'sideImage',
        sideImagePath,
        contentType: sideMimeType,
      );

      request.files.add(frontFile);
      request.files.add(sideFile);

      // Add fields as form data
      request.fields.addAll({
        'userId': userId,
        'height': height.toString(),
        'gender': gender,
        if (notes != null) 'notes': notes,
      });

      // DEBUG: Print request details before sending
      print('=== MEASUREMENT REQUEST DEBUG ===');
      print('URL: ${request.url}');
      print('Method: ${request.method}');
      print('\nHEADERS (Note: Content-Type with boundary will be auto-added by send()):');
      print('  Accept: application/json (response format we want)');
      print('  Content-Type: multipart/form-data; boundary=<auto-generated>');
      print('  ^^ This is automatically set by MultipartRequest.send()');
      request.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('\nFILES (sent as multipart/form-data):');
      print('  Front Image:');
      print('    - Field name: ${frontFile.field}');
      print('    - Filename: ${frontFile.filename}');
      print('    - Content-Type: ${frontFile.contentType}');
      print('    - Length: ${frontFile.length} bytes');
      print('    - Path: $frontImagePath');
      print('    - Extension: ${frontImagePath.split('.').last}');
      print('  Side Image:');
      print('    - Field name: ${sideFile.field}');
      print('    - Filename: ${sideFile.filename}');
      print('    - Content-Type: ${sideFile.contentType}');
      print('    - Length: ${sideFile.length} bytes');
      print('    - Path: $sideImagePath');
      print('    - Extension: ${sideImagePath.split('.').last}');
      print('\nFORM FIELDS (sent as multipart/form-data):');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });
      print('\n📤 Sending as: multipart/form-data');
      print('================================\n');

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      // DEBUG: Print response details
      print('\n=== MEASUREMENT RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('\nResponse Body:');
      print(response.body);
      print('================================\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Successfully processed measurement');
        print('Parsed response: $responseData');

        // Backend returns { success: true, data: {...}, message: "..." }
        // Extract the actual measurement data from the 'data' field
        final measurementData = responseData['data'] ?? responseData;
        print('Measurement data: $measurementData');

        return ApiResponse.success(Measurement.fromJson(measurementData));
      } else {
        print('❌ Failed to process measurement');
        return ApiResponse.error(
            'Failed to process measurement: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Process measurement error: $e');
    }
  }

  /// Get all measurements
  static Future<ApiResponse<List<Measurement>>> getAllMeasurements() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/measurements'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final measurements =
            data.map((json) => Measurement.fromJson(json)).toList();
        return ApiResponse.success(measurements);
      } else {
        return ApiResponse.error(
            'Failed to get measurements: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get measurements error: $e');
    }
  }

  /// Get measurements for a specific user
  static Future<ApiResponse<List<Measurement>>> getUserMeasurements(
      String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/measurements/user/$userId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final measurements =
            data.map((json) => Measurement.fromJson(json)).toList();
        return ApiResponse.success(measurements);
      } else {
        return ApiResponse.error(
            'Failed to get user measurements: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get user measurements error: $e');
    }
  }

  /// Get single measurement by ID
  static Future<ApiResponse<Measurement>> getMeasurementById(
      String measurementId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/measurements/$measurementId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Measurement.fromJson(data));
      } else {
        return ApiResponse.error(
            'Failed to get measurement: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get measurement error: $e');
    }
  }

  /// Share measurement with a tailor
  static Future<ApiResponse<Map<String, dynamic>>> shareMeasurement({
    required String measurementId,
    required String tailorId,
    required String userId,
    String? message,
  }) async {
    try {
      final body = {
        'measurementId': measurementId,
        'tailorId': tailorId,
        if (message != null) 'message': message,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/measurements/share?userId=$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse.success(jsonDecode(response.body));
      } else {
        return ApiResponse.error(
            'Failed to share measurement: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Share measurement error: $e');
    }
  }

  /// Get shared measurements for a user
  static Future<ApiResponse<List<Map<String, dynamic>>>> getSharedMeasurements(
      String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/measurements/shared/user/$userId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return ApiResponse.success(
            data.map((e) => e as Map<String, dynamic>).toList());
      } else {
        return ApiResponse.error(
            'Failed to get shared measurements: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get shared measurements error: $e');
    }
  }

  /// Delete measurement
  static Future<ApiResponse<void>> deleteMeasurement(
      String measurementId, String userId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/measurements/$measurementId?userId=$userId'),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error(
            'Failed to delete measurement: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Delete measurement error: $e');
    }
  }

  // ============ TAILOR ENDPOINTS ============

  /// Create a new tailor
  static Future<ApiResponse<Tailor>> createTailor({
    required String businessName,
    required String ownerName,
    required String email,
    String? phoneNumber,
    String? city,
    List<String>? specialties,
  }) async {
    try {
      final body = {
        'businessName': businessName,
        'ownerName': ownerName,
        'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (city != null) 'city': city,
        if (specialties != null) 'specialties': specialties,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/tailors'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Tailor.fromJson(data));
      } else {
        return ApiResponse.error('Failed to create tailor: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Create tailor error: $e');
    }
  }

  /// Get all tailors
  static Future<ApiResponse<List<Tailor>>> getAllTailors() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/tailors'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tailors = data.map((json) => Tailor.fromJson(json)).toList();
        return ApiResponse.success(tailors);
      } else {
        return ApiResponse.error('Failed to get tailors: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get tailors error: $e');
    }
  }

  /// Get tailor by ID
  static Future<ApiResponse<Tailor>> getTailorById(String tailorId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/tailors/$tailorId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Tailor.fromJson(data));
      } else {
        return ApiResponse.error('Failed to get tailor: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get tailor error: $e');
    }
  }

  /// Get measurements received by a tailor
  static Future<ApiResponse<List<Map<String, dynamic>>>>
      getTailorMeasurements(String tailorId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/tailors/$tailorId/measurements'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return ApiResponse.success(
            data.map((e) => e as Map<String, dynamic>).toList());
      } else {
        return ApiResponse.error(
            'Failed to get tailor measurements: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Get tailor measurements error: $e');
    }
  }

  /// Update tailor
  static Future<ApiResponse<Tailor>> updateTailor(
      String tailorId, Map<String, dynamic> updates) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/tailors/$tailorId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updates),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Tailor.fromJson(data));
      } else {
        return ApiResponse.error('Failed to update tailor: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Update tailor error: $e');
    }
  }

  /// Delete tailor
  static Future<ApiResponse<void>> deleteTailor(String tailorId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/tailors/$tailorId'))
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to delete tailor: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Delete tailor error: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Get MIME type from file extension
  static MediaType _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      default:
        // Default to jpeg if unknown
        return MediaType('image', 'jpeg');
    }
  }
}

// ============ API RESPONSE WRAPPER ============

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse._(isSuccess: false, errorMessage: message);
  }
}
