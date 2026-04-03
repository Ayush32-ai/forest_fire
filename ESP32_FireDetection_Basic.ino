/*
  ==========================================
  FOREST FIRE DETECTION SYSTEM - ESP32 (BASIC)
  Standalone Smoke, Temperature & Humidity Monitor
  ==========================================
  
  Simple version without WiFi
  Use this if you prefer a standalone device
  with Serial monitoring only
*/

#include "DHT.h"

// 🔌 Pin Definitions
#define SMOKE_PIN 34      // ADC pin for MQ-2 smoke sensor
#define LED 2             // Alert LED
#define BUZZER 5          // Alert buzzer
#define DHTPIN 4          // DHT sensor data pin
#define DHTTYPE DHT11     // Change to DHT22 if needed

// 🌡️ Sensor Setup
DHT dht(DHTPIN, DHTTYPE);

// 📊 Global Variables
int threshold = 0;
int smokeLevel = 0;
float humidity = 0.0;
float temperature = 0.0;
bool smokeDetected = false;
unsigned long lastAlertTime = 0;
const unsigned long alertCooldown = 5000; // 5 second cooldown between alerts

// 🎯 Alert Thresholds
const float TEMP_HIGH = 35.0;
const float TEMP_LOW = 10.0;
const float HUMIDITY_HIGH = 80.0;
const float HUMIDITY_LOW = 30.0;

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
  Serial.println("\n🔥 Starting Forest Fire Detection System...");

  // Warm up MQ-2 sensor for 20 seconds
  Serial.println("⏳ Warming up smoke sensor (20 seconds)...");
  delay(20000);

  // 🔍 Auto Calibration in clean air
  calibrateSmokeSensor();

  Serial.println("\n✅ System initialized successfully!");
  printSystemStatus();
}

// ============================================
// MAIN LOOP
// ============================================
void loop() {
  // 🔥 Read Smoke Level
  smokeLevel = analogRead(SMOKE_PIN);

  // 💧 Read Humidity & Temperature
  humidity = dht.readHumidity();
  temperature = dht.readTemperature();

  // Display real-time data
  displayData();

  // 🚨 Check Alert Conditions
  checkAlerts();

  delay(2000); // DHT sensor requires 2-second minimum interval
}

// ============================================
// DISPLAY SENSOR DATA
// ============================================
void displayData() {
  Serial.print("\n📡 SENSOR READINGS | ");
  Serial.print("Smoke: ");
  Serial.print(smokeLevel);
  Serial.print("/1023");

  // Check for DHT errors
  if (isnan(humidity) || isnan(temperature)) {
    Serial.print(" | ❌ DHT Error!");
  } else {
    Serial.print(" | Humidity: ");
    Serial.print(humidity);
    Serial.print("%");

    Serial.print(" | Temp: ");
    Serial.print(temperature);
    Serial.print("°C");
  }

  Serial.println();
}

// ============================================
// ALERT CHECKING FUNCTION
// ============================================
void checkAlerts() {
  bool alertTriggered = false;
  String alertMessage = "";

  // 🔴 Smoke Detection Check
  if (smokeLevel > threshold) {
    alertTriggered = true;
    alertMessage = "🔴 SMOKE DETECTED";
    smokeDetected = true;
  }
  // 🔥 High Temperature Check
  else if (temperature > TEMP_HIGH && temperature > 0) {
    alertTriggered = true;
    alertMessage = "🔥 HIGH TEMPERATURE";
  }
  // ❄️ Low Temperature Check
  else if (temperature < TEMP_LOW && temperature > -50) {
    alertTriggered = true;
    alertMessage = "❄️ LOW TEMPERATURE";
  }
  // 💧 High Humidity Check
  else if (humidity > HUMIDITY_HIGH && humidity > 0) {
    alertTriggered = true;
    alertMessage = "💧 HIGH HUMIDITY";
  }
  // 🏜️ Low Humidity Check
  else if (humidity < HUMIDITY_LOW && humidity > 0) {
    alertTriggered = true;
    alertMessage = "🏜️ LOW HUMIDITY";
  }
  // ✅ All Clear
  else {
    smokeDetected = false;
    digitalWrite(LED, LOW);
    digitalWrite(BUZZER, LOW);
    Serial.println("  --> 🟢 NORMAL");
  }

  // Trigger alert if needed (with cooldown to prevent spam)
  if (alertTriggered && (millis() - lastAlertTime) > alertCooldown) {
    triggerAlert(alertMessage);
    lastAlertTime = millis();
  }
}

