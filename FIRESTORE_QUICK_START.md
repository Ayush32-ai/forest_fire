# 🚀 Firestore Quick Start - 3 Steps

## Step 1: Firebase Console (5 minutes)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your **forest_fire** project
3. Click **"Firestore Database"** (left sidebar)
4. Click **"Create database"**
5. Choose **"Start in test mode"**
6. Select location: **asia-south1** (Mumbai) or closest to you
7. Click **"Enable"**

## Step 2: Security Rules (2 minutes)

1. In Firestore, click **"Rules"** tab
2. Copy-paste this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /sensor_readings/{reading} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /fire_alerts/{alert} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /analytics/{data} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **"Publish"**

## Step 3: Test Your App (2 minutes)

1. Run your app: `flutter run`
2. Sign up a new user
3. Go to Firebase Console → Firestore → Data
4. You should see:
   - **users** collection with your profile
   - **sensor_readings** collection (when ESP32 sends data)
   - **fire_alerts** collection (when risk is high)

## ✅ Done!

Your app now stores:
- ✅ User profiles (name, email, phone, location)
- ✅ ESP32 sensor history (temperature, humidity, smoke)
- ✅ Fire alerts (when risk ≥ 40%)
- ✅ Analytics data

## 📱 View Profile in App

Add this to your navigation:

```dart
// In your app bar or drawer
IconButton(
  icon: Icon(Icons.person),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfileScreen()),
    );
  },
)
```

## 🔍 Verify Data

Check Firebase Console:
- Go to **Firestore Database** → **Data** tab
- Browse collections: users, sensor_readings, fire_alerts
- See real-time updates as app runs

## 📊 What's Stored

### User Profile
```
users/{userId}
  - name: "John Doe"
  - email: "john@example.com"
  - phoneNumber: "+1234567890"
  - location: "Mumbai"
```

### Sensor Readings
```
sensor_readings/{auto-id}
  - temperature: 35.5
  - humidity: 45.2
  - smokeLevel: 120
  - timestamp: 2026-04-28 10:30:00
```

### Fire Alerts
```
fire_alerts/{auto-id}
  - riskScore: 75.5
  - riskLevel: "High Risk"
  - temperature: 42.0
  - smokeLevel: 250
  - acknowledged: false
```

## 🆘 Need Help?

See full guide: `FIRESTORE_SETUP_GUIDE.md`
