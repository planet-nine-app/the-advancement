# ProS3 Wand - Setup Guide

## Quick Start

### 1. Install Arduino IDE and ESP32 Support

**Add ESP32 Board Manager URL**:
```
Arduino IDE → Preferences → Additional Boards Manager URLs:
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

**Install ESP32 Board Package**:
```
Tools → Board → Boards Manager → Search "esp32" → Install "esp32 by Espressif Systems" (v2.0.14+)
```

### 2. Configure Board Settings

```
Tools → Board → ESP32 Arduino → ESP32S3 Dev Module

Configuration:
  USB CDC On Boot: Enabled
  CPU Frequency: 240MHz (WiFi)
  Core Debug Level: None
  USB DFU On Boot: Disabled
  Erase All Flash: Disabled
  Events Run On: Core 1
  Flash Mode: QIO 80MHz
  Flash Size: 16MB (128Mb)
  JTAG Adapter: Disabled
  Arduino Runs On: Core 1
  USB Firmware MSC On Boot: Disabled
  Partition Scheme: Default 4MB with spiffs (1.2MB APP/1.5MB SPIFFS)
  PSRAM: OPI PSRAM
  Upload Mode: UART0 / Hardware CDC
  Upload Speed: 921600
  USB Mode: Hardware CDC and JTAG
```

### 3. Install Required Libraries

**Via Arduino Library Manager** (`Tools → Manage Libraries`):

1. **Bitcoin** by micro-bitcoin (or **uBitcoin** by Stepan Snigirev)
   - Search: "Bitcoin" or "uBitcoin"
   - Install latest version
   - Provides secp256k1 elliptic curve cryptography (required by sessionless library)
   - **Note**: uBitcoin is recommended for ESP32 as it's optimized for embedded systems

2. **Preferences** (built-in)
   - No installation needed, part of ESP32 core

3. **BLE** (built-in)
   - No installation needed, part of ESP32 core

**Sessionless C++ Library** (included):
- The sessionless library files are already included in the sketch directory
- Files: `sessionless.cpp`, `sessionless.h`, `keccak.c`, `keccak.h`, `hash_types.h`, etc.
- These provide Planet Nine's official Sessionless authentication
- Uses ESP32 hardware RNG for cryptographically secure key generation

### 4. Upload the Sketch

1. Connect ProS3 to computer via USB-C
2. Select correct port: `Tools → Port → /dev/cu.usbmodem14201` (macOS) or `COM3` (Windows)
3. Click **Upload** button
4. Wait for compilation and upload (takes ~30 seconds)

### 5. Open Serial Monitor

```
Tools → Serial Monitor
Baud Rate: 115200
```

**Expected Output**:
```
╔════════════════════════════════════════╗
║   🪄  ProS3 Wand - Physical MAGIC  🪄  ║
║        The Advancement Embedded        ║
║     Using Sessionless C++ Library      ║
╚════════════════════════════════════════╝

🔘 Button initialized on GPIO0

🆕 No keys found, generating new keypair...

🔐 Generating new Sessionless keypair...
✅ Keypair generated successfully!
🔑 Public Key: 02a1b2c3d4e5f6...
💾 Keys saved to NVS

📡 Initializing BLE...
🪄 Wand Name: P9-Wand-A1B2C3D4
✅ BLE initialized and advertising!
📱 Waiting for Mac app connection...

✅ Wand initialization complete!
🪄 Ready to cast spells!
```

## Hardware Pinout

### Built-in Components

```
ProS3 Built-in:
  GPIO0   - BOOT Button (built-in, active LOW)
  GPIO18  - RGB LED (WS2812 NeoPixel)
  GPIO43  - UART TX
  GPIO44  - UART RX
```

### Expansion Options

```
Recommended GPIO for future expansion:
  GPIO1-7   - General purpose (buttons, sensors)
  GPIO8-9   - I2C (SDA/SCL for IMU)
  GPIO10-11 - SPI (for displays, SD cards)
  GPIO12-17 - Additional I/O (haptics, LEDs)
