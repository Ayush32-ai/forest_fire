# 🔥 Forest Fire Monitor - Quick Start Guide

## ⚡ Quick Setup (5 Steps)

### Step 1: Upload ESP32 Code
1. Open Arduino IDE
2. Install libraries: `Adafruit DHT` + `ArduinoJson`
3. Open `ESP32_FireDetection_WiFi.ino`
4. Update WiFi credentials (lines 24-25):
   ```cpp
   const char* ssid = "YOUR_WIFI_NAME";
   const char* password = "YOUR_PASSWORD";
   ```
5. Connect ESP32 → Upload via Tools → Upload

### Step 2: Wire Your Sensors
```
MQ-2 (Smoke)     → GPIO34 (ADC)
DHT11 (Temp/Hum) → GPIO4 (Data)
LED              → GPIO2
Buzzer           → GPIO5
```

### Step 3: Find ESP32 IP
1. Serial Monitor (115200 baud)
2. Look for: `IP Address: 192.168.x.x`
3. Save this IP address

### Step 4: Install Flutter App
```bash
flutter pub get
flutter run
```

### Step 5: Test the System
- Check app displays sensor values
- LED should blink on alert
- Buzzer should sound on smoke detection

---

## 📱 App UI Overview

```
┌─────────────────────────────────┐
│  Forest Fire Monitor   [Connected]│
├─────────────────────────────────┤
│  STATUS: [NORMAL] ✅             │
│  All systems normal              │
├─────────────────────────────────┤
│  🌡️  Temperature: 28.5°C         │
│      Normal: 10°C - 35°C          │
├─────────────────────────────────┤
│  💧 Humidity: 65.0%              │
│      Normal: 30% - 80%            │
├─────────────────────────────────┤
│  💨 Smoke Level: 350/1023       │
│      Threshold: 400 [SAFE]        │
├─────────────────────────────────┤
│  Max Temp: 33.5°C | Min Temp: 25°C│
│  Device: ESP32 | Sensor: DHT11   │
└─────────────────────────────────┘
```

---

## 🎯 API Testing

### Test with cURL:
```bash
# Get sensor data
curl http://192.168.1.XXX/api/sensors

# Get device status
curl http://192.168.1.XXX/api/status

# Health check
curl http://192.168.1.XXX/health
```

### Test with Postman:
1. Create new request
2. GET `http://192.168.1.XXX/api/sensors`
3. Send

---

## 🚨 Alert Indicators

| Status | Color | LED | Buzzer | When |
|--------|-------|-----|--------|------|
| NORMAL | 🟢 Green | OFF | OFF | All good |
| CAUTION | 🟠 Orange | ON | ON | Temp/humidity alert |
| FIRE ALERT | 🔴 Red | ON | ON | Smoke detected |

---

## 🔧 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| App shows "Disconnected" | Check WiFi, verify IP address |
| No sensor readings | Check GPIO connections, verify DHT library |
| No smoke detection | Calibrate sensor in clean air, check MQ-2 power |
| API returns error | Ensure ESP32 is on same WiFi network |

---

## 📊 Serial Monitor Output Example

```
==================================================
      🔥 FOREST FIRE DETECTION SYSTEM v1.0 🔥
        ESP32 Module with WiFi Integration
==================================================

📡 SENSOR READINGS: 154.23s
  🌡️  Temperature: 28.5°C
  💧 Humidity: 65.0%
  💨 Smoke Level: 350/1023 (Threshold: 400)
  🚨 Status: 🟢 NORMAL

✅ WiFi Connected!
   IP Address: 192.168.1.100
```

---

## 📝 Important Credentials

Keep these safe:
- **WiFi SSID**: _________________
- **WiFi Password**: _________________
- **ESP32 IP Address**: 192.168.1._______
- **Device Name**: ESP32 Fire Monitor

---

## 🎓 How It Works

```
┌─────────────────────────────────────────────┐
│              SYSTEM ARCHITECTURE             │
├─────────────────────────────────────────────┤
│  Sensors (MQ-2, DHT11)                       │
│         ↓                                     │
│  ESP32 Reads & Processes                     │
│         ↓                                     │
│  Triggers Alerts (LED, Buzzer)               │
│         ↓                                     │
│  WiFi HTTP Server                            │
│         ↓                                     │
│  Flutter Mobile App                          │
│         ↓                                     │
│  User Gets Real-Time Alerts & Monitoring    │
└─────────────────────────────────────────────┘
```

---

## 📞 Contact & Support

For issues or questions:
1. Check Serial Monitor output
2. Review README_SETUP.md
3. Verify all connections
4. Test API endpoints manually

---

## ✅ Verification Checklist

- [ ] ESP32 code uploaded successfully
- [ ] WiFi connected and IP obtained
- [ ] Sensors wired correctly
- [ ] Flutter app installed on phone
- [ ] App can connect to ESP32 IP
- [ ] Real-time sensor data displaying
- [ ] LED and Buzzer respond to alerts
- [ ] All thresholds configured

**System Ready! 🎉**
