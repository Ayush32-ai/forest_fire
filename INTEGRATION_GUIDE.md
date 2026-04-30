# Integration Guide - Update main.dart

## 🔄 How to Integrate Enhanced OTP Screens

### Current main.dart Structure (Example)
```dart
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? LoginScreen(
            onSignUpPressed: () {
              setState(() => _showLogin = false);
            },
          )
        : SignUpScreen(
            onSignInPressed: () {
              setState(() => _showLogin = true);
            },
          );
  }
}
```

### Updated main.dart (New Enhanced Screens)
```dart
// CHANGE THIS:
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';

// TO THIS:
import 'screens/enhanced_signup_screen.dart';
import 'screens/enhanced_login_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? EnhancedLoginScreen(           // ← Changed
            onSignUpPressed: () {
              setState(() => _showLogin = false);
            },
          )
        : EnhancedSignupScreen(          // ← Changed
            onSignInPressed: () {
              setState(() => _showLogin = true);
            },
          );
  }
}
```

---

## 📋 Copy-Paste Integration

### Step 1: Update Imports
Find this in your `main.dart`:
```dart
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
```

Replace with:
```dart
import 'screens/enhanced_signup_screen.dart';
import 'screens/enhanced_login_screen.dart';
```

### Step 2: Update LoginScreen
Find this:
```dart
LoginScreen(
  onSignUpPressed: () { ... }
)
```

Replace with:
```dart
EnhancedLoginScreen(
  onSignUpPressed: () { ... }
)
```

### Step 3: Update SignUpScreen
Find this:
```dart
SignUpScreen(
  onSignInPressed: () { ... }
)
```

Replace with:
```dart
EnhancedSignupScreen(
  onSignInPressed: () { ... }
)
```

### Step 4: Run
```bash
flutter pub get
flutter run
```

---

## 🎯 Full Example (Complete main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/enhanced_signup_screen.dart';      // ← NEW
import 'screens/enhanced_login_screen.dart';      // ← NEW
// import 'screens/home_screen.dart';  // Your home page after login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forest Fire Monitor',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in - show home screen
          // return const HomeScreen();
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome! ${snapshot.data!.email}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // User not logged in - show auth screens
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? EnhancedLoginScreen(                      // ← NEW
            onSignUpPressed: () {
              setState(() => _showLogin = false);
            },
          )
        : EnhancedSignupScreen(                     // ← NEW
            onSignInPressed: () {
              setState(() => _showLogin = true);
            },
          );
  }
}
```

---

## 🔄 Migration Steps (Detailed)

### Step 1: Backup Original Files
```bash
cd lib/screens
cp signup_screen.dart signup_screen.dart.backup
cp login_screen.dart login_screen.dart.backup
```

### Step 2: Keep Old Files or Delete
**Option A: Keep Old Files (Recommended for now)**
- Leave old `signup_screen.dart` and `login_screen.dart` as is
- Only import the new ones
- Easy to rollback if needed

**Option B: Delete Old Files**
```bash
rm signup_screen.dart
rm login_screen.dart
```

### Step 3: Update main.dart
Replace the imports and widget names as shown above

### Step 4: Run Tests
```bash
flutter pub get
flutter pub outdated
flutter run
```

### Step 5: Test Features
- [ ] Sign up with all fields
- [ ] Receive OTP
- [ ] Login with password + OTP
- [ ] Check console for debug logs

---

## 🚨 If Something Breaks

### Issue: Import Error
```
Error: The library 'file:///lib/screens/login_screen.dart' doesn't export a name 'LoginScreen'
```

**Solution:**
Make sure you updated the import:
```dart
// WRONG
import 'screens/login_screen.dart';

// CORRECT
import 'screens/enhanced_login_screen.dart';
```

### Issue: Widget Not Found
```
Error: The name 'LoginScreen' isn't a type
```

**Solution:**
Replace `LoginScreen` with `EnhancedLoginScreen`:
```dart
// WRONG
return LoginScreen(...);

