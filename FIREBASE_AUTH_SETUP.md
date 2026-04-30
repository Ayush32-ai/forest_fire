# Firebase Authentication Setup Guide

This guide will help you complete the Firebase authentication setup for your Forest Fire Monitor app.

## ✅ What's Been Done

1. Added Firebase dependencies to `pubspec.yaml`:
   - `firebase_core`: Firebase core functionality
   - `firebase_auth`: Authentication services
   - `google_sign_in`: Google Sign-In integration
   - `sign_in_with_apple`: Apple Sign-In support

2. Created authentication services in `lib/services/auth_service.dart`:
   - Email sign-up and sign-in
   - Google Sign-In
   - Password reset
   - Sign out

3. Created UI screens:
   - Login screen with email and Google sign-in
   - Sign-up screen with validation
   - Integrated into main app with auth state management
   - Added logout button to app

4. Created Firebase configuration file

## 🔧 Next Steps to Complete Setup

### Step 1: Install Dependencies
Run the following command in your terminal:

```bash
flutter pub get
```

### Step 2: Android Configuration (Already Done)

Your `android/app/google-services.json` is already configured with:
- Project ID: `ayush82-ee6b9`
- API Key: `AIzaSyAcNm75Z8wY7xjIskSUHWvZVi-P7NrYh9s`

### Step 3: iOS Configuration

#### 3a. Add GoogleService-Info.plist to iOS Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ayush82-ee6b9`
3. Add an iOS app:
   - Bundle ID: `com.example.forest_fire` (or your actual bundle ID)
   - Download `GoogleService-Info.plist`
4. Add the file to your iOS project:
   - Open `ios/Runner.xcworkspace` in Xcode (NOT Runner.xcodeproj)
   - Right-click on Runner → Add Files to "Runner"
   - Select the downloaded `GoogleService-Info.plist`
   - Make sure it's added to the Runner target

#### 3b. Update Firebase SDK Version (iOS)

Edit `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FIREBASE_ANALYTICS_COLLECTION_ENABLED=1',
      ]
    end
  end
end
```

#### 3c. Update iOS Deployment Target

In `ios/Podfile`, ensure minimum deployment target:

```ruby
platform :ios, '12.0'
```

### Step 4: Configure Google Sign-In

#### 4a. Android Configuration

Add to `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:21.0.0'
}
```

#### 4b. iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project → Runner target
3. Go to Info tab
4. Add the following URL scheme:
   - Key: `CFBundleURLTypes`
   - Add a URL type with:
     - Identifier: `com.googleusercontent.apps`
     - URL Schemes: `com.googleusercontent.apps.YOUR_GOOGLE_APP_ID`

To get your Google App ID:
1. Go to Firebase Console
2. Project Settings → Your Apps → iOS app
3. Look for the `GOOGLE_APP_ID` in GoogleService-Info.plist

### Step 5: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project `ayush82-ee6b9`
3. Go to Authentication → Sign-in method
4. Enable:
   - Email/Password
   - Google
   - (Optional) Apple Sign-In for iOS

### Step 6: Test the App

Run the app with:

```bash
flutter run
```

Test the following flows:
1. ✅ Email sign-up with validation
2. ✅ Email sign-in
3. ✅ Google Sign-In
4. ✅ Sign out
5. ✅ Session persistence (still logged in after app restart)

## 📱 Platform-Specific Notes

### Android
- Ensure you're using a device or emulator with Google Play Services
- The `google-services.json` is already configured

### iOS
- Use Xcode to manage iOS configuration
- CocoaPods will download Firebase SDKs automatically
- Test on a physical device for Google Sign-In (simulators may have issues)

## 🆘 Troubleshooting

### "PlatformException: DEVELOPER_ERROR"
- Check Google credentials in Firebase Console
- Ensure keystore/signing certificate matches
- Rebuild the app: `flutter clean && flutter pub get && flutter run`

### "FirebaseAuthException: An internal error has occurred"
- Verify Firebase project ID in `firebase_options.dart`
- Check internet connection
- Ensure Firebase Authentication is enabled in Console

### "GoogleSignIn platform not initialized"
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app

### iOS GoogleService-Info.plist not found
- Ensure the file is added to Xcode (not just in the file system)
- Verify it's added to the Runner target (not just the project)
- Clean and rebuild: `flutter clean && flutter run`

## 📄 File Structure

```
lib/
├── main.dart                 # Updated with Firebase initialization
├── firebase_options.dart     # Firebase configuration
├── services/
│   └── auth_service.dart     # Authentication service
├── screens/
│   ├── login_screen.dart     # Login UI
│   └── signup_screen.dart    # Sign-up UI
```

## 🔐 Security Notes

1. **API Keys**: The API keys in this project are for demo/development. For production:
   - Restrict API key usage in Firebase Console
   - Use App Check for production
   - Enable Security Rules for Firestore/Realtime Database

2. **Password Reset**: Users can reset their password via "Forgot Password" link (can be added to login screen)

3. **Session Management**: Auth state is automatically managed by Firebase

## ✨ Features Implemented

- ✅ Email/Password Sign-Up with validation
- ✅ Email/Password Sign-In
- ✅ Google Sign-In
- ✅ Sign Out with menu button
- ✅ Session persistence (auto-login on app restart)
- ✅ Error handling and user-friendly messages
- ✅ Loading states and feedback
- ✅ Password visibility toggle

## 📚 Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