```

## BLE Protocol Details

### Service UUID
```
0x0000F9A0-0000-1000-8000-00805F9B34FB
```

### Characteristics

#### Public Key Characteristic (0xF9A1)
- **Properties**: Read, Notify
- **Data**: 33 bytes (compressed secp256k1 public key)
- **Format**: `0x02/0x03 + 32-byte x-coordinate`
- **Behavior**: Automatically sent on connection

#### Command Characteristic (0xF9A2)
- **Properties**: Write
- **Data**: JSON command string
- **Format**: `{"action": "cast", "spell": "lumos"}`
- **Behavior**: Mac app can send spell commands to wand

## Button Usage

**Built-in BOOT Button (GPIO0)**:
- **Single Press**: Cast spell (sends notify to Mac app)
- **Long Press**: (reserved for future features)
- **Double Press**: (reserved for future features)

## LED Status Codes

The built-in RGB LED can indicate wand status:

```
🔴 Red Blink      - Initializing
🔵 Blue Solid     - BLE advertising (waiting for connection)
🟢 Green Solid    - Connected to Mac app
🟡 Yellow Blink   - Spell casting
🟣 Purple Pulse   - Low battery
⚪ White Flash    - Error
```

*(LED code not yet implemented - future enhancement)*

## Troubleshooting

### Problem: Wand not appearing in Bluetooth devices

**Solution**:
1. Check Serial Monitor output - is BLE advertising?
2. Power cycle the ProS3 (disconnect USB, reconnect)
3. Check Mac Bluetooth is enabled
4. Try scanning with nRF Connect app to verify BLE is working

### Problem: Upload fails with "Failed to connect to ESP32"

**Solution**:
1. Hold BOOT button while clicking Upload
2. Release BOOT button when "Connecting..." appears
3. Verify correct COM port is selected
4. Try lower upload speed (115200)

### Problem: Keys regenerate on every boot

**Solution**:
1. Check NVS partition is configured correctly
2. Verify Flash Size is set to 16MB
3. Try "Erase All Flash" then re-upload

### Problem: BLE connection drops frequently

**Solution**:
1. Reduce distance between wand and Mac
2. Remove interference sources (other BLE devices)
3. Check battery level (low battery causes drops)

## Power Management

### USB Power
- **Recommended**: Development and testing
- **Current Draw**: ~80mA active, ~20mA idle

### Battery Power
- **Recommended Battery**: 500mAh - 2000mAh LiPo (JST connector)
- **Battery Life**:
  - Active BLE: ~6-24 hours (depending on battery size)
  - Deep sleep: ~2-8 months
- **Charging**: Built-in LiPo charging via USB-C

### Deep Sleep (Future Feature)
```cpp
// Enter deep sleep for 10 seconds
esp_sleep_enable_timer_wakeup(10 * 1000000); // microseconds
esp_deep_sleep_start();
```

## Next Steps

### Phase 1: Current Implementation ✅
- [x] Key generation and storage
- [x] BLE advertising and connection
- [x] Public key transmission
- [x] Button input handling

### Phase 2: Mac App Integration (In Progress)
- [ ] BLEWandManager.swift implementation
- [ ] Auto-connection to known wands
- [ ] Julia coordinating key registration
- [ ] Spell command transmission

### Phase 3: Enhanced Input
- [ ] IMU integration (gesture recognition)
- [ ] Capacitive touch sensing
- [ ] Multi-button combinations
- [ ] Haptic feedback

### Phase 4: Direct WiFi MAGIC
- [ ] Connect to WiFi
- [ ] Direct spell casting to Fount
- [ ] OTA firmware updates
- [ ] Web configuration portal

## Support

For issues, questions, or contributions:
- GitHub: [planet-nine-app/the-advancement](https://github.com/planet-nine-app/the-advancement)
- Discord: Planet Nine community server

---

**Happy spell casting!** 🪄✨
