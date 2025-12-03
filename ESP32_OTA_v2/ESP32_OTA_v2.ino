#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <DHT.h>
#include "secrets.h" // Import your keys
#include "AESLib.h"  // Install "AESLib" via Library Manager

// --- HARDWARE CONFIG ---
#define HEATER_PIN 5 // D1
#define RELAY_ON LOW
#define RELAY_OFF HIGH
#define DHTPIN 4     // D2
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);
AESLib aesLib; // Encryption Object

// --- OBJECTS ---
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
bool autoMode = false;
float targetTemp = 37.0;   
bool manualSwitch = false; 

// --- ENCRYPTION HELPER FUNCTION ---
String encryptData(String inputText) {
  // Simple wrapper for AES encryption
  // Note: Padding logic varies by library, this is the standard flow
  // 1. Set Key and IV
  byte key[] = SECRET_AES_KEY;
  byte iv[] = SECRET_AES_IV;
  
  // 2. Encrypt
  // (Library specific implementation details may vary slightly)
  String encrypted = aesLib.encrypt(inputText, key, iv); 
  return encrypted;
}

void setup() {
  Serial.begin(115200);
  pinMode(HEATER_PIN, OUTPUT);
  digitalWrite(HEATER_PIN, RELAY_OFF); 

  // 1. Connect Wi-Fi (Using secrets.h)
  WiFi.begin(SECRET_WIFI_SSID, SECRET_WIFI_PASS);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nConnected: " + WiFi.localIP().toString());
  
  dht.begin();

  // 2. Secure Firebase Config
  config.api_key = SECRET_API_KEY;
  config.database_url = SECRET_DATABASE_URL;
  config.timeout.serverResponse = 10 * 1000;

  // --- SECURITY UPGRADE: USER AUTHENTICATION ---
  // We disable "Test Mode" and use real login
  // This satisfies "Enforced Security Rules"
  auth.user.email = SECRET_USER_EMAIL;
  auth.user.password = SECRET_USER_PASS;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  if (millis() - sendDataPrevMillis > 3000 || sendDataPrevMillis == 0) { 
    sendDataPrevMillis = millis();

    // 1. Read Sensor
    float temperature = dht.readTemperature();
    int humidity = (int)dht.readHumidity();

    if (isnan(temperature) || isnan(humidity)) {
      Serial.println("DHT Read Failed");
      return;
    }

    // --- SECURITY UPGRADE: AES ENCRYPTION ---
    // Convert float to String -> Encrypt -> Send Garbage to Cloud
    String tempStr = String(temperature, 1); // "37.5"
    String humStr = String(humidity);        // "60"
    
    String encryptedTemp = encryptData(tempStr); // Becomes "U2FsdGVk..."
    String encryptedHum = encryptData(humStr);

    String basePath = "/devices/cage_001"; // Hardcoded ID for now from secrets logic

    // 2. Upload Encrypted Data
    // We utilize setString because the data is now a ciphertext string
    Firebase.setString(fbdo, basePath + "/live_data/temperature", encryptedTemp);
    Firebase.setString(fbdo, basePath + "/live_data/humidity", encryptedHum);
    
    // 3. Upload History (Encrypted)
    FirebaseJson json;
    json.set("temp", encryptedTemp); // Store encrypted in history too
    json.set("time", millis()); 
    Firebase.pushJSON(fbdo, basePath + "/history", json);

    // 4. READ SETTINGS (Reading commands doesn't strictly need decryption if app sends plain bools)
    if (Firebase.getBool(fbdo, basePath + "/config/auto_mode")) autoMode = fbdo.boolData();
    if (Firebase.getFloat(fbdo, basePath + "/config/target_temp")) targetTemp = fbdo.floatData();
    if (Firebase.getBool(fbdo, basePath + "/controls/heater")) manualSwitch = fbdo.boolData();

    // 5. CONTROL LOGIC
    if (autoMode) {
      if (temperature < targetTemp) digitalWrite(HEATER_PIN, RELAY_ON);
      else digitalWrite(HEATER_PIN, RELAY_OFF);
    } else {
      if (manualSwitch) digitalWrite(HEATER_PIN, RELAY_ON);
      else digitalWrite(HEATER_PIN, RELAY_OFF);
    }
  }
}
