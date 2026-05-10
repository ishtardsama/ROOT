<br />
<div align="center">
    <img src="images/POLELogo.jpeg" alt="Logo" width="500" height="300">
  </a>

  <h3 align="center">ROOT</h3>

  <p align="center">
    A low-power, Wi-Fi-enabled sensor node designed to easily monitor the health of your plants.<br />
    <a href="https://github.com/ishtardsama/ROOT">View Demo</a>
    &middot;
    <a href="https://github.com/ishtardsama/ROOT/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/ishtardsama/ROOT/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

# About the project


**ROOT** is a Wi-Fi-enabled sensor node designed to easily monitor the health of your plants. Built on the **XIAO ESP32-C3**, it tracks soil moisture and ambient light levels, sending real-time data to a mobile dashboard via WiFi.

# Built with
* [![Flutter][Flutter.dev]][Flutter-url]
* [![C++][Cpp.com]][Cpp-url]
* [![Dart][Dart.dev]][Dart-url]
* [![Kotlin][Kotlin.lang]][Kotlin-url]
  
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

ROOT is still a work in progress, help me by [proposing features](https://github.com/ishtardsama/ROOT/issues/new?labels=enhancement&template=feature-request---.md) you would like to be seen implemented!

<br>

**Minimum Viable Product (v1.0)**
- [x] Hardware component selection and sourcing
- [x] Moisture sensor integration
- [x] Light sensor integration
- [x] Basic WiFi and data transmission

**Simple App Design (v1.2)**
- [x] Dashboard

**QOL (v1.2)**
- [ ] Watering and lighting push notifications
- [x] Voltage divider curcuit for real time battery percentage monitoring 
- [ ] Battery low push notification

**Plant Health (v1.3)**
- [ ] VPD calculation 
- [ ] Circadian rhythm monitoring
- [ ] Light to drinking ratio

**App Updates (v1.4)**
- [ ] Plant health stuff integration
- [ ] UI enhancements
- [ ] Data storage to see past plant analytics

**Environmental Considerations (v1.5)**
- [ ] Enclosure
- [ ] Waterproofing
- [ ] Solar pannel for charging


See the [open issues](https://github.com/ishtardsama/ROOT/issues) for a full list of proposed features (and known issues).



## Usage
Learn how to use ROOT with our [demo video! (unavailable)](https://youtube.com/)


## License
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.




[Kotlin.lang]: https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white
[Kotlin-url]: https://kotlinlang.org/
[Cpp.com]: https://img.shields.io/badge/C++-00599C?style=for-the-badge&logo=cplusplus&logoColor=white
[Cpp-url]: https://isocpp.org/
[Flutter.dev]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev/
[Dart.dev]: https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white
[Dart-url]: https://dart.dev/
[issues-url]: https://github.com/ishtardsama/ROOT/issues
