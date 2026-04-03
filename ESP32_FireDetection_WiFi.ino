/*
  ==========================================
  FOREST FIRE DETECTION SYSTEM - ESP32
  Professional IoT Fire & Smoke Detection
  ==========================================
  
  Features:
  - Real-time temperature & humidity monitoring (DHT11/DHT22)
  - Smoke detection with MQ-2 sensor
  - WiFi connectivity for mobile app integration
  - Automatic calibration
  - Alert system (LED + Buzzer)
  - Serial monitoring + HTTP API
*/

#include "DHT.h"
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// 🔌 Pin Definitions
#define SMOKE_PIN 34      // ADC pin for MQ-2 smoke sensor
#define LED 2             // Alert LED
#define BUZZER 5          // Alert buzzer
#define DHTPIN 4          // DHT sensor data pin
#define DHTTYPE DHT11     // Change to DHT22 if using DHT22

// 📡 WiFi Configuration
const char* ssid = "YOUR_SSID";           // Change to your WiFi SSID
const char* password = "YOUR_PASSWORD";    // Change to your WiFi password
WebServer server(80);

// 🌡️ Sensor Setup
DHT dht(DHTPIN, DHTTYPE);

// 📊 Global Variables
int threshold = 0;
int smokeLevel = 0;
float humidity = 0.0;
float temperature = 0.0;
bool smokeDetected = false;
unsigned long lastReadTime = 0;
const unsigned long readInterval = 2000; // 2-second interval

// 🎯 Alert Thresholds
const float TEMP_HIGH = 35.0;
const float TEMP_LOW = 10.0;
const float HUMIDITY_HIGH = 80.0;
const float HUMIDITY_LOW = 30.0;

// 📝 Debug Flag
const bool DEBUG = true;

