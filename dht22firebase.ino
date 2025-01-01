#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT22.h>

// Replace with your network credentials
const char* WIFI_SSID = "Level 14";
const char* WIFI_PASSWORD = "00000000";

// Replace with your Firebase project details
#define FIREBASE_API_KEY "AIzaSyC5a0K3abajnUc1U2fKnGqa1EzKGvCkBJY"
#define FIREBASE_PROJECT_ID "projectmcsdht-d0951" // Firestore project ID

#define DHTPIN 4
#define DHTTYPE DHT22

DHT22 dht22(DHTPIN);

String getFirestoreUrl(const String& path) {
  return "https://firestore.googleapis.com/v1/projects/" + String(FIREBASE_PROJECT_ID) + "/databases/(default)/documents/" + path + "?key=" + FIREBASE_API_KEY;
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();
}

void loop() {
  float humidity = dht22.getHumidity();
  float temperature = dht22.getTemperature();

  Serial.println("Temp : " + String(temperature));
  Serial.println("Humidity : " + String(humidity));

  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }

  String documentPath = "dht/CZUN0BJvkMLp5NcKxugN";
  String url = getFirestoreUrl(documentPath);

  HTTPClient http;
  http.begin(url);

  http.addHeader("Content-Type", "application/json");

  String payload = "{\"fields\": {\"humidity\": {\"integerValue\": \"" + String((int)humidity) + "\"}, \"temp\": {\"integerValue\": \"" + String((int)temperature) + "\"}}}";

  int httpResponseCode = http.PATCH(payload);

  if (httpResponseCode > 0) {
    Serial.printf("Firestore update successful, HTTP response code: %d\n", httpResponseCode);
  } else {
    Serial.printf("Error updating Firestore, HTTP response code: %d\n", httpResponseCode);
  }

  http.end();

  delay(1); // Wait 2 seconds before sending again
}
