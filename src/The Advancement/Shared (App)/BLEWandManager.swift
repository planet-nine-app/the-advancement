/**
 * BLEWandManager.swift
 * The Advancement
 *
 * Manages Bluetooth Low Energy connections to ProS3 wands
 *
 * Responsibilities:
 * - Scan for Planet Nine wands
 * - Auto-connect to discovered wands
 * - Read wand public keys
 * - Register wands as coordinating keys with Julia
 * - Handle spell cast notifications from wands
 *
 * Author: Planet Nine
 * License: MIT
 */

import Foundation
import CoreBluetooth

// MARK: - Wand Model

/// Represents a connected wand device
struct Wand: Identifiable {
    let id: UUID
    let name: String
    var publicKey: String
    let rssi: Int
    var isConnected: Bool
    var lastSeen: Date
}

// MARK: - BLE Wand Manager Delegate

protocol BLEWandManagerDelegate: AnyObject {
    func wandDidConnect(_ wand: Wand)
    func wandDidDisconnect(_ wand: Wand)
    func wandDidReceivePublicKey(_ wand: Wand, publicKey: String)
    func wandDidCastSpell(_ wand: Wand, spell: String)
}

// MARK: - BLE Wand Manager

class BLEWandManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var discoveredWands: [Wand] = []
    @Published var connectedWands: [Wand] = []
    @Published var isScanning: Bool = false

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var wandCharacteristics: [UUID: (pubKey: CBCharacteristic?, command: CBCharacteristic?)] = [:]

    weak var delegate: BLEWandManagerDelegate?

    // BLE UUIDs (must match ProS3 wand)
    private let wandServiceUUID = CBUUID(string: "0000F9A0-0000-1000-8000-00805F9B34FB")
    private let pubKeyCharUUID = CBUUID(string: "0000F9A1-0000-1000-8000-00805F9B34FB")
    private let commandCharUUID = CBUUID(string: "0000F9A2-0000-1000-8000-00805F9B34FB")

    // MARK: - Singleton

    static let shared = BLEWandManager()

    // MARK: - Initialization

    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public Methods

    /// Start scanning for wands
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("⚠️ Bluetooth not ready, state: \(centralManager.state.rawValue)")
            return
        }

        print("🔍 Starting BLE scan for Planet Nine wands...")
        isScanning = true

        // Scan for wand service UUID
        centralManager.scanForPeripherals(
            withServices: [wandServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    /// Stop scanning for wands
    func stopScanning() {
        print("🛑 Stopping BLE scan")
        isScanning = false
        centralManager.stopScan()
    }

    /// Connect to a specific wand
    func connect(to wand: Wand) {
        guard let peripheral = discoveredPeripherals[wand.id] else {
            print("❌ Peripheral not found for wand: \(wand.name)")
            return
        }

        print("🔗 Connecting to wand: \(wand.name)...")
        centralManager.connect(peripheral, options: nil)
    }

    /// Disconnect from a wand
    func disconnect(from wand: Wand) {
        guard let peripheral = discoveredPeripherals[wand.id] else {
            print("❌ Peripheral not found for wand: \(wand.name)")
            return
        }

        print("🔌 Disconnecting from wand: \(wand.name)...")
        centralManager.cancelPeripheralConnection(peripheral)
    }

    /// Send command to wand
    func sendCommand(to wand: Wand, command: String) {
        guard let peripheral = discoveredPeripherals[wand.id],
              let commandChar = wandCharacteristics[wand.id]?.command else {
            print("❌ Cannot send command - wand not connected or characteristic not found")
            return
        }

        let data = command.data(using: .utf8)!
        peripheral.writeValue(data, for: commandChar, type: .withResponse)
        print("📤 Sent command to wand: \(command)")
    }

    // MARK: - Helper Methods

    private func updateWandInList(_ wand: Wand, connected: Bool) {
        DispatchQueue.main.async {
            if connected {
                // Add to connected wands
                if let index = self.connectedWands.firstIndex(where: { $0.id == wand.id }) {
                    self.connectedWands[index] = wand
                } else {
                    self.connectedWands.append(wand)
                }
            } else {
                // Remove from connected wands
                self.connectedWands.removeAll { $0.id == wand.id }
            }

            // Update in discovered wands
            if let index = self.discoveredWands.firstIndex(where: { $0.id == wand.id }) {
                self.discoveredWands[index] = wand
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEWandManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("🔵 Bluetooth state: Unknown")
        case .resetting:
            print("🔵 Bluetooth state: Resetting")
        case .unsupported:
            print("❌ Bluetooth state: Unsupported")
        case .unauthorized:
            print("❌ Bluetooth state: Unauthorized")
        case .poweredOff:
            print("🔴 Bluetooth state: Powered Off")
        case .poweredOn:
            print("✅ Bluetooth state: Powered On")
            startScanning() // Auto-start scanning when Bluetooth is ready
        @unknown default:
            print("⚠️ Bluetooth state: Unknown default")
        }
    }

    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any],
                       rssi RSSI: NSNumber) {

        let wandName = peripheral.name ?? "Unknown Wand"

        // Only process wands with P9-Wand prefix
        guard wandName.hasPrefix("P9-Wand-") else {
            return
        }

        print("🪄 Discovered wand: \(wandName) (RSSI: \(RSSI))")

        // Store peripheral
        discoveredPeripherals[peripheral.identifier] = peripheral

        // Create wand object
        let wand = Wand(
            id: peripheral.identifier,
            name: wandName,
            publicKey: "", // Will be populated after connection
            rssi: RSSI.intValue,
            isConnected: false,
            lastSeen: Date()
        )

        // Add to discovered wands
        DispatchQueue.main.async {
            if !self.discoveredWands.contains(where: { $0.id == wand.id }) {
                self.discoveredWands.append(wand)
            }
        }

        // Auto-connect to discovered wand
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to: \(peripheral.name ?? "Unknown")")

        // Set delegate and discover services
        peripheral.delegate = self
        peripheral.discoverServices([wandServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                       didDisconnectPeripheral peripheral: CBPeripheral,
                       error: Error?) {
        print("❌ Disconnected from: \(peripheral.name ?? "Unknown")")

        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }

        // Update wand status
        if let index = discoveredWands.firstIndex(where: { $0.id == peripheral.identifier }) {
            var wand = discoveredWands[index]
            wand.isConnected = false
            updateWandInList(wand, connected: false)
            delegate?.wandDidDisconnect(wand)
        }

        // Clean up
        wandCharacteristics.removeValue(forKey: peripheral.identifier)

        // Auto-reconnect after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.discoveredPeripherals[peripheral.identifier] != nil {
                print("🔄 Attempting to reconnect to \(peripheral.name ?? "Unknown")...")
                central.connect(peripheral, options: nil)
            }
        }
    }

    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        print("❌ Failed to connect to: \(peripheral.name ?? "Unknown")")
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEWandManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == wandServiceUUID {
                print("📡 Found wand service")
                peripheral.discoverCharacteristics([pubKeyCharUUID, commandCharUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverCharacteristicsFor service: CBService,
                   error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        var pubKeyChar: CBCharacteristic?
        var commandChar: CBCharacteristic?

        for characteristic in characteristics {
            switch characteristic.uuid {
            case pubKeyCharUUID:
                print("🔑 Found public key characteristic")
                pubKeyChar = characteristic

                // Read public key immediately
                peripheral.readValue(for: characteristic)

                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)

            case commandCharUUID:
                print("📝 Found command characteristic")
                commandChar = characteristic

            default:
                break
            }
        }

        // Store characteristics
        wandCharacteristics[peripheral.identifier] = (pubKeyChar, commandChar)
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didUpdateValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        if let error = error {
            print("❌ Error reading characteristic: \(error.localizedDescription)")
            return
        }

        switch characteristic.uuid {
        case pubKeyCharUUID:
            // Wand sent public key
            if let data = characteristic.value, data.count == 33 {
                let publicKey = data.map { String(format: "%02x", $0) }.joined()
                print("🔑 Received public key: \(publicKey)")

                // Update wand object
                if let index = discoveredWands.firstIndex(where: { $0.id == peripheral.identifier }) {
                    var wand = discoveredWands[index]
                    wand.publicKey = publicKey
                    wand.isConnected = true
                    updateWandInList(wand, connected: true)

                    // Notify delegate
                    delegate?.wandDidConnect(wand)
                    delegate?.wandDidReceivePublicKey(wand, publicKey: publicKey)
                }
            }

        case commandCharUUID:
            // Wand sent command (e.g., spell cast notification)
            if let data = characteristic.value,
               let command = String(data: data, encoding: .utf8) {
                print("📥 Received command from wand: \(command)")

                // Parse JSON command
                if let jsonData = command.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                   let action = json["action"],
                   let spell = json["spell"],
                   action == "cast" {

                    // Notify delegate of spell cast
                    if let wand = discoveredWands.first(where: { $0.id == peripheral.identifier }) {
                        delegate?.wandDidCastSpell(wand, spell: spell)
                    }
                }
            }

        default:
            break
        }
    }
}
