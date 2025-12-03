#ifndef SECRETS_H
#define SECRETS_H

// --- WI-FI SECRETS ---
#define SECRET_WIFI_SSID "STUDBME2"
#define SECRET_WIFI_PASS "BME2Stud"

// --- FIREBASE SECRETS ---
#define SECRET_API_KEY "AIzaSyAHf19K5grxX58sEgzXSQq-zTZXgrpP-k4"
#define SECRET_DATABASE_URL "petsycare-10533-default-rtdb.europe-west1.firebasedatabase.app"

// --- AUTHENTICATION (New!) ---
// Create a generic user in Firebase Console -> Auth for this cage
#define SECRET_USER_EMAIL "cage001@petsy.com"
#define SECRET_USER_PASS "cage123456"

// --- ENCRYPTION KEY (AES-128) ---
// Must be exactly 16 characters. Must match Flutter's key.
#define SECRET_AES_KEY "petsycare_secret" 
#define SECRET_AES_IV  "petsycare_init_v"

#endif