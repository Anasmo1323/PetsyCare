#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>

// --- 1. WI-FI CONFIGURATION (EDIT THESE) ---
#define WIFI_SSID "STUDBME2"
#define WIFI_PASSWORD "BME2Stud"
#define HEATER_PIN 5
// --- 2. FIREBASE CONFIGURATION (ALREADY FILLED FOR YOU) ---
// Your Web API Key
#define API_KEY "AIzaSyAHf19K5grxX58sEgzXSQq-zTZXgrpP-k4"

// Your Database URL (No 'https://' and no trailing '/')
#define DATABASE_URL "petsycare-10533-default-rtdb.europe-west1.firebasedatabase.app"

// The Device ID must match what you typed in the App's "Add Patient" page
#define DEVICE_ID "cage_001"

// --- OBJECTS ---
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
int count = 0;

void setup() {
  Serial.begin(115200);

  // 1. Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  pinMode(HEATER_PIN, OUTPUT);
  // 2. Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Set the database read/write timeout (optional but recommended)
  config.timeout.serverResponse = 10 * 1000;

  // Sign in anonymously (since we are in Test Mode)
  config.signer.test_mode = true;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // Check if 5 seconds have passed (Avoid spamming the database)
  if (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0) {
    sendDataPrevMillis = millis();

    // 3. Create Simulation Data
    // Generates a random temperature between 36.0 and 40.0
    float simulatedTemp = random(3600, 4000) / 10.0;
    int simulatedHum = random(40, 60);

    Serial.println("------------------------------------");
    Serial.print("Sending Temp: ");
    Serial.print(simulatedTemp);
    Serial.println(" C");

    // 4. Send to 'live_data' (For the Big Number Display)
    // Path: /devices/cage_001/live_data
    String basePath = "/devices/" + String(DEVICE_ID) + "/live_data";

    if (Firebase.setFloat(fbdo, basePath + "/temperature", simulatedTemp)) {
      Serial.println("Live Temp SENT");
    } else {
      Serial.print("Live Temp ERROR: ");
      Serial.println(fbdo.errorReason());
    }

    if (Firebase.setInt(fbdo, basePath + "/humidity", simulatedHum)) {
      // Humidity sent
    }

    // 5. Send to 'history' (For the Chart)
    // Path: /devices/cage_001/history
    String historyPath = "/devices/" + String(DEVICE_ID) + "/history";
    
    // Create a JSON object for the history entry
    FirebaseJson json;
    json.set("temp", simulatedTemp);
    json.set("time", millis()); // Using uptime as a simple timestamp
    
    // pushJSON creates a new unique ID (like "-Nxy89...") automatically
    if (Firebase.pushJSON(fbdo, historyPath, json)) {
      Serial.println("History Point SENT");
    } else {
      Serial.print("History ERROR: ");
      Serial.println(fbdo.errorReason());
    }
  }
// ... after sending temperature ...

  // --- 6. Check Heater Status (Receive from App) ---
  // Path: /devices/cage_001/controls/heater
  String controlPath = "/devices/" + String(DEVICE_ID) + "/controls/heater";

  if (Firebase.getBool(fbdo, controlPath)) {
    bool isHeaterOn = fbdo.boolData();
    
    // Turn the pin HIGH (1) or LOW (0) based on the database value
    digitalWrite(HEATER_PIN, isHeaterOn ? HIGH : LOW);
    
    Serial.print("Heater Status: ");
    Serial.println(isHeaterOn ? "ON (1)" : "OFF (0)");
  } else {
    // Only print error if it's not just "path not found" (which happens if you haven't clicked the button yet)
    Serial.print("Check heater failed: ");
    Serial.println(fbdo.errorReason());
  }

  // Wait 3 seconds before next update
  delay(3000);
}