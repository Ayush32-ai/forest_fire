# 🧪 Testing & Troubleshooting Guide

## ✅ Pre-Deployment Testing Checklist

### Hardware Verification

- [ ] ESP32 boots successfully (USB power)
- [ ] LED lights up when GPIO2 is HIGH
- [ ] Buzzer sounds when GPIO5 is HIGH  
- [ ] DHT11 sensor connected to GPIO4
- [ ] MQ-2 sensor connected to GPIO34
- [ ] All sensors have proper power (3.3V)
- [ ] No floating wires or loose connections

### ESP32 Code Testing

- [ ] Code compiles without errors
- [ ] WiFi credentials updated
- [ ] Upload successful (Serial shows "...done")
- [ ] No COM port errors

### Sensor Calibration

- [ ] Warm-up period completes (20 seconds)
- [ ] Calibration shows reasonable baseline value
- [ ] Threshold is calculated correctly

### Serial Monitor Output

```
Expected sequence:
1. Baud rate confirms (115200)
2. System header appears
3. "Warming up smoke sensor..." message
4. Calibration progress dots appear
5. "Calibration Complete!" message
6. Sensor readings appear every 2 seconds
```

---

## 🔍 Step-by-Step Testing

### Test 1: Hardware Connectivity

1. **Upload this test code:**
   ```cpp
   void setup() {
     Serial.begin(115200);
     pinMode(2, OUTPUT);    // LED
     pinMode(5, OUTPUT);    // Buzzer
     pinMode(4, INPUT);     // DHT Data
     pinMode(34, INPUT);    // Smoke Analog
   }
   
   void loop() {
     Serial.print("LED: ");
     digitalWrite(2, HIGH);
     delay(500);
     Serial.println("ON");
     
     Serial.print("Buzzer: ");
     digitalWrite(5, HIGH);
     delay(500);
     Serial.println("ON");
     
     digitalWrite(2, LOW);
     digitalWrite(5, LOW);
     delay(1000);
   }
   ```

2. **Verify:**
   - LED blinks on/off
   - Buzzer beeps on/off
   - Serial shows messages

### Test 2: DHT Sensor

```cpp
#include "DHT.h"

#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();
}

void loop() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  if (isnan(temp) || isnan(humidity)) {
    Serial.println("DHT Error!");
  } else {
    Serial.print("Temp: ");
    Serial.print(temp);
    Serial.println("°C");
  }
  delay(2000);
}
```

**Expected Output:**
```
Temp: 25.5°C
Humidity: 60.0%
Temp: 25.6°C
Humidity: 59.8%
```

### Test 3: Smoke Sensor

```cpp
void setup() {
  Serial.begin(115200);
  pinMode(34, INPUT);
}

void loop() {
  int smoke = analogRead(34);
  Serial.print("Smoke Level: ");
  Serial.println(smoke);
  delay(1000);
}
```

**Expected Output:**
```
Clean air: 250-400 (typical)
Near smoke: 600-800
Active fire: 800-1000+
```

### Test 4: WiFi Connectivity

```cpp
#include <WiFi.h>

const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected!");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi Failed!");
  }
}

void loop() {}
```

### Test 5: API Endpoint Test

1. **Find ESP32 IP from Serial Monitor**
2. **Test in browser:**
   - `http://192.168.1.XXX/`  (should show HTML dashboard)
   - `http://192.168.1.XXX/api/sensors` (should show JSON)

3. **Test with cURL:**
   ```bash
   curl http://192.168.1.XXX/api/sensors
   ```

4. **Expected Response:**
   ```json
   {
     "temperature": 28.5,
     "humidity": 65.0,
     "smokeLevel": 350,
     "threshold": 400,
     "smokeDetected": false
   }
   ```

### Test 6: Alert System

1. **Temperature Alert:**
   - Heat sensor: Alert should trigger at > 35°C
   - Cool sensor: Alert should trigger at < 10°C

2. **Humidity Alert:**
   - Breathe on sensor: Humidity rises, alert at > 80%
   - Keep dry: Alert at < 30%

3. **Smoke Alert:**
   - Light incense near sensor
   - Smoke level should rise above threshold
   - LED and Buzzer should activate

---

## 🐛 Troubleshooting

### Issue: "DHT Error!" shows in Serial Monitor

**Possible Causes:**
- DHT11 not powered properly (check 3.3V supply)
- Data pin not connected to GPIO4
- Library not installed correctly
- DHT11 is faulty

**Solutions:**
```cpp
// 1. Check voltage - should be 3.3V:
analogRead(analogPin) // Should be around 1023

// 2. Reinstall DHT library
// Sketch > Include Library > Manage Libraries
// Search "DHT" > Install "Adafruit DHT Unified Library"

// 3. Test with explicit pins:
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// 4. Add delay before reading:
dht.begin();
delay(2000);  // Wait 2 seconds
float temp = dht.readTemperature();

// 5. Replace DHT11 if still failing
```

### Issue: App shows "Disconnected"

**Possible Causes:**
- Wrong ESP32 IP address
- WiFi network is 5GHz (ESP32 only supports 2.4GHz)
- Firewall blocking local access
- App and ESP32 on different networks

**Solutions:**
```cpp
// 1. Verify WiFi:
Serial.println(WiFi.localIP());  // Check IP in Serial Monitor

// 2. Verify network type:
// WiFi settings > Your network > Check it says "2.4GHz"

// 3. Try with static IP:
IPAddress ip(192, 168, 1, 100);
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);
WiFi.config(ip, gateway, subnet);

// 4. Add WiFi reconnection:
if (WiFi.status() != WL_CONNECTED) {
  WiFi.reconnect();
}
```

