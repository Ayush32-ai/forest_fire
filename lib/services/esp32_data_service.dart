import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'firestore_service.dart';

/// Service to manage ESP32 data collection and preprocessing
class ESP32DataService {
  final String deviceBaseUrl;
  final FirestoreService _firestoreService = FirestoreService();

  // Data storage for ML analysis
  final List<Map<String, dynamic>> sensorReadings = [];
  final int maxReadings = 1000; // Keep last 1000 readings

  ESP32DataService({required this.deviceBaseUrl});

  /// Fetch enhanced sensor data with additional metrics
  Future<Map<String, dynamic>> fetchEnhancedSensorData() async {
    try {
      final uri = Uri.parse('$deviceBaseUrl/data');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final enhancedData = _enhanceSensorData(data);

        // Store for ML analysis
        _storeReading(enhancedData);

        return enhancedData;
      }
      return {};
    } catch (e) {
      print('Error fetching ESP32 data: $e');
      return {};
    }
  }

  /// Enhance sensor data with calculated metrics
  Map<String, dynamic> _enhanceSensorData(Map<String, dynamic> rawData) {
    final temperature = _parseDouble(
      rawData['temperature'] ?? rawData['temp'] ?? 0,
    );
    final humidity = _parseDouble(rawData['humidity'] ?? 0);
    final smokeLevel = _parseInt(
      rawData['smoke'] ?? rawData['smokeLevel'] ?? 0,
    );

    return {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'temperature': temperature,
      'humidity': humidity,
      'smokeLevel': smokeLevel,
      'threshold': _parseInt(rawData['threshold'] ?? 400),
      'smokeDetected': _parseBool(
        rawData['smokeDetected'] ?? rawData['smoke_detected'],
      ),

      // Calculated features for ML
      'heatIndex': _calculateHeatIndex(temperature, humidity),
      'dewPoint': _calculateDewPoint(temperature, humidity),
      'vaporPressureDeficit': _calculateVPD(temperature, humidity),
      'smokeIntensity': _calculateSmokeIntensity(smokeLevel),
      'dangerousRange': _isInDangerousRange(temperature, humidity, smokeLevel),
    };
  }

  /// Calculate Heat Index
  double _calculateHeatIndex(double temp, double humidity) {
    if (temp < 26.7) return temp;

    const c1 = -42.379;
    const c2 = 2.04901523;
    const c3 = 10.14333127;
    const c4 = -0.22475541;
    const c5 = -0.00683783;
    const c6 = -0.05481717;
    const c7 = 0.00122874;
    const c8 = 0.00085282;
    const c9 = -0.00000199;

    final t2 = temp * temp;
    final h2 = humidity * humidity;

    final hi =
        c1 +
        c2 * temp +
        c3 * humidity +
        c4 * temp * humidity +
        c5 * t2 +
        c6 * h2 +
        c7 * t2 * humidity +
        c8 * temp * h2 +
        c9 * t2 * h2;

    return hi;
  }

  /// Calculate Dew Point
  double _calculateDewPoint(double temp, double humidity) {
    const a = 17.27;
    const b = 237.7; // in celsius

    final alpha = ((a * temp) / (b + temp)) + log(humidity / 100);
    return (b * alpha) / (a - alpha);
  }

  /// Calculate Vapor Pressure Deficit
  double _calculateVPD(double temp, double humidity) {
    const a = 6.1078;
    const b = 17.27;
    const c = 237.7;

    final saturationVP = a * exp(b * temp / (c + temp));
    final actualVP = (humidity / 100) * saturationVP;

    return saturationVP - actualVP;
  }

  /// Calculate smoke intensity level
  String _calculateSmokeIntensity(int smokeLevel) {
    if (smokeLevel < 100) return "Very Low";
    if (smokeLevel < 200) return "Low";
    if (smokeLevel < 350) return "Moderate";
    if (smokeLevel < 500) return "High";
    return "Very High";
  }

  /// Check if readings are in dangerous range
  bool _isInDangerousRange(
    double temperature,
    double humidity,
    int smokeLevel,
  ) {
    return (temperature > 35 && humidity < 40) ||
        smokeLevel > 400 ||
        (temperature > 30 && humidity < 30);
  }

  /// Store reading for historical analysis
  void _storeReading(Map<String, dynamic> data) {
    sensorReadings.add(data);

    // Keep only latest readings
    if (sensorReadings.length > maxReadings) {
      sensorReadings.removeAt(0);
    }

    // Save to Firestore (async, don't wait)
    _saveToFirestore(data);
  }

  /// Save sensor reading to Firestore
  Future<void> _saveToFirestore(Map<String, dynamic> data) async {
    try {
      await _firestoreService.saveSensorReading(
        temperature: data['temperature'] ?? 0.0,
        humidity: data['humidity'] ?? 0.0,
        smokeLevel: data['smokeLevel'] ?? 0,
        deviceId: deviceBaseUrl,
      );
    } catch (e) {
      print('⚠️ Failed to save to Firestore: $e');
    }
  }

  /// Get statistical summary of stored readings
  Map<String, dynamic> getStatisticalSummary() {
    if (sensorReadings.isEmpty) {
      return {'count': 0, 'avgTemp': 0, 'avgHumidity': 0, 'avgSmoke': 0};
    }

    final temps = sensorReadings
        .map((r) => r['temperature'] as double)
        .toList();
    final humidities = sensorReadings
        .map((r) => r['humidity'] as double)
        .toList();
    final smokes = sensorReadings.map((r) => r['smokeLevel'] as int).toList();

    return {
      'count': sensorReadings.length,
      'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
      'minTemp': temps.reduce((a, b) => a < b ? a : b),
      'maxTemp': temps.reduce((a, b) => a > b ? a : b),
      'stdDevTemp': _calculateStdDev(temps),
      'avgHumidity': humidities.reduce((a, b) => a + b) / humidities.length,
      'minHumidity': humidities.reduce((a, b) => a < b ? a : b),
      'maxHumidity': humidities.reduce((a, b) => a > b ? a : b),
      'avgSmoke': smokes.reduce((a, b) => a + b) / smokes.length,
      'maxSmoke': smokes.reduce((a, b) => a > b ? a : b),
      'dangerousReadings': sensorReadings
          .where((r) => r['dangerousRange'] == true)
          .length,
    };
  }

  /// Detect anomalies in sensor data
  List<Map<String, dynamic>> detectAnomalies() {
    if (sensorReadings.length < 10) return [];

    final anomalies = <Map<String, dynamic>>[];
    final temps = sensorReadings
        .map((r) => r['temperature'] as double)
        .toList();

    final mean = temps.reduce((a, b) => a + b) / temps.length;
    final stdDev = _calculateStdDev(temps);

    for (int i = 0; i < sensorReadings.length; i++) {
      final reading = sensorReadings[i];
      final temp = reading['temperature'] as double;
      final zScore = (temp - mean).abs() / (stdDev > 0 ? stdDev : 1);

      // Z-score > 3 is typically considered anomalous
      if (zScore > 3) {
        anomalies.add({
          'index': i,
          'timestamp': reading['timestamp'],
          'temperature': temp,
          'zScore': zScore,
          'type': 'Temperature Spike',
        });
      }

      // Check for rapid changes
      if (i > 0) {
        final tempChange =
            (temp - (sensorReadings[i - 1]['temperature'] as double)).abs();
        if (tempChange > 5) {
          anomalies.add({
            'index': i,
            'timestamp': reading['timestamp'],
            'temperatureChange': tempChange,
            'type': 'Rapid Temperature Change',
          });
        }
      }
    }

    return anomalies;
  }

  /// Export data for external ML analysis
  String exportDataAsCSV() {
    final buffer = StringBuffer();
    buffer.writeln(
      'timestamp,temperature,humidity,smokeLevel,heatIndex,dewPoint,'
      'smokeIntensity,dangerousRange',
    );

    for (final reading in sensorReadings) {
      buffer.writeln(
        '${reading['timestamp']},${reading['temperature']},${reading['humidity']},'
        '${reading['smokeLevel']},${reading['heatIndex']},${reading['dewPoint']},'
        '${reading['smokeIntensity']},${reading['dangerousRange']}',
      );
    }

    return buffer.toString();
  }

  // Helper methods
  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value == '1' ||
          value.toLowerCase() == 'yes';
    }
    return false;
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;

    return sqrt(variance);
  }
}
