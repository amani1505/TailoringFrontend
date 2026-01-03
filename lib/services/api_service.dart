import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class ApiService {
  // Update this to match your backend URL
  // Using computer's actual IP (192.168.0.55) because 10.0.2.2 is blocked
  // For local development: http://localhost:3003/api/v1
  // For Android emulator: http://192.168.0.55:3003/api/v1 (your backend port is 3003)
  // For iOS simulator: http://localhost:3003/api/v1
  // For physical device: http://192.168.0.55:3003/api/v1
  static const String baseUrl = 'http://192.168.0.29:3003/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectivityTimeout = Duration(seconds: 10);
  
  // Maximum file size (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
  
  // Supported image formats
  static const List<String> supportedFormats = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  
  /// Enhanced connectivity check with multiple fallbacks
  static Future<ConnectivityResult> checkConnectivity() async {
    print('=== CONNECTIVITY CHECK ===');
    
    // Method 1: Check server health endpoint
    try {
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(connectivityTimeout);
      
      if (healthResponse.statusCode == 200) {
        print('✓ Server health check passed');
        return ConnectivityResult.serverAvailable;
      } else {
        print('✗ Server health check failed: ${healthResponse.statusCode}');
      }
    } on SocketException catch (e) {
      print('✗ Server health check - Socket error: $e');
    } on TimeoutException catch (e) {
      print('✗ Server health check - Timeout: $e');
    } catch (e) {
      print('✗ Server health check - Error: $e');
    }
    
    // Method 2: Check general internet connectivity
    try {
      final internetResponse = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Accept': 'text/html'},
      ).timeout(connectivityTimeout);
      
      if (internetResponse.statusCode == 200) {
        print('✓ Internet available but server unreachable');
        return ConnectivityResult.internetOnlyServerDown;
      }
    } on SocketException catch (e) {
      print('✗ Internet check - Socket error: $e');
    } on TimeoutException catch (e) {
      print('✗ Internet check - Timeout: $e');
    } catch (e) {
      print('✗ Internet check - Error: $e');
    }
    
    // Method 3: Try alternative connectivity check
    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(connectivityTimeout);
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        print('✓ DNS resolution works - Internet available but server down');
        return ConnectivityResult.internetOnlyServerDown;
      }
    } catch (e) {
      print('✗ DNS lookup failed: $e');
    }
    
    print('✗ No connectivity detected');
    return ConnectivityResult.offline;
  }

  /// Validate image file before upload
  static Future<ValidationResult> _validateImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      // Check if file exists
      if (!await file.exists()) {
        return ValidationResult.error('Image file not found at path: $imagePath');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        return ValidationResult.error('Image file is empty');
      }
      
      if (fileSize > maxFileSize) {
        return ValidationResult.error('Image file too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum allowed: ${maxFileSize / 1024 / 1024}MB');
      }

      // Check file extension
      final fileExtension = path.extension(imagePath).toLowerCase();
      if (!supportedFormats.contains(fileExtension)) {
        return ValidationResult.error('Unsupported image format: $fileExtension. Supported formats: ${supportedFormats.join(', ')}');
      }

      // Validate image content by reading first few bytes
      final imageBytes = await file.readAsBytes();
      if (!_isValidImageFile(imageBytes, fileExtension)) {
        return ValidationResult.error('File appears to be corrupted or is not a valid image');
      }

      return ValidationResult.success(fileSize, fileExtension);
    } catch (e) {
      return ValidationResult.error('File validation failed: $e');
    }
  }

  /// Check if file is a valid image by examining file signature
  static bool _isValidImageFile(Uint8List bytes, String extension) {
    if (bytes.length < 8) return false;
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        // JPEG files start with FF D8 FF
        return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      case '.png':
        // PNG files start with 89 50 4E 47 0D 0A 1A 0A
        return bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
      case '.gif':
        // GIF files start with GIF87a or GIF89a
        final header = String.fromCharCodes(bytes.take(6));
        return header == 'GIF87a' || header == 'GIF89a';
      case '.webp':
        // WebP files have RIFF in first 4 bytes and WEBP in bytes 8-11
        return bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
               bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50;
      default:
        return true; // Allow unknown formats to pass through
    }
  }

  /// Main image upload method with enhanced validation and error handling
  static Future<UploadResult> uploadImage(String imagePath) async {
    print('=== STARTING UPLOAD PROCESS ===');
    
    try {
      // Step 1: Validate the image file
      final validationResult = await _validateImage(imagePath);
      if (!validationResult.isValid) {
        return UploadResult.fileError(validationResult.errorMessage!);
      }

      final fileSize = validationResult.fileSize!;
      final fileExtension = validationResult.fileExtension!;
      final fileName = path.basename(imagePath);
      
      print('=== FILE INFO ===');
      print('File path: $imagePath');
      print('File name: $fileName');
      print('File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
      print('File extension: $fileExtension');

      // Step 2: Check connectivity before attempting upload
      final connectivityResult = await checkConnectivity();
      
      switch (connectivityResult) {
        case ConnectivityResult.offline:
          print('Device is offline - caching for later');
          return UploadResult.offline('No internet connection detected');
          
        case ConnectivityResult.internetOnlyServerDown:
          print('Internet available but server is down - caching for later');
          return UploadResult.serverDown('Server is not accessible but internet is available');
          
        case ConnectivityResult.serverAvailable:
          print('Server is available - proceeding with upload');
          break;
      }

      // Step 3: Proceed with upload
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      
      print('Image bytes length: ${imageBytes.length}');
      print('First 10 bytes: ${imageBytes.take(10).toList()}');

      // Create multipart request with retry logic
      return await _performUpload(imageBytes, fileName, fileSize, fileExtension);

    } on SocketException catch (e) {
      print('✗ Network/Socket error: $e');
      return UploadResult.networkError('Network connection failed: ${e.message}');
    } on TimeoutException catch (e) {
      print('✗ Timeout error: $e');
      return UploadResult.timeout('Request timed out: ${e.message ?? 'Connection timeout'}');
    } on HttpException catch (e) {
      print('✗ HTTP error: $e');
      return UploadResult.networkError('HTTP error: ${e.message}');
    } on FileSystemException catch (e) {
      print('✗ File system error: $e');
      return UploadResult.fileError('File access error: ${e.message}');
    } catch (e) {
      print('✗ Unexpected error: $e');
      print('Error type: ${e.runtimeType}');
      return UploadResult.unknownError('Unexpected error: $e');
    }
  }

  /// Perform the actual upload with enhanced request configuration
  static Future<UploadResult> _performUpload(
    Uint8List imageBytes,
    String fileName,
    int fileSize,
    String fileExtension
  ) async {
    try {
      // Create multipart request
      // Backend expects /measurements/process, not /upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/measurements/process'),
      );

      // Determine content type
      final contentType = _getContentType(fileExtension);

      // Create multipart file with optimized settings
      final multipartFile = http.MultipartFile.fromBytes(
        'image', // Field name expected by server
        imageBytes,
        filename: fileName,
        contentType: contentType,
      );

      request.files.add(multipartFile);

      // Add comprehensive metadata fields
      request.fields.addAll({
        'file_size': fileSize.toString(),
        'file_name': fileName,
        'content_type': contentType.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': Platform.operatingSystem,
        'app_version': '1.0.0',
        'upload_id': _generateUploadId(),
      });

      // Add optimized headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-MeasurementApp/1.0.0 (${Platform.operatingSystem})',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate',
        'Cache-Control': 'no-cache',
      });

      _logRequestDetails(request);

      // Send request with timeout and progress tracking
      print('=== SENDING REQUEST ===');
      final response = await request.send().timeout(
        requestTimeout,
        onTimeout: () {
          throw TimeoutException('Request timeout after ${requestTimeout.inSeconds} seconds');
        },
      );

      return await _handleResponse(response);

    } catch (e) {
      print('✗ Upload execution error: $e');
      rethrow;
    }
  }

  /// Handle and parse the response
  static Future<UploadResult> _handleResponse(http.StreamedResponse response) async {
    print('=== RESPONSE INFO ===');
    print('Status code: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Content length: ${response.contentLength ?? 'unknown'}');

    final responseBody = await response.stream.bytesToString();
    print('Response body: $responseBody');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(responseBody);
        
        // Validate response structure
        if (jsonResponse is! Map<String, dynamic>) {
          throw FormatException('Invalid response format: expected JSON object');
        }
        
        print('✓ Upload successful: $jsonResponse');
        return UploadResult.success(jsonResponse);
      } catch (e) {
        print('JSON decode error: $e');
        return UploadResult.serverError('Invalid JSON response from server: $responseBody');
      }
    } else {
      print('✗ Server error: ${response.statusCode} - $responseBody');
      
      // Provide more specific error handling based on status code
      final errorMessage = _getErrorMessageForStatusCode(response.statusCode, responseBody);
      
      if (response.statusCode >= 500) {
        return UploadResult.serverError(errorMessage);
      } else if (response.statusCode == 413) {
        return UploadResult.fileError('File too large for server');
      } else if (response.statusCode == 415) {
        return UploadResult.fileError('Unsupported media type');
      } else {
        return UploadResult.clientError(errorMessage);
      }
    }
  }

  /// Get appropriate error message based on HTTP status code
  static String _getErrorMessageForStatusCode(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return 'Bad request: $responseBody';
      case 401:
        return 'Unauthorized access';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Upload endpoint not found';
      case 408:
        return 'Request timeout';
      case 413:
        return 'File too large';
      case 415:
        return 'Unsupported file type';
      case 429:
        return 'Too many requests - please try again later';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      case 504:
        return 'Gateway timeout';
      default:
        return 'HTTP error ${statusCode}: $responseBody';
    }
  }

  static void _logRequestDetails(http.MultipartRequest request) {
    print('=== REQUEST INFO ===');
    print('URL: ${request.url}');
    print('Method: ${request.method}');
    print('Headers: ${request.headers}');
    print('Fields: ${request.fields}');
    print('Files: ${request.files.length} file(s)');
    
    if (request.files.isNotEmpty) {
      final firstFile = request.files.first;
      print('File field name: ${firstFile.field}');
      print('File filename: ${firstFile.filename}');
      print('File content type: ${firstFile.contentType}');
      print('File length: ${firstFile.length} bytes');
    }
  }

  static MediaType _getContentType(String fileExtension) {
    switch (fileExtension) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg'); // Default fallback
    }
  }

  /// Generate unique upload ID for tracking
  static String _generateUploadId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Alternative upload method with different approach (simplified)
  static Future<UploadResult> uploadImageAlternative(String imagePath) async {
    try {
      print('=== TRYING ALTERNATIVE UPLOAD METHOD ===');
      
      final validationResult = await _validateImage(imagePath);
      if (!validationResult.isValid) {
        return UploadResult.fileError(validationResult.errorMessage!);
      }

      // Check connectivity first
      final connectivityResult = await checkConnectivity();
      if (connectivityResult != ConnectivityResult.serverAvailable) {
        return UploadResult.offline('Server not available via alternative method');
      }

      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      final fileName = path.basename(imagePath);

      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: _getContentType(path.extension(imagePath).toLowerCase()),
      );

      request.files.add(multipartFile);
      
      // Minimal headers for alternative method
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App-Alternative/1.0.0',
      });

      final streamedResponse = await request.send().timeout(requestTimeout);
      return await _handleResponse(streamedResponse);

    } catch (e) {
      print('Alternative upload error: $e');
      if (e is SocketException) {
        return UploadResult.networkError('Alternative method network error: ${e.message}');
      }
      return UploadResult.unknownError('Alternative method error: $e');
    }
  }

  /// Test basic connectivity with the server
  static Future<bool> testBasicConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      print('Basic connectivity test: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 404; // 404 is OK if endpoint doesn't exist
    } catch (e) {
      print('Basic connectivity test failed: $e');
      return false;
    }
  }
}

// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSize;
  final String? fileExtension;

  ValidationResult._(this.isValid, this.errorMessage, [this.fileSize, this.fileExtension]);

  static ValidationResult success(int fileSize, String fileExtension) => 
      ValidationResult._(true, null, fileSize, fileExtension);
  
  static ValidationResult error(String message) => 
      ValidationResult._(false, message);
}

// Enum for connectivity results
enum ConnectivityResult {
  serverAvailable,
  internetOnlyServerDown,
  offline,
}

// Enhanced result class for upload operations
class UploadResult {
  final UploadStatus status;
  final String message;
  final Map<String, dynamic>? data;

  UploadResult._(this.status, this.message, [this.data]);

  static UploadResult success(Map<String, dynamic> data) => 
      UploadResult._(UploadStatus.success, 'Upload successful', data);
  
  static UploadResult offline(String message) => 
      UploadResult._(UploadStatus.offline, message);
  
  static UploadResult serverDown(String message) => 
      UploadResult._(UploadStatus.serverDown, message);
  
  static UploadResult networkError(String message) => 
      UploadResult._(UploadStatus.networkError, message);
  
  static UploadResult serverError(String message) => 
      UploadResult._(UploadStatus.serverError, message);
  
  static UploadResult clientError(String message) => 
      UploadResult._(UploadStatus.clientError, message);
  
  static UploadResult timeout(String message) => 
      UploadResult._(UploadStatus.timeout, message);
  
  static UploadResult fileError(String message) => 
      UploadResult._(UploadStatus.fileError, message);
  
  static UploadResult unknownError(String message) => 
      UploadResult._(UploadStatus.unknownError, message);

  bool get isSuccess => status == UploadStatus.success;
  bool get shouldCache => status == UploadStatus.offline || 
                         status == UploadStatus.serverDown || 
                         status == UploadStatus.networkError ||
                         status == UploadStatus.timeout;
}

enum UploadStatus {
  success,
  offline,
  serverDown,
  networkError,
  serverError,
  clientError,
  timeout,
  fileError,
  unknownError,
}