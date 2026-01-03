# Camera Integration Guide - Adapting Your Existing Code

## Overview

Your existing `measurement_screen.dart` captures **ONE image**. The NestJS backend requires **TWO images** (front + side view) for accurate body measurements using MediaPipe AI.

I've created a new screen (`measurement_capture_screen.dart`) that handles the 2-image capture flow, but you can also adapt your existing code.

---

## Option 1: Use the New Screen (Recommended)

### Quick Integration

Replace your existing `MeasurementScreen` navigation with:

**In `home_screen.dart` (line 122):**

```dart
// OLD CODE:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MeasurementScreen(
      camera: widget.cameras.first,
    ),
  ),
);

// NEW CODE:
import 'package:frontend/screens/measurement_capture_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MeasurementCaptureScreen(
      camera: widget.cameras.first,
      userId: 'your-user-id', // Get from user management
      userHeight: 175.0, // Get from user profile
      userGender: 'male', // Get from user profile
    ),
  ),
);
```

### Features of New Screen

✅ Captures **both front and side** images
✅ Progress indicator showing capture steps
✅ Integrated with `TailoringApiClient`
✅ Shows measurement results directly
✅ Handles all error cases
✅ Clean UI with guided overlay

---

## Option 2: Adapt Your Existing measurement_screen.dart

If you want to keep your existing screen, here's how to modify it:

### Step 1: Add State Variables

```dart
// In _MeasurementScreenState class

File? _frontImage;  // Add this
File? _sideImage;   // Add this
String _captureMode = 'front';  // Add this ('front' or 'side')

// Keep your existing:
// File? _selectedImage;
```

### Step 2: Modify _captureImage() Method

```dart
Future<void> _captureImage() async {
  if (!_showCamera || _controller == null) return;

  setState(() {
    _isProcessing = true;
    _debugInfo = 'Capturing ${_captureMode} image...';
  });

  try {
    await _initializeControllerFuture;
    final image = await _controller!.takePicture();
    final capturedFile = File(image.path);

    setState(() {
      if (_captureMode == 'front') {
        _frontImage = capturedFile;
        _captureMode = 'side';
        _debugInfo = 'Front image captured! Now capture SIDE view';
      } else {
        _sideImage = capturedFile;
        _showCamera = false;
        _debugInfo = 'Both images captured! Ready to process';
      }
    });

    // Only process when both images are captured
    if (_frontImage != null && _sideImage != null) {
      await _processImages(_frontImage!.path, _sideImage!.path);
    }
  } catch (e) {
    setState(() {
      _debugInfo = 'Capture failed: $e';
    });
    _showError('Failed to capture image: $e');
  } finally {
    setState(() => _isProcessing = false);
  }
}
```

### Step 3: Replace _processImage() with New Method

```dart
Future<void> _processImages(String frontImagePath, String sideImagePath) async {
  setState(() {
    _debugInfo = 'Processing measurements from both images...';
    _isProcessing = true;
  });

  try {
    // Import the API client at top of file:
    // import 'package:frontend/services/tailoring_api_client.dart';
    // import 'package:frontend/models/measurement_model.dart';

    final response = await TailoringApiClient.processMeasurement(
      frontImagePath: frontImagePath,
      sideImagePath: sideImagePath,
      userId: 'your-user-id', // TODO: Get from user management
      height: 175.0, // TODO: Get from user profile
      gender: 'male', // TODO: Get from user profile
      notes: 'Captured on ${DateTime.now()}',
    );

    setState(() => _isProcessing = false);

    if (response.isSuccess) {
      Measurement measurement = response.data!;
      _showMeasurementResults(measurement);
    } else {
      _showSnackBar('Error: ${response.errorMessage}', Colors.red);
    }
  } catch (e) {
    setState(() {
      _debugInfo = 'Processing error: $e';
      _isProcessing = false;
    });
    _showError('Processing failed: $e');
  }
}

void _showMeasurementResults(Measurement measurement) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
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
            _buildMeasurementRow('Shoulder', measurement.shoulderWidth),
            _buildMeasurementRow('Sleeve', measurement.sleeveLength),
            _buildMeasurementRow('Neck', measurement.neckCircumference),
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
            _resetCamera();
          },
          child: Text('Take Another'),
        ),
      ],
    ),
  );
}

Widget _buildMeasurementRow(String label, double? value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Text(
          value != null ? '${value.toStringAsFixed(1)} cm' : 'N/A',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    ),
  );
}
```

### Step 4: Update _resetCamera()

```dart
void _resetCamera() {
  setState(() {
    _frontImage = null;  // Add this
    _sideImage = null;   // Add this
    _captureMode = 'front';  // Add this
    _selectedImage = null;
    _showCamera = true;
    _debugInfo = '';
  });
  _initializeCamera();
}
```

### Step 5: Update UI to Show Capture Mode

In your camera overlay (around line 740), update the text:

```dart
Text(
  _captureMode == 'front'
    ? 'Position person\nFACING camera'
    : 'Position person\nSIDE view',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
  ),
),
```

### Step 6: Add Progress Indicator (Optional)

Add this below your AppBar:

```dart
if (_frontImage != null && _sideImage == null)
  Container(
    padding: EdgeInsets.all(12),
    color: Colors.blue,
    child: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Front image captured ✓ Now capture SIDE view',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  ),
```

