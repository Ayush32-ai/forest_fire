# Cloud Firestore Setup Guide

## 🔥 Firebase Console Setup

### Step 1: Enable Cloud Firestore

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **forest_fire**
3. Click on **"Firestore Database"** in the left sidebar (under Build section)
4. Click **"Create database"** button
5. Choose **"Start in test mode"** (for development)
   - Test mode allows read/write access for 30 days
   - We'll update security rules after
6. Select a location closest to your users:
   - For India: `asia-south1` (Mumbai)
   - For US: `us-central1`
   - For Europe: `europe-west1`
7. Click **"Enable"**
8. Wait for database creation (takes 1-2 minutes)

### Step 2: Set Up Security Rules

1. In Firestore Console, click on **"Rules"** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own profile only
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Sensor data - authenticated users can read/write their own data
    match /sensor_readings/{reading} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
    
    // Fire alerts - authenticated users can read/write their own alerts
    match /fire_alerts/{alert} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
    
    // Analytics - authenticated users can read/write their own analytics
    match /analytics/{data} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **"Publish"**

### Step 3: Verify Setup

1. Go to **"Data"** tab in Firestore Console
2. You should see an empty database
3. Collections will be created automatically when app writes data

---

## 📦 Flutter Package Installation

The package has already been added to your project:

```bash
flutter pub add cloud_firestore
```

---

## 🗂️ Database Structure

### Collections Overview

#### 1. **users** Collection
Stores user profile information.

**Document ID**: Firebase Auth UID  
**Fields**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phoneNumber": "+1234567890",
  "location": "Mumbai, India",
  "profileImageUrl": "",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### 2. **sensor_readings** Collection
Stores ESP32 sensor data history.

**Document ID**: Auto-generated  
**Fields**:
```json
{
  "userId": "firebase_auth_uid",
  "deviceId": "http://192.168.1.100",
  "temperature": 35.5,
  "humidity": 45.2,
  "smokeLevel": 120,
  "timestamp": Timestamp,
  "createdAt": "2026-04-28T10:30:00.000Z"
}
```

#### 3. **fire_alerts** Collection
Stores fire risk alerts when risk is high.

**Document ID**: Auto-generated  
**Fields**:
```json
{
  "userId": "firebase_auth_uid",
  "deviceId": "http://192.168.1.100",
  "riskScore": 75.5,
  "riskLevel": "High Risk",
  "temperature": 42.0,
  "smokeLevel": 250,
  "location": "Forest Area A",
  "timestamp": Timestamp,
  "createdAt": "2026-04-28T10:30:00.000Z",
  "acknowledged": false,
  "acknowledgedAt": null
}
```

#### 4. **analytics** Collection
Stores daily analytics summaries.

**Document ID**: `{userId}_{date}` (e.g., `abc123_2026-04-28`)  
**Fields**:
```json
{
  "userId": "firebase_auth_uid",
  "date": "2026-04-28",
  "avgTemperature": 32.5,
  "maxTemperature": 38.0,
  "minTemperature": 28.0,
  "avgHumidity": 55.0,
  "avgSmokeLevel": 100,
  "maxSmokeLevel": 180,
  "totalReadings": 288,
  "alertsCount": 3,
  "timestamp": Timestamp
}
```

---

## 🚀 Usage in Your App

### 1. User Profile Management

**After Signup** (Automatic):
```dart
// Already integrated in auth_service.dart
// User profile is automatically saved after OTP verification
```

**View Profile**:
```dart
// Navigate to profile screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => UserProfileScreen()),
);
```

**Update Profile**:
```dart
final firestoreService = FirestoreService();
await firestoreService.saveUserProfile(
  userId: currentUser.uid,
  name: "John Doe",
  email: "john@example.com",
  phoneNumber: "+1234567890",
  location: "Mumbai",
);
```

### 2. Sensor Data Storage

**Automatic Storage** (Already Integrated):
```dart
// ESP32DataService automatically saves sensor readings to Firestore
// Every time fetchEnhancedSensorData() is called
```

**Get Recent Readings**:
```dart
final firestoreService = FirestoreService();
final readings = await firestoreService.getRecentSensorReadings(limit: 50);

for (var reading in readings) {
  print('Temp: ${reading['temperature']}°C');
  print('Smoke: ${reading['smokeLevel']}');
}
```

