#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <BH1750.h>
#include "arduino_secrets.h"

const char* ssid = SSID;
const char* password = PASS;

const int MOISTURE_PIN = 2; 
BH1750 lightMeter(0x23);
WebServer server(80);

void handleData() {
    int rawMoisture = analogRead(MOISTURE_PIN);
    float lux = lightMeter.readLightLevel();
    
    int moisturePercent = map(rawMoisture, 2730, 1350, 0, 100);
    moisturePercent = constrain(moisturePercent, 0, 100);

    StaticJsonDocument<256> doc;
    doc["moisture"] = moisturePercent;
    doc["light"] = (lux < 0) ? 0 : (int)lux; 
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

    Wire.begin(); 
    lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);

    analogSetAttenuation(ADC_11db); 

    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    
    server.on("/data", HTTP_GET, handleData);
    server.begin();
    Serial.println("\n[SYSTEM] ROOT Online");
}

void loop() {
    server.handleClient();
    delay(10);
}