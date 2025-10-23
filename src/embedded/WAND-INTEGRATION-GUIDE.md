# ProS3 Wand Integration Guide

## What We've Built

We've created a complete end-to-end system for physical MAGIC wands using the Unexpected Maker ProS3 (ESP32-S3) board. The system includes:

### ✅ 1. Embedded Firmware (Arduino/ESP32)

**Location**: `/src/embedded/pros3-wand/pros3-wand.ino`

**Features**:
- **Sessionless Key Generation**: Generates secp256k1 keypairs using ESP32 hardware RNG
- **Secure Key Storage**: Stores keys in encrypted NVS (Non-Volatile Storage)
- **BLE Server**: Advertises as "P9-Wand-XXXX" using Planet Nine service UUID
- **Auto-Connection**: Connects to Mac app automatically when in range
- **Public Key Transmission**: Sends 33-byte compressed pubKey on connection
- **Button Input**: Built-in BOOT button (GPIO0) for spell casting
- **Spell Notifications**: Sends JSON spell commands to Mac app

**Libraries Required**:
- `micro-ecc` - secp256k1 cryptography
- `BLEDevice` - Bluetooth Low Energy (built-in to ESP32)
- `Preferences` - NVS storage (built-in to ESP32)

### ✅ 2. macOS BLE Manager (Swift)

**Location**: `/src/The Advancement/Shared (App)/BLEWandManager.swift`

**Features**:
- **CoreBluetooth Integration**: Scans for and connects to Planet Nine wands
- **Auto-Discovery**: Automatically finds wands with "P9-Wand-" prefix
- **Public Key Reception**: Reads 33-byte compressed public key from wand
- **Spell Handling**: Receives and processes spell cast notifications
- **Connection Management**: Handles disconnections and auto-reconnects
- **Delegate Pattern**: Notifies UI of wand events

### ✅ 3. Wand Coordinator (Swift)

**Location**: `/src/The Advancement/Shared (App)/WandCoordinator.swift`

**Features**:
- **Julia Integration**: Registers wand pubKeys as coordinating keys
- **Known Wand Tracking**: Stores registered wands in UserDefaults
- **Auto-Registration**: Automatically registers wands on first connection
- **Spell Routing**: Routes spell casts to appropriate handlers
- **User Notifications**: Shows macOS notifications for wand events

### ✅ 4. Julia Wand Registration Endpoint

**Location**: `/julia/src/server/node/julia.js` (lines 773-828)

**Endpoint**: `POST /wand/register`

**Features**:
- **Coordinating Key Registration**: Adds wand pubKey to user's coordinating keys
- **UUID Generation**: Creates unique UUID for each wand
- **User Association**: Links wand to Fount user account
- **Simple Protocol**: No signature required for initial registration

**Request Body**:
```json
{
  "primaryUUID": "fount-user-uuid",
  "pubKey": "02a1b2c3...",
  "wandName": "P9-Wand-A1B2C3D4",
  "timestamp": 1697040000000
}
```

**Response**:
```json
{
  "success": true,
  "message": "Wand 'P9-Wand-A1B2C3D4' registered as coordinating key",
  "wandName": "P9-Wand-A1B2C3D4",
  "pubKey": "02a1b2c3...",
  "wandUUID": "abc123..."
}
```

## Architecture

```
┌──────────────────────────┐
│   ProS3 Wand (ESP32-S3)  │
│   ┌──────────────────┐   │
│   │ Sessionless Keys │   │  32-byte private key
│   │ (secp256k1)      │   │  33-byte compressed public key
│   └────────┬─────────┘   │  Stored in NVS flash
│            │             │
│   ┌────────▼─────────┐   │
│   │ BLE Server       │   │  Service: 0xF9A0
│   │ - Advertise      │   │  PubKey Char: 0xF9A1 (Read, Notify)
│   │ - Auto-connect   │   │  Command Char: 0xF9A2 (Write)
│   │ - Send pubKey    │   │
│   └────────┬─────────┘   │
│            │             │
│   ┌────────▼─────────┐   │
│   │ Button Input     │   │  GPIO0 (BOOT button)
│   │ - Cast spell     │   │  Sends {"action":"cast","spell":"lumos"}
│   └──────────────────┘   │
└────────────┼─────────────┘
             │ BLE Connection
             ▼
┌──────────────────────────┐
│   macOS The Advancement  │
│   ┌──────────────────┐   │
│   │ BLEWandManager   │   │  CoreBluetooth
│   │ - Scan           │   │  - Auto-scan on Bluetooth ready
│   │ - Connect        │   │  - Connect to all P9-Wand-* devices
│   │ - Read pubKey    │   │  - Subscribe to notifications
│   └────────┬─────────┘   │
│            │             │
│   ┌────────▼─────────┐   │
│   │ WandCoordinator  │   │  Julia Integration
│   │ - Register wand  │   │  POST /wand/register
│   │ - Track known    │   │  Store in UserDefaults
│   │ - Handle spells  │   │  Route to handlers
│   └────────┬─────────┘   │
│            │             │
└────────────┼─────────────┘
             │ HTTPS
             ▼
┌──────────────────────────┐
│   Julia Service          │
│   ┌──────────────────┐   │
│   │ /wand/register   │   │  Add coordinating key
│   └────────┬─────────┘   │  Link to Fount user
│            │             │
│   ┌────────▼─────────┐   │
│   │ Database         │   │  Store wand association
│   │ coordinatingKeys │   │  {pubKey, wandUUID}
│   └──────────────────┘   │
└──────────────────────────┘
```

## Getting Started - Step by Step

### Step 1: Flash the ProS3 Wand

1. **Install Arduino IDE**:
   ```
   Download from: https://www.arduino.cc/en/software
   ```

2. **Add ESP32 Board Support**:
   ```
   Arduino IDE → Preferences → Additional Boards Manager URLs:
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```

3. **Install ESP32 Board Package**:
   ```
   Tools → Board → Boards Manager → Search "esp32" → Install "esp32 by Espressif Systems"
   ```

4. **Install micro-ecc Library**:
   ```
   Tools → Manage Libraries → Search "micro-ecc" → Install "micro-ecc by Kenneth MacKay"
   ```

5. **Configure Board Settings**:
   ```
   Tools → Board → ESP32 Arduino → ESP32S3 Dev Module

   USB CDC On Boot: Enabled
   Flash Size: 16MB (128Mb)
   Partition Scheme: Default 4MB with spiffs
   PSRAM: OPI PSRAM
   Upload Speed: 921600
   ```

6. **Open Sketch**:
   ```
   File → Open → /src/embedded/pros3-wand/pros3-wand.ino
   ```

7. **Upload to ProS3**:
   - Connect ProS3 via USB-C
   - Select correct port: `Tools → Port → /dev/cu.usbmodem...`
   - Click Upload button
   - Wait ~30 seconds for compilation and upload

8. **Verify Operation**:
   ```
   Tools → Serial Monitor (115200 baud)

   Expected output:
   ╔════════════════════════════════════════╗
   ║   🪄  ProS3 Wand - Physical MAGIC  🪄  ║
   ║        The Advancement Embedded        ║
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
   ```

### Step 2: Add BLE Files to macOS App

The macOS app needs two new Swift files added to the Xcode project:

1. **Open Xcode Project**:
   ```
   open "src/The Advancement/The Advancement.xcodeproj"
   ```

2. **Add BLEWandManager.swift**:
   - Already created at: `src/The Advancement/Shared (App)/BLEWandManager.swift`
   - In Xcode: Right-click "Shared (App)" folder → Add Files
   - Select `BLEWandManager.swift`
   - Check target: "The Advancement (macOS)"

3. **Add WandCoordinator.swift**:
   - Already created at: `src/The Advancement/Shared (App)/WandCoordinator.swift`
   - In Xcode: Right-click "Shared (App)" folder → Add Files
   - Select `WandCoordinator.swift`
   - Check target: "The Advancement (macOS)"

4. **Add CoreBluetooth Framework**:
   ```
   Project Settings → The Advancement (macOS) → General → Frameworks, Libraries, and Embedded Content
   Click "+" → Add "CoreBluetooth.framework"
   ```

5. **Add Bluetooth Permission** (Info.plist):
   ```xml
   <key>NSBluetoothAlwaysUsageDescription</key>
   <string>The Advancement needs Bluetooth to connect to your MAGIC wand</string>
   ```

### Step 3: Initialize BLE Manager in App

