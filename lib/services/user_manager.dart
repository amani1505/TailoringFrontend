import 'package:frontend/services/tailoring_api_client.dart';
import 'package:frontend/models/user_model.dart';

/// Simple User Manager for handling user authentication and profile
/// Uses in-memory storage for demo - replace with shared_preferences or secure storage
class UserManager {
  // Made public so registration bottom sheet can set them
  static User? _currentUser;
  static String? _currentUserId;

  // Setters for external access
  static void setCurrentUser(User user) {
    _currentUser = user;
    _currentUserId = user.id;
  }

  static void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Get or create current user
  static Future<String> getCurrentUserId() async {
    if (_currentUserId != null) {
      return _currentUserId!;
    }

    // For demo: create a default user
    // In production: implement proper login/registration flow
    final response = await TailoringApiClient.createUser(
      firstName: 'Demo',
      lastName: 'User',
      email: 'demo${DateTime.now().millisecondsSinceEpoch}@example.com',
      gender: 'male',
      height: 175.0,
      weight: 70.0,
    );

    if (response.isSuccess) {
      _currentUser = response.data!;
      _currentUserId = _currentUser!.id;
      return _currentUserId!;
    }

    throw Exception('Failed to create user: ${response.errorMessage}');
  }

  /// Get current user object
  static Future<User> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser!;
    }

    // Fetch user by ID
    final userId = await getCurrentUserId();
    final response = await TailoringApiClient.getUserById(userId);

    if (response.isSuccess) {
      _currentUser = response.data!;
      return _currentUser!;
    }

    throw Exception('Failed to get user: ${response.errorMessage}');
  }

  /// Get user height (required for measurement processing)
  static Future<double> getUserHeight() async {
    final user = await getCurrentUser();
    return user.height ?? 175.0; // Default height if not set
  }

  /// Get user gender (required for measurement processing)
  static Future<String> getUserGender() async {
    final user = await getCurrentUser();
    return user.gender ?? 'male'; // Default gender if not set
  }

  /// Update user profile
  static Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    double? height,
    double? weight,
  }) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (email != null) updates['email'] = email;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (gender != null) updates['gender'] = gender;
    if (height != null) updates['height'] = height;
    if (weight != null) updates['weight'] = weight;

    final response = await TailoringApiClient.updateUser(_currentUserId!, updates);

    if (response.isSuccess) {
      _currentUser = response.data!;
      return true;
    }

    return false;
  }

  /// Logout user
  static void logout() {
    _currentUser = null;
    _currentUserId = null;
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _currentUserId != null;
  }
}

// ===== WITH SHARED PREFERENCES VERSION =====
// Uncomment this version if you want persistent storage
// Add to pubspec.yaml: shared_preferences: ^2.2.2

/*
import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  static const String _userIdKey = 'user_id';
  static const String _userHeightKey = 'user_height';
  static const String _userGenderKey = 'user_gender';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _userEmailKey = 'user_email';

  static User? _currentUser;

  /// Get or create current user with persistent storage
  static Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId != null) {
      return userId;
    }

    // Create new user
    final response = await TailoringApiClient.createUser(
      firstName: 'Demo',
      lastName: 'User',
      email: 'demo${DateTime.now().millisecondsSinceEpoch}@example.com',
      gender: 'male',
      height: 175.0,
      weight: 70.0,
    );

    if (response.isSuccess) {
      _currentUser = response.data!;
      userId = _currentUser!.id;

      // Save to persistent storage
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userFirstNameKey, _currentUser!.firstName);
      await prefs.setString(_userLastNameKey, _currentUser!.lastName);
      await prefs.setString(_userEmailKey, _currentUser!.email);
      if (_currentUser!.height != null) {
        await prefs.setDouble(_userHeightKey, _currentUser!.height!);
      }
      if (_currentUser!.gender != null) {
        await prefs.setString(_userGenderKey, _currentUser!.gender!);
      }

      return userId;
    }

    throw Exception('Failed to create user: ${response.errorMessage}');
  }

  /// Get current user
  static Future<User> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser!;
    }

    final userId = await getCurrentUserId();
    final response = await TailoringApiClient.getUserById(userId);

    if (response.isSuccess) {
      _currentUser = response.data!;
      return _currentUser!;
    }

    throw Exception('Failed to get user: ${response.errorMessage}');
  }

  /// Get user height
  static Future<double> getUserHeight() async {
    final prefs = await SharedPreferences.getInstance();
    double? height = prefs.getDouble(_userHeightKey);

    if (height != null) {
      return height;
    }

    final user = await getCurrentUser();
    return user.height ?? 175.0;
  }

  /// Get user gender
  static Future<String> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    String? gender = prefs.getString(_userGenderKey);

    if (gender != null) {
      return gender;
    }

    final user = await getCurrentUser();
    return user.gender ?? 'male';
  }

  /// Update user profile with persistent storage
  static Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    double? height,
    double? weight,
  }) async {
    final userId = await getCurrentUserId();

    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (email != null) updates['email'] = email;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (gender != null) updates['gender'] = gender;
    if (height != null) updates['height'] = height;
    if (weight != null) updates['weight'] = weight;

    final response = await TailoringApiClient.updateUser(userId, updates);

    if (response.isSuccess) {
      _currentUser = response.data!;

      // Update persistent storage
      final prefs = await SharedPreferences.getInstance();
      if (firstName != null) await prefs.setString(_userFirstNameKey, firstName);
      if (lastName != null) await prefs.setString(_userLastNameKey, lastName);
      if (email != null) await prefs.setString(_userEmailKey, email);
      if (gender != null) await prefs.setString(_userGenderKey, gender);
      if (height != null) await prefs.setDouble(_userHeightKey, height);

      return true;
    }

    return false;
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userHeightKey);
    await prefs.remove(_userGenderKey);
    await prefs.remove(_userFirstNameKey);
    await prefs.remove(_userLastNameKey);
    await prefs.remove(_userEmailKey);
    _currentUser = null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null;
  }
}
*/
