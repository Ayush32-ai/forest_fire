import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ml_prediction_service.dart';
import 'dart:math';

class AnalyticsDashboardScreen extends StatefulWidget {
  final double temperature;
  final double humidity;
  final int smokeLevel;
  final List<double> temperatureHistory;
  final List<int> smokeHistory;

  const AnalyticsDashboardScreen({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.smokeLevel,
    required this.temperatureHistory,
    required this.smokeHistory,
  });

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final MLPredictionService _mlService;
  late AnimationController _animationController;
  late FireRiskPredictionModel _riskModel;
  Map<String, dynamic> _trendData = {};
  List<Map<String, dynamic>> _githubRepos = [];

  @override
  void initState() {
    super.initState();
    _mlService = MLPredictionService();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _riskModel = FireRiskPredictionModel(
      temperature: widget.temperature,
      humidity: widget.humidity,
      smokeLevel: widget.smokeLevel,
      windSpeed: Random().nextDouble() * 25,
      daysWithoutRain: Random().nextInt(30),
      vegetationDensity: Random().nextDouble(),
    );

    _loadData();
  }

  void _loadData() async {
    final trends = await _mlService.analyzeTrendData(
      widget.temperatureHistory,
      widget.smokeHistory,
    );
    final repos = await _mlService.fetchWildfireHistoricalData();

    setState(() {
      _trendData = trends;
      _githubRepos = repos;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riskScore = _riskModel.predictFireRisk();
    final confidence = _riskModel.predictConfidence();
    final categoryInfo = _riskModel.getRiskCategoryColor();
    final recommendations = _mlService.getPredictiveRecommendations(
      riskScore,
      _trendData['temperature']?['trend'] ?? 0,
      _trendData['smoke']?['trend'] ?? 0,
    );
    final metrics = _mlService.getModelMetrics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI/ML Analytics'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Main Risk Score Card
            _buildRiskScoreCard(riskScore, confidence, categoryInfo),
            const SizedBox(height: 24),

            // 📊 Charts Section
            _buildChartsSection(),
            const SizedBox(height: 24),

            // 📈 Trend Analysis
            _buildTrendAnalysis(),
            const SizedBox(height: 24),

            // 💡 AI Recommendations
            _buildRecommendationsCard(recommendations),
            const SizedBox(height: 24),

            // 🌍 GitHub Data Integration
            _buildGitHubDataCard(),
            const SizedBox(height: 24),

            // 🧠 ML Model Metrics
            _buildModelMetricsCard(metrics),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard(
    double riskScore,
    double confidence,
    Map<String, dynamic> categoryInfo,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(categoryInfo['color'])),
            Color(int.parse(categoryInfo['color'])).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(categoryInfo['color'])).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryInfo['emoji'],
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fire Risk Score',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${riskScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${confidence.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: riskScore / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _riskModel.getRiskCategory(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoryInfo['recommendation'],
            style: const TextStyle(color: Colors.white70, height: 1.5),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Real-Time Sensor Analytics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        // Temperature Chart
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌡️ Temperature Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 5,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 0.5,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: max(
                            1.0,
                            (widget.temperatureHistory.length ~/ 5).toDouble(),
                          ),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}°',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          widget.temperatureHistory.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            widget.temperatureHistory[index],
                          ),
                        ),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.red],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.3),
                              Colors.red.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Smoke Chart
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💨 Smoke Level Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 100,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: max(
                            1.0,
                            (widget.smokeHistory.length ~/ 5).toDouble(),
                          ),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    barGroups: List.generate(
                      widget.smokeHistory.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: widget.smokeHistory[index].toDouble(),
                            gradient: const LinearGradient(
                              colors: [Colors.grey, Colors.black45],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis() {
    if (_trendData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Trend Analysis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            '🌡️ Temperature',
            _trendData['temperature']?['average'] ?? 0,
            _trendData['temperature']?['direction'] ?? '',
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            '💨 Smoke Level',
            _trendData['smoke']?['average'] ?? 0,
            _trendData['smoke']?['direction'] ?? '',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Text(
                  '🎯 Trend Score: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${((_trendData['prediction']?['trend_score'] ?? 0) * 10).toStringAsFixed(1)}/100',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'Confidence: ${((_trendData['prediction']?['confidence'] ?? 0)).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, dynamic value, String direction) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(value is int ? value : (value as double).toStringAsFixed(1))}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                direction,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 AI Recommendations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildGitHubDataCard() {
    if (_githubRepos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.green[700]),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌍 GitHub Wildfire Datasets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ..._githubRepos
              .take(3)
              .map(
                (repo) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  repo['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '⭐ ${repo['stars']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            repo['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildModelMetricsCard(Map<String, dynamic> metrics) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧠 ML Model Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Accuracy',
            '${(metrics['accuracy'] * 100).toStringAsFixed(0)}%',
            metrics['accuracy'],
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Precision',
            '${(metrics['precision'] * 100).toStringAsFixed(0)}%',
            metrics['precision'],
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Recall',
            '${(metrics['recall'] * 100).toStringAsFixed(0)}%',
            metrics['recall'],
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'F1 Score',
            '${(metrics['f1_score'] * 100).toStringAsFixed(0)}%',
            metrics['f1_score'],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Data: ${metrics['training_samples']} samples',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last Updated: ${metrics['last_updated'].split('.').first}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }
}
