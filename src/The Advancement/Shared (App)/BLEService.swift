//
//  BLEService.swift
//  The Advancement
//
//  Created by Claude Code on 1/15/25.
//  BLE key exchange service for interacting keys
//

import Foundation
import CoreBluetooth

// MARK: - BLE Constants
struct BLEConstants {
    // Planet Nine BLE Service (Purple theme: 9B59B6)
    static let serviceUUID = CBUUID(string: "9B59B600-0000-1000-8000-00805F9B34FB")

    // Characteristics
    static let pubKeyUUID = CBUUID(string: "9B59B601-0000-1000-8000-00805F9B34FB")
    static let signatureUUID = CBUUID(string: "9B59B602-0000-1000-8000-00805F9B34FB")
    static let messageUUID = CBUUID(string: "9B59B603-0000-1000-8000-00805F9B34FB")
}

// MARK: - BLE Key Data Model
struct BLEKeyData: Codable {
    let pubKey: String
    let signature: String
    let message: String

    func toJSON() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    static func fromJSON(_ json: String) -> BLEKeyData? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(BLEKeyData.self, from: data)
    }
}

// MARK: - Discovered Device Model
struct BLEDiscoveredDevice {
    let peripheral: CBPeripheral
    let name: String?
    let rssi: NSNumber
    let advertisementData: [String: Any]

    var displayName: String {
        return name ?? "Unknown Device"
    }

    var signalStrength: String {
        let rssiValue = rssi.intValue
        if rssiValue > -50 {
            return "Excellent"
        } else if rssiValue > -70 {
            return "Good"
        } else if rssiValue > -85 {
            return "Fair"
        } else {
            return "Weak"
        }
    }
}

// MARK: - BLE Service
class BLEService: NSObject {

    enum BLEError: Error {
        case notSupported
        case bluetoothOff
        case unauthorized
        case advertisingFailed(String)
        case scanningFailed(String)
        case connectionFailed(String)
        case readFailed(String)
        case writeFailed(String)
        case invalidData
        case characteristicNotFound
        case serviceNotFound
    }

    // MARK: - Properties

    // Peripheral Manager (for advertising our key)
    private var peripheralManager: CBPeripheralManager?
    private var advertisingCompletion: ((Result<Void, BLEError>) -> Void)?
    private var keyToAdvertise: BLEKeyData?

    // Central Manager (for scanning and receiving keys)
    private var centralManager: CBCentralManager?
    private var scanCompletion: ((Result<BLEKeyData, BLEError>) -> Void)?
    private var discoveredDevices: [UUID: BLEDiscoveredDevice] = [:]
    private var deviceDiscoveryHandler: (([BLEDiscoveredDevice]) -> Void)?

    // Connection state
    private var connectedPeripheral: CBPeripheral?
    private var discoveredService: CBService?
    private var pubKeyCharacteristic: CBCharacteristic?
    private var signatureCharacteristic: CBCharacteristic?
    private var messageCharacteristic: CBCharacteristic?

    // Data buffers for reading
    private var receivedPubKey: String?
    private var receivedSignature: String?
    private var receivedMessage: String?

    // MARK: - Singleton
    static let shared = BLEService()

    private override init() {
        super.init()
    }

    // MARK: - Initialization
    private func initializePeripheralManager() {
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
    }

    private func initializeCentralManager() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    // MARK: - Check BLE Availability
    static func isBLEAvailable() -> Bool {
        // This will be determined by the central/peripheral manager state
        return true // Actual check happens in delegate methods
    }

    // MARK: - Advertise Key (Peripheral Mode)

    /// Start advertising our public key and signature for others to read
    func advertiseKey(pubKey: String, signature: String, message: String, completion: @escaping (Result<Void, BLEError>) -> Void) {
        NSLog("ADVANCEAPP-BLE: 📢 Starting to advertise key")

        initializePeripheralManager()

        guard let peripheralManager = peripheralManager else {
            completion(.failure(.notSupported))
            return
        }

        self.keyToAdvertise = BLEKeyData(pubKey: pubKey, signature: signature, message: message)
        self.advertisingCompletion = completion

        // If peripheral manager is already powered on, start immediately
        if peripheralManager.state == .poweredOn {
            startAdvertising()
        }
        // Otherwise, wait for state update in delegate
    }

