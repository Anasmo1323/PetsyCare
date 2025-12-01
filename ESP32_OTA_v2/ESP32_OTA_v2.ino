#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <DHT.h>

// --- 1. WI-FI CONFIGURATION ---
#define WIFI_SSID "STUDBME2"
#define WIFI_PASSWORD "BME2Stud"

// --- RELAY / HEATER CONFIGURATION ---
// IMPORTANT: Check your board pinout. 
// On NodeMCU: GPIO 5 is usually D1. 
#define HEATER_PIN 5 
#define RELAY_ON LOW
#define RELAY_OFF HIGH

// --- DHT SENSOR CONFIGURATION ---
// On NodeMCU: GPIO 4 is usually D2.
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// --- 2. FIREBASE CONFIGURATION ---
#define API_KEY "AIzaSyAHf19K5grxX58sEgzXSQq-zTZXgrpP-k4"
#define DATABASE_URL "petsycare-10533-default-rtdb.europe-west1.firebasedatabase.app"
#define DEVICE_ID "cage_001"

// --- OBJECTS ---
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;

// Variables to hold database values
bool autoMode = false;     
float targetTemp = 37.0;   
bool manualSwitch = false; 

void setup() {
  Serial.begin(115200);

  // Initialize Pins
  pinMode(HEATER_PIN, OUTPUT);
  digitalWrite(HEATER_PIN, RELAY_OFF); 

  // Connect Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected: ");
  Serial.println(WiFi.localIP());
  
  dht.begin();

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.timeout.serverResponse = 10 * 1000;
  config.signer.test_mode = true;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // FIXED: Added the missing "||" operator here
  if (millis() - sendDataPrevMillis > 3000 || sendDataPrevMillis == 0) { 
    sendDataPrevMillis = millis();

    // 1. Read Sensor Data
    float temperature = dht.readTemperature();
    int humidity = (int)dht.readHumidity();

    if (isnan(temperature) || isnan(humidity)) {
      Serial.println("DHT Read Failed");
      return; 
    }

    // Define Base Path
    String basePath = "/devices/" + String(DEVICE_ID);

    // 2. Upload Live Data (For Big Gauge)
    Firebase.setFloat(fbdo, basePath + "/live_data/temperature", temperature);
    Firebase.setInt(fbdo, basePath + "/live_data/humidity", humidity);
    
    // 3. Upload History Data (For the Chart) -- ADDED THIS BACK
    FirebaseJson json;
    json.set("temp", temperature);
    json.set("time", millis()); 
    Firebase.pushJSON(fbdo, basePath + "/history", json);

    // 4. READ SETTINGS (The "Brain" part)
    // FIXED: Path names now match Flutter App exactly
    
    // A. Check Mode (Auto vs Manual) -> Path: config/auto_mode
    if (Firebase.getBool(fbdo, basePath + "/config/auto_mode")) {
      autoMode = fbdo.boolData();
    }
    
    // B. Check Target Temp -> Path: config/target_temp
    if (Firebase.getFloat(fbdo, basePath + "/config/target_temp")) {
      targetTemp = fbdo.floatData();
    }

    // C. Check Manual Switch State -> Path: controls/heater
    if (Firebase.getBool(fbdo, basePath + "/controls/heater")) {
      manualSwitch = fbdo.boolData();
    }

    Serial.println("-------------------------");
    Serial.printf("Temp: %.1f C | Target: %.1f C | AutoMode: %s\n", temperature, targetTemp, autoMode ? "TRUE" : "FALSE");

    // 5. CONTROL LOGIC
    if (autoMode) {
      // --- AUTOMATIC THERMOSTAT LOGIC ---
      if (temperature < targetTemp) {
        digitalWrite(HEATER_PIN, RELAY_ON);
        Serial.println("Action: Heater ON (Too Cold)");
      } else {
        digitalWrite(HEATER_PIN, RELAY_OFF);
        Serial.println("Action: Heater OFF (Warm Enough)");
      }
    } 
    else {
      // --- MANUAL APP CONTROL LOGIC ---
      if (manualSwitch) {
        digitalWrite(HEATER_PIN, RELAY_ON);
        Serial.println("Action: Heater ON (Manual)");
      } else {
        digitalWrite(HEATER_PIN, RELAY_OFF);
        Serial.println("Action: Heater OFF (Manual)");
      }
    }
  }
}
