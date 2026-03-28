# ROOT v1.0 | Smart Plant Monitor


**ROOT** is a low-power, Wi-Fi-enabled sensor node designed to monitor the health of indoor houseplants. Built on the **XIAO ESP32-C3**, it tracks soil moisture and ambient light levels, sending real-time data to a mobile dashboard via your personal cloud server.

---

## Features
* **Capacitive Sensing:** Corrosion-resistant soil moisture tracking.
* **Lux Precision:** High-accuracy light monitoring via BH1750 (GY-302).
* **Deep Sleep Optimized:** Powered by a 1000mAh LiPo battery, lasting 3–6 months per charge.
* **Mobile Dashboards:** Real-time gauges and push notifications for watering/lighting alerts.
* **Cloud Integrated:** Works with Home Assistant (ZimaOS) or Blynk IoT.

---

## Hardware Bill of Materials (BOM)

| Component | Specification | Function |
| :--- | :--- | :--- |
| **Microcontroller** | [Seeed Studio XIAO ESP32C3](https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html) | Main Brain & Wi-Fi |
| **Moisture Sensor** | Capacitive Soil Moisture v2.0 | Soil hydration levels |
| **Light Sensor** | BH1750 (GY-302) | Ambient Light (Lux) |
| **Battery** | 3.7V 1000mAh LiPo (603048) | Portable power |
| **Enclosure** | 3D Printed / IP65 Project Box | Weatherproofing |

---

## Wiring Diagram

| Sensor | Wire Color | XIAO ESP32C3 Pin |
| :--- | :--- | :--- |
| **Moisture (VCC)** | Red | 3V3 |
| **Moisture (GND)** | Black | GND |
| **Moisture (Data)** | Yellow | **A0** |
| **Light (SDA)** | - | **D4** |
| **Light (SCL)** | - | **D5** |

---

## Getting Started

### 1. Prerequisites
* Arduino IDE or VS Code with PlatformIO.
* ESP32 Board Manager installed.
* Libraries: `Blynk`, `BH1750`, `Wire`.

### 2. Configuration
Create a `secrets.h` file in the root directory (do not commit this to Git!):
```cpp
#define BLYNK_TEMPLATE_ID "YOUR_ID"
#define BLYNK_DEVICE_NAME "ROOT_01"
#define BLYNK_AUTH_TOKEN "YOUR_TOKEN"

char ssid[] = "Your_WiFi_Name";
char pass[] = "Your_Password";
```

### 3. Calibration
1.  Run the `calibration.ino` script.
2.  Note the raw analog value for "Dry Soil" and "Submerged in Water."
3.  Update the `DRY_VALUE` and `WET_VALUE` constants in the main code.

---

## Project Structure
```text
ROOT/
├── src/
│   ├── main.cpp         # Main logic & Deep Sleep loop
│   └── calibration.cpp  # Sensor calibration utility
├── include/
│   └── secrets.h.example # Template for credentials
├── docs/                # Wiring diagrams and photos
├── .gitignore           # Keeps build files & secrets private
└── README.md            # You are here!
```

---

## License
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---
