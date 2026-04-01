# ROOT v1.0 | Smart Plant Monitor


**ROOT** is a low-power, Wi-Fi-enabled sensor node designed to easily monitor the health of your plants. Built on the **XIAO ESP32-C3**, it tracks soil moisture and ambient light levels, sending real-time data to a mobile dashboard via WiFi.



## Features
* **Capacitive Sensing:** Corrosion-resistant soil moisture tracking.
* **Lux Precision:** High-accuracy light monitoring via BH1750 (GY-302).
* **Deep Sleep Optimized:** Powered by a 1000mAh LiPo battery, lasting 3–6 months per charge.
* **Mobile Dashboards:** Real-time gauges and push notifications for watering/lighting alerts.


## Hardware Bill of Materials

| Component | Specification | Function |
| :--- | :--- | :--- |
| **Microcontroller** | [Seeed Studio XIAO ESP32C3](https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html) | Main Brain & Wi-Fi |
| **Moisture Sensor** | Capacitive Soil Moisture v2.0 | Soil moisture levels |
| **Light Sensor** | BH1750 (GY-302) | Light Levels (Lux) |
| **Battery** | 3.7V 1000mAh LiPo (603048) | Power |

  
## Roadmap

ROOT is still a work in progress, help us by [proposing features](https://github.com/ishtardsama/ROOT/issues/new?labels=enhancement&template=feature-request---.md) you would like to be seen implemented!

<br>

**Minimum Viable Product (v1.0)**
- [x] Hardware component selection and sourcing
- [ ] Initial sensor integration
- [ ] Basic WiFi and data transmission

**Power Optimization & QOL (v1.1)**
- [ ] Mobile dashboard
- [ ] Implement sleep logic to extend battery life
- [ ] Watering and lighting push notifications
- [ ] Voltage divider curcuit for real time battery percentage monitoring 
- [ ] Battery low push notification

**Plant Health (v1.2)**
- [ ] VPD calculation 
- [ ] Circadian rhythm monitoring
- [ ] Light to drinking ratio

**Environmental Considerations (v1.3)**
- [ ] Enclosure
- [ ] Waterproofing
- [ ] Solar pannel for charging


See the [open issues](https://github.com/ishtardsama/ROOT/issues) for a full list of proposed features (and known issues).



## Usage
Learn how to use ROOT with our [demo video! (unavailable)](https://youtube.com/)


## License
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

