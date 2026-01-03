import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/measurement_model.dart';
import 'dart:io';

/// Updated Measurement Screen for Backend Integration
/// This screen captures BOTH front and side images required by the backend
class MeasurementCaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId; // User ID from your user management
  final double userHeight; // User's height in cm
  final String userGender; // 'male' or 'female'

  const MeasurementCaptureScreen({
    required this.camera,
    required this.userId,
    required this.userHeight,
    required this.userGender,
    super.key,
  });

  @override
  _MeasurementCaptureScreenState createState() => _MeasurementCaptureScreenState();
}

class _MeasurementCaptureScreenState extends State<MeasurementCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  File? _frontImage;
  File? _sideImage;
  bool _isProcessing = false;
  bool _showCamera = true;
  String _currentCapture = 'front'; // 'front' or 'side'

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null) return;

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final capturedFile = File(image.path);

      setState(() {
        if (_currentCapture == 'front') {
          _frontImage = capturedFile;
          _currentCapture = 'side';
          _showSnackBar('Front image captured! Now capture side view', Colors.green);
        } else {
          _sideImage = capturedFile;
          _showCamera = false;
          _showSnackBar('Side image captured! Ready to process', Colors.green);
        }
      });
    } catch (e) {
      _showSnackBar('Failed to capture image: $e', Colors.red);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (_currentCapture == 'front') {
            _frontImage = File(pickedFile.path);
            _currentCapture = 'side';
            _showSnackBar('Front image selected! Now select side view', Colors.green);
          } else {
            _sideImage = File(pickedFile.path);
            _showCamera = false;
            _showSnackBar('Side image selected! Ready to process', Colors.green);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', Colors.red);
    }
  }

  Future<void> _processMeasurement() async {
    if (_frontImage == null || _sideImage == null) {
      _showSnackBar('Both front and side images are required', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing measurements...'),
              SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await TailoringApiClient.processMeasurement(
        frontImagePath: _frontImage!.path,
        sideImagePath: _sideImage!.path,
        userId: widget.userId,
        height: widget.userHeight,
        gender: widget.userGender,
        notes: 'Captured on ${DateTime.now()}',
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.isSuccess) {
        _showMeasurementResults(response.data!);
      } else {
        _showSnackBar('Error: ${response.errorMessage}', Colors.red);
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showSnackBar('Processing failed: $e', Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showMeasurementResults(Measurement measurement) {
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeasurementRow('Height', measurement.height),
              _buildMeasurementRow('Chest', measurement.chestCircumference),
              _buildMeasurementRow('Waist', measurement.waistCircumference),
              _buildMeasurementRow('Hips', measurement.hipCircumference),
              _buildMeasurementRow('Shoulder Width', measurement.shoulderWidth),
              _buildMeasurementRow('Sleeve Length', measurement.sleeveLength),
              _buildMeasurementRow('Neck', measurement.neckCircumference),
              _buildMeasurementRow('Bicep', measurement.bicepCircumference),
              _buildMeasurementRow('Wrist', measurement.wristCircumference),
              Divider(height: 24),
              Text(
                'Measurement ID: ${measurement.id}',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: Text('Take Another'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, double? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value != null ? '${value.toStringAsFixed(1)} cm' : 'N/A',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _frontImage = null;
      _sideImage = null;
      _showCamera = true;
      _currentCapture = 'front';
    });
    _initializeCamera();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Body Measurement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_frontImage != null || _sideImage != null)
            IconButton(
              onPressed: _reset,
              icon: Icon(Icons.refresh),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Camera/Image Preview
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

          // Controls
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: _buildControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildProgressStep(
            number: '1',
            label: 'Front View',
            isComplete: _frontImage != null,
            isActive: _currentCapture == 'front',
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _frontImage != null ? Colors.green : Colors.grey[300],
            ),
          ),
          _buildProgressStep(
            number: '2',
            label: 'Side View',
            isComplete: _sideImage != null,
            isActive: _currentCapture == 'side',
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _sideImage != null ? Colors.green : Colors.grey[300],
            ),
          ),
          _buildProgressStep(
            number: '3',
            label: 'Process',
            isComplete: false,
            isActive: _frontImage != null && _sideImage != null,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required String number,
    required String label,
    required bool isComplete,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? Colors.green
                : isActive
                    ? Colors.blue
                    : Colors.grey[300],
          ),
          child: Center(
            child: isComplete
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    number,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.blue : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewWidget() {
    // Show result preview if both images captured
    if (_frontImage != null && _sideImage != null) {
      return Row(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_frontImage!, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Front',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, color: Colors.white),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_sideImage!, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Side',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Show captured front image while waiting for side
    if (_frontImage != null && _currentCapture == 'side') {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_frontImage!, fit: BoxFit.cover),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Front image captured ✓\nNow capture SIDE view',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    // Show camera preview
    if (_showCamera && _initializeControllerFuture != null) {
      return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                _buildCameraOverlay(),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      );
    }

    return Center(child: Text('No preview available'));
  }

  Widget _buildCameraOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentCapture == 'front'
                        ? Icons.person
                        : Icons.accessibility_new,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _currentCapture == 'front'
                        ? 'Position person\nfacing camera'
                        : 'Position person\nside view',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      );
    }

    if (_frontImage != null && _sideImage != null) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: _processMeasurement,
            icon: Icon(Icons.analytics, size: 28),
            label: Text('Process Measurement', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: Icon(Icons.refresh),
            label: Text('Start Over'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _captureImage,
            icon: Icon(Icons.camera_alt, size: 24),
            label: Text('Capture', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickFromGallery,
            icon: Icon(Icons.photo_library, size: 24),
            label: Text('Gallery', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