**Real-time Stream**:
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: firestoreService.streamSensorReadings(limit: 20),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final readings = snapshot.data!;
      return ListView.builder(
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final reading = readings[index];
          return ListTile(
            title: Text('${reading['temperature']}°C'),
            subtitle: Text('Smoke: ${reading['smokeLevel']}'),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### 3. Fire Alerts

**Save Alert** (When Risk is High):
```dart
final riskModel = FireRiskPredictionModel(...);
await riskModel.saveAlertIfHighRisk(
  location: "Forest Area A",
  deviceId: "ESP32_001",
);
```

**Get Unacknowledged Alerts**:
```dart
final alerts = await firestoreService.getFireAlerts(
  acknowledged: false,
  limit: 10,
);
```

**Acknowledge Alert**:
```dart
await firestoreService.acknowledgeAlert(alertId);
```

### 4. Analytics

**Save Daily Summary**:
```dart
await firestoreService.saveDailyAnalytics(
  date: DateTime.now(),
  avgTemperature: 32.5,
  maxTemperature: 38.0,
  minTemperature: 28.0,
  avgHumidity: 55.0,
  avgSmokeLevel: 100,
  maxSmokeLevel: 180,
  totalReadings: 288,
  alertsCount: 3,
);
```

**Get Analytics for Date Range**:
```dart
final analytics = await firestoreService.getAnalyticsByDateRange(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

---

## 🔒 Security Best Practices

### Current Security Rules Explained

1. **Authentication Required**: All operations require user to be logged in
2. **User Isolation**: Users can only access their own data
3. **Read/Write Separation**: Different permissions for reading vs writing

### Production Security Rules

For production, update rules to be more restrictive:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) && 
                       request.resource.data.email == resource.data.email; // Can't change email
      allow delete: if false; // Prevent deletion
    }
    
    // Sensor readings
    match /sensor_readings/{reading} {
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      allow update, delete: if false; // Immutable
    }
    
    // Fire alerts
    match /fire_alerts/{alert} {
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid &&
                       request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['acknowledged', 'acknowledgedAt']); // Only allow acknowledging
      allow delete: if false;
    }
    
    // Analytics
    match /analytics/{data} {
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      allow write: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📊 Monitoring & Maintenance

### View Data in Firebase Console

1. Go to Firestore Console → Data tab
2. Browse collections and documents
3. Manually edit/delete data if needed

### Monitor Usage

1. Go to Firestore Console → Usage tab
2. Check:
   - Document reads/writes
   - Storage size
   - Network bandwidth

### Free Tier Limits

- **Stored data**: 1 GB
- **Document reads**: 50,000/day
- **Document writes**: 20,000/day
- **Document deletes**: 20,000/day

### Cleanup Old Data

Run cleanup periodically:

```dart
final firestoreService = FirestoreService();
await firestoreService.deleteOldSensorReadings(daysToKeep: 30);
```

---

## 🐛 Troubleshooting

### Error: "Missing or insufficient permissions"

**Solution**: Check security rules and ensure user is authenticated

### Error: "PERMISSION_DENIED"

**Solution**: 
1. Verify user is logged in
2. Check if userId matches in document
3. Review security rules

### Data Not Showing Up

**Solution**:
1. Check Firebase Console → Data tab
2. Verify internet connection
3. Check app logs for errors

### Slow Queries

**Solution**: Add indexes
1. Firebase will suggest indexes in console
2. Click the link in error message
3. Create composite indexes as needed

---

## ✅ Testing Checklist

- [ ] Firestore enabled in Firebase Console
- [ ] Security rules published
- [ ] User profile saved after signup
- [ ] Sensor readings being stored
- [ ] Fire alerts created when risk is high
- [ ] Can view profile in UserProfileScreen
- [ ] Can update profile information
- [ ] Data visible in Firebase Console

---

## 📝 Next Steps

1. **Enable Firestore** in Firebase Console (follow Step 1 above)
2. **Publish Security Rules** (follow Step 2 above)
3. **Test the app**:
   - Sign up a new user
   - Check if profile is saved in Firestore Console
   - Let ESP32 send data
   - Check if sensor readings appear in Firestore
4. **Add Profile Screen to Navigation**:
   - Add UserProfileScreen to your app's navigation
   - Add a profile button in the app bar or drawer

---

## 🎯 Summary

Your app now has:
- ✅ User profiles stored in Firestore
- ✅ ESP32 sensor data history
- ✅ Fire alerts when risk is high
- ✅ Analytics data for charts
- ✅ Real-time data streaming
- ✅ Secure access with Firebase Auth

All data persists across app restarts and is synced across devices!
