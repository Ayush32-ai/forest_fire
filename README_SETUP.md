# 🔥 Forest Fire Detection System

A professional IoT fire and smoke detection system using ESP32 and Flutter mobile app with real-time monitoring, automated alerts, and WiFi connectivity.

## 📋 System Overview

This system consists of:

1. **Hardware**: ESP32 DevKit Module + Sensors
   - DHT11/DHT22 Temperature & Humidity Sensor
   - MQ-2 Smoke/Gas Sensor
   - LED (Alert Indicator)
   - Buzzer (Audio Alert)

2. **Software**: Flutter Mobile Application
   - Real-time sensor data display
   - Professional minimalistic UI
   - Automated alerts for dangerous conditions
   - Connection status monitoring

## 🎯 Features

✅ **Temperature Monitoring**
- Real-time temperature tracking
- High/Low temperature alerts
- Automatic threshold detection

✅ **Humidity Monitoring**
- Continuous humidity sensing
- Alert for high/low humidity
- Normal range: 30-80%

✅ **Smoke Detection**
- MQ-2 sensor-based detection
- Auto-calibration in clean air
- Rapid alert triggering

✅ **Alert System**
- Visual alerts (LED)
- Audio alerts (Buzzer)
- Mobile notifications
- Color-coded status indicators

✅ **WiFi Connectivity**
- HTTP API for data access
- JSON response format
- Real-time remote monitoring

✅ **Professional UI**
- Minimalistic design
- Color-coded status (Green/Orange/Red)
- Detailed sensor cards
- System information display

## ⚡ Hardware Setup

### Wiring Diagram (ESP32 DevKit)

```
MQ-2 Smoke Sensor:
  VCC → 5V
  GND → GND
  AO → GPIO34 (Analog Pin)

DHT11/DHT22:
  VCC → 3.3V
  GND → GND
  DATA → GPIO4

LED (Alert):
  Positive → GPIO2 (via 220Ω resistor)
  Negative → GND

Buzzer (Active):
  Positive → GPIO5
  Negative → GND
```

### Pin Definitions

| Component | Pin | Type |
|-----------|-----|------|
| MQ-2 Sensor | GPIO34 | ADC (Analog) |
| DHT Sensor | GPIO4 | Digital |
| LED | GPIO2 | Digital Output |
| Buzzer | GPIO5 | Digital Output |

## 💻 ESP32 Code Installation

### Step 1: Install Arduino IDE
Download from https://www.arduino.cc/en/software

### Step 2: Add ESP32 Board Support
1. File → Preferences
2. Add to "Additional Boards Manager URLs":
   ```
   https://dl.espressif.com/dl/package_esp32_index.json
   ```
3. Tools → Board → Boards Manager
4. Search "esp32" and install latest version

### Step 3: Install Required Libraries
1. Sketch → Include Library → Manage Libraries
2. Search and install:
   - **Adafruit DHT Unified Library**
   - **ArduinoJson** (by Benoit Blanchon)

### Step 4: Configure WiFi
Edit these lines in `ESP32_FireDetection_WiFi.ino`:

```cpp
const char* ssid = "YOUR_SSID";        // Your WiFi network name
const char* password = "YOUR_PASSWORD"; // Your WiFi password
```

### Step 5: Upload Code
1. Select Board: Tools → Board → ESP32 Dev Module
2. Select Port: Tools → Port → COM[X]
3. Sketch → Upload
4. Monitor output at 115200 baud rate

### Step 6: Find ESP32 IP Address
After upload, check Serial Monitor output:
```
IP Address: 192.168.1.XXX
```

## 📱 Flutter App Setup

### Step 1: Install Flutter
https://flutter.dev/docs/get-started/install

### Step 2: Install Dependencies
```bash
cd forest_fire
flutter pub get
```

### Step 3: Run Application

**Android:**
```bash
flutter run
```

**iOS:**
```bash
flutter run -d iPhone
```

**Web:**
```bash
flutter run -d chrome
```

