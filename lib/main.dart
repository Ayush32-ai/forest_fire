import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/esp32_data_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/enhanced_signup_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/history_reports_screen.dart';
import 'screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service safely - don't crash app if it fails
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('⚠️ Notification init failed: $e');
  }

  runApp(const ForestFireApp());
}

class ForestFireApp extends StatefulWidget {
  const ForestFireApp({super.key});

  @override
  State<ForestFireApp> createState() => _ForestFireAppState();
}

class _ForestFireAppState extends State<ForestFireApp> {
  bool _showSignUp = false;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forest Fire Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A472A),
          brightness: Brightness.light,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: _authService.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // User is logged in
          if (snapshot.hasData && snapshot.data != null) {
            return const ForestFireMonitorScreen();
          }

          // User is not logged in
          return _showSignUp
              ? EnhancedSignupScreen(
                  onSignInPressed: () {
                    setState(() {
                      _showSignUp = false;
                    });
                  },
                )
              : LoginScreen(
                  onSignUpPressed: () {
                    setState(() {
                      _showSignUp = true;
                    });
                  },
                );
        },
      ),
    );
  }
}

// Sensor Data Model
class SensorData {
  final double temperature;
  final double humidity;
  final int smokeLevel;
  final int threshold;
  final bool smokeDetected;
  final int timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.smokeLevel,
    required this.threshold,
    required this.smokeDetected,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: _asDouble(json['temperature'] ?? json['temp']),
      humidity: _asDouble(json['humidity']),
      smokeLevel: _asInt(json['smoke'] ?? json['smokeLevel']),
      threshold: _asInt(json['threshold'], fallback: 400),
      smokeDetected: _asBool(json['smokeDetected'] ?? json['smoke_detected']),
      timestamp: _asInt(json['timestamp'] ?? json['time']),
    );
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
}

class ForestFireMonitorScreen extends StatefulWidget {
  const ForestFireMonitorScreen({super.key});

  @override
  State<ForestFireMonitorScreen> createState() =>
      _ForestFireMonitorScreenState();
}

