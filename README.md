# ROOT v1.0 | Smart Plant Monitor


**ROOT** is a low-power, Wi-Fi-enabled sensor node designed to easily monitor the health of your plants. Built on the **XIAO ESP32-C3**, it tracks soil moisture and ambient light levels, sending real-time data to a mobile dashboard via WiFi.



## Features
* **Capacitive Sensing:** Corrosion-resistant soil moisture tracking.
* **Lux Precision:** High-accuracy light monitoring via BH1750 (GY-302).
* **Deep Sleep Optimized:** Powered by a 1000mAh LiPo battery, lasting 3–6 months per charge.
* **Mobile Dashboards:** Real-time gauges and push notifications for watering/lighting alerts.
* **Accurate Plant Health:** by using VPD and circadian rhythm calculation to determine action needed.


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
- [x] Moisture sensor integration
- [ ] Light sensor integration
- [ ] Basic WiFi and data transmission

**App Development (v1.2)**
- [ ]  Dashboard

**Power Optimization & QOL (v1.2)**
- [ ] Implement sleep logic to extend battery life
- [ ] Watering and lighting push notifications
- [ ] Voltage divider curcuit for real time battery percentage monitoring 
- [ ] Battery low push notification

**Plant Health (v1.3)**
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




Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce vel ullamcorper libero. Aenean sit amet arcu ac nisl mattis pretium. Cras rutrum lorem vitae nibh pellentesque, sed hendrerit dolor posuere. Duis vitae consequat est. Maecenas tempor dictum viverra. Mauris facilisis dui imperdiet nibh molestie aliquet. Donec sit amet dui turpis. Suspendisse urna ipsum, lacinia in diam a, porta blandit erat. Nam bibendum mauris id lectus lacinia lacinia. Mauris tristique dolor sed eleifend porta.
