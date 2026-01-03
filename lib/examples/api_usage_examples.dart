import 'package:flutter/material.dart';
import '../services/tailoring_api_client.dart';
import '../models/user_model.dart';
import '../models/measurement_model.dart';
import '../models/tailor_model.dart';

/// Example 1: User Registration Screen
class UserRegistrationExample extends StatefulWidget {
  @override
  State<UserRegistrationExample> createState() => _UserRegistrationExampleState();
}

class _UserRegistrationExampleState extends State<UserRegistrationExample> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = 'male';
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await TailoringApiClient.createUser(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      gender: _selectedGender,
    );

    setState(() => _isLoading = false);

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully!')),
      );

      // Navigate to home or save user ID for later use
      final userId = response.data!.id;
      print('New user ID: $userId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register User')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ['male', 'female'].map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (v) => setState(() => _selectedGender = v!),
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 2: Measurement Processing Integration
/// This shows how to integrate the API with your existing measurement screen
class MeasurementProcessingExample {
  /// Call this after capturing front and side images
  static Future<Measurement?> processImages({
    required String frontImagePath,
    required String sideImagePath,
    required String userId,
    required double userHeight,
    required String gender,
    required BuildContext context,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing measurement...'),
          ],
        ),
      ),
    );

    final response = await TailoringApiClient.processMeasurement(
      frontImagePath: frontImagePath,
      sideImagePath: sideImagePath,
      userId: userId,
      height: userHeight,
      gender: gender,
      notes: 'Captured on ${DateTime.now()}',
    );

    // Close loading dialog
    Navigator.of(context).pop();

    if (response.isSuccess) {
      final measurement = response.data!;

      // Show success dialog with measurements
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Measurement Complete!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMeasurementRow('Chest', measurement.chestCircumference),
                _buildMeasurementRow('Waist', measurement.waistCircumference),
                _buildMeasurementRow('Hips', measurement.hipCircumference),
                _buildMeasurementRow('Shoulder Width', measurement.shoulderWidth),
                _buildMeasurementRow('Sleeve Length', measurement.sleeveLength),
                _buildMeasurementRow('Neck', measurement.neckCircumference),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );

      return measurement;
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${response.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  static Widget _buildMeasurementRow(String label, double? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${value?.toStringAsFixed(1) ?? 'N/A'} cm'),
        ],
      ),
    );
  }
}

/// Example 3: Measurement History Screen
class MeasurementHistoryScreen extends StatefulWidget {
  final String userId;

  const MeasurementHistoryScreen({required this.userId});

  @override
  State<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
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

    final response =
        await TailoringApiClient.getUserMeasurements(widget.userId);

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
      appBar: AppBar(
        title: Text('My Measurements'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadMeasurements,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $errorMessage'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadMeasurements,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No measurements yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              'Measurement ${measurements.length - index}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _formatDate(measurement.createdAt),
              style: TextStyle(fontSize: 12),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Height', measurement.height),
                    _buildDetailRow('Chest', measurement.chestCircumference),
                    _buildDetailRow('Waist', measurement.waistCircumference),
                    _buildDetailRow('Hips', measurement.hipCircumference),
                    _buildDetailRow('Shoulder', measurement.shoulderWidth),
                    _buildDetailRow('Sleeve', measurement.sleeveLength),
                    _buildDetailRow('Neck', measurement.neckCircumference),
                    _buildDetailRow('Bicep', measurement.bicepCircumference),
                    _buildDetailRow('Wrist', measurement.wristCircumference),
                    if (measurement.notes != null) ...[
                      Divider(),
                      Text('Notes: ${measurement.notes}'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, double? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value != null ? '${value.toStringAsFixed(1)} cm' : 'N/A',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Example 4: Tailor Selection Screen
class TailorSelectionScreen extends StatefulWidget {
  final String userId;
  final String measurementId;

  const TailorSelectionScreen({
    required this.userId,
    required this.measurementId,
  });

  @override
  State<TailorSelectionScreen> createState() => _TailorSelectionScreenState();
}

class _TailorSelectionScreenState extends State<TailorSelectionScreen> {
  List<Tailor> tailors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTailors();
  }

  Future<void> loadTailors() async {
    final response = await TailoringApiClient.getAllTailors();

    setState(() {
      isLoading = false;
      if (response.isSuccess) {
        tailors = response.data!;
      }
    });
  }

  Future<void> shareMeasurement(Tailor tailor) async {
    final response = await TailoringApiClient.shareMeasurement(
      measurementId: widget.measurementId,
      tailorId: tailor.id,
      userId: widget.userId,
      message: 'Please review my measurements',
    );

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared with ${tailor.businessName}')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Tailor')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: tailors.length,
              itemBuilder: (context, index) {
                final tailor = tailors[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(tailor.businessName[0]),
                  ),
                  title: Text(tailor.businessName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tailor.ownerName),
                      if (tailor.specialties != null)
                        Text(
                          tailor.specialties!.join(', '),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('${tailor.rating.toStringAsFixed(1)}'),
                    ],
                  ),
                  onTap: () => shareMeasurement(tailor),
                );
              },
            ),
    );
  }
}

/// Example 5: Health Check Widget
class BackendHealthCheck extends StatefulWidget {
  @override
  State<BackendHealthCheck> createState() => _BackendHealthCheckState();
}

class _BackendHealthCheckState extends State<BackendHealthCheck> {
  bool? isHealthy;
  String? healthInfo;

  @override
  void initState() {
    super.initState();
    checkHealth();
  }

  Future<void> checkHealth() async {
    final response = await TailoringApiClient.checkHealth();

    setState(() {
      isHealthy = response.isSuccess;
      if (response.isSuccess) {
        healthInfo = 'Server is running\nUptime: ${response.data?['uptime']}s';
      } else {
        healthInfo = response.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          isHealthy == true ? Icons.check_circle : Icons.error,
          color: isHealthy == true ? Colors.green : Colors.red,
        ),
        title: Text('Backend Status'),
        subtitle: Text(healthInfo ?? 'Checking...'),
        trailing: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: checkHealth,
        ),
      ),
    );
  }
}