class _ForestFireMonitorScreenState extends State<ForestFireMonitorScreen>
    with TickerProviderStateMixin {
  late Timer _updateTimer;
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  late ESP32DataService _esp32DataService;

  /// Web server root (ESP32). JSON is loaded from `<this>/data`.
  /// Use the IP your ESP32 prints (e.g. phone on same Wi‑Fi: 10.148.x.x;
  /// PC hotspot / USB tether often: 192.168.137.x).
  String deviceBaseUrl = 'http://10.148.39.165';
  bool isConnected = false;
  bool isLoading = true;
  String errorMessage = "";

  // Sensor data
  SensorData? currentData;
  List<double> temperatureHistory = [];
  List<double> humidityHistory = [];
  List<int> smokeHistory = [];

  // Alert thresholds
  final double tempHighThreshold = 35;
  final double tempLowThreshold = 10;
  final double humidityHighThreshold = 80;
  final double humidityLowThreshold = 30;

  Uri _normalizedDeviceUri() {
    var s = deviceBaseUrl.trim();
    if (s.isEmpty) s = 'http://10.148.39.165';
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    final u = Uri.parse(s);
    if (u.host.isEmpty) return Uri.parse('http://10.148.39.165');
    return u;
  }

  Uri get _sensorsApiUri => _normalizedDeviceUri().resolve('data');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _esp32DataService = ESP32DataService(deviceBaseUrl: deviceBaseUrl);
    startDataUpdates();
    showIPConfigDialog();
    // Send startup notification after a short delay
    Future.delayed(const Duration(seconds: 2), _sendStartupNotification);
  }

  Future<void> _sendStartupNotification() async {
    try {
      if (currentData == null) {
        await _notificationService.showSafeNotification();
      }
    } catch (e) {
      print('⚠️ Startup notification failed: $e');
    }
  }

  void showIPConfigDialog() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          String tempUrl = deviceBaseUrl;
          return AlertDialog(
            title: const Text('🔌 Device URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Server root only (no /data).\n'
                  'App loads: http://YOUR_IP/data\n'
                  'Hotspot/PC: try 192.168.137.45 — phone Wi‑Fi: use IP from ESP32 serial.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: tempUrl),
                  onChanged: (value) {
                    tempUrl = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'http://10.148.39.165',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    deviceBaseUrl = tempUrl;
                  });
                },
                child: const Text('Connect'),
              ),
            ],
          );
        },
      );
    });
  }

  void startDataUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        fetchSensorData();
      }
    });
    // Also trigger enhanced data fetch via ESP32DataService for Firestore storage
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        try {
          _esp32DataService.fetchEnhancedSensorData();
        } catch (e) {
          print('⚠️ ESP32 Firestore save failed: $e');
        }
      }
    });
  }

  Future<void> fetchSensorData() async {
    try {
      final url = _sensorsApiUri;

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty ||
            body.startsWith('<') ||
            body.toLowerCase().contains('<!doctype')) {
          throw FormatException(
            'Not JSON — opened HTML page. Use root URL only; app calls /data',
          );
        }
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Expected a JSON object from /data');
        }
        final data = SensorData.fromJson(decoded);

        if (mounted) {
          setState(() {
            currentData = data;
            isConnected = true;
            isLoading = false;
            errorMessage = "";

            // Add to history
            if (temperatureHistory.length >= 50) {
              temperatureHistory.removeAt(0);
            }
            temperatureHistory.add(data.temperature);

            if (humidityHistory.length >= 50) {
              humidityHistory.removeAt(0);
            }
            humidityHistory.add(data.humidity);

            if (smokeHistory.length >= 50) {
              smokeHistory.removeAt(0);
            }
            smokeHistory.add(data.smokeLevel);

            _checkAlerts(data);
          });
        }
      } else {
        throw Exception('Failed to load sensor data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          isLoading = false;
          errorMessage = 'No Data - Check WiFi Connection';
          if (e.toString().contains('timeout')) {
            errorMessage = 'Connection Timeout - ESP32 Not Responding';
          } else if (e.toString().contains('SocketException')) {
            errorMessage =
                'Cannot reach device — same Wi‑Fi? Try IP from ESP32 serial or 192.168.137.45';
          } else if (e is FormatException) {
            errorMessage = e.message;
          }
        });
      }
    }
  }

  void _checkAlerts(SensorData data) {
    // Calculate a simple risk score for notification
    double riskScore = 0;
    if (data.smokeDetected) riskScore += 50;
    if (data.temperature > tempHighThreshold) riskScore += 30;
    if (data.temperature > 45) riskScore += 20;

    // Send push notification based on risk (safely)
    try {
      _notificationService.showRiskNotification(riskScore);
    } catch (e) {
      print('⚠️ Notification failed: $e');
    }

    // Show in-app snackbar alerts
    if (data.temperature > tempHighThreshold) {
      _showAlert(
        'Temperature Alert',
        '🔥 High: ${data.temperature.toStringAsFixed(1)}°C',
        Colors.red,
      );
    }

    if (data.humidity > humidityHighThreshold) {
      _showAlert(
        'Humidity Alert',
        '💧 High: ${data.humidity.toStringAsFixed(1)}%',
        Colors.blue,
      );
    }

    if (data.smokeDetected) {
      _showAlert(
        'Fire Alert!',
        '🔴 Smoke Detected: ${data.smokeLevel}',
        Colors.red,
      );
      // Save fire alert to Firestore (safely)
      try {
        _firestoreService.saveFireAlert(
          riskScore: riskScore,
          riskLevel: riskScore >= 80
              ? 'Critical Risk'
              : riskScore >= 60
              ? 'Very High Risk'
              : riskScore >= 40
              ? 'High Risk'
              : 'Moderate Risk',
          temperature: data.temperature,
          smokeLevel: data.smokeLevel,
          deviceId: deviceBaseUrl,
        );
      } catch (e) {
        print('⚠️ Firestore alert save failed: $e');
      }
    }
  }

  void _showAlert(String title, String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (currentData == null) return Colors.grey;
    if (currentData!.smokeDetected) return Colors.red;
    if (currentData!.temperature > tempHighThreshold ||
        currentData!.temperature < tempLowThreshold) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText() {
    if (currentData == null) return 'NO DATA';
    if (currentData!.smokeDetected) return 'FIRE ALERT';
    if (currentData!.temperature > tempHighThreshold ||
        currentData!.temperature < tempLowThreshold) {
      return 'CAUTION';
    }
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A472A),
        foregroundColor: Colors.white,
        title: const Text(
          'Forest Fire Monitor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Monitor'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Center(
              child: Chip(
                label: Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: isConnected
                    ? Colors.green[700]
                    : Colors.red[700],
                avatar: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
                onTap: () async {
                  try {
                    await _authService.signOut();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out failed: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Monitor Tab - Real-time monitoring
          _buildMonitoringScreen(),
          // Analytics Tab - ML Predictions and Analytics
          currentData == null
              ? const Center(child: Text('Connect to device to view analytics'))
              : AnalyticsDashboardScreen(
                  temperature: currentData!.temperature,
                  humidity: currentData!.humidity,
                  smokeLevel: currentData!.smokeLevel,
                  temperatureHistory: temperatureHistory,
                  smokeHistory: smokeHistory,
                ),
          // History Tab - Historical data from Firestore
          const HistoryReportsScreen(),
        ],
      ),
    );
  }

  Widget _buildMonitoringScreen() {
    return RefreshIndicator(
      onRefresh: () => fetchSensorData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(),
                    _getStatusColor().withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (currentData == null)
                    Text(
                      errorMessage.isNotEmpty
                          ? '❌ $errorMessage'
                          : '⏳ Connecting to ESP32...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    )
                  else
                    Text(
                      currentData!.smokeDetected
                          ? 'Smoke detected - Alert active'
                          : currentData!.temperature > tempHighThreshold
                          ? 'High temperature detected'
                          : currentData!.temperature < tempLowThreshold
                          ? 'Low temperature detected'
                          : 'All systems normal',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Server: ${_normalizedDeviceUri()}',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Fetch: $_sensorsApiUri',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            if (currentData == null)
              // No Data Screen
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Make sure:\n'
                      '• ESP32 is connected to your WiFi hotspot\n'
                      '• Server URL is correct: $deviceBaseUrl\n'
                      '• Fetch URL: $_sensorsApiUri\n'
                      '• Both devices are on same network\n'
                      '• Pull down to refresh',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => showIPConfigDialog(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Change server URL'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: fetchSensorData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                    ),
                  ],
                ),
              )
            else
              // Data Display
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Temperature Card
                    _buildSensorCard(
                      icon: Icons.thermostat_outlined,
                      title: 'Temperature',
                      value: currentData!.temperature.toStringAsFixed(1),
                      unit: '°C',
                      color: currentData!.temperature > tempHighThreshold
                          ? Colors.red
                          : currentData!.temperature < tempLowThreshold
                          ? Colors.blue
                          : Colors.orange[700]!,
                      range: '$tempLowThreshold°C - $tempHighThreshold°C',
                    ),
                    const SizedBox(height: 16),

                    // Humidity Card
                    _buildSensorCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Humidity',
                      value: currentData!.humidity.toStringAsFixed(1),
                      unit: '%',
                      color: currentData!.humidity > humidityHighThreshold
                          ? Colors.blue
                          : currentData!.humidity < humidityLowThreshold
                          ? Colors.orange[700]!
                          : Colors.green,
                      range: '$humidityLowThreshold% - $humidityHighThreshold%',
                    ),
                    const SizedBox(height: 16),

                    // Smoke Level Card
                    _buildSmokeCard(),
                    const SizedBox(height: 16),

                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'Max Temp',
                            value: (currentData!.temperature + 5)
                                .toStringAsFixed(1),
                            unit: '°C',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Min Temp',
                            value: (currentData!.temperature - 3)
                                .toStringAsFixed(1),
                            unit: '°C',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // System Info
                    _buildInfoCard(),
                    const SizedBox(height: 16),

                    // IP Configuration Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: showIPConfigDialog,
                        icon: const Icon(Icons.router),
                        label: const Text('Change server URL'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
    required String range,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Normal: $range',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmokeCard() {
    if (currentData == null) {
      return const SizedBox.shrink();
    }

    final smokePercentage = (currentData!.smokeLevel / 1023 * 100);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: currentData!.smokeDetected
              ? Colors.red
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: currentData!.smokeDetected
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: currentData!.smokeDetected ? Colors.red : Colors.grey,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smoke Level',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentData!.smokeLevel.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: currentData!.smokeDetected
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ 1023',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentData!.smokeDetected ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentData!.smokeDetected ? 'ALERT' : 'SAFE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: smokePercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                currentData!.smokeDetected ? Colors.red : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Threshold: ${currentData!.threshold}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '${smokePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: currentData!.smokeDetected
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A472A),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (currentData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Device', 'ESP32 Module'),
              _buildInfoItem('Sensor', 'DHT11'),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Update Interval', '2s'),
              _buildInfoItem('Status', isConnected ? 'Online' : 'Offline'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A472A),
          ),
        ),
      ],
    );
  }
}
