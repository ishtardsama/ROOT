#include <Wire.h>
#include <BH1750.h>

BH1750 lightMeter(0x23); 


const int AIR_VALUE = 2730;   
const int WATER_VALUE = 1350; 

void setup() {
  Serial.begin(115200);
  
  Wire.begin(); 
  
  if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
    Serial.println(F("ROOT v1.0: Light Sensor [ONLINE]"));
  } else {
    Serial.println(F("ROOT v1.0: Light Sensor [ERROR]"));
  }
  
  Serial.println(F("---------------------------------"));
}

void loop() {
  int rawMoisture = analogRead(A0);
  int moisturePercent = map(rawMoisture, AIR_VALUE, WATER_VALUE, 0, 100);
  moisturePercent = constrain(moisturePercent, 0, 100);

  float lux = lightMeter.readLightLevel();

  Serial.print(F("SOIL: "));
  Serial.print(moisturePercent);
  Serial.print(F("% ("));
  Serial.print(rawMoisture);
  Serial.print(F(") | "));

  Serial.print(F("LIGHT: "));
  Serial.print(lux);
  Serial.println(F(" lx"));

  if (moisturePercent < 20 && lux < 500) {
    Serial.println(F(">> ALERT: Your plant needs more water and light."));
  } else if (lux < 500) {
    Serial.println(F(">> Alert: Your plant needs more light"));
  } else if (moisturePercent < 20) {
    Serial.println(F(">> Alert: Your plant needs more water"));
  } else {
    Serial.println(F(">> Alert: Your plant is fine"));
  }

  delay(2000); 
}