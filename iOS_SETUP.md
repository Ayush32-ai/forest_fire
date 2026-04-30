# iOS Configuration for Google Sign-In

## Quick Setup for iOS

### 1. Add GoogleService-Info.plist

1. Download from Firebase Console:
   - Project Settings → iOS app → GoogleService-Info.plist
   - Add to: `ios/Runner/GoogleService-Info.plist`

2. In Xcode:
   - Open `ios/Runner.xcworkspace`
   - Right-click Runner → Add Files to "Runner"
   - Select GoogleService-Info.plist
   - ✅ Check "Copy items if needed"
   - ✅ Make sure "Runner" target is selected

### 2. Add URL Scheme for Google Sign-In

The URL scheme will be automatically configured via the GoogleService-Info.plist file, but you may also need to add it manually:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Runner target
3. Go to Info tab
4. Look for "URL types" or add it:
   - Add a new entry: `URL types`
   - Set Identifier: `com.googleusercontent.apps`
   - Set URL Schemes: Extract from GoogleService-Info.plist `GOOGLE_OAUTH_CALLBACK_SCHEME_IDENTIFIER`
   
### 3. Update Info.plist

The `ios/Runner/Info.plist` should already have most configurations, but verify:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>googlechrome</string>
  <string>googleplus</string>
</array>
```

### 4. Pod Installation

Run:
```bash
cd ios
pod repo update
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### 5. Verify Setup

1. Build and run on a physical device (Google Sign-In may not work on simulator)
2. Tap "Sign in with Google"
3. You should see the Google sign-in flow

### 6. Troubleshooting iOS

**Issue: "The operation couldn't be completed. (com.google.GIDSignIn error -1.)"**
- Solution: Ensure GoogleService-Info.plist is added to Xcode project
- Verify the plist is in the correct location: `ios/Runner/`

**Issue: URL scheme error**
- Solution: Check the `REVERSED_CLIENT_ID` in GoogleService-Info.plist
- Add this value as URL scheme in Xcode

**Issue: App crashes on Google Sign-In**
- Solution: Make sure you're testing on physical device, not simulator
- Run `flutter clean` and rebuild

## Firebase Console iOS App Configuration

Your iOS app should have these settings in Firebase Console:

1. **Bundle ID**: `com.example.forest_fire` (or your actual bundle ID)
2. **Team ID**: Available in Apple Developer account
3. **App Store ID**: (Optional, for App Store distribution)

## Next Steps

1. ✅ Add GoogleService-Info.plist
2. ✅ Update iOS deployment target to 12.0 or higher
3. ✅ Run `pod install`
4. ✅ Build and test on physical device
5. ✅ Test Google Sign-In flow
