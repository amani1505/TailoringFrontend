# User Registration Bottom Sheet Feature

## 📋 Overview

Added a beautiful user registration bottom sheet that appears before measurement capture. This collects all required user information for the backend API.

---

## ✨ What Was Added

### New Files Created:

1. **`lib/widgets/user_registration_bottom_sheet.dart`**
   - Beautiful bottom sheet UI
   - Form validation
   - Gender selection with icons
   - Height/weight inputs
   - Integrates with TailoringApiClient
   - Creates user in backend

### Files Modified:

2. **`lib/screens/home_screen.dart`**
   - Added import for registration bottom sheet
   - Checks if user exists before showing bottom sheet
   - Shows registration for new users only
   - Automatically navigates to measurement after registration

3. **`lib/services/user_manager.dart`**
   - Added public setter methods
   - `setCurrentUser(User user)` - Store user after registration
   - `setCurrentUserId(String userId)` - Store user ID

---

## 🎯 How It Works

### User Flow:

```
1. User opens app
   ↓
2. Taps "Capture Measurements"
   ↓
3. Check: Is user registered?

   NO (First time) → Show Registration Bottom Sheet
   ├─ User fills form:
   │  - First Name, Last Name
   │  - Email
   │  - Phone (optional)
   │  - Gender (Male/Female)
   │  - Height (required for AI)
   │  - Weight (optional)
   ├─ Tap "Continue to Measurement"
   ├─ Backend creates user
   ├─ Store user in UserManager
   └─ Navigate to MeasurementCaptureScreen

   YES (Returning) → Navigate directly to MeasurementCaptureScreen
```

---

## 🎨 Bottom Sheet Features

### Form Fields:

1. **First Name*** (Required)
   - Validates not empty

2. **Last Name*** (Required)
   - Validates not empty

3. **Email*** (Required)
   - Validates email format
   - Checks for @ symbol

4. **Phone Number** (Optional)
   - No validation

5. **Gender*** (Required)
   - Visual selection with icons
   - Male / Female options
   - Color-coded selection

6. **Height*** (Required for accuracy)
   - Number input in cm
   - Default: 170 cm
   - Validates 100-250 cm range
   - Required for MediaPipe AI

7. **Weight** (Optional)
   - Number input in kg
   - Optional field

### UI Elements:

- ✅ Drag handle at top
- ✅ Icon-based gender selection
- ✅ Info box explaining height importance
- ✅ Loading state during API call
- ✅ Error handling with SnackBar
- ✅ Auto-closes on success
- ✅ Responsive to keyboard

---

## 💻 Code Examples

### Opening the Bottom Sheet:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => UserRegistrationBottomSheet(
    onUserCreated: (User user) {
      // User successfully created
      print('User ID: ${user.id}');
      print('Name: ${user.fullName}');
      print('Height: ${user.height} cm');
    },
  ),
);
```

### Checking if User Exists:

```dart
if (UserManager.isLoggedIn()) {
  // User exists, proceed
  final userId = await UserManager.getCurrentUserId();
} else {
  // Show registration
  showRegistrationBottomSheet();
}
```

### Storing User After Registration:

```dart
onUserCreated: (User user) {
  // Store in UserManager
  UserManager.setCurrentUser(user);

  // Now user is available globally
  print('Stored user: ${user.id}');
}
```

---

## 🔄 Backend Integration

### API Call:

```dart
POST /api/v1/users
Content-Type: application/json

Body:
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phoneNumber": "+1234567890",  // optional
  "gender": "male",
  "height": 175.0,
  "weight": 70.0  // optional
}

