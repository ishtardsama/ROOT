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
BH1750 lightMeter(0x23);
WebServer server(80);

void handleData() {
    int rawMoisture = analogRead(MOISTURE_PIN);
    int moisturePercent = map(rawMoisture, 2730, 1350, 0, 100);
    moisturePercent = constrain(moisturePercent, 0, 100);

    float lux = lightMeter.readLightLevel();
    if (lux < 0) lux = 0;

    StaticJsonDocument<256> doc;
    doc["moisture"] = moisturePercent;
    doc["light"] = (int)lux; 
    doc["status"] = "OK";

    String response;
    serializeJson(doc, response);
    
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);

    Serial.printf("ROOT: M %d%% | L %d lx\n", moisturePercent, (int)lux);
}

void setup() {
    Serial.begin(115200);
    delay(2000);
    Serial.println("\n---SYSTEM  BOOTING ---");

    Wire.begin(); 
    delay(100);

    if (!WiFi.config(local_IP, gateway, subnet)) {
        Serial.println("Static IP Error");
    }
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi Connected.");

    //dk why i keep having erroes w light sensor connection
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
}

void loop() {
    server.handleClient();
    
    static unsigned long lastBeat = 0;
    if (millis() - lastBeat > 10000) {
        Serial.println("System Active: Waiting for app response...");
        lastBeat = millis();
    }
    delay(10);
}