#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <ArduinoJson.h>
#include "arduino_secrets.h" 

const char* ssid = SSID;
const char* password = PASS;

WebServer server(80);
const int moisturePin = 2; 

void handleGetData() {
    int rawValue = analogRead(moisturePin);
    
    int moisturePercent = map(rawValue, 4095, 1500, 0, 100);
    moisturePercent = constrain(moisturePercent, 0, 100);

    StaticJsonDocument<200> doc;
    doc["sensor_id"] = "ESP32_BALCONY_01";
    doc["moisture"] = moisturePercent;
    doc["raw_adc"] = rawValue;

    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
}

void setup() {
    Serial.begin(115200);

    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println("\nWiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    if (MDNS.begin("leaf-link")) {
        Serial.println("MDNS responder started");
    }

    server.on("/data", handleGetData);
    server.begin();
    Serial.println("HTTP Server started");
}

void loop() {
    server.handleClient();
    delay(10);
}