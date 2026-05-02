#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <BH1750.h>
#include <arduino_secrets.h>

const char* ssid = SSID;
const char* password = PASS;

IPAddress local_IP(192, 168, 222, 105); 
IPAddress gateway(192, 168, 222, 1);    
IPAddress subnet(255, 255, 255, 0);

const int MOISTURE_PIN = 2; 
const int BATTERY_PIN = 34; 
BH1750 lightMeter(0x23);
WebServer server(80);

unsigned long lastBeat = 0; 

void handleData() {
    lastBeat = millis(); 

    int rawMoisture = analogRead(MOISTURE_PIN);
    int moisturePercent = map(rawMoisture, 2730, 1350, 0, 100);
    moisturePercent = constrain(moisturePercent, 0, 100);

    float lux = lightMeter.readLightLevel();
    if (lux < 0) lux = 0;

    int rawBat = analogRead(BATTERY_PIN);

    float batVoltage = (rawBat / 4095.0) * 3.3 * 2; 
    
    int batPercent = map(batVoltage * 100, 320, 420, 0, 100);
    batPercent = constrain(batPercent, 0, 100);

    StaticJsonDocument<256> doc;
    doc["moisture"] = moisturePercent;
    doc["light"] = (int)lux; 
    doc["battery"] = batPercent; 
    doc["status"] = "OK";

    String response;
    serializeJson(doc, response);
    
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);

    Serial.printf("ROOT: M %d%% | L %d lx | B %d%%\n", moisturePercent, (int)lux, batPercent);
}

void setup() {
    Serial.begin(115200);
    delay(2000);
    Serial.println("\n--- SYSTEM BOOTING (Woke up from sleep or hard reset) ---");

    Wire.begin(); 
    delay(100);

    if (!WiFi.config(local_IP, gateway, subnet)) {
        Serial.println("Static IP Error");
    }
    WiFi.begin(ssid, password);

    int wifiAttempts = 0;
    while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
        delay(500);
        Serial.print(".");
        wifiAttempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi Connected.");
    } else {
        Serial.println("\nWiFi Failed. Going back to sleep to save power.");
        esp_sleep_enable_timer_wakeup(30ULL * 60 * 1000000); 
        esp_deep_sleep_start();
    }

    delay(500); 
    if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
        Serial.println("BH1750 [ONLINE]");
    } else {
        Serial.println("BH1750 [STILL ERROR] - Trying soft reset...");
        Wire.endTransmission();
        delay(100);
        lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
    }

    server.on("/data", HTTP_GET, handleData);
    server.begin();
    Serial.print("App URL: http://");
    Serial.println(WiFi.localIP());
    
    lastBeat = millis(); 
}

void loop() {
    server.handleClient();
    if (millis() - lastBeat > 15000) {
        Serial.println("App disconnected (no requests for 15s).");
        
        //database heere gua

        Serial.println("Going to Deep Sleep for 30 minutes...");
        
        esp_sleep_enable_timer_wakeup(30ULL * 60 * 1000000); 
        esp_deep_sleep_start();
    }
    
    delay(10);
}