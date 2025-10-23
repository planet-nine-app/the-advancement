/**
 * ProS3 Wand - Physical MAGIC Device
 *
 * The Advancement's first embedded device using ESP32-S3
 *
 * Features:
 * - Sessionless authentication (secp256k1) using official sessionless C++ library
 * - BLE auto-connection to macOS The Advancement
 * - Coordinating key registration with Julia
 * - Physical spell casting via button
 *
 * Hardware: Unexpected Maker ProS3
 * Board: ESP32S3 Dev Module
 *
 * Author: Planet Nine
 * License: MIT
 */

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_NeoPixel.h>
#include "sessionless.h"

// ============================================================================
// CONFIGURATION
// ============================================================================

// BLE Service & Characteristic UUIDs (Planet Nine Wand Protocol)
#define WAND_SERVICE_UUID           "0000F9A0-0000-1000-8000-00805F9B34FB"
#define WAND_PUBKEY_CHAR_UUID       "0000F9A1-0000-1000-8000-00805F9B34FB"
#define WAND_COMMAND_CHAR_UUID      "0000F9A2-0000-1000-8000-00805F9B34FB"

// GPIO Pins
#define BUTTON_PIN         0   // Built-in BOOT button
#define RGB_LED_PIN        18  // Built-in RGB LED (WS2812)

// NVS Storage Keys
#define NVS_NAMESPACE      "wand"
#define NVS_PRIVATE_KEY    "privkey"
#define NVS_PUBLIC_KEY     "pubkey"
#define NVS_WAND_ID        "wandid"

// ============================================================================
// GLOBAL STATE
// ============================================================================

Preferences preferences;
BLEServer* pServer = nullptr;
BLECharacteristic* pPubKeyCharacteristic = nullptr;
BLECharacteristic* pCommandCharacteristic = nullptr;

Keys wandKeys;  // Sessionless Keys struct (publicKey[33], privateKey[32])

bool deviceConnected = false;
bool oldDeviceConnected = false;
String wandName;

// RGB LED
Adafruit_NeoPixel pixel(1, RGB_LED_PIN, NEO_GRB + NEO_KHZ800);

// LED Colors
#define COLOR_OFF        pixel.Color(0, 0, 0)
#define COLOR_GREEN      pixel.Color(0, 255, 0)      // Running/Ready
#define COLOR_BLUE       pixel.Color(0, 0, 255)      // Advertising
#define COLOR_CYAN       pixel.Color(0, 255, 255)    // Connected
#define COLOR_YELLOW     pixel.Color(255, 255, 0)    // Spell casting
#define COLOR_RED        pixel.Color(255, 0, 0)      // Error

// ============================================================================
// BLE SERVER CALLBACKS
// ============================================================================

class WandServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    pixel.setPixelColor(0, COLOR_CYAN);
    pixel.show();
    Serial.println("🔗 BLE Client Connected!");

    // Send public key immediately upon connection
    if (pPubKeyCharacteristic) {
      pPubKeyCharacteristic->setValue(wandKeys.publicKey, PUBLIC_KEY_SIZE_BYTES);
      pPubKeyCharacteristic->notify();
      Serial.println("📤 Sent public key to Mac app");
    }
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    pixel.setPixelColor(0, COLOR_BLUE);
    pixel.show();
    Serial.println("❌ BLE Client Disconnected");
  }
};

// ============================================================================
// BLE COMMAND CHARACTERISTIC CALLBACKS
// ============================================================================

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue();

    if (value.length() > 0) {
      Serial.print("📥 Received command: ");
      Serial.println(value);

      // Parse command (JSON format expected)
      // Future: Handle spell casting commands from Mac app
    }
  }
};

// ============================================================================
// CRYPTOGRAPHIC KEY GENERATION
// ============================================================================

/**
 * Generate new secp256k1 keypair using sessionless library
 * Uses ESP32 hardware RNG for cryptographically secure randomness
 */
void generateKeys() {
  Serial.println("\n🔐 Generating new Sessionless keypair...");

  if (sessionless::generateKeys(wandKeys)) {
    Serial.println("✅ Keypair generated successfully!");

    // Print public key for debugging
    Serial.print("🔑 Public Key: ");
    printHex(wandKeys.publicKey, PUBLIC_KEY_SIZE_BYTES);
    Serial.println();
  } else {
    Serial.println("❌ Key generation failed!");
  }
}

/**
 * Load keys from NVS, or generate new ones if not found
 */
void loadOrGenerateKeys() {
  preferences.begin(NVS_NAMESPACE, false); // Read-write mode

  size_t privKeyLen = preferences.getBytesLength(NVS_PRIVATE_KEY);

  if (privKeyLen == PRIVATE_KEY_SIZE_BYTES) {
    // Keys exist in NVS, load them
    Serial.println("📂 Loading existing keys from NVS...");

    preferences.getBytes(NVS_PRIVATE_KEY, wandKeys.privateKey, PRIVATE_KEY_SIZE_BYTES);
    preferences.getBytes(NVS_PUBLIC_KEY, wandKeys.publicKey, PUBLIC_KEY_SIZE_BYTES);

    Serial.println("✅ Keys loaded successfully!");
    Serial.print("🔑 Public Key: ");
    printHex(wandKeys.publicKey, PUBLIC_KEY_SIZE_BYTES);
    Serial.println();

  } else {
    // No keys found, generate new ones
    Serial.println("🆕 No keys found, generating new keypair...");

    generateKeys();

    // Save keys to NVS
    preferences.putBytes(NVS_PRIVATE_KEY, wandKeys.privateKey, PRIVATE_KEY_SIZE_BYTES);
    preferences.putBytes(NVS_PUBLIC_KEY, wandKeys.publicKey, PUBLIC_KEY_SIZE_BYTES);

    Serial.println("💾 Keys saved to NVS");
  }

  preferences.end();
}

// ============================================================================
// BLE INITIALIZATION
// ============================================================================

void initBLE() {
  Serial.println("\n📡 Initializing BLE...");

  // Create wand name from last 4 bytes of public key
  char wandId[9];
  snprintf(wandId, sizeof(wandId), "%02X%02X%02X%02X",
           wandKeys.publicKey[29], wandKeys.publicKey[30],
           wandKeys.publicKey[31], wandKeys.publicKey[32]);
  wandName = "P9-Wand-" + String(wandId);

  Serial.print("🪄 Wand Name: ");
  Serial.println(wandName);

  // Initialize BLE
  BLEDevice::init(wandName.c_str());

  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new WandServerCallbacks());

  // Create BLE Service
  BLEService* pService = pServer->createService(WAND_SERVICE_UUID);

  // Create Public Key Characteristic (Read + Notify)
  pPubKeyCharacteristic = pService->createCharacteristic(
    WAND_PUBKEY_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pPubKeyCharacteristic->addDescriptor(new BLE2902());
  pPubKeyCharacteristic->setValue(wandKeys.publicKey, PUBLIC_KEY_SIZE_BYTES);

  // Create Command Characteristic (Write)
  pCommandCharacteristic = pService->createCharacteristic(
    WAND_COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(WAND_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // Help with iPhone connection
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();

  Serial.println("✅ BLE initialized and advertising!");
  Serial.println("📱 Waiting for Mac app connection...");
}

// ============================================================================
// BUTTON HANDLING
// ============================================================================

volatile bool buttonPressed = false;
unsigned long lastButtonPress = 0;
const unsigned long debounceDelay = 200; // 200ms debounce

void IRAM_ATTR handleButtonPress() {
  unsigned long now = millis();
  if (now - lastButtonPress > debounceDelay) {
    buttonPressed = true;
    lastButtonPress = now;
  }
}

void setupButton() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(BUTTON_PIN), handleButtonPress, FALLING);
  Serial.println("🔘 Button initialized on GPIO0");
}

void handleButton() {
  if (buttonPressed) {
    buttonPressed = false;

    Serial.println("\n🪄 Button pressed - casting spell!");

    // Flash yellow for spell casting
    pixel.setPixelColor(0, COLOR_YELLOW);
    pixel.show();

    if (deviceConnected) {
      // Send spell cast command to Mac app
      const char* spellCmd = "{\"action\":\"cast\",\"spell\":\"lumos\"}";
      pCommandCharacteristic->setValue((uint8_t*)spellCmd, strlen(spellCmd));
      pCommandCharacteristic->notify();
      Serial.println("✨ Spell cast notification sent!");
    } else {
      Serial.println("⚠️  Not connected to Mac app");
    }

    // Return to previous state after 300ms
    delay(300);
    pixel.setPixelColor(0, deviceConnected ? COLOR_CYAN : COLOR_BLUE);
    pixel.show();
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

void printHex(const uint8_t* data, size_t len) {
  for (size_t i = 0; i < len; i++) {
    if (data[i] < 0x10) Serial.print("0");
    Serial.print(data[i], HEX);
  }
}

// ============================================================================
// ARDUINO SETUP & LOOP
// ============================================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n\n");
  Serial.println("╔════════════════════════════════════════╗");
  Serial.println("║   🪄  ProS3 Wand - Physical MAGIC  🪄  ║");
  Serial.println("║        The Advancement Embedded        ║");
  Serial.println("║     Using Sessionless C++ Library      ║");
  Serial.println("╚════════════════════════════════════════╝");
  Serial.println();

  // Initialize RGB LED
  pixel.begin();
  pixel.setBrightness(50);  // 20% brightness (easier on eyes)
  pixel.setPixelColor(0, COLOR_GREEN);
  pixel.show();
  Serial.println("💡 RGB LED initialized");

  // Initialize button
  setupButton();

  // Load or generate cryptographic keys
  loadOrGenerateKeys();

  // Initialize BLE
  initBLE();

  Serial.println("\n✅ Wand initialization complete!");
  Serial.println("🪄 Ready to cast spells!\n");

  // Set LED to blue (advertising)
  pixel.setPixelColor(0, COLOR_BLUE);
  pixel.show();
}

void loop() {
  // Handle BLE connection state changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Give BLE stack time to prepare
    pServer->startAdvertising();
    pixel.setPixelColor(0, COLOR_BLUE);
    pixel.show();
    Serial.println("📡 Restarting BLE advertising...");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Handle button press for spell casting
  handleButton();

  delay(10);
}