// ============================================
// TRIGGER ALERT - LED & BUZZER
// ============================================
void triggerAlert(String message) {
  digitalWrite(LED, HIGH);    // Turn on alert LED
  digitalWrite(BUZZER, HIGH); // Sound the buzzer

  Serial.println("  --> " + message);

  // Optional: Beep pattern (uncomment to use)
  // for (int i = 0; i < 3; i++) {
  //   digitalWrite(BUZZER, HIGH);
  //   delay(200);
  //   digitalWrite(BUZZER, LOW);
  //   delay(200);
  // }
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
  threshold = cleanAirValue + 300; // Threshold = clean air + 300 units

  Serial.println("\n✅ Calibration Complete!");
  Serial.print("📊 Clean Air Value: ");
  Serial.println(cleanAirValue);

  Serial.print("⚠️  Threshold Set To: ");
  Serial.println(threshold);
  Serial.println("   (Smoke detected when level exceeds this value)");
}

// ============================================
// PRINT SYSTEM HEADER
// ============================================
void printHeader() {
  Serial.println("\n\n");
  Serial.println("╔═══════════════════════════════════════════════════════╗");
  Serial.println("║     🔥 FOREST FIRE DETECTION SYSTEM v1.0 🔥           ║");
  Serial.println("║        ESP32 Module - STANDALONE MODE                 ║");
  Serial.println("╚═══════════════════════════════════════════════════════╝");
  Serial.println();
}

// ============================================
// PRINT SYSTEM STATUS
// ============================================
void printSystemStatus() {
  Serial.println("\n" + String(50, '='));
  Serial.println("      SYSTEM INITIALIZATION COMPLETE");
  Serial.println(String(50, '='));

  Serial.print("✅ DHT Sensor (GPIO ");
  Serial.print(DHTPIN);
  Serial.println("): Ready");

  Serial.print("✅ MQ-2 Smoke Sensor (GPIO ");
  Serial.print(SMOKE_PIN);
  Serial.println("): Ready");

  Serial.print("✅ LED Alert (GPIO ");
  Serial.print(LED);
  Serial.println("): Ready");

  Serial.print("✅ Buzzer Alert (GPIO ");
  Serial.print(BUZZER);
  Serial.println("): Ready");

  Serial.println("\n📊 SENSOR THRESHOLDS:");
  Serial.print("  🌡️  Temperature:    ");
  Serial.print(TEMP_LOW);
  Serial.print("°C - ");
  Serial.print(TEMP_HIGH);
  Serial.println("°C");

  Serial.print("  💧 Humidity:       ");
  Serial.print(HUMIDITY_LOW);
  Serial.print("% - ");
  Serial.print(HUMIDITY_HIGH);
  Serial.println("%");

  Serial.print("  💨 Smoke Threshold: ");
  Serial.println(threshold);

  Serial.println(String(50, '='));
  Serial.println("\n🚀 System Ready - Monitoring Started\n");
}

// ============================================
// ADDITIONAL FEATURES (Optional)
// ============================================

/*
  BUZZER BEEP PATTERN (uncomment in triggerAlert if needed):
  
  void buzzerBeep(int times, int duration) {
    for (int i = 0; i < times; i++) {
      digitalWrite(BUZZER, HIGH);
      delay(duration);
      digitalWrite(BUZZER, LOW);
      delay(duration);
    }
  }
*/

/*
  LED BLINK PATTERN (optional enhancement):
  
  void ledBlink(int times, int duration) {
    for (int i = 0; i < times; i++) {
      digitalWrite(LED, HIGH);
      delay(duration);
      digitalWrite(LED, LOW);
      delay(duration);
    }
  }
*/

/*
  EEPROM STORAGE (to save threshold):
  
  #include <EEPROM.h>
  
  void saveThreshold() {
    EEPROM.write(0, threshold);
    EEPROM.commit();
  }
  
  void loadThreshold() {
    threshold = EEPROM.read(0);
  }
*/

// ============================================
// SERIAL MONITOR OUTPUT INFO
// ============================================
/*
  BAUD RATE: 115200
  
  Expected Output:
  
  📡 SENSOR READINGS | Smoke: 350/1023 | Humidity: 65% | Temp: 28.5°C
  --> 🟢 NORMAL
  
  📡 SENSOR READINGS | Smoke: 450/1023 | Humidity: 75% | Temp: 32°C
  --> 🔴 SMOKE DETECTED
  
  Buzzer and LED will activate when alert is triggered.
*/

// ============================================
// TROUBLESHOOTING GUIDE
// ============================================
/*
  Problem: DHT Error showing in Serial Monitor
  Solution: 
    - Check GPIO4 connection
    - Verify sensor power supply (3.3V)
    - Replace DHT library with latest version
    - Try DHT22 instead of DHT11

  Problem: Smoke sensor reading always high
  Solution:
    - Ensure 20-second warm-up
    - Clean sensor with air blast
    - Verify GPIO34 connection
    - Calibrate in fresh air

  Problem: LED/Buzzer not responding
  Solution:
    - Check GPIO2 and GPIO5 connections
    - Verify resistor on LED circuit
    - Test with digitalWrite(LED, HIGH) in setup()
    - Check power supply to modules

  Problem: No serial output
  Solution:
    - Verify baud rate 115200
    - Check USB cable connection
    - Try different USB port
    - Select correct COM port in Arduino IDE
*/