// CORRECT
return EnhancedLoginScreen(...);
```

### Issue: Ambiguous Name
```
Error: The name 'LoginScreen' is ambiguous
```

**Solution:**
Remove the old import:
```dart
// DELETE THIS:
import 'screens/login_screen.dart';

// KEEP THIS:
import 'screens/enhanced_login_screen.dart';
```

---

## 🔍 Verify Integration

### Check 1: Imports Correct
```bash
grep -n "import.*screen" lib/main.dart
# Should show:
# enhanced_signup_screen.dart
# enhanced_login_screen.dart
```

### Check 2: No Compilation Errors
```bash
flutter analyze
# Should show no errors
```

### Check 3: Run App
```bash
flutter run
# Should start without errors
```

### Check 4: Test Screens
1. App starts → See login screen
2. Click "Sign Up" → See signup form
3. Fill form → Check email field validation
4. Fill all fields → Click Continue → OTP screen

---

## 📊 Widget Tree Comparison

### OLD Structure
```
AuthWrapper
  ├─ LoginScreen
  │  ├─ Email input
  │  ├─ Password input
  │  └─ Sign in button
  │
  └─ SignUpScreen
     ├─ Email input
     ├─ Name input
     ├─ Password input
     ├─ Confirm password
     └─ Sign up button
```

### NEW Structure
```
AuthWrapper
  ├─ EnhancedLoginScreen
  │  ├─ Email input
  │  ├─ Password input
  │  └─ Sign in button (sends OTP)
  │  └─ OtpVerificationWithPasswordScreen
  │     ├─ 6 OTP input fields
  │     └─ Verify & Sign In button
  │
  └─ EnhancedSignupScreen
     ├─ Email input
     ├─ Full Name input
     ├─ Phone Number input
     ├─ Password input
     ├─ Confirm password
     ├─ Terms checkbox
     └─ Continue button (sends OTP)
     └─ OtpVerificationScreen
        ├─ 6 OTP input fields
        └─ Verify OTP button
```

---

## 🎯 After Integration

### What You'll Get:
✅ New signup with name, phone, password  
✅ Dual-factor login (password + OTP)  
✅ Better error handling  
✅ Debug logging  
✅ Enhanced UI/UX  

### What You Won't Lose:
✅ Existing Firebase integration  
✅ Google Sign-In (still available)  
✅ User authentication  
✅ App state management  

---

## 💡 Next Steps

### 1. Complete Integration
- [ ] Update main.dart with new imports
- [ ] Test signup and login flows
- [ ] Verify email OTP delivery
- [ ] Check console for debug logs

### 2. Optional: Store Phone Number
Add Firestore code to save phone:
```dart
// In completeSignupWithOtp() method
await FirebaseFirestore.instance
    .collection('users')
    .doc(userCredential.user!.uid)
    .set({
      'email': email,
      'displayName': fullName,
      'phoneNumber': phoneNumber,
      'createdAt': DateTime.now(),
    });
```

### 3. Production Ready
- [ ] Move API key to environment variables
- [ ] Set up error monitoring
- [ ] Configure email domain
- [ ] Load test with multiple users
- [ ] Monitor Brevo email delivery

---

## 📝 Checklist Before Going Live

- [ ] main.dart updated with new imports
- [ ] No compilation errors (`flutter analyze`)
- [ ] Test signup flow (all fields)
- [ ] Test login flow (password + OTP)
- [ ] Check console for debug 📧 emoji
- [ ] Verify OTP email arrives
- [ ] Test error scenarios
- [ ] Backup original files
- [ ] Firebase rules configured
- [ ] Brevo sender email verified

---

## 🆘 Support Resources

**Documentation Files Created:**
- `OTP_ENHANCED_SETUP.md` - Full setup guide
- `OTP_QUICK_START.md` - Quick reference
- This file - Integration guide

**Brevo Support:**
- https://www.brevo.com/support
- API Docs: https://developers.brevo.com

**Firebase Support:**
- https://firebase.google.com/support
- Console: https://console.firebase.google.com

---

**Status:** ✅ Ready for Integration  
**Last Updated:** April 23, 2026