    private func startAdvertising() {
        guard let peripheralManager = peripheralManager,
              let keyData = keyToAdvertise else {
            NSLog("ADVANCEAPP-BLE: ❌ Cannot start advertising - no peripheral manager or key data")
            advertisingCompletion?(.failure(.advertisingFailed("Not initialized")))
            advertisingCompletion = nil
            return
        }

        // Stop any existing advertising
        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }

        // Remove any existing services
        peripheralManager.removeAllServices()

        // Create characteristics
        let pubKeyCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.pubKeyUUID,
            properties: [.read, .write],
            value: nil, // Dynamic value
            permissions: [.readable, .writeable]
        )

        let signatureCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.signatureUUID,
            properties: [.read, .write],
            value: nil, // Dynamic value
            permissions: [.readable, .writeable]
        )

        let messageCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.messageUUID,
            properties: [.read],
            value: nil, // Dynamic value
            permissions: [.readable]
        )

        // Create service
        let service = CBMutableService(type: BLEConstants.serviceUUID, primary: true)
        service.characteristics = [pubKeyCharacteristic, signatureCharacteristic, messageCharacteristic]

        // Add service
        peripheralManager.add(service)

        // Start advertising
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.serviceUUID],
            CBAdvertisementDataLocalNameKey: "Planet Nine Key"
        ]

        peripheralManager.startAdvertising(advertisementData)

        NSLog("ADVANCEAPP-BLE: ✅ Started advertising Planet Nine BLE service")
    }

    /// Stop advertising
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        NSLog("ADVANCEAPP-BLE: 🛑 Stopped advertising")
    }

    // MARK: - Scan for Keys (Central Mode)

    /// Scan for nearby devices advertising Planet Nine keys
    func scanForKeys(deviceDiscovery: @escaping ([BLEDiscoveredDevice]) -> Void) {
        NSLog("ADVANCEAPP-BLE: 🔍 Starting to scan for keys")

        initializeCentralManager()

        guard let centralManager = centralManager else {
            return
        }

        self.deviceDiscoveryHandler = deviceDiscovery
        self.discoveredDevices.removeAll()

        // If central manager is already powered on, start immediately
        if centralManager.state == .poweredOn {
            startScanning()
        }
        // Otherwise, wait for state update in delegate
    }

    private func startScanning() {
        guard let centralManager = centralManager else {
            NSLog("ADVANCEAPP-BLE: ❌ Cannot start scanning - no central manager")
            return
        }

        // Stop any existing scan
        if centralManager.isScanning {
            centralManager.stopScan()
        }

        // Start scanning for Planet Nine service
        let scanOptions: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]

        centralManager.scanForPeripherals(
            withServices: [BLEConstants.serviceUUID],
            options: scanOptions
        )

        NSLog("ADVANCEAPP-BLE: ✅ Started scanning for Planet Nine BLE service")
    }

    /// Stop scanning
    func stopScanning() {
        centralManager?.stopScan()
        discoveredDevices.removeAll()
        NSLog("ADVANCEAPP-BLE: 🛑 Stopped scanning")
    }

    // MARK: - Connect and Read Key

    /// Connect to a discovered device and read its key
    func connectAndReadKey(from device: BLEDiscoveredDevice, completion: @escaping (Result<BLEKeyData, BLEError>) -> Void) {
        NSLog("ADVANCEAPP-BLE: 🔗 Connecting to device: \(device.displayName)")

        guard let centralManager = centralManager else {
            completion(.failure(.notSupported))
            return
        }

        self.scanCompletion = completion
        self.connectedPeripheral = device.peripheral

        // Reset data buffers
        self.receivedPubKey = nil
        self.receivedSignature = nil
        self.receivedMessage = nil

        // Set peripheral delegate
        device.peripheral.delegate = self

        // Stop scanning while we connect
        centralManager.stopScan()

        // Connect to peripheral
        centralManager.connect(device.peripheral, options: nil)
    }

    /// Disconnect from current peripheral
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            NSLog("ADVANCEAPP-BLE: 🔌 Disconnected from peripheral")
        }

        connectedPeripheral = nil
        discoveredService = nil
        pubKeyCharacteristic = nil
        signatureCharacteristic = nil
        messageCharacteristic = nil
    }

    // MARK: - Helper Methods

    private func checkIfDataComplete() {
        guard let pubKey = receivedPubKey,
              let signature = receivedSignature,
              let message = receivedMessage else {
            // Still waiting for more data
            return
        }

        NSLog("ADVANCEAPP-BLE: ✅ Received complete key data")
        NSLog("ADVANCEAPP-BLE:    PubKey: \(String(pubKey.prefix(20)))...")
        NSLog("ADVANCEAPP-BLE:    Signature: \(String(signature.prefix(20)))...")
        NSLog("ADVANCEAPP-BLE:    Message: \(message)")

        let keyData = BLEKeyData(pubKey: pubKey, signature: signature, message: message)
        scanCompletion?(.success(keyData))
        scanCompletion = nil

        // Disconnect after reading
        disconnect()
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BLEService: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        NSLog("ADVANCEAPP-BLE: 📊 Peripheral manager state: \(peripheral.state.rawValue)")

        switch peripheral.state {
        case .poweredOn:
            NSLog("ADVANCEAPP-BLE: ✅ Peripheral manager powered on")
            // If we were waiting to advertise, start now
            if keyToAdvertise != nil {
                startAdvertising()
            }

        case .poweredOff:
            NSLog("ADVANCEAPP-BLE: ⚠️ Bluetooth is powered off")
            advertisingCompletion?(.failure(.bluetoothOff))
            advertisingCompletion = nil

        case .unauthorized:
            NSLog("ADVANCEAPP-BLE: ⚠️ Bluetooth unauthorized")
            advertisingCompletion?(.failure(.unauthorized))
            advertisingCompletion = nil

        case .unsupported:
            NSLog("ADVANCEAPP-BLE: ⚠️ Bluetooth unsupported")
            advertisingCompletion?(.failure(.notSupported))
            advertisingCompletion = nil

        default:
            break
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            NSLog("ADVANCEAPP-BLE: ❌ Failed to add service: \(error.localizedDescription)")
            advertisingCompletion?(.failure(.advertisingFailed(error.localizedDescription)))
            advertisingCompletion = nil
            return
        }

        NSLog("ADVANCEAPP-BLE: ✅ Service added successfully")
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            NSLog("ADVANCEAPP-BLE: ❌ Failed to start advertising: \(error.localizedDescription)")
            advertisingCompletion?(.failure(.advertisingFailed(error.localizedDescription)))
            advertisingCompletion = nil
            return
        }

        NSLog("ADVANCEAPP-BLE: ✅ Started advertising successfully")
        advertisingCompletion?(.success(()))
        advertisingCompletion = nil
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        NSLog("ADVANCEAPP-BLE: 📖 Received read request for characteristic: \(request.characteristic.uuid)")

        guard let keyData = keyToAdvertise else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        var value: Data?

        switch request.characteristic.uuid {
        case BLEConstants.pubKeyUUID:
            value = keyData.pubKey.data(using: .utf8)
            NSLog("ADVANCEAPP-BLE: 📤 Responding with pubKey")

        case BLEConstants.signatureUUID:
            value = keyData.signature.data(using: .utf8)
            NSLog("ADVANCEAPP-BLE: 📤 Responding with signature")

        case BLEConstants.messageUUID:
            value = keyData.message.data(using: .utf8)
            NSLog("ADVANCEAPP-BLE: 📤 Responding with message")

        default:
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        guard let responseValue = value else {
            peripheral.respond(to: request, withResult: .invalidAttributeValueLength)
            return
        }

        request.value = responseValue
        peripheral.respond(to: request, withResult: .success)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("ADVANCEAPP-BLE: 📊 Central manager state: \(central.state.rawValue)")

        switch central.state {
        case .poweredOn:
            NSLog("ADVANCEAPP-BLE: ✅ Central manager powered on")
            // If we were waiting to scan, start now
            if deviceDiscoveryHandler != nil {
                startScanning()
            }

        case .poweredOff:
            NSLog("ADVANCEAPP-BLE: ⚠️ Bluetooth is powered off")
            scanCompletion?(.failure(.bluetoothOff))
            scanCompletion = nil

        case .unauthorized:
            NSLog("ADVANCEAPP-BLE: ⚠️ Bluetooth unauthorized")
            scanCompletion?(.failure(.unauthorized))
            scanCompletion = nil

        case .unsupported:
            NSLog("ADVANCEAPP-BLE: ⚠️ Bluetooth unsupported")
            scanCompletion?(.failure(.notSupported))
            scanCompletion = nil

        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("ADVANCEAPP-BLE: 🔍 Discovered peripheral: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")

        let device = BLEDiscoveredDevice(
            peripheral: peripheral,
            name: peripheral.name,
            rssi: RSSI,
            advertisementData: advertisementData
        )

        discoveredDevices[peripheral.identifier] = device

        // Notify handler of discovered devices
        let devices = Array(discoveredDevices.values).sorted { $0.rssi.intValue > $1.rssi.intValue }
        deviceDiscoveryHandler?(devices)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("ADVANCEAPP-BLE: ✅ Connected to peripheral: \(peripheral.name ?? "Unknown")")

        // Discover Planet Nine service
        peripheral.discoverServices([BLEConstants.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("ADVANCEAPP-BLE: ❌ Failed to connect: \(error?.localizedDescription ?? "Unknown error")")

        scanCompletion?(.failure(.connectionFailed(error?.localizedDescription ?? "Unknown error")))
        scanCompletion = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("ADVANCEAPP-BLE: 🔌 Disconnected from peripheral")

        if let error = error {
            NSLog("ADVANCEAPP-BLE: ⚠️ Disconnect error: \(error.localizedDescription)")
        }

        connectedPeripheral = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BLEService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            NSLog("ADVANCEAPP-BLE: ❌ Service discovery error: \(error.localizedDescription)")
            scanCompletion?(.failure(.serviceNotFound))
            scanCompletion = nil
            return
        }

        guard let services = peripheral.services else {
            NSLog("ADVANCEAPP-BLE: ❌ No services found")
            scanCompletion?(.failure(.serviceNotFound))
            scanCompletion = nil
            return
        }

        NSLog("ADVANCEAPP-BLE: 🔍 Discovered \(services.count) service(s)")

        // Find Planet Nine service
        guard let service = services.first(where: { $0.uuid == BLEConstants.serviceUUID }) else {
            NSLog("ADVANCEAPP-BLE: ❌ Planet Nine service not found")
            scanCompletion?(.failure(.serviceNotFound))
            scanCompletion = nil
            return
        }

        discoveredService = service
        NSLog("ADVANCEAPP-BLE: ✅ Found Planet Nine service")

        // Discover characteristics
        peripheral.discoverCharacteristics([
            BLEConstants.pubKeyUUID,
            BLEConstants.signatureUUID,
            BLEConstants.messageUUID
        ], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            NSLog("ADVANCEAPP-BLE: ❌ Characteristic discovery error: \(error.localizedDescription)")
            scanCompletion?(.failure(.characteristicNotFound))
            scanCompletion = nil
            return
        }

        guard let characteristics = service.characteristics else {
            NSLog("ADVANCEAPP-BLE: ❌ No characteristics found")
            scanCompletion?(.failure(.characteristicNotFound))
            scanCompletion = nil
            return
        }

        NSLog("ADVANCEAPP-BLE: 🔍 Discovered \(characteristics.count) characteristic(s)")

        // Store characteristics and read values
        for characteristic in characteristics {
            switch characteristic.uuid {
            case BLEConstants.pubKeyUUID:
                pubKeyCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                NSLog("ADVANCEAPP-BLE: 📖 Reading pubKey characteristic")

            case BLEConstants.signatureUUID:
                signatureCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                NSLog("ADVANCEAPP-BLE: 📖 Reading signature characteristic")

            case BLEConstants.messageUUID:
                messageCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                NSLog("ADVANCEAPP-BLE: 📖 Reading message characteristic")

            default:
                NSLog("ADVANCEAPP-BLE: ⚠️ Unknown characteristic: \(characteristic.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("ADVANCEAPP-BLE: ❌ Read error for \(characteristic.uuid): \(error.localizedDescription)")
            scanCompletion?(.failure(.readFailed(error.localizedDescription)))
            scanCompletion = nil
            return
        }

        guard let data = characteristic.value,
              let stringValue = String(data: data, encoding: .utf8) else {
            NSLog("ADVANCEAPP-BLE: ❌ Invalid data for characteristic \(characteristic.uuid)")
            scanCompletion?(.failure(.invalidData))
            scanCompletion = nil
            return
        }

        // Store received values
        switch characteristic.uuid {
        case BLEConstants.pubKeyUUID:
            receivedPubKey = stringValue
            NSLog("ADVANCEAPP-BLE: ✅ Received pubKey: \(String(stringValue.prefix(20)))...")

        case BLEConstants.signatureUUID:
            receivedSignature = stringValue
            NSLog("ADVANCEAPP-BLE: ✅ Received signature: \(String(stringValue.prefix(20)))...")

        case BLEConstants.messageUUID:
            receivedMessage = stringValue
            NSLog("ADVANCEAPP-BLE: ✅ Received message: \(stringValue)")

        default:
            break
        }

        // Check if we have all the data
        checkIfDataComplete()
    }
}
