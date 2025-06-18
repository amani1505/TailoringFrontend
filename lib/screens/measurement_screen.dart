import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_service.dart';
import 'package:frontend/utils/csv_generator.dart';
import 'package:frontend/utils/pdf_generator.dart';
import 'dart:io';

class MeasurementScreen extends StatefulWidget {
  final CameraDescription camera;
  const MeasurementScreen({required this.camera, super.key});

  @override
  _MeasurementScreenState createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isOffline = false;
  bool _isProcessing = false;
  File? _selectedImage;
  bool _showCamera = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  void _initializeCamera() {
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_showCamera || _controller == null) return;
    
    setState(() {
      _isProcessing = true;
      _debugInfo = 'Capturing image...';
    });
    
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      
      // Verify the captured image
      final capturedFile = File(image.path);
      final fileExists = await capturedFile.exists();
      final fileSize = fileExists ? await capturedFile.length() : 0;
      
      setState(() {
        _selectedImage = capturedFile;
        _showCamera = false;
        _debugInfo = 'Image captured: ${image.path}\nFile exists: $fileExists\nFile size: $fileSize bytes';
      });
      
      print('=== CAPTURED IMAGE INFO ===');
      print('Path: ${image.path}');
      print('File exists: $fileExists');
      print('File size: $fileSize bytes');
      
