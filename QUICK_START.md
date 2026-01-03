# Quick Start Guide - Integrating Backend API

This guide shows you how to quickly integrate the NestJS backend API into your existing Flutter app.

## 1️⃣ Prerequisites (1 minute)

Make sure your backend is running:

```bash
cd tailoring-backend
npm run start:dev
```

Verify it's accessible:
```bash
curl http://localhost:3000/api/v1/health
```

## 2️⃣ Configure Base URL (1 minute)

Open `lib/services/tailoring_api_client.dart` and set the correct URL:

```dart
// Line 15 - Update based on your platform:

// ✓ For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

// ✓ For iOS Simulator:
static const String baseUrl = 'http://localhost:3000/api/v1';

// ✓ For Physical Device (replace with your computer's IP):
static const String baseUrl = 'http://192.168.1.100:3000/api/v1';
```

**Find your IP:**
- macOS/Linux: `ifconfig | grep inet`
- Windows: `ipconfig`

## 3️⃣ Test Connection (2 minutes)

Add this test to your main.dart or any screen:

```dart
import 'package:frontend/services/tailoring_api_client.dart';

void testBackendConnection() async {
  print('Testing backend connection...');

  final response = await TailoringApiClient.checkHealth();

  if (response.isSuccess) {
    print('✓ Backend connected!');
    print('Server status: ${response.data}');
  } else {
    print('✗ Connection failed: ${response.errorMessage}');
  }
}
```

Call it in your `initState()` or button press.

## 4️⃣ Update Your Existing Screens

### A. Measurement Screen Integration

Update your existing measurement screen to send images to the backend:

```dart
// In your measurement_screen.dart or similar file

import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/measurement_model.dart';

// After capturing front and side images:
Future<void> processAndSaveMeasurement(
  String frontImagePath,
  String sideImagePath,
  String userId,
  double height,
  String gender,
) async {
  // Show loading indicator
  setState(() => isProcessing = true);

  final response = await TailoringApiClient.processMeasurement(
    frontImagePath: frontImagePath,
    sideImagePath: sideImagePath,
    userId: userId,
    height: height,
    gender: gender,
    notes: 'Captured at ${DateTime.now()}',
  );

  setState(() => isProcessing = false);

  if (response.isSuccess) {
    Measurement measurement = response.data!;

    // Display the results
    print('Chest: ${measurement.chestCircumference} cm');
    print('Waist: ${measurement.waistCircumference} cm');
    print('Hips: ${measurement.hipCircumference} cm');

    // Navigate to results screen or show dialog
    _showMeasurementResults(measurement);
  } else {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${response.errorMessage}')),
    );
  }
}

void _showMeasurementResults(Measurement measurement) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Your Measurements'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Chest: ${measurement.chestCircumference?.toStringAsFixed(1)} cm'),
          Text('Waist: ${measurement.waistCircumference?.toStringAsFixed(1)} cm'),
          Text('Hips: ${measurement.hipCircumference?.toStringAsFixed(1)} cm'),
          Text('Shoulder: ${measurement.shoulderWidth?.toStringAsFixed(1)} cm'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

### B. History Screen Integration

Update your history screen to fetch measurements from backend:

```dart
// In your history_screen.dart

import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/measurement_model.dart';

class HistoryScreen extends StatefulWidget {
  final String userId; // You need to store user ID after login/registration

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Measurement> measurements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMeasurements();
  }

  Future<void> loadMeasurements() async {
    setState(() => isLoading = true);

    final response = await TailoringApiClient.getUserMeasurements(widget.userId);

    setState(() {
      isLoading = false;
      if (response.isSuccess) {
        measurements = response.data!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final m = measurements[index];
        return ListTile(
          title: Text('Measurement ${index + 1}'),
          subtitle: Text('Chest: ${m.chestCircumference} cm'),
          trailing: Text('${m.createdAt.day}/${m.createdAt.month}'),
        );
      },
    );
  }
}
```

## 5️⃣ User Management (Optional)

If you don't have a user system yet, create one:

```dart
// Store user ID locally using shared_preferences
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getOrCreateUser() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');

  if (userId == null) {
    // Create new user
    final response = await TailoringApiClient.createUser(
      firstName: 'Default',
      lastName: 'User',
      email: 'user@example.com',
      gender: 'male',
      height: 170.0,
    );

    if (response.isSuccess) {
      userId = response.data!.id;
      await prefs.setString('user_id', userId);
    }
  }

  return userId!;
}
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

