# Flutter Frontend + NestJS Backend Integration Guide

## Table of Contents
1. [Setup Instructions](#setup-instructions)
2. [Configuration](#configuration)
3. [API Client Usage](#api-client-usage)
4. [Code Examples](#code-examples)
5. [Troubleshooting](#troubleshooting)

---

## Setup Instructions

### Step 1: Update Dependencies

Add the required package to `pubspec.yaml` (already added):

```yaml
dependencies:
  http: ^1.1.0
  path: ^1.8.3
```

Then run:
```bash
flutter pub get
```

### Step 2: Configure Base URL

The API client uses different URLs based on your platform:

**In `lib/services/tailoring_api_client.dart`, update `baseUrl`:**

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

// For iOS Simulator
static const String baseUrl = 'http://localhost:3000/api/v1';

// For Physical Device (replace with your computer's IP)
static const String baseUrl = 'http://192.168.1.100:3000/api/v1';
```

**To find your computer's IP:**
- **macOS/Linux:** `ifconfig | grep inet`
- **Windows:** `ipconfig`

### Step 3: Start the Backend

Make sure your NestJS backend is running:

```bash
cd tailoring-backend
npm run start:dev
```

The backend should be accessible at `http://localhost:3000`

### Step 4: Test Connectivity

Add this to your Flutter app to test the connection:

```dart
import 'package:frontend/services/tailoring_api_client.dart';

Future<void> testConnection() async {
  final response = await TailoringApiClient.checkHealth();

  if (response.isSuccess) {
    print('✓ Connected to backend!');
    print('Health data: ${response.data}');
  } else {
    print('✗ Connection failed: ${response.errorMessage}');
  }
}
```

---

## Configuration

### Android Network Permissions

Ensure you have internet permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS Network Configuration

For local development, add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note:** Remove this in production and use HTTPS!

---

## API Client Usage

The `TailoringApiClient` provides all backend functionality:

### Import the Client

```dart
import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/measurement_model.dart';
import 'package:frontend/models/tailor_model.dart';
```

### API Response Pattern

All methods return an `ApiResponse<T>` object:

```dart
class ApiResponse<T> {
  final bool isSuccess;      // true if request succeeded
  final T? data;             // response data (if success)
  final String? errorMessage; // error message (if failed)
}
```

**Usage pattern:**

```dart
final response = await TailoringApiClient.someMethod();

if (response.isSuccess) {
  // Handle success
  final data = response.data;
  print('Success: $data');
} else {
  // Handle error
  print('Error: ${response.errorMessage}');
}
```

---

## Code Examples

### 1. Create a User

```dart
Future<void> createNewUser() async {
  final response = await TailoringApiClient.createUser(
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@example.com',
    phoneNumber: '+1234567890',
    gender: 'male',
    height: 175.5,
    weight: 70.0,
  );

  if (response.isSuccess) {
    User user = response.data!;
    print('User created: ${user.fullName}');
    print('User ID: ${user.id}');
  } else {
    print('Failed to create user: ${response.errorMessage}');
  }
}
```

### 2. Process Body Measurement

```dart
Future<void> processMeasurement(String userId) async {
  // Paths to captured images
  final String frontImagePath = '/path/to/front_image.jpg';
  final String sideImagePath = '/path/to/side_image.jpg';

  final response = await TailoringApiClient.processMeasurement(
    frontImagePath: frontImagePath,
    sideImagePath: sideImagePath,
    userId: userId,
    height: 175.0,  // User's height in cm
    gender: 'male',
    notes: 'First measurement',
  );

  if (response.isSuccess) {
    Measurement measurement = response.data!;
    print('Measurement ID: ${measurement.id}');
    print('Chest: ${measurement.chestCircumference} cm');
    print('Waist: ${measurement.waistCircumference} cm');
    print('Shoulder width: ${measurement.shoulderWidth} cm');
  } else {
    print('Measurement failed: ${response.errorMessage}');
  }
}
```

### 3. Get User's Measurement History

```dart
Future<void> fetchUserMeasurements(String userId) async {
  final response = await TailoringApiClient.getUserMeasurements(userId);

  if (response.isSuccess) {
    List<Measurement> measurements = response.data!;

    print('Found ${measurements.length} measurements');

    for (var measurement in measurements) {
      print('Date: ${measurement.createdAt}');
      print('Chest: ${measurement.chestCircumference} cm');
      print('---');
    }
  } else {
    print('Error: ${response.errorMessage}');
  }
}
```

### 4. Share Measurement with Tailor

```dart
Future<void> shareMeasurementWithTailor({
  required String measurementId,
  required String tailorId,
  required String userId,
}) async {
  final response = await TailoringApiClient.shareMeasurement(
    measurementId: measurementId,
    tailorId: tailorId,
    userId: userId,
    message: 'Please make a suit with these measurements',
  );

  if (response.isSuccess) {
    print('Measurement shared successfully!');
    print('Response: ${response.data}');
  } else {
    print('Failed to share: ${response.errorMessage}');
  }
}
```

### 5. Get All Tailors

```dart
Future<void> fetchTailors() async {
  final response = await TailoringApiClient.getAllTailors();

  if (response.isSuccess) {
    List<Tailor> tailors = response.data!;

    for (var tailor in tailors) {
      print('Business: ${tailor.businessName}');
      print('Owner: ${tailor.ownerName}');
      print('Rating: ${tailor.rating}/5.0');
      print('Specialties: ${tailor.specialties?.join(', ')}');
      print('---');
    }
  } else {
    print('Error: ${response.errorMessage}');
  }
}
```

### 6. Complete Workflow Example

```dart
Future<void> completeUserJourney() async {
  // Step 1: Create user
  final userResponse = await TailoringApiClient.createUser(
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    gender: 'female',
    height: 165.0,
  );

  if (!userResponse.isSuccess) {
    print('User creation failed');
    return;
  }

  final userId = userResponse.data!.id;
  print('✓ User created: $userId');

  // Step 2: Process measurement
  final measurementResponse = await TailoringApiClient.processMeasurement(
    frontImagePath: '/path/to/front.jpg',
    sideImagePath: '/path/to/side.jpg',
    userId: userId,
    height: 165.0,
    gender: 'female',
  );

  if (!measurementResponse.isSuccess) {
    print('Measurement failed');
    return;
  }

  final measurementId = measurementResponse.data!.id;
  print('✓ Measurement processed: $measurementId');

  // Step 3: Get all tailors
  final tailorsResponse = await TailoringApiClient.getAllTailors();

  if (tailorsResponse.isSuccess && tailorsResponse.data!.isNotEmpty) {
    final tailorId = tailorsResponse.data!.first.id;
    print('✓ Found tailor: $tailorId');

    // Step 4: Share measurement with tailor
    final shareResponse = await TailoringApiClient.shareMeasurement(
      measurementId: measurementId,
      tailorId: tailorId,
      userId: userId,
      message: 'Please make a dress',
    );

    if (shareResponse.isSuccess) {
      print('✓ Measurement shared with tailor!');
    }
  }
}
```

### 7. Widget Integration Example

```dart
import 'package:flutter/material.dart';
import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/measurement_model.dart';

class MeasurementHistoryScreen extends StatefulWidget {
  final String userId;

  const MeasurementHistoryScreen({required this.userId});

  @override
  State<MeasurementHistoryScreen> createState() => _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState extends State<MeasurementHistoryScreen> {
  List<Measurement> measurements = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadMeasurements();
  }

  Future<void> loadMeasurements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await TailoringApiClient.getUserMeasurements(widget.userId);

    setState(() {
      isLoading = false;
      if (response.isSuccess) {
        measurements = response.data!;
      } else {
        errorMessage = response.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Measurements')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : ListView.builder(
                  itemCount: measurements.length,
                  itemBuilder: (context, index) {
                    final measurement = measurements[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Measurement ${index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${measurement.createdAt.toLocal()}'),
                            Text('Chest: ${measurement.chestCircumference} cm'),
                            Text('Waist: ${measurement.waistCircumference} cm'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadMeasurements,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to backend

**Solutions:**
1. Verify backend is running: `curl http://localhost:3000/api/v1/health`
2. Check firewall settings
3. Use correct IP address for physical devices
4. For Android emulator, use `10.0.2.2` instead of `localhost`
5. For iOS simulator, `localhost` should work

### CORS Errors

**Problem:** CORS policy blocking requests

**Solution:** Ensure backend has CORS enabled in `main.ts`:
```typescript
app.enableCors({
  origin: '*', // For development
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  credentials: true,
});
```

### Image Upload Fails

**Problem:** Images not uploading

**Solutions:**
1. Check file size (max 10MB by default)
2. Verify file format (JPG, JPEG, PNG)
3. Ensure file path is correct
4. Check backend `uploads/` directory permissions

### Network Timeout

**Problem:** Requests timing out

**Solutions:**
1. Increase timeout in `tailoring_api_client.dart`:
   ```dart
   static const Duration timeout = Duration(seconds: 60);
   ```
2. Check network speed
3. Optimize image sizes before upload

### Testing Backend Connectivity

```bash
# Test health endpoint
curl http://localhost:3000/api/v1/health

# Expected response:
{
  "status": "ok",
  "timestamp": "...",
  "uptime": 123.45,
  "services": {
    "database": "ok",
    "python": "Python 3.x.x",
    "mediapipe": "v0.x.x"
  }
}
```

### Enable Debugging

Add debug prints in your Flutter code:

```dart
Future<void> debugApiCall() async {
  print('Making API call...');
  final response = await TailoringApiClient.checkHealth();
  print('Response success: ${response.isSuccess}');
  print('Response data: ${response.data}');
  print('Error message: ${response.errorMessage}');
}
```

---

## Additional Resources

- **Backend API Docs:** `/tailoring-backend/README.md`
- **Backend Architecture:** `/tailoring-backend/ARCHITECTURE.md`
- **Flutter HTTP Package:** https://pub.dev/packages/http

---

## Quick Reference

### All Available Endpoints

**Users:**
- `createUser()` - Create new user
- `getAllUsers()` - Get all users
- `getUserById(userId)` - Get specific user
- `updateUser(userId, updates)` - Update user
- `deleteUser(userId)` - Delete user

**Measurements:**
- `processMeasurement()` - Upload images and get measurements
- `getAllMeasurements()` - Get all measurements
- `getUserMeasurements(userId)` - Get user's measurements
- `getMeasurementById(id)` - Get specific measurement
- `shareMeasurement()` - Share with tailor
- `getSharedMeasurements(userId)` - Get shared measurements
- `deleteMeasurement(id, userId)` - Delete measurement

**Tailors:**
- `createTailor()` - Register new tailor
- `getAllTailors()` - Get all tailors
- `getTailorById(tailorId)` - Get specific tailor
- `getTailorMeasurements(tailorId)` - Get measurements received by tailor
- `updateTailor(tailorId, updates)` - Update tailor
- `deleteTailor(tailorId)` - Delete tailor

**Health:**
- `checkHealth()` - Check server status

---

## Production Considerations

1. **Security:**
   - Implement JWT authentication
   - Use HTTPS in production
   - Validate all user inputs
   - Never hardcode API keys

2. **Error Handling:**
   - Implement retry logic for failed requests
   - Show user-friendly error messages
   - Log errors for debugging

3. **Performance:**
   - Cache frequently accessed data
   - Compress images before upload
   - Implement pagination for large lists
   - Use connection pooling

4. **Testing:**
   - Write unit tests for API client
   - Test offline scenarios
   - Test with slow network conditions
   - Mock API responses for UI testing

---

**Happy Coding!**