Response (Success):
{
  "id": "abc-123-...",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phoneNumber": "+1234567890",
  "gender": "male",
  "height": 175.0,
  "weight": 70.0,
  "isActive": true,
  "createdAt": "2026-01-02T10:00:00Z",
  "updatedAt": "2026-01-02T10:00:00Z"
}
```

### Error Handling:

- Shows SnackBar with error message
- Form stays open for correction
- Loading state stops
- User can retry

---

## 🎨 UI/UX Details

### Design:
- Rounded top corners (24px radius)
- Clean white background
- Color-coded gender selection
- Blue theme matching app
- Responsive layout

### Interactions:
- Tap outside to dismiss
- Drag down to close
- Keyboard-aware (form scrolls up)
- Loading state disables button
- Success auto-closes

### Validation:
- Real-time validation on submit
- Red error messages under fields
- Disabled submit button during loading
- Clear error feedback

---

## 📱 Screenshots (UI Description)

```
┌─────────────────────────────────────┐
│         ━━━ (drag handle)          │
│                                     │
│  👤  Create Your Profile            │
│                                     │
│  We need some basic information...  │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │First Name│  │Last Name │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────┐       │
│  │ Email                   │       │
│  └─────────────────────────┘       │
│                                     │
│  ┌─────────────────────────┐       │
│  │ Phone (optional)        │       │
│  └─────────────────────────┘       │
│                                     │
│  Gender *                           │
│  ┌──────────┐  ┌──────────┐        │
│  │  👨 Male  │  │ 👩 Female │       │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │Height(cm)│  │Weight(kg)│        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ℹ️  Your height is crucial for     │
│     accurate measurements           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ✓ Continue to Measurement   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## ✅ Testing Checklist

- [ ] Bottom sheet appears on first app launch
- [ ] Form validation works for all fields
- [ ] Gender selection highlights properly
- [ ] Height validation (100-250 cm)
- [ ] Email validation (contains @)
- [ ] API call creates user successfully
- [ ] Loading state shows during API call
- [ ] Error handling shows SnackBar
- [ ] Success closes bottom sheet
- [ ] UserManager stores user data
- [ ] Navigation to measurement works
- [ ] Returning users skip registration
- [ ] Keyboard doesn't cover form

---

## 🚀 Usage

### First Time Users:

1. Open app
2. Tap "Capture Measurements"
3. **Bottom sheet appears** ← NEW!
4. Fill in profile information
5. Tap "Continue to Measurement"
6. Proceed to capture images

### Returning Users:

1. Open app
2. Tap "Capture Measurements"
3. Goes directly to measurement screen
4. No registration needed

---

## 🔧 Customization

### Change Default Height:

```dart
// In user_registration_bottom_sheet.dart
final _heightController = TextEditingController(text: '175'); // Change here
```

### Add More Fields:

```dart
// Add new field in bottom sheet
TextFormField(
  controller: _addressController,
  decoration: InputDecoration(
    labelText: 'Address',
    prefixIcon: Icon(Icons.home_outlined),
  ),
),

// Add to API call
final response = await TailoringApiClient.createUser(
  // ... existing fields
  address: _addressController.text,
);
```

### Customize Colors:

```dart
// Change accent color from blue to green
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green, // Change here
  ),
)
```

---

## 🐛 Troubleshooting

### Bottom sheet doesn't appear:

**Check:**
- UserManager.isLoggedIn() returns false
- home_screen.dart has correct import

### Form validation fails:

**Check:**
- Required fields have values
- Email contains @
- Height is between 100-250

### API call fails:

**Check:**
- Backend is running
- Base URL is correct (192.168.0.55:3003)
- Network connectivity

### User not stored:

**Check:**
- UserManager.setCurrentUser(user) is called
- user object is not null

---

## 📝 Notes

- Registration happens **once per app install**
- User data stored **in-memory** (clears on app restart)
- For persistent storage, use shared_preferences version in user_manager.dart
- Height is **required** for accurate MediaPipe measurements
- Gender helps AI with body proportion calculations

---

## 🎉 Benefits

✅ Better UX - Smooth onboarding
✅ Data validation - Ensures quality input
✅ Backend integration - Creates real users
✅ Reusable widget - Can use elsewhere
✅ Error handling - User-friendly messages
✅ Skip for returning users - No repeated registration
✅ Clean design - Matches app theme

---

**Feature ready to use!** Restart your app and tap "Capture Measurements" to see the registration bottom sheet. 🚀
