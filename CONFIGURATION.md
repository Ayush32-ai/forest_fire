# ⚙️ Configuration & Customization Guide

## 📝 How to Customize Alert Thresholds

### 1. Temperature Thresholds

Edit these values in ESP32 code:

```cpp
// Current values:
const float TEMP_HIGH = 35.0;    // Alert when above 35°C
const float TEMP_LOW = 10.0;     // Alert when below 10°C

// Example adjustments:
// For tropical regions (increase thresholds):
const float TEMP_HIGH = 40.0;    // 40°C
const float TEMP_LOW = 15.0;     // 15°C

// For cold regions (decrease thresholds):
const float TEMP_HIGH = 30.0;    // 30°C
const float TEMP_LOW = 5.0;      // 5°C
```

### 2. Humidity Thresholds

```cpp
// Current values:
const float HUMIDITY_HIGH = 80.0;  // Alert when above 80%
const float HUMIDITY_LOW = 30.0;   // Alert when below 30%

// Example adjustments:
// For dry regions:
const float HUMIDITY_HIGH = 75.0;  // 75%
const float HUMIDITY_LOW = 20.0;   // 20%

// For humid regions:
const float HUMIDITY_HIGH = 85.0;  // 85%
const float HUMIDITY_LOW = 40.0;   // 40%
```

### 3. Smoke Detection Threshold

The smoke threshold is **auto-calibrated** on startup. To adjust sensitivity:

```cpp
// In calibrateSmokeSensor() function:
// Current: threshold = cleanAirValue + 300;

// More sensitive (lower number = more false alarms):
threshold = cleanAirValue + 150;  // Very sensitive

// Less sensitive (higher number = might miss smoke):
threshold = cleanAirValue + 500;  // Less sensitive

// Recommended: 250-400 range depending on environment
```

---

## 🎨 Customize Flutter App Colors

Edit colors in `lib/main.dart`:

### Change Primary Color (App Theme)

```dart
// Find this line and change the color:
seedColor: const Color(0xFF1A472A),  // Dark green

// Other color options:
seedColor: const Color(0xFF FF6B35),   // Orange
seedColor: const Color(0xFF 004E89),   // Blue
seedColor: const Color(0xFF C41E3A),   // Red
seedColor: const Color(0xFF 2D6A4F),   // Forest Green
```

### Change Status Colors

```dart
// In _getStatusColor() method:
if (isSmokeDetected) return Colors.red;           // Smoke alert color
if (temperature > tempHighThreshold || ...) return Colors.orange;  // Caution color
return Colors.green;                             // Normal color

// You can also use custom colors:
if (isSmokeDetected) return const Color(0xFFFF0000);  // RGB Red
```

### Change AppBar Color

```dart
backgroundColor: const Color(0xFF1A472A),  // Change this value
// To light gray for example:
backgroundColor: const Color(0xFFECECEC),
```

---

## ⏱️ Adjust Update Intervals

### ESP32 Update Frequency

```cpp
// In main loop:
const unsigned long readInterval = 2000; // 2 seconds (default)

// Faster readings:
const unsigned long readInterval = 1000; // 1 second (more power usage)

// Slower readings:
const unsigned long readInterval = 5000; // 5 seconds (less power usage)
```

### Flutter UI Refresh Rate

Already optimized - updates whenever ESP32 sends new data.

---

## 🔊 Customize Alert Behavior

### Buzzer Duration

```cpp
void triggerAlert(String message) {
  digitalWrite(LED, HIGH);
  digitalWrite(BUZZER, HIGH);

  Serial.println("  --> " + message);

  // Add timed buzzer pulse:
  delay(500);           // Buzzer on for 500ms
  digitalWrite(BUZZER, LOW);
  delay(200);           // Off for 200ms
  digitalWrite(BUZZER, HIGH);
  delay(500);           // On for 500ms
  digitalWrite(BUZZER, LOW);
}
```

### Alert Cooldown

```cpp
// Prevent alert spam (wait before next alert):
const unsigned long alertCooldown = 5000; // 5 seconds

// Faster alerts (dangerous):
const unsigned long alertCooldown = 1000; // 1 second

// Less notifications (might miss events):
const unsigned long alertCooldown = 10000; // 10 seconds
```

---

## 📱 Customize Flutter UI Text

### Change Device Name

In `lib/main.dart`, find `_buildInfoItem` function:

```dart
_buildInfoItem('Device', 'ESP32 Module'),     // Change this text
_buildInfoItem('Sensor', 'DHT11'),

// Example:
_buildInfoItem('Device', 'Forest Monitor Pro'),
_buildInfoItem('Sensor', 'DHT22 - Premium'),
```

### Change Status Messages