Then run: `flutter pub get`

## 6️⃣ Complete Integration Example

Here's a complete example showing the full flow:

```dart
import 'package:flutter/material.dart';
import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/measurement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompleteMeasurementFlow extends StatefulWidget {
  @override
  _CompleteMeasurementFlowState createState() => _CompleteMeasurementFlowState();
}

class _CompleteMeasurementFlowState extends State<CompleteMeasurementFlow> {
  String? userId;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    initializeUser();
  }

  Future<void> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');

    if (storedUserId == null) {
      // Create user
      final response = await TailoringApiClient.createUser(
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        gender: 'male',
        height: 175.0,
      );

      if (response.isSuccess) {
        storedUserId = response.data!.id;
        await prefs.setString('user_id', storedUserId);
      }
    }

    setState(() {
      userId = storedUserId;
    });
  }

  Future<void> processMeasurement() async {
    if (userId == null) {
      print('User not initialized');
      return;
    }

    // Replace these with your actual image paths
    String frontImagePath = '/path/to/front_image.jpg';
    String sideImagePath = '/path/to/side_image.jpg';

    setState(() => isProcessing = true);

    final response = await TailoringApiClient.processMeasurement(
      frontImagePath: frontImagePath,
      sideImagePath: sideImagePath,
      userId: userId!,
      height: 175.0,
      gender: 'male',
    );

    setState(() => isProcessing = false);

    if (response.isSuccess) {
      Measurement measurement = response.data!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success!'),
          content: Text(
            'Chest: ${measurement.chestCircumference}\n'
            'Waist: ${measurement.waistCircumference}\n'
            'Hips: ${measurement.hipCircumference}'
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Measurement')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userId != null)
              Text('User ID: $userId'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isProcessing ? null : processMeasurement,
              child: isProcessing
                  ? CircularProgressIndicator()
                  : Text('Process Measurement'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 7️⃣ Common Issues & Solutions

### Issue: "Connection refused"
**Solution:** Check if backend is running and use correct IP:
```bash
# Check backend
curl http://localhost:3000/api/v1/health

# For Android emulator, use:
http://10.0.2.2:3000/api/v1
```

### Issue: "SocketException"
**Solution:** Add internet permission to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Issue: "CORS error"
**Solution:** Backend should have CORS enabled (it already does in the NestJS backend)

### Issue: "File not found"
**Solution:** Verify image paths are absolute paths:
```dart
// ✓ Good
'/data/user/0/.../cache/image123.jpg'

// ✗ Bad
'image123.jpg'
```

## 8️⃣ Next Steps

1. ✅ Test backend connection
2. ✅ Create/fetch user
3. ✅ Process measurement
4. ✅ View measurement history
5. ⬜ Share measurements with tailors
6. ⬜ Add user authentication
7. ⬜ Add offline support
8. ⬜ Optimize images before upload

## 9️⃣ Useful Commands

```bash
# Backend
cd tailoring-backend
npm run start:dev          # Start development server
npm run build              # Build for production
npm run start:prod         # Start production server

# Flutter
flutter pub get            # Install dependencies
flutter run                # Run app
flutter clean              # Clean build cache
flutter doctor             # Check environment
```

## 🔟 Resources

- **Full Integration Guide:** `BACKEND_INTEGRATION_GUIDE.md`
- **Code Examples:** `lib/examples/api_usage_examples.dart`
- **Backend API Docs:** `../tailoring-backend/README.md`
- **Models:** `lib/models/`

---

## Quick Copy-Paste Checklist

```dart
// 1. Import API client
import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/measurement_model.dart';

// 2. Process measurement
final response = await TailoringApiClient.processMeasurement(
  frontImagePath: frontPath,
  sideImagePath: sidePath,
  userId: userId,
  height: 175.0,
  gender: 'male',
);

// 3. Check result
if (response.isSuccess) {
  Measurement m = response.data!;
  print('Chest: ${m.chestCircumference}');
} else {
  print('Error: ${response.errorMessage}');
}
```

**That's it! You're ready to go!** 🚀