// ============================================
// SETUP FUNCTION
// ============================================
void setup() {
  Serial.begin(115200);
  delay(2000);

  printHeader();

  // Initialize pins
  pinMode(LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(SMOKE_PIN, INPUT);

  digitalWrite(LED, LOW);
  digitalWrite(BUZZER, LOW);

  // Initialize DHT sensor
  dht.begin();
  Serial.println("🔥 Starting Forest Fire Detection System...");

  // Warm up MQ-2 sensor
  Serial.println("\n⏳ Warming up smoke sensor (20 seconds)...");
  delay(20000);

  // Auto-calibrate smoke sensor
  calibrateSmokeSensor();

  // Connect to WiFi
  connectToWiFi();

  // Setup HTTP Server Routes
  setupServerRoutes();
  server.begin();

  Serial.println("\n✅ System initialized successfully!");
  printSystemStatus();
}

// ============================================
// MAIN LOOP
// ============================================
void loop() {
  server.handleClient();

  // Read sensors every interval
  if (millis() - lastReadTime >= readInterval) {
    lastReadTime = millis();
    readSensors();
    checkAlerts();
    displayReadings();
  }
}

// ============================================
// SENSOR READING FUNCTION
// ============================================
void readSensors() {
  // Read smoke level
  smokeLevel = analogRead(SMOKE_PIN);

  // Read temperature and humidity
  humidity = dht.readHumidity();
  temperature = dht.readTemperature();

  // Check for sensor errors
  if (isnan(humidity) || isnan(temperature)) {
    if (DEBUG) Serial.println("❌ DHT11 Sensor Error!");
    humidity = 0.0;
    temperature = 0.0;
  }

  // Check smoke detection
  smokeDetected = smokeLevel > threshold;
}

// ============================================
// ALERT CHECKING FUNCTION
// ============================================
void checkAlerts() {
  // Temperature Alert
  if (temperature > TEMP_HIGH) {
    triggerAlert("🔥 HIGH TEMPERATURE", temperature);
  } else if (temperature < TEMP_LOW && temperature > 0) {
    triggerAlert("❄️ LOW TEMPERATURE", temperature);
  }

  // Humidity Alert
  if (humidity > HUMIDITY_HIGH) {
    triggerAlert("💧 HIGH HUMIDITY", humidity);
  } else if (humidity < HUMIDITY_LOW && humidity > 0) {
    triggerAlert("🏜️ LOW HUMIDITY", humidity);
  }

  // Smoke Detection Alert
  if (smokeDetected) {
    triggerAlert("🔴 SMOKE DETECTED", smokeLevel);
  } else {
    // All clear - turn off alert devices
    digitalWrite(LED, LOW);
    digitalWrite(BUZZER, LOW);
  }
}

// ============================================
// ALERT TRIGGER FUNCTION
// ============================================
void triggerAlert(const char* alertType, float value) {
  digitalWrite(LED, HIGH);
  digitalWrite(BUZZER, HIGH);

  if (DEBUG) {
    Serial.print("🚨 ALERT: ");
    Serial.print(alertType);
    Serial.print(" - Value: ");
    Serial.println(value);
  }
}

// ============================================
// SMOKE SENSOR CALIBRATION
// ============================================
void calibrateSmokeSensor() {
  Serial.println("\n🔍 Calibrating smoke sensor in clean air...");

  long sum = 0;
  const int CALIBRATION_SAMPLES = 50;

  for (int i = 0; i < CALIBRATION_SAMPLES; i++) {
    int val = analogRead(SMOKE_PIN);
    sum += val;

    // Progress indicator
    if ((i + 1) % 10 == 0) {
      Serial.print(".");
    }

    delay(100);
  }

  int cleanAirValue = sum / CALIBRATION_SAMPLES;
  threshold = cleanAirValue + 300; // Set threshold 300 units above clean air

  Serial.println("\n✅ Calibration Complete!");
  Serial.print("📊 Clean Air Value: ");
  Serial.println(cleanAirValue);
  Serial.print("⚠️  Threshold Set To: ");
  Serial.println(threshold);
}

// ============================================
// WiFi CONNECTION
// ============================================
void connectToWiFi() {
  Serial.println("\n📡 Connecting to WiFi...");
  Serial.print("   SSID: ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("   IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi Connection Failed!");
    Serial.println("   Running in standalone mode...");
  }
}

// ============================================
// HTTP SERVER ROUTES
// ============================================
void setupServerRoutes() {
  // Main API endpoint - returns JSON sensor data
  server.on("/api/sensors", HTTP_GET, handleSensorData);

  // Status endpoint
  server.on("/api/status", HTTP_GET, handleStatus);

  // Health check
  server.on("/health", HTTP_GET, []() {
    server.send(200, "text/plain", "OK");
  });

  // Root endpoint
  server.on("/", HTTP_GET, []() {
    String html = "<html><head><title>Forest Fire Monitor</title></head>";
    html += "<body style='font-family:Arial; margin:20px;'>";
    html += "<h1>🔥 Forest Fire Detection System</h1>";
    html += "<p><strong>Temperature:</strong> " + String(temperature) + "°C</p>";
    html += "<p><strong>Humidity:</strong> " + String(humidity) + "%</p>";
    html += "<p><strong>Smoke Level:</strong> " + String(smokeLevel) + "/1023</p>";
    html += "<p><strong>Status:</strong> " + String(smokeDetected ? "🔴 ALERT" : "🟢 NORMAL") + "</p>";
    html += "</body></html>";
    server.send(200, "text/html", html);
  });
}

// ============================================
// HTTP HANDLER - SENSOR DATA
// ============================================
void handleSensorData() {
  // Create JSON response
  StaticJsonDocument<256> doc;

  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["smokeLevel"] = smokeLevel;
  doc["threshold"] = threshold;
  doc["smokeDetected"] = smokeDetected;
  doc["timestamp"] = millis();

  // Serialize JSON to string
  String response;
  serializeJson(doc, response);

  // Send response
  server.send(200, "application/json", response);
}

// ============================================
// HTTP HANDLER - STATUS
// ============================================
void handleStatus() {
  StaticJsonDocument<256> doc;

  doc["deviceName"] = "ESP32 Fire Monitor";
  doc["sensorType"] = "DHT11 + MQ-2";
  doc["firmwareVersion"] = "1.0.0";
  doc["wifiConnected"] = (WiFi.status() == WL_CONNECTED);
  doc["ipAddress"] = WiFi.localIP().toString();
  doc["uptime"] = millis();

  String response;
  serializeJson(doc, response);

  server.send(200, "application/json", response);
}

// ============================================
// DISPLAY READINGS - SERIAL OUTPUT
// ============================================
void displayReadings() {
  Serial.print("\n📡 SENSOR READINGS: ");
  Serial.print(millis() / 1000.0);
  Serial.println("s");

  Serial.print("  🌡️  Temperature: ");
  Serial.print(temperature);
  Serial.println("°C");

  Serial.print("  💧 Humidity: ");
  Serial.print(humidity);
  Serial.println("%");

  Serial.print("  💨 Smoke Level: ");
  Serial.print(smokeLevel);
  Serial.print("/1023 (Threshold: ");
  Serial.print(threshold);
  Serial.println(")");

  Serial.print("  🚨 Status: ");
  if (smokeDetected) {
    Serial.println("🔴 SMOKE DETECTED");
  } else if (temperature > TEMP_HIGH || temperature < TEMP_LOW) {
    Serial.println("🟠 CAUTION - TEMP");
  } else if (humidity > HUMIDITY_HIGH || humidity < HUMIDITY_LOW) {
    Serial.println("🟠 CAUTION - HUMIDITY");
  } else {
    Serial.println("🟢 NORMAL");
  }
}

// ============================================
// SYSTEM STATUS OUTPUT
// ============================================
void printSystemStatus() {
  Serial.println("\n" + String(50, '='));
  Serial.println("      SYSTEM STATUS");
  Serial.println(String(50, '='));

  Serial.print("WiFi: ");
  Serial.println(WiFi.status() == WL_CONNECTED ? "✅ Connected" : "❌ Disconnected");

  Serial.print("Device IP: ");
  Serial.println(WiFi.localIP());

  Serial.print("DHT Sensor: ✅ Ready");
  Serial.print("\nMQ-2 Sensor: ✅ Ready");
  Serial.print("\nLED Pin: ");
  Serial.println(LED);

  Serial.print("Buzzer Pin: ");
  Serial.println(BUZZER);

  Serial.println(String(50, '='));
}

// ============================================
// HEADER OUTPUT
// ============================================
void printHeader() {
  Serial.println("\n\n");
  Serial.println("╔═══════════════════════════════════════════════════════╗");
  Serial.println("║     🔥 FOREST FIRE DETECTION SYSTEM v1.0 🔥           ║");
  Serial.println("║        ESP32 Module with WiFi Integration             ║");
  Serial.println("╚═══════════════════════════════════════════════════════╝");
  Serial.println();
}

// ============================================
// API ENDPOINTS REFERENCE:
// ============================================
/*
 * GET /api/sensors
 *   Returns: {temperature, humidity, smokeLevel, threshold, smokeDetected, timestamp}
 *
 * GET /api/status
 *   Returns: {deviceName, sensorType, firmwareVersion, wifiConnected, ipAddress, uptime}
 *
 * GET /health
 *   Returns: OK (ping endpoint)
 *
 * GET /
 *   Returns: Simple HTML dashboard
*/

// ============================================
// INSTALLATION NOTES:
// ============================================
/*
 * 1. Install DHT library: Adafruit DHT Unified Library
 * 2. Install JSON library: ArduinoJson
 * 3. Update WiFi SSID and PASSWORD constants
 * 4. Configure pins according to your setup
 * 5. Upload to ESP32 using Arduino IDE
 * 6. Monitor Serial output at 115200 baud
*/