### Issue: Smoke sensor always showing high values

**Possible Causes:**
- Sensor not warmed up properly
- Calibration failed
- Sensor damaged
- analog pin not properly configured

**Solutions:**
```cpp
// 1. Increase warm-up time:
delay(30000);  // 30 seconds instead of 20

// 2. Re-calibrate in fresh air:
// Power cycle ESP32 while holding it in outdoor fresh air

// 3. Lower the sensitivity:
threshold = cleanAirValue + 500;  // Increase from 300

// 4. Test raw readings:
void readSmoke() {
  for(int i = 0; i < 10; i++) {
    Serial.println(analogRead(34));
    delay(200);
  }
}

// 5. Replace MQ-2 sensor if readings are erratic
```

### Issue: LED/Buzzer not responding

**Possible Causes:**
- GPIO pin configuration wrong
- Pin numbers incorrect
- Buzzer/LED not powered
- Current limiting resistor needed for LED

**Solutions:**
```cpp
// 1. Test GPIO directly in setup()
void setup() {
  pinMode(2, OUTPUT);
  digitalWrite(2, HIGH);
  delay(1000);
  digitalWrite(2, LOW);
}

// 2. Verify pin definitions:
#define LED 2
#define BUZZER 5
// Not GPIO2/GPIO5 which are different pins

// 3. Add current limiting resistor to LED:
// Should be 220Ω - 1kΩ resistor in series with LED

// 4. Check buzzer polarity:
// Positive pin should go to GPIO (through resistor)
// Negative pin to GND

// 5. Use digitalWrite correctly:
digitalWrite(pin, HIGH);   // Turn on
delay(500);
digitalWrite(pin, LOW);    // Turn off
```

### Issue: No Serial Output

**Possible Causes:**
- Wrong COM port selected
- Wrong baud rate (should be 115200)
- USB cable not working
- ESP32 USB chip driver not installed

**Solutions:**
```
1. Check COM port:
   - Device Manager > COM & LPT ports
   - Should show USB Serial or CH340

2. Verify baud rate:
   - Tools > Serial Monitor
   - Bottom right dropdown: 115200

3. Try different USB cable

4. Install driver:
   - CH340 driver: https://github.com/wch-ch/ch341ser
   - Or use official FTDI driver

5. Full reset:
   - Disconnect USB
   - Press ESP32 boot button 3 seconds
   - Reconnect USB
   - Reupload code
```

### Issue: WiFi Won't Connect

**Possible Causes:**
- Wrong SSID/password
- 5GHz WiFi (ESP32 needs 2.4GHz)
- WiFi security type not supported
- Too far from router

**Solutions:**
```cpp
// 1. Double-check credentials:
const char* ssid = "YOUR_SSID";      // Check for typos
const char* password = "YOUR_PASSWORD";  // Check for spaces

// 2. Scan available networks:
void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  
  int n = WiFi.scanNetworks();
  for (int i = 0; i < n; i++) {
    Serial.println(WiFi.SSID(i));
  }
}

// 3. Increase WiFi timeout:
WiFi.setAutoReconnect(true);
WiFi.persistent(true);

// 4. Add debugging:
WiFi.begin(ssid, password);
Serial.println("Connecting...");
int attempts = 0;
while (WiFi.status() != WL_CONNECTED && attempts < 20) {
  delay(500);
  Serial.print("Status: ");
  Serial.println(WiFi.status());
  attempts++;
}
```

### Issue: API Returns 404 Error

**Possible Causes:**
- Wrong URL format
- Endpoint doesn't exist
- Server crashed
- Wrong IP address

**Solutions:**
```
1. Verify URL format:
   Correct:   http://192.168.1.100/api/sensors
   Wrong:     http://192.168.1.100:80/api/sensors (port unnecessary)

2. Test basic endpoint:
   http://192.168.1.100/  (root endpoint)

3. Check API is running:
   server.on("/api/sensors", HTTP_GET, handleSensorData);
   server.begin();

4. Check for typos in endpoint paths

5. Restart ESP32 if server seems unresponsive
```

---

## 📊 Performance Monitoring

### Check Memory Usage

```cpp
void setup() {
  Serial.begin(115200);
}

void loop() {
  Serial.print("Free heap: ");
  Serial.print(ESP.getFreeHeap());
  Serial.println(" bytes");
  
  delay(5000);
}
```

**Healthy System:**
- Free heap > 100,000 bytes
- No continuous decrease (memory leak)

### Monitor Temperature

```cpp
void loop() {
  Serial.print("Internal temp: ");
  Serial.print(temperatureRead());
  Serial.println("°C");
  
  delay(5000);
}
```

---

## ✅ Final Verification Before Deployment

- [ ] All test cases pass
- [ ] Serial output is clean (no errors)
- [ ] Sensors read reasonable values
- [ ] WiFi stability for > 1 hour
- [ ] API endpoints work reliably
- [ ] Alerts trigger correctly
- [ ] App connects and shows live data
- [ ] System runs stable for 24+ hours
- [ ] No memory leaks detected
- [ ] Calibration values are consistent

---

## 📞 If All Else Fails

1. **Factory Reset ESP32:**
   - Erase flash: `esptool.py erase_flash`
   - Reupload from scratch

2. **Replace Components:**
   - Try different DHT (DHT22 if using DHT11)
   - Try different MQ-2 sensor
   - Test with breadboard instead of connections

3. **Check Power Supply:**
   - Use proper USB power adapter (not USB hub)
   - Voltage should be stable 5V

4. **Serial Debugging:**
   - Add `Serial.println()` on every state change
   - Monitor for unexpected resets
   - Check for stack overflow messages

---

**You're ready to deploy! 🚀**
