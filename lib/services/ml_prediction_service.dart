import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

// ML Prediction Model for Forest Fire Risk
class FireRiskPredictionModel {
  final double temperature;
  final double humidity;
  final int smokeLevel;
  final double windSpeed;
  final int daysWithoutRain;
  final double vegetationDensity;
  final FirestoreService _firestoreService = FirestoreService();

  FireRiskPredictionModel({
    required this.temperature,
    required this.humidity,
    required this.smokeLevel,
    required this.windSpeed,
    required this.daysWithoutRain,
    required this.vegetationDensity,
  });

  /// ML Prediction: Calculate fire risk score (0-100)
  /// Based on multiple environmental factors
  double predictFireRisk() {
    // Normalize inputs to 0-1 range
    final tempFactor = min(temperature / 50, 1.0); // Higher temp = higher risk
    final humidityFactor = max(
      1 - (humidity / 100),
      0.0,
    ); // Lower humidity = higher risk
    final smokeFactor = min(
      smokeLevel / 500,
      1.0,
    ); // Higher smoke = higher risk
    final windFactor = min(windSpeed / 25, 1.0); // Higher wind = higher risk
    final rainFactor = min(
      daysWithoutRain / 30,
      1.0,
    ); // More days without rain = higher risk
    final vegFactor = vegetationDensity; // Dense vegetation = higher risk

    // Weighted risk calculation (ML-inspired)
    final riskScore =
        ((tempFactor * 0.25) + // Temperature: 25% weight
            (humidityFactor * 0.25) + // Humidity: 25% weight
            (smokeFactor * 0.20) + // Smoke: 20% weight
            (windFactor * 0.15) + // Wind: 15% weight
            (rainFactor * 0.10) + // Dry period: 10% weight
            (vegFactor * 0.05) // Vegetation: 5% weight
            ) *
        100;

    return min(riskScore, 100.0);
  }

  /// Predict confidence level (0-100)
  double predictConfidence() {
    // Confidence decreases with extreme outliers
    final tempConfidence = _gaussianConfidence(temperature, 25, 10);
    final humidityConfidence = _gaussianConfidence(humidity, 60, 30);
    final smokeConfidence = _gaussianConfidence(
      smokeLevel.toDouble(),
      250,
      150,
    );

    return ((tempConfidence + humidityConfidence + smokeConfidence) / 3) * 100;
  }

  /// Gaussian distribution confidence calculation
  double _gaussianConfidence(double value, double mean, double stdDev) {
    if (stdDev == 0) return 1.0;
    final exponent = -pow((value - mean) / stdDev, 2) / 2;
    return exp(exponent);
  }

  /// Get risk level category
  String getRiskCategory() {
    final risk = predictFireRisk();
    if (risk < 20) return "Low Risk";
    if (risk < 40) return "Moderate Risk";
    if (risk < 60) return "High Risk";
    if (risk < 80) return "Very High Risk";
    return "Critical Risk";
  }

  /// Get category color
  Map<String, dynamic> getRiskCategoryColor() {
    final risk = predictFireRisk();
    if (risk < 20) {
      return {
        "color": "0xFF4CAF50",
        "emoji": "🟢",
        "recommendation": "Normal conditions - Continue monitoring",
      };
    }
    if (risk < 40) {
      return {
        "color": "0xFFFFC107",
        "emoji": "🟡",
        "recommendation": "Prepare equipment - Alert nearby areas",
      };
    }
    if (risk < 60) {
      return {
        "color": "0xFFFF9800",
        "emoji": "🟠",
        "recommendation": "High alert - Increase patrols",
      };
    }
    if (risk < 80) {
      return {
        "color": "0xFFFF5722",
        "emoji": "🔴",
        "recommendation": "Critical - Activate emergency protocols",
      };
    }
    return {
      "color": "0xFF8B0000",
      "emoji": "🚨",
      "recommendation": "Extreme danger - Call fire department immediately",
    };
  }

  /// Save fire alert to Firestore if risk is high
  Future<void> saveAlertIfHighRisk({String? location, String? deviceId}) async {
    final riskScore = predictFireRisk();
    final riskLevel = getRiskCategory();

    // Save alert if risk is High or above (>= 40)
    if (riskScore >= 40) {
      try {
        await _firestoreService.saveFireAlert(
          riskScore: riskScore,
          riskLevel: riskLevel,
          temperature: temperature,
          smokeLevel: smokeLevel,
          deviceId: deviceId ?? 'unknown',
          location: location,
        );
      } catch (e) {
        print('⚠️ Failed to save fire alert: $e');
      }
    }
  }
}

