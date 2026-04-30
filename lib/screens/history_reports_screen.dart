import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class HistoryReportsScreen extends StatefulWidget {
  const HistoryReportsScreen({super.key});

  @override
  State<HistoryReportsScreen> createState() => _HistoryReportsScreenState();
}

class _HistoryReportsScreenState extends State<HistoryReportsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  List<Map<String, dynamic>> _sensorReadings = [];
  List<Map<String, dynamic>> _fireAlerts = [];
  bool _isLoading = true;
  int _daysRange = 7; // Default: last 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: _daysRange));

    final readings = await _firestoreService.getSensorReadingsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    final alerts = await _firestoreService.getFireAlerts(limit: 100);

    setState(() {
      _sensorReadings = readings;
      _fireAlerts = alerts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Reports'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (days) {
              setState(() => _daysRange = days);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Last 24 Hours')),
              const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 Days')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
            Tab(icon: Icon(Icons.warning), text: 'Alerts'),
            Tab(icon: Icon(Icons.list), text: 'Readings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendsTab(),
                _buildAlertsTab(),
                _buildReadingsTab(),
              ],
            ),
    );
  }

  // ==================== TRENDS TAB ====================
  Widget _buildTrendsTab() {
    if (_sensorReadings.isEmpty) {
      return const Center(child: Text('No data available for selected period'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildTemperatureChart(),
          const SizedBox(height: 24),
          _buildSmokeChart(),
          const SizedBox(height: 24),
          _buildHumidityChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final temps = _sensorReadings
        .map((r) => (r['temperature'] ?? 0.0) as double)
        .toList();
    final smoke = _sensorReadings
        .map((r) => (r['smokeLevel'] ?? 0) as int)
        .toList();

    final avgTemp = temps.isEmpty
        ? 0.0
        : temps.reduce((a, b) => a + b) / temps.length;
    final maxTemp = temps.isEmpty ? 0.0 : temps.reduce((a, b) => a > b ? a : b);
    final avgSmoke = smoke.isEmpty
        ? 0
        : smoke.reduce((a, b) => a + b) ~/ smoke.length;
    final maxSmoke = smoke.isEmpty ? 0 : smoke.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Temp',
            '${avgTemp.toStringAsFixed(1)}°C',
            'Max: ${maxTemp.toStringAsFixed(1)}°C',
            Colors.orange,
            Icons.thermostat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Smoke',
            '$avgSmoke',
            'Max: $maxSmoke',
            Colors.grey,
            Icons.cloud,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _sensorReadings.length && i < 50; i++) {
      final temp = (_sensorReadings[i]['temperature'] ?? 0.0) as double;
      spots.add(FlSpot(i.toDouble(), temp));
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temperature Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}°C',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmokeChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _sensorReadings.length && i < 50; i++) {
      final smoke = (_sensorReadings[i]['smokeLevel'] ?? 0) as int;
      spots.add(FlSpot(i.toDouble(), smoke.toDouble()));
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smoke Level Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.grey,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _sensorReadings.length && i < 50; i++) {
      final humidity = (_sensorReadings[i]['humidity'] ?? 0.0) as double;
      spots.add(FlSpot(i.toDouble(), humidity));
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Humidity Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ALERTS TAB ====================
  Widget _buildAlertsTab() {
    if (_fireAlerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No fire alerts!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('All conditions are safe'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fireAlerts.length,
      itemBuilder: (context, index) {
        final alert = _fireAlerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final riskLevel = alert['riskLevel'] ?? 'Unknown';
    final riskScore = (alert['riskScore'] ?? 0.0) as double;
    final temp = (alert['temperature'] ?? 0.0) as double;
    final smoke = (alert['smokeLevel'] ?? 0) as int;
    final acknowledged = alert['acknowledged'] ?? false;
    final createdAt = alert['createdAt'] ?? '';

    Color color = Colors.grey;
    IconData icon = Icons.info;

    if (riskLevel.contains('Moderate')) {
      color = Colors.yellow[700]!;
      icon = Icons.warning;
    } else if (riskLevel.contains('High')) {
      color = Colors.orange;
      icon = Icons.warning_amber;
    } else if (riskLevel.contains('Very High')) {
      color = Colors.deepOrange;
      icon = Icons.error;
    } else if (riskLevel.contains('Critical')) {
      color = Colors.red;
      icon = Icons.dangerous;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          riskLevel,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Risk Score: ${riskScore.toStringAsFixed(1)}%'),
            Text('Temp: ${temp.toStringAsFixed(1)}°C | Smoke: $smoke'),
            Text(
              _formatDateTime(createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: acknowledged
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  await _firestoreService.acknowledgeAlert(alert['id']);
                  _loadData();
                },
              ),
      ),
    );
  }

  // ==================== READINGS TAB ====================
  Widget _buildReadingsTab() {
    if (_sensorReadings.isEmpty) {
      return const Center(child: Text('No sensor readings available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sensorReadings.length,
      itemBuilder: (context, index) {
        final reading = _sensorReadings[index];
        return _buildReadingCard(reading);
      },
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    final temp = (reading['temperature'] ?? 0.0) as double;
    final humidity = (reading['humidity'] ?? 0.0) as double;
    final smoke = (reading['smokeLevel'] ?? 0) as int;
    final createdAt = reading['createdAt'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.sensors)),
        title: Text(_formatDateTime(createdAt)),
        subtitle: Row(
          children: [
            Icon(Icons.thermostat, size: 16, color: Colors.orange),
            Text(' ${temp.toStringAsFixed(1)}°C  '),
            Icon(Icons.water_drop, size: 16, color: Colors.blue),
            Text(' ${humidity.toStringAsFixed(1)}%  '),
            Icon(Icons.cloud, size: 16, color: Colors.grey),
            Text(' $smoke'),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