---

## Option 3: Minimal Integration (Keep OLD + Add NEW)

Keep both screens and let users choose:

### Update home_screen.dart

```dart
// Add import
import 'package:frontend/screens/measurement_capture_screen.dart';

// In your home screen, add a choice dialog:
void _showMeasurementOptions(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Choose Measurement Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.science, color: Colors.blue),
            title: Text('AI Body Measurement'),
            subtitle: Text('Accurate measurements using 2 photos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeasurementCaptureScreen(
                    camera: widget.cameras.first,
                    userId: 'user-id',
                    userHeight: 175.0,
                    userGender: 'male',
                  ),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.camera, color: Colors.green),
            title: Text('Quick Capture'),
            subtitle: Text('Single photo capture (old method)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeasurementScreen(
                    camera: widget.cameras.first,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// Update the button in _buildPrimaryCard:
onTap: () => _showMeasurementOptions(context),
```

---

## User Management Setup

You need to manage user IDs for the API. Here's a simple approach:

### 1. Add shared_preferences

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.2
```

Run: `flutter pub get`

### 2. Create User Manager

```dart
// lib/services/user_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/user_model.dart';

class UserManager {
  static Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      // Create a new user
      final response = await TailoringApiClient.createUser(
        firstName: 'User',
        lastName: 'Name',
        email: 'user@example.com',
        gender: 'male',
        height: 175.0,
      );

      if (response.isSuccess) {
        userId = response.data!.id;
        await prefs.setString('user_id', userId);
        await prefs.setString('user_height', '175.0');
        await prefs.setString('user_gender', 'male');
      }
    }

    return userId ?? '';
  }

  static Future<double> getUserHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return double.parse(prefs.getString('user_height') ?? '175.0');
  }

  static Future<String> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_gender') ?? 'male';
  }

  static Future<User?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId.isEmpty) return null;

    final response = await TailoringApiClient.getUserById(userId);
    return response.isSuccess ? response.data : null;
  }
}
```

### 3. Use User Manager in Your Screen

```dart
// In MeasurementCaptureScreen or updated MeasurementScreen

import 'package:frontend/services/user_manager.dart';

class _MeasurementScreenState extends State<MeasurementScreen> {
  String? _userId;
  double? _userHeight;
  String? _userGender;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userId = await UserManager.getCurrentUserId();
    _userHeight = await UserManager.getUserHeight();
    _userGender = await UserManager.getUserGender();
    setState(() {});
  }

  // Then use in processMeasurement:
  final response = await TailoringApiClient.processMeasurement(
    frontImagePath: frontPath,
    sideImagePath: sidePath,
    userId: _userId!,
    height: _userHeight!,
    gender: _userGender!,
  );
}
```

---

## Complete Updated Navigation Example

```dart
// In home_screen.dart

import 'package:frontend/screens/measurement_capture_screen.dart';
import 'package:frontend/services/user_manager.dart';

// Replace the navigation onTap:
onTap: () async {
  // Get user data
  final userId = await UserManager.getCurrentUserId();
  final userHeight = await UserManager.getUserHeight();
  final userGender = await UserManager.getUserGender();

  // Navigate to measurement screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MeasurementCaptureScreen(
        camera: widget.cameras.first,
        userId: userId,
        userHeight: userHeight,
        userGender: userGender,
      ),
    ),
  );
},
```

---

## Testing Your Integration

### 1. Test Backend Connection

```dart
// Add a test button in your app
Future<void> testBackend() async {
  final health = await TailoringApiClient.checkHealth();
  if (health.isSuccess) {
    print('✓ Backend connected: ${health.data}');
  } else {
    print('✗ Backend error: ${health.errorMessage}');
  }
}
```

### 2. Test User Creation

```dart
final userId = await UserManager.getCurrentUserId();
print('User ID: $userId');
```

### 3. Test Measurement Flow

1. Launch app
2. Tap "Capture Measurements"
3. Take front photo
4. Take side photo
5. Tap "Process Measurement"
6. Wait for results dialog

---

## Key Differences: Old vs New

| Feature | Old Screen | New Screen |
|---------|------------|------------|
| Images Required | 1 | 2 (front + side) |
| Backend Integration | ❌ Custom API | ✅ TailoringApiClient |
| Progress Indicator | ❌ | ✅ |
| Measurement Results | Basic JSON | ✅ Formatted display |
| User Management | ❌ | ✅ Required |
| AI Processing | ❌ | ✅ MediaPipe backend |

---

## Troubleshooting

**Problem:** "User ID not found"
**Solution:** Make sure to call `UserManager.getCurrentUserId()` before navigating

**Problem:** "Both images required"
**Solution:** Ensure you capture both front AND side views

**Problem:** "Backend connection failed"
**Solution:** Check `baseUrl` in `tailoring_api_client.dart` - use `10.0.2.2` for Android emulator

**Problem:** "Image processing takes too long"
**Solution:** This is normal! MediaPipe AI processing can take 5-15 seconds

---

## Recommended Approach

For best results, I recommend **Option 1** (use the new screen) because:

✅ Purpose-built for 2-image capture
✅ Better UX with progress indicators
✅ Integrated error handling
✅ Clean separation of concerns
✅ Ready to use out of the box

Your old screen can remain as a backup or quick-capture option.

---

**Happy Coding!** 🚀