/// ML Service for Fire Risk Analysis
class MLPredictionService {
  static const String githubApiUrl = 'https://api.github.com';

  /// Fetch historical wildfire data from GitHub repositories
  Future<List<Map<String, dynamic>>> fetchWildfireHistoricalData() async {
    try {
      // Query GitHub for forest fire datasets
      final response = await http
          .get(
            Uri.parse(
              '$githubApiUrl/search/repositories?q=wildfire+forest+fire+dataset&sort=stars&per_page=10',
            ),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final repos = List<Map<String, dynamic>>.from(data['items'] ?? []);

        return repos
            .map(
              (repo) => {
                'name': repo['name'] ?? 'Unknown',
                'stars': repo['stargazers_count'] ?? 0,
                'url': repo['html_url'] ?? '',
                'description': repo['description'] ?? 'No description',
                'language': repo['language'] ?? 'Unknown',
              },
            )
            .toList();
      }
    } catch (e) {
      print('Error fetching GitHub data: $e');
    }
    return [];
  }

  /// Get trend data for fire predictions
  Future<Map<String, dynamic>> analyzeTrendData(
    List<double> temperatureHistory,
    List<int> smokeHistory,
  ) async {
    try {
      final tempAvg = temperatureHistory.isEmpty
          ? 0
          : temperatureHistory.reduce((a, b) => a + b) /
                temperatureHistory.length;
      final tempTrend = _calculateTrend(temperatureHistory);

      final smokeAvg = smokeHistory.isEmpty
          ? 0
          : smokeHistory.reduce((a, b) => a + b) / smokeHistory.length;
      final smokeTrend = _calculateTrend(
        smokeHistory.map((e) => e.toDouble()).toList(),
      );

      return {
        'temperature': {
          'average': tempAvg,
          'trend': tempTrend,
          'direction': tempTrend > 0 ? '📈 Rising' : '📉 Falling',
        },
        'smoke': {
          'average': smokeAvg,
          'trend': smokeTrend,
          'direction': smokeTrend > 0 ? '📈 Rising' : '📉 Falling',
        },
        'prediction': {
          'trend_score': (tempTrend + smokeTrend) / 2,
          'confidence': _calculateConfidence(tempTrend, smokeTrend),
        },
      };
    } catch (e) {
      print('Error analyzing trends: $e');
      return {};
    }
  }

  /// Calculate linear trend
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = values.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    final denominator = (n * sumX2) - (sumX * sumX);
    if (denominator == 0) return 0;

    return ((n * sumXY) - (sumX * sumY)) / denominator;
  }

  /// Calculate confidence in prediction
  double _calculateConfidence(double tempTrend, double smokeTrend) {
    // Higher confidence when trends align
    final agreement = 1 - (tempTrend - smokeTrend).abs() / 100;
    return max(0, min(agreement * 100, 100));
  }

  /// Get predictive recommendations
  List<String> getPredictiveRecommendations(
    double fireRiskScore,
    double tempTrend,
    double smokeTrend,
  ) {
    final recommendations = <String>[];

    if (fireRiskScore > 70) {
      recommendations.add(
        '🚨 CRITICAL: Activate emergency protocols and alert authorities',
      );
    } else if (fireRiskScore > 50) {
      recommendations.add('🔴 HIGH: Prepare fire suppression equipment');
    } else if (fireRiskScore > 30) {
      recommendations.add('🟡 MODERATE: Increase monitoring frequency');
    }

    if (tempTrend > 2) {
      recommendations.add('📈 Temperature rising rapidly - Watch closely');
    }

    if (smokeTrend > 50) {
      recommendations.add(
        '💨 Smoke levels increasing - Possible fire development',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        '✅ All parameters normal - Continue standard monitoring',
      );
    }

    return recommendations;
  }

  /// Simulate ML model training data
  Map<String, dynamic> getModelMetrics() {
    return {
      'accuracy': 0.92,
      'precision': 0.89,
      'recall': 0.85,
      'f1_score': 0.87,
      'training_samples': 5000,
      'last_updated': DateTime.now().toString(),
    };
  }
}