      await _processImage(image.path);
    } catch (e) {
      setState(() {
        _debugInfo = 'Capture failed: $e';
      });
      _showError('Failed to capture image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isProcessing = true;
      _debugInfo = 'Picking image from gallery...';
    });
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // Verify the picked image
        final selectedFile = File(pickedFile.path);
        final fileExists = await selectedFile.exists();
        final fileSize = fileExists ? await selectedFile.length() : 0;
        
        setState(() {
          _selectedImage = selectedFile;
          _showCamera = false;
          _debugInfo = 'Image picked: ${pickedFile.path}\nFile exists: $fileExists\nFile size: $fileSize bytes';
        });
        
        print('=== PICKED IMAGE INFO ===');
        print('Path: ${pickedFile.path}');
        print('File exists: $fileExists');
        print('File size: $fileSize bytes');
        
        await _processImage(pickedFile.path);
      } else {
        setState(() {
          _debugInfo = 'No image selected';
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo = 'Gallery pick failed: $e';
      });
      _showError('Failed to pick image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

Future<void> _processImage(String imagePath) async {
    setState(() {
      _debugInfo = 'Processing image: $imagePath';
    });
    
    try {
      // Double-check file exists before processing
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at: $imagePath');
      }
      
      final fileSize = await file.length();
      print('=== PROCESSING IMAGE ===');
      print('Path: $imagePath');
      print('Size: $fileSize bytes');
      
      setState(() {
        _debugInfo = 'Checking connectivity and uploading...\nFile: $imagePath\nSize: $fileSize bytes';
      });

      // Use the enhanced upload method
      final uploadResult = await ApiService.uploadImage(imagePath);

      // Handle different result types
      switch (uploadResult.status) {
        case UploadStatus.success:
          setState(() {
            _debugInfo = 'Upload successful!\nResponse: ${uploadResult.data}';
            _isOffline = false;
          });
          _showSuccessDialog(uploadResult.data!);
          await PdfGenerator.generateReport(uploadResult.data!['measurements']);
          await CsvGenerator.exportMeasurements(uploadResult.data!['measurements']);
          break;

        case UploadStatus.offline:
          setState(() {
            _debugInfo = 'Device is offline - caching image locally';
            _isOffline = true;
          });
          await OfflineService.cacheMeasurement(imagePath, 'customer_123');
          _showSnackBar('📱 No internet connection. Image cached locally for later processing.', Colors.orange);
          break;

        case UploadStatus.serverDown:
          setState(() {
            _debugInfo = 'Server is down but internet is available - caching image';
            _isOffline = true;
          });
          await OfflineService.cacheMeasurement(imagePath, 'customer_123');
          _showSnackBar('🔧 Server is temporarily unavailable. Image cached locally.', Colors.amber);
          
          // Optionally try alternative method
          _showRetryDialog(imagePath, 'Server is down. Would you like to try an alternative upload method?');
          break;

        case UploadStatus.networkError:
          setState(() {
            _debugInfo = 'Network error - ${uploadResult.message}';
            _isOffline = true;
          });
          await OfflineService.cacheMeasurement(imagePath, 'customer_123');
          _showSnackBar('🌐 Network error. Image cached for when connection improves.', Colors.red[400]!);
          break;

        case UploadStatus.timeout:
          setState(() {
            _debugInfo = 'Upload timed out - ${uploadResult.message}';
          });
          _showTimeoutDialog(imagePath);
          break;

        case UploadStatus.serverError:
          setState(() {
            _debugInfo = 'Server error - ${uploadResult.message}';
          });
          _showSnackBar('🔥 Server error occurred. Please try again later.', Colors.red);
          break;

        case UploadStatus.clientError:
          setState(() {
            _debugInfo = 'Client error - ${uploadResult.message}';
          });
          _showSnackBar('⚠️ Upload failed due to client error. Please check the image.', Colors.orange);
          break;

        case UploadStatus.fileError:
          setState(() {
            _debugInfo = 'File error - ${uploadResult.message}';
          });
          _showSnackBar('📁 File error: ${uploadResult.message}', Colors.red);
          break;

        case UploadStatus.unknownError:
          setState(() {
            _debugInfo = 'Unknown error - ${uploadResult.message}';
          });
          _showSnackBar('❓ Unexpected error occurred. Please try again.', Colors.red);
          break;
      }
    } catch (e) {
      setState(() {
        _debugInfo = 'Processing error: $e';
      });
      print('Processing error: $e');
      _showError('Processing failed: $e');
    }
  }

  void _showTimeoutDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer, color: Colors.amber),
            SizedBox(width: 12),
            Text('Upload Timed Out'),
          ],
        ),
        content: Text('The upload is taking longer than expected. This might be due to slow internet connection.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Cache the image for offline processing
              OfflineService.cacheMeasurement(imagePath, 'customer_123');
              setState(() => _isOffline = true);
              _showSnackBar('Image cached for later processing.', Colors.orange);
            },
            child: Text('Cache for Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processImage(imagePath); // Retry
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(String imagePath, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 12),
            Text('Connection Issue'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tryAlternativeUpload(imagePath);
            },
            child: Text('Try Alternative'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processImage(imagePath); // Retry original method
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryAlternativeUpload(String imagePath) async {
    setState(() {
      _debugInfo = 'Trying alternative upload method...';
    });

    final result = await ApiService.uploadImageAlternative(imagePath);
    
    if (result.isSuccess) {
      setState(() {
        _debugInfo = 'Alternative upload successful!';
        _isOffline = false;
      });
      _showSuccessDialog(result.data!);
    } else {
      setState(() {
        _debugInfo = 'Alternative upload also failed - caching image';
        _isOffline = true;
      });
      await OfflineService.cacheMeasurement(imagePath, 'customer_123');
      _showSnackBar('Alternative method also failed. Image cached locally.', Colors.red);
    }
  }

  // Add a connectivity test button to the UI
  Widget _buildConnectivityTestButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _testConnectivity,
        icon: Icon(Icons.network_check),
        label: Text('Test Connection'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _testConnectivity() async {
    setState(() {
      _debugInfo = 'Testing connectivity...';
    });

    final connectivityResult = await ApiService.checkConnectivity();
    
    String message;
    Color color;
    
    switch (connectivityResult) {
      case ConnectivityResult.serverAvailable:
        message = '✅ Server is available and ready!';
        color = Colors.green;
        setState(() => _isOffline = false);
        break;
      case ConnectivityResult.internetOnlyServerDown:
        message = '🌐 Internet OK, but server is down';
        color = Colors.amber;
        setState(() => _isOffline = true);
        break;
      case ConnectivityResult.offline:
        message = '📱 No internet connection detected';
        color = Colors.red;
        setState(() => _isOffline = true);
        break;
    }

    setState(() {
      _debugInfo = 'Connectivity test: $message';
    });
    
    _showSnackBar(message, color);
  }

  // Enhanced debug info display
  void _showDetailedDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detailed Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_isOffline ? '🔴 Offline Mode' : '🟢 Online Mode'),
              SizedBox(height: 16),
              Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_debugInfo.isEmpty ? 'No debug info available' : _debugInfo),
              SizedBox(height: 16),
              Text('Server URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(ApiService.baseUrl),
              SizedBox(height: 8),
              Text('Request Timeout:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${ApiService.requestTimeout.inSeconds} seconds'),
              if (_selectedImage != null) ...[
                SizedBox(height: 16),
                Text('Selected Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<int>(
                  future: _selectedImage!.length(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Path: ${_selectedImage!.path}'),
                          Text('Size: ${snapshot.data} bytes'),
                          Text('Exists: ${_selectedImage!.existsSync()}'),
                        ],
                      );
                    }
                    return Text('Loading file info...');
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _testConnectivity();
            },
            child: Text('Test Connection'),
          ),
        ],
      ),
    );
  }
  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Measurements Ready!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size Recommendation: ${response['size']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ...response['measurements'].entries.map<Widget>((entry) =>
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${entry.key.toString().toUpperCase()}:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${entry.value}" inches'),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetCamera();
            },
            child: Text('Take Another'),
          ),
        ],
      ),
    );
  }

  void _resetCamera() {
    setState(() {
      _selectedImage = null;
      _showCamera = true;
      _debugInfo = '';
    });
    _initializeCamera();
  }

  void _showError(String message) {
    _showSnackBar(message, Colors.red);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Information'),
        content: SingleChildScrollView(
          child: Text(_debugInfo.isEmpty ? 'No debug info available' : _debugInfo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Capture Measurements'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Debug button
          IconButton(
            onPressed: _showDebugInfo,
            icon: Icon(Icons.bug_report),
            tooltip: 'Debug Info',
          ),
          if (_selectedImage != null)
            IconButton(
              onPressed: _resetCamera,
              icon: Icon(Icons.refresh),
              tooltip: 'Reset Camera',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Camera/Image Preview Section
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildPreviewWidget(),
                ),
              ),
            ),
            
            // Debug info section (only show if there's debug info)
            if (_debugInfo.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(_debugInfo, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            
            // Controls Section
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_isProcessing)
                      Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing image...', 
                              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      )
                    else if (_selectedImage == null)
                      _buildActionButtons()
                    else
                      _buildProcessingButtons(),
                    
                    if (_isOffline)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Offline Mode', style: TextStyle(color: Colors.orange[800])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWidget() {
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),
          // Show file info overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FutureBuilder<int>(
                future: _selectedImage!.length(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      '${(snapshot.data! / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }
                  return Text('...', style: TextStyle(color: Colors.white, fontSize: 12));
                },
              ),
            ),
          ),
        ],
      );
    }

    if (_showCamera && _initializeControllerFuture != null) {
      return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                // Camera overlay
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Position person here',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Initializing camera...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }
        },
      );
    }

    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Camera not available', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildButton(
                onPressed: _captureImage,
                icon: Icons.camera_alt,
                label: 'Capture Photo',
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildButton(
                onPressed: _pickImageFromGallery,
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            onPressed: _resetCamera,
            icon: Icons.refresh,
            label: 'Take Another',
            color: Colors.grey,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildButton(
            onPressed: () => _processImage(_selectedImage!.path),
            icon: Icons.analytics,
            label: 'Process Again',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}