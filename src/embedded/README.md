# The Advancement Embedded Systems

## Overview

The Advancement's embedded systems enable **physical MAGIC** through cryptographically-enabled hardware devices. These devices integrate seamlessly with the Planet Nine ecosystem using Sessionless authentication and BLE communication.

## ProS3 Wand - First Physical MAGIC Device

### Hardware

**[Unexpected Maker ProS3](https://unexpectedmaker.com/shop.html#!/ProS3-D/p/759221737)**
- **MCU**: ESP32-S3 (dual-core Xtensa LX7 @ 240MHz)
- **Flash**: 16MB
- **PSRAM**: 8MB
- **Connectivity**: WiFi 802.11 b/g/n + Bluetooth 5.0 (BLE)
- **Power**: Built-in LiPo charging, deep sleep support
- **Sensors**: Built-in RGB LED, 3.3V I/O
- **Development**: Arduino, ESP-IDF, MicroPython support

### Architecture

```
┌─────────────────────────────┐
│   ProS3 Wand (ESP32-S3)     │
│   ┌─────────────────────┐   │
│   │ Sessionless Keys    │   │  Generate/Store
│   │ (secp256k1)         │   │  in NVS Flash
│   └──────────┬──────────┘   │
│              │              │
│   ┌──────────▼──────────┐   │
│   │  BLE Server         │   │  Service UUID:
│   │  - Advertise        │   │  0xF9A0 (Planet Nine)
│   │  - Auto-connect     │   │
│   │  - Send pubKey      │   │  Characteristic UUID:
│   └──────────┬──────────┘   │  0xF9A1 (Wand PubKey)
│              │              │
└──────────────┼──────────────┘
               │ BLE Connection
               ▼
┌─────────────────────────────┐
│   macOS The Advancement     │
│   ┌─────────────────────┐   │
│   │ BLEWandManager      │   │  CoreBluetooth
│   │ (Swift)             │   │  - Scan for wands
│   └──────────┬──────────┘   │  - Auto-connect
│              │              │  - Receive pubKey
│   ┌──────────▼──────────┐   │
│   │ Julia Integration   │   │  POST /nfc/verify
│   │ - Add coordinating  │   │  (reuse NFC endpoint)
│   │   key               │   │
│   └─────────────────────┘   │
└─────────────────────────────┘
```

### Cryptographic Keys

The wand uses **Sessionless authentication** with secp256k1 elliptic curve cryptography:

- **Private Key**: 32 bytes, stored securely in ESP32-S3 NVS (Non-Volatile Storage)
- **Public Key**: 33 bytes (compressed format), transmitted over BLE
- **Key Generation**: Uses ESP32 hardware RNG for entropy
- **Key Persistence**: Keys survive power cycles, stored in encrypted NVS partition

### BLE Protocol

#### Service Definition
```
Service UUID: 0x0000F9A0-0000-1000-8000-00805F9B34FB
  - Planet Nine Wand Service

Characteristic UUIDs:
  0x0000F9A1-0000-1000-8000-00805F9B34FB (Read, Notify)
    - Wand Public Key (33 bytes, compressed secp256k1)

  0x0000F9A2-0000-1000-8000-00805F9B34FB (Write)
    - Wand Commands (for future spell casting)
```

#### Connection Flow

1. **Wand Wakeup**: ProS3 wakes from deep sleep
2. **Key Check**: Load or generate Sessionless keypair
3. **BLE Advertising**: Broadcast as "P9-Wand-XXXX" (XXXX = last 4 hex of pubKey)
4. **Auto-Connect**: Mac app scans and auto-connects to known wands
5. **PubKey Transfer**: Wand sends 33-byte compressed public key
6. **Julia Registration**: Mac app sends to Julia as coordinating key
7. **Ready**: Wand is now authenticated and ready for MAGIC

### Power Management

The ProS3 excels at low-power operation:

- **Deep Sleep**: < 10µA current draw
- **Wake Sources**:
  - Button press (GPIO interrupt)
  - Timer (periodic wakeup)
  - BLE connection request
- **Battery Life**:
  - 500mAh LiPo: ~2 months standby
  - Active use (1min/day): ~1 week

### User Input Options

The ProS3 supports multiple input methods for spell casting:

#### 1. **Buttons** (Easiest to Start)
- Built-in BOOT button (GPIO0)
- External buttons on GPIO pins
- **Use Cases**: Single-click spells, double-click for menu
- **Pros**: Simple, reliable, tactile feedback
- **Cons**: Limited expressiveness

#### 2. **IMU (Accelerometer + Gyroscope)**
- External MPU6050, LSM6DS3, or similar
- **Use Cases**: Wand gestures (swish & flick!), spell patterns
- **Pros**: Highly expressive, natural wand movements
- **Cons**: Requires calibration, gesture recognition

#### 3. **Capacitive Touch**
- ESP32-S3 has 14 capacitive touch pins
- **Use Cases**: Touch-sensitive wand grip, multi-touch spells
- **Pros**: No moving parts, elegant
- **Cons**: Requires conductive surfaces

#### 4. **Haptic Feedback**
- DRV2605L haptic driver + LRA motor
- **Use Cases**: Spell confirmation, tactile feedback
- **Pros**: Immersive experience
- **Cons**: Additional component, power consumption

#### 5. **LED Indicators**
- Built-in RGB LED (WS2812/NeoPixel on GPIO18)
- **Use Cases**: Status indication, spell effects
- **Pros**: Visual feedback, built-in to ProS3
- **Cons**: Power hungry for battery operation

### Recommended Starter Configuration

For the initial prototype, I recommend:

```
Input:
  - Built-in BOOT button (GPIO0) - Single spell cast
  - External button on GPIO1 - Mode switch

Output:
  - Built-in RGB LED - Status (connected, casting, etc.)

Future Expansion:
  - IMU on I2C (SDA=GPIO8, SCL=GPIO9) for gestures
  - Haptic feedback on GPIO10
  - Additional spell buttons on GPIO2-7
```

## Development Setup

### Arduino IDE Setup

1. **Install ESP32 Arduino Core**:
   ```
   File → Preferences → Additional Boards Manager URLs:
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```

2. **Install Board**:
   ```
   Tools → Board → Boards Manager
   Search: "esp32"
   Install: "esp32 by Espressif Systems" (2.0.14 or later)
   ```

3. **Select ProS3**:
   ```
   Tools → Board → ESP32 Arduino → ESP32S3 Dev Module
   ```

4. **Configure Settings**:
   ```
   USB CDC On Boot: Enabled
   Flash Size: 16MB (128Mb)
   Partition Scheme: Default 4MB with spiffs
   PSRAM: OPI PSRAM
   Upload Speed: 921600
   ```

### Required Libraries

Install via Arduino Library Manager:

```
- micro-ecc (for secp256k1 cryptography)
- ArduinoBLE or NimBLE-Arduino (for Bluetooth)
- Preferences (built-in for NVS storage)
```

### macOS Development

Add to The Advancement Xcode project:

```
Frameworks:
  - CoreBluetooth.framework

New Files:
  - BLEWandManager.swift (BLE scanning and connection)
  - WandCoordinator.swift (Julia integration)
```

## Security Considerations

### Key Storage

- **ESP32 NVS Encryption**: Enable NVS encryption in Arduino partition table
- **No Key Export**: Private keys never leave the device
- **Secure Boot**: Optional - can enable ESP32 secure boot for production

### BLE Security

- **Pairing**: Support BLE pairing for encrypted connections
- **MITM Protection**: Use passkey entry or numeric comparison
- **Bonding**: Save bonding info for automatic reconnection

### Julia Verification

The wand uses the **same verification flow as NFC coordinating keys**:

1. Wand generates signature over a known message
2. Mac app sends `{pubKey, signature}` to Julia `/nfc/verify`
3. Julia verifies signature and adds as coordinating key
4. Wand is now trusted for MAGIC spells

## Future Capabilities

### Spell Casting via Gestures

With IMU integration:
```cpp
// Detect "Lumos" gesture (upward flick)
if (detectGesture() == GESTURE_LUMOS) {
  castSpell("lumos", /* params */);
}
```

### Direct WiFi MAGIC

Skip Mac app, cast spells directly to Fount:
```cpp
WiFiClientSecure client;
String payload = createSpellPayload("arethaUserPurchase", params);
client.post("https://test1.fount.allyabase.com/resolve", payload);
```

### Multi-Wand Coordination

Multiple wands can coordinate through BLE Mesh:
```
Wand A + Wand B together → Unlock special spell
```

### Wand-to-Wand Communication

Transfer nineum, send messages, duel (for gaming):
```
BLE GATT Server/Client dual role
Peer-to-peer mesh network
```

## File Structure

```
embedded/
├── README.md                    # This file
├── pros3-wand/                  # ProS3 wand implementation
│   ├── pros3-wand.ino          # Main Arduino sketch
│   ├── SessionlessKeys.cpp     # secp256k1 key generation
│   ├── SessionlessKeys.h
│   ├── WandBLE.cpp             # BLE server implementation
│   ├── WandBLE.h
│   ├── SpellCaster.cpp         # Spell casting logic (future)
│   ├── SpellCaster.h
│   └── README.md               # ProS3-specific docs
└── examples/                    # Example sketches
    ├── simple-wand/            # Minimal wand with button
    ├── gesture-wand/           # IMU gesture recognition
    └── mesh-wand/              # Multi-wand coordination
```

## Getting Started

1. **Hardware**: Acquire ProS3 board, USB-C cable, optional LiPo battery
2. **Arduino**: Set up development environment (see above)
3. **Flash**: Upload `pros3-wand.ino` to ProS3
4. **macOS**: Add BLE support to The Advancement app
5. **Test**: Power on wand, watch auto-connection
6. **Cast**: Press button to cast your first spell!

---

**Welcome to physical MAGIC** - where cryptography meets hardware, and Planet Nine extends into the real world. 🪄✨