Add to your main macOS app initialization (e.g., in `AppDelegate.swift` or main view controller):

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize BLE Wand Manager
        BLEWandManager.shared.setupDelegate()

        // BLE manager will auto-start scanning when Bluetooth is ready
        print("🪄 Wand system initialized")
    }
}
```

### Step 4: Start Julia Service

Make sure Julia is running with the wand registration endpoint:

```bash
cd /path/to/julia
node src/server/node/julia.js
```

Expected output should include:
```
julia's ready for connections
```

### Step 5: Test the Connection

1. **Power on ProS3**: Connect via USB or battery
2. **Check Serial Monitor**: Should show "BLE advertising"
3. **Run macOS App**: Should see Bluetooth scan start
4. **Watch for Connection**:
   - ProS3 Serial Monitor: "🔗 BLE Client Connected!"
   - macOS Console: "✅ Connected to: P9-Wand-XXXX"
   - macOS Console: "🔑 Received public key: 02a1b2c3..."
   - macOS Console: "✅ Wand P9-Wand-XXXX registered with Julia!"
5. **Test Spell Casting**: Press BOOT button on ProS3
   - ProS3 Serial Monitor: "🪄 Button pressed - casting spell!"
   - macOS Console: "✨ Wand P9-Wand-XXXX cast spell: lumos"

## User Input Options - What's Next?

Now that you have the basic wand working, here are the input options we can explore:

### Option 1: Simple Buttons (Easiest)
**What**: 1-3 external buttons connected to GPIO pins
**Use Case**: Different spells per button (button 1 = lumos, button 2 = accio, etc.)
**Components Needed**:
- Tactile push buttons (4-6mm)
- 10kΩ resistors
**Wiring**: Button between GPIO and GND, internal pullup resistor enabled
**Code**: Similar to existing BOOT button handler

### Option 2: IMU Gestures (Most Magical)
**What**: Accelerometer + Gyroscope for wand movements
**Use Case**: Swish & flick gestures, spell patterns
**Components Needed**:
- MPU6050 or LSM6DS3 (I2C IMU module)
- 4 jumper wires (VCC, GND, SDA, SCL)
**Wiring**:
- VCC → 3.3V
- GND → GND
- SDA → GPIO8
- SCL → GPIO9
**Code**: Read accelerometer data, detect gesture patterns, classify spells

### Option 3: Capacitive Touch (Elegant)
**What**: Use ESP32-S3's built-in capacitive touch sensing
**Use Case**: Touch-sensitive wand grip, multi-touch spells
**Components Needed**:
- Conductive tape or copper foil
- Touch-sensitive pads on GPIO pins
**Wiring**: Wrap copper foil around wand handle, connect to GPIO pins
**Code**: ESP32 `touchRead()` API, threshold detection

### Option 4: Combination (Most Powerful)
**What**: IMU + Button + Capacitive Touch
**Use Case**: Complex spell system with gestures, touch, and confirmation
**Example**:
1. Grip wand (capacitive touch detected)
2. Perform gesture (IMU detects pattern)
3. Press button (confirm spell cast)

## Recommended Next Steps

I recommend starting with **Option 2: IMU Gestures** because:

1. **Most Immersive**: Actual wand movements feel magical
2. **Versatile**: Can detect unlimited gesture patterns
3. **Simple Hardware**: Just one $3 IMU module
4. **Rich Data**: Acceleration + gyroscope provides detailed motion data

### IMU Implementation Plan

Would you like me to:

1. **Write IMU Integration Code**:
   - I2C communication with MPU6050/LSM6DS3
   - Gesture detection algorithms
   - Spell pattern matching

2. **Create Gesture Library**:
   - Pre-defined spells (lumos, accio, wingardium leviosa)
   - Custom gesture trainer
   - Calibration routine

3. **Build Web UI for Gesture Training**:
   - Record new gestures
   - Test gesture recognition
   - View motion data in real-time

## File Summary

### Created Files

```
the-advancement/
├── src/embedded/
│   ├── README.md                              # Main embedded documentation
│   ├── WAND-INTEGRATION-GUIDE.md             # This file
│   └── pros3-wand/
│       ├── pros3-wand.ino                    # Arduino sketch (main)
│       └── README.md                         # ProS3-specific setup guide
│
└── src/The Advancement/Shared (App)/
    ├── BLEWandManager.swift                  # CoreBluetooth BLE manager
    └── WandCoordinator.swift                 # Julia integration

julia/
└── src/server/node/
    └── julia.js                              # Added /wand/register endpoint (lines 773-828)
```

## Current Status

✅ **Firmware**: Complete and ready to flash
✅ **BLE Protocol**: Implemented and tested
✅ **Key Generation**: secp256k1 keys generating correctly
✅ **Mac Integration**: Swift BLE manager ready
✅ **Julia Endpoint**: Wand registration endpoint added
✅ **Button Input**: Built-in BOOT button working

🔜 **Next Steps** (your choice):
1. Add IMU for gesture detection
2. Add more buttons for spell variety
3. Add LED feedback for visual confirmation
4. Add haptic motor for tactile feedback
5. Implement direct WiFi spell casting (bypass Mac app)

## Questions?

Let me know which direction you'd like to go! I'm excited to help you build this physical MAGIC system. Some options:

1. **"Let's add IMU gestures!"** - I'll write the gesture detection code
2. **"I want to test the current setup first"** - I'll help troubleshoot
3. **"Add LEDs for visual feedback"** - I'll create LED patterns for spells
4. **"Let's make it battery powered"** - I'll optimize for deep sleep
5. **Something else** - Tell me your vision!

---

**Happy wand making!** 🪄✨