```dart
// In _getStatusText() method:
if (isSmokeDetected) return 'FIRE ALERT';      // Change text
if (temperature > tempHighThreshold || ...) return 'CAUTION';
return 'NORMAL';

// Example:
if (isSmokeDetected) return '🔥 EMERGENCY';
if (temperature > tempHighThreshold || ...) return '⚠️ WARNING';
return '✅ SAFE';
```

---

## 🌍 Modify WiFi Connection (Advanced)

### WiFi Configuration

In WiFi version ESP32 code:

```cpp
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

// Add WiFi retry logic:
void connectToWiFi() {
  WiFi.begin(ssid, password);
  int attempts = 0;
  
  // Increase timeout from 20 to 30 attempts:
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
}
```

### Change HTTP Port

```cpp
// Default is port 80:
WebServer server(80);

// Change to different port (e.g., 8080):
WebServer server(8080);

// Then access via: http://192.168.1.XXX:8080/api/sensors
```

---

## 📊 Add Custom Data Logging

### SD Card Logging (Enhanced Version)

```cpp
#include <SD.h>

const int chipSelect = 5;

void initSDCard() {
  SD.begin(chipSelect);
}

void logToSD() {
  File dataFile = SD.open("sensor_log.csv", FILE_WRITE);
  
  if (dataFile) {
    // Write timestamp,temp,humidity,smoke
    dataFile.print(millis());
    dataFile.print(",");
    dataFile.print(temperature);
    dataFile.print(",");
    dataFile.print(humidity);
    dataFile.print(",");
    dataFile.println(smokeLevel);
    dataFile.close();
  }
}
```

---

## 🔋 Power Optimization

### Reduce Power Consumption

```cpp
// Increase sensor read interval:
const unsigned long readInterval = 5000; // From 2000ms to 5000ms

// Disable serial debug output:
const bool DEBUG = false;  // Saves power

// Put ESP32 in light sleep:
esp_light_sleep_start();

// Reduce WiFi transmit power:
WiFi.setTxPower(WIFI_POWER_8_5dBm);  // Lower power
```

---

## 🔐 Security Considerations

### Secure WiFi Password Storage (Advanced)

```cpp
// Use environment variables instead of hardcoding:
// Create secrets.h file:
#define WIFI_SSID "your_ssid"
#define WIFI_PASSWORD "your_password"

// Then in main code:
#include "secrets.h"
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;
```

### HTTPS Support (Advanced)

```cpp
// Requires certificates:
#include <WiFiClientSecure.h>

WiFiClientSecure client;
client.setCACert(ca_cert);  // Use SSL certificate
```

---

## 📈 Real-time Monitoring Enhancement

### Add Data Graphing to Flutter

```dart
// Install fl_chart package (already in pubspec.yaml)
import 'package:fl_chart/fl_chart.dart';

// Create line chart from temperature history:
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: List.generate(temperatureHistory.length,
          (index) => FlSpot(index.toDouble(), temperatureHistory[index])
        ),
        isCurved: true,
        color: Colors.red,
      ),
    ],
  ),
)
```

---

## 🎓 Example: Complete Custom Configuration

### Scenario: Forest Fire Prevention in Dry Climate

```cpp
// ESP32 Configuration
const float TEMP_HIGH = 40.0;        // Higher temp threshold
const float TEMP_LOW = 5.0;           // Lower (occasional freezing)
const float HUMIDITY_HIGH = 70.0;     // Lower humidity alert
const float HUMIDITY_LOW = 10.0;      // Very dry climates
threshold = cleanAirValue + 200;      // More smoke sensitive

const unsigned long readInterval = 1000;      // Faster updates
const unsigned long alertCooldown = 2000;     // More frequent alerts
```

### Scenario: Urban Residential Area

```cpp
// Less sensitive thresholds
const float TEMP_HIGH = 38.0;
const float TEMP_LOW = 12.0;
const float HUMIDITY_HIGH = 75.0;
const float HUMIDITY_LOW = 35.0;
threshold = cleanAirValue + 400;     // More smoke tolerant

const unsigned long readInterval = 3000;      // Slower updates
const unsigned long alertCooldown = 7000;     // Less frequent alerts
```

---

## 🧪 Testing Configuration Changes

1. **Upload new code** to ESP32
2. **Monitor Serial output** to verify changes
3. **Check readings** match expected ranges
4. **Test alerts** by introducing smoke/changing temperature
5. **Verify LED/Buzzer** respond correctly

---

## 📚 Useful Resources

- DHT Library Docs: https://learn.adafruit.com/dht
- ESP32 GPIO Reference: https://randomnerdtutorials.com/esp32-pinout-reference
- Arduino JSON: https://arduinojson.org/
- Flutter Widget Guide: https://flutter.dev/docs/development/ui/widgets

---

## ⚠️ Important Notes

- ✅ Always test changes in safe environment
- ✅ Keep backup of original configuration
- ✅ Document all custom changes made
- ✅ Test thoroughly before deployment
- ✅ Monitor system after changes for 24+ hours