## 📊 API Endpoints

The ESP32 provides RESTful API endpoints:

### Get Sensor Data
```
GET /api/sensors
```

Response:
```json
{
  "temperature": 28.5,
  "humidity": 65.0,
  "smokeLevel": 350,
  "threshold": 400,
  "smokeDetected": false,
  "timestamp": 154234000
}
```

### Get System Status
```
GET /api/status
```

Response:
```json
{
  "deviceName": "ESP32 Fire Monitor",
  "sensorType": "DHT11 + MQ-2",
  "firmwareVersion": "1.0.0",
  "wifiConnected": true,
  "ipAddress": "192.168.1.100",
  "uptime": 3600000
}
```

### Health Check
```
GET /health
```

Response: `OK`

## 🚨 Alert Thresholds

| Condition | Threshold | Action |
|-----------|-----------|--------|
| Temperature | > 35°C or < 10°C | Red Alert |
| Humidity | > 80% or < 30% | Orange Alert |
| Smoke | Level > Calibrated Threshold | Red Alert |

## 🔧 Calibration

The system auto-calibrates the smoke sensor on startup:

1. Sensor warms up for 20 seconds
2. Reads 50 samples in clean air
3. Sets threshold 300 units above clean air value

**Manual Recalibration:**
1. Reset ESP32 in clean air environment
2. Monitor Serial output for calibration messages
3. System sets new threshold automatically

## 📈 Data Logging (Optional Enhancement)

To add SD card logging:

```cpp
#include <SD.h>

void logSensorData() {
  File dataFile = SD.open("data.csv", FILE_WRITE);
  if (dataFile) {
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

## 🔌 IoT Cloud Integration

### Firebase Integration (Optional)
Add Firebase configuration to connect cloud storage:

```cpp
#include <Firebase_ESP_Client.h>

// Configure Firebase
FirebaseConfig config;
FirebaseAuth auth;
```

## 🐛 Troubleshooting

### ESP32 Not Connecting to WiFi
- Check SSID and password
- Ensure 2.4GHz WiFi (not 5GHz)
- Reset ESP32 and reconfigure

### DHT Sensor Not Reading
- Verify GPIO4 connection
- Check sensor power supply (3.3V)
- Replace sensor if faulty

### MQ-2 Giving Inconsistent Readings
- Ensure 20-second warm-up
- Check sensor calibration
- Verify GPIO34 connection
- Adjust threshold if needed

### Flutter App Connection Issues
- Check ESP32 is on same WiFi network
- Verify IP address is correct
- Ensure firewall allows local network access
- Restart both ESP32 and app

## 📚 Component Specifications

### DHT11 Sensor
- Temperature Range: 0-50°C
- Humidity Range: 0-100%
- Accuracy: ±2°C, ±5%
- Update Rate: ~1 sample/second

### MQ-2 Smoke Sensor
- Detection Range: 300-10000 ppm
- Response Time: < 10 seconds
- Operating Voltage: 5V
- Analog Output: 0-1023 (ESP32 ADC)

### ESP32 DevKit
- Processor: Dual-core 32-bit
- RAM: 520 KB
- WiFi: 802.11 b/g/n
- Operating Voltage: 3.3V

## 📄 License

Professional IoT Application - Free to use and modify

## 👨‍💻 Author

Created for Forest Fire Detection - IoT Safety System

---

## 🚀 Next Steps

1. **Test the system** in a safe environment
2. **Calibrate sensors** for your location
3. **Configure WiFi** credentials
4. **Deploy the mobile app** on your devices
5. **Monitor real-time data** through the dashboard

## ⚠️ Safety Notes

- **This system is a detection tool** - always have backup alarms
- **Regular maintenance** - test monthly
- **Professional grade monitoring** - consult fire safety experts
- **Keep away from moisture** - protect all electronics
- **Proper installation** - follow wiring diagram carefully

---

**For updates and troubleshooting:** Check logs in Serial Monitor at 115200 baud
