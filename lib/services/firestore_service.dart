import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER PROFILE ====================

  /// Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phoneNumber,
    String? location,
    String? profileImageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'location': location ?? '',
        'profileImageUrl': profileImageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User profile saved for: $email');
    } catch (e) {
      print('❌ Error saving user profile: $e');
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Update user location
  Future<void> updateUserLocation(String userId, String location) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating location: $e');
      throw Exception('Failed to update location: $e');
    }
  }

  // ==================== SENSOR READINGS ====================

  /// Save ESP32 sensor reading
  Future<void> saveSensorReading({
    required double temperature,
    required double humidity,
    required int smokeLevel,
    required String deviceId,
  }) async {
    try {
      await _firestore.collection('sensor_readings').add({
        'userId': currentUserId,
        'deviceId': deviceId,
        'temperature': temperature,
        'humidity': humidity,
        'smokeLevel': smokeLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      print(
        '✅ Sensor reading saved: T=$temperature°C, H=$humidity%, S=$smokeLevel',
      );
    } catch (e) {
      print('❌ Error saving sensor reading: $e');
    }
  }

  /// Get recent sensor readings (last N readings)
  Future<List<Map<String, dynamic>>> getRecentSensorReadings({
    int limit = 50,
    String? deviceId,
  }) async {
    try {
      Query query = _firestore
          .collection('sensor_readings')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (deviceId != null) {
        query = query.where('deviceId', isEqualTo: deviceId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting sensor readings: $e');
      return [];
    }
  }

  /// Get sensor readings for a date range
  Future<List<Map<String, dynamic>>> getSensorReadingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? deviceId,
  }) async {
    try {
      Query query = _firestore
          .collection('sensor_readings')
          .where('userId', isEqualTo: currentUserId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true);

      if (deviceId != null) {
        query = query.where('deviceId', isEqualTo: deviceId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting sensor readings by date: $e');
      return [];
    }
  }

  /// Stream sensor readings in real-time
  Stream<List<Map<String, dynamic>>> streamSensorReadings({
    int limit = 20,
    String? deviceId,
  }) {
    Query query = _firestore
        .collection('sensor_readings')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (deviceId != null) {
      query = query.where('deviceId', isEqualTo: deviceId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ==================== FIRE ALERTS ====================

  /// Save fire alert
  Future<void> saveFireAlert({
    required double riskScore,
    required String riskLevel,
    required double temperature,
    required int smokeLevel,
    required String deviceId,
    String? location,
  }) async {
    try {
      await _firestore.collection('fire_alerts').add({
        'userId': currentUserId,
        'deviceId': deviceId,
        'riskScore': riskScore,
        'riskLevel': riskLevel,
        'temperature': temperature,
        'smokeLevel': smokeLevel,
        'location': location ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'acknowledged': false,
      });

      print('🚨 Fire alert saved: Risk=$riskLevel ($riskScore)');
    } catch (e) {
      print('❌ Error saving fire alert: $e');
    }
  }

  /// Get fire alerts
  Future<List<Map<String, dynamic>>> getFireAlerts({
    int limit = 50,
    bool? acknowledged,
  }) async {
    try {
      Query query = _firestore
          .collection('fire_alerts')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (acknowledged != null) {
        query = query.where('acknowledged', isEqualTo: acknowledged);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting fire alerts: $e');
      return [];
    }
  }

  /// Acknowledge fire alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _firestore.collection('fire_alerts').doc(alertId).update({
        'acknowledged': true,
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error acknowledging alert: $e');
    }
  }

  /// Stream fire alerts in real-time
  Stream<List<Map<String, dynamic>>> streamFireAlerts({
    int limit = 20,
    bool? acknowledged,
  }) {
    Query query = _firestore
        .collection('fire_alerts')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (acknowledged != null) {
      query = query.where('acknowledged', isEqualTo: acknowledged);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ==================== ANALYTICS DATA ====================

  /// Save daily analytics summary
  Future<void> saveDailyAnalytics({
    required DateTime date,
    required double avgTemperature,
    required double maxTemperature,
    required double minTemperature,
    required double avgHumidity,
    required int avgSmokeLevel,
    required int maxSmokeLevel,
    required int totalReadings,
    required int alertsCount,
  }) async {
    try {
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('analytics')
          .doc('${currentUserId}_$dateKey')
          .set({
            'userId': currentUserId,
            'date': dateKey,
            'avgTemperature': avgTemperature,
            'maxTemperature': maxTemperature,
            'minTemperature': minTemperature,
            'avgHumidity': avgHumidity,
            'avgSmokeLevel': avgSmokeLevel,
            'maxSmokeLevel': maxSmokeLevel,
            'totalReadings': totalReadings,
            'alertsCount': alertsCount,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print('📊 Analytics saved for: $dateKey');
    } catch (e) {
      print('❌ Error saving analytics: $e');
    }
  }

  /// Get analytics for date range
  Future<List<Map<String, dynamic>>> getAnalyticsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startKey =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endKey =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection('analytics')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting analytics: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Delete old sensor readings (cleanup)
  Future<void> deleteOldSensorReadings({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('sensor_readings')
          .where('userId', isEqualTo: currentUserId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('🗑️ Deleted ${snapshot.docs.length} old sensor readings');
    } catch (e) {
      print('❌ Error deleting old readings: $e');
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final readings = await getRecentSensorReadings(limit: 1000);
      final alerts = await getFireAlerts(limit: 1000);

      return {
        'totalReadings': readings.length,
        'totalAlerts': alerts.length,
        'unacknowledgedAlerts': alerts
            .where((a) => a['acknowledged'] == false)
            .length,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {'totalReadings': 0, 'totalAlerts': 0, 'unacknowledgedAlerts': 0};
    }
  }
}
