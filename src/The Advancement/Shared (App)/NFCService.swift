//
//  NFCService.swift
//  The Advancement
//
//  Created by Claude Code on 10/12/25.
//  NFC reading and writing service for coordinating keys
//

import Foundation
import CoreNFC

// MARK: - NFC Tag Data Model
struct NFCTagData: Codable {
    let pubKey: String
    let signature: String

    func toJSON() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    static func fromJSON(_ json: String) -> NFCTagData? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(NFCTagData.self, from: data)
    }
}

// MARK: - NFC Service
class NFCService: NSObject {

    enum NFCError: Error {
        case notSupported
        case readFailed(String)
        case writeFailed(String)
        case invalidData
        case tagNotFound
    }

    // MARK: - Properties
    private var readSession: NFCNDEFReaderSession?
    private var writeSession: NFCNDEFReaderSession?
    private var readCompletion: ((Result<NFCTagData, NFCError>) -> Void)?
    private var writeCompletion: ((Result<Void, NFCError>) -> Void)?
    private var dataToWrite: NFCTagData?

    // MARK: - Singleton
    static let shared = NFCService()

    private override init() {
        super.init()
    }

    // MARK: - Check NFC Availability
    static func isNFCAvailable() -> Bool {
        return NFCNDEFReaderSession.readingAvailable
    }

    // MARK: - Read NFC Tag
    func readTag(completion: @escaping (Result<NFCTagData, NFCError>) -> Void) {
        guard NFCService.isNFCAvailable() else {
            completion(.failure(.notSupported))
            return
        }

        self.readCompletion = completion

        readSession = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )

        readSession?.alertMessage = "Hold your iPhone near the NFC tag to read coordinating key"
        readSession?.begin()

        NSLog("ADVANCEAPP-NFC: 📱 Started NFC reading session")
    }

    // MARK: - Write NFC Tag
    func writeTag(pubKey: String, signature: String, completion: @escaping (Result<Void, NFCError>) -> Void) {
        guard NFCService.isNFCAvailable() else {
            completion(.failure(.notSupported))
            return
        }

        let tagData = NFCTagData(pubKey: pubKey, signature: signature)
        self.dataToWrite = tagData
        self.writeCompletion = completion

        writeSession = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false
        )

        writeSession?.alertMessage = "Hold your iPhone near the NFC tag to write coordinating key"
        writeSession?.begin()

        NSLog("ADVANCEAPP-NFC: ✍️ Started NFC writing session")
    }

    // MARK: - Helper: Create NDEF Message from TagData
    private func createNDEFMessage(from tagData: NFCTagData) -> NFCNDEFMessage? {
        guard let json = tagData.toJSON() else {
            NSLog("ADVANCEAPP-NFC: ❌ Failed to encode tag data to JSON")
            return nil
        }

        guard let payload = json.data(using: .utf8) else {
            NSLog("ADVANCEAPP-NFC: ❌ Failed to convert JSON to data")
            return nil
        }

        // Create NDEF record with JSON payload
        // Using MIME type for JSON
        let record = NFCNDEFPayload(
            format: .media,
            type: "application/json".data(using: .utf8)!,
            identifier: Data(),
            payload: payload
        )

        return NFCNDEFMessage(records: [record])
    }

    // MARK: - Helper: Parse TagData from NDEF Message
    private func parseTagData(from message: NFCNDEFMessage) -> NFCTagData? {
        guard let record = message.records.first else {
            NSLog("ADVANCEAPP-NFC: ⚠️ No NDEF records found")
            return nil
        }

        // Extract payload
        let payload = record.payload

        // For MIME type records, skip the first byte (language code length)
        let actualPayload: Data
        if record.typeNameFormat == .media {
            actualPayload = payload
        } else if record.typeNameFormat == .nfcWellKnown {
            // For well-known type, first byte is language code length
            actualPayload = payload.count > 1 ? payload.dropFirst() : payload
        } else {
            actualPayload = payload
        }

        guard let json = String(data: actualPayload, encoding: .utf8) else {
            NSLog("ADVANCEAPP-NFC: ❌ Failed to decode payload to string")
            return nil
        }

        NSLog("ADVANCEAPP-NFC: 📦 Parsed JSON: \(json)")

        return NFCTagData.fromJSON(json)
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCService: NFCNDEFReaderSessionDelegate {

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        NSLog("ADVANCEAPP-NFC: ❌ Session invalidated: \(error.localizedDescription)")

        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                NSLog("ADVANCEAPP-NFC: 🚫 User canceled NFC session")
            case .readerSessionInvalidationErrorSessionTimeout:
                NSLog("ADVANCEAPP-NFC: ⏱️ NFC session timeout")
            default:
                NSLog("ADVANCEAPP-NFC: ❌ NFC error code: \(nfcError.code.rawValue)")
            }
        }

        // Call appropriate completion handler with error
        if session == readSession {
            readCompletion?(.failure(.readFailed(error.localizedDescription)))
            readCompletion = nil
        } else if session == writeSession {
            writeCompletion?(.failure(.writeFailed(error.localizedDescription)))
            writeCompletion = nil
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        NSLog("ADVANCEAPP-NFC: 🎯 Detected NDEF messages: \(messages.count)")

        guard let message = messages.first else {
            readCompletion?(.failure(.invalidData))
            readCompletion = nil
            session.invalidate()
            return
        }

        guard let tagData = parseTagData(from: message) else {
            readCompletion?(.failure(.invalidData))
            readCompletion = nil
            session.invalidate()
            return
        }

        NSLog("ADVANCEAPP-NFC: ✅ Successfully read tag data")
        NSLog("ADVANCEAPP-NFC:    PubKey: \(String(tagData.pubKey.prefix(20)))")
        NSLog("ADVANCEAPP-NFC:    Signature: \(String(tagData.signature.prefix(20)))")

        readCompletion?(.success(tagData))
        readCompletion = nil

        session.alertMessage = "Successfully read coordinating key!"
        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        NSLog("ADVANCEAPP-NFC: 📍 Detected \(tags.count) NFC tag(s)")

        guard let tag = tags.first else {
            if session == readSession {
                readCompletion?(.failure(.tagNotFound))
                readCompletion = nil
            } else if session == writeSession {
                writeCompletion?(.failure(.tagNotFound))
                writeCompletion = nil
            }
            session.invalidate()
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                NSLog("ADVANCEAPP-NFC: ❌ Connection error: \(error.localizedDescription)")
                if session == self.readSession {
                    self.readCompletion?(.failure(.readFailed(error.localizedDescription)))
                    self.readCompletion = nil
                } else if session == self.writeSession {
                    self.writeCompletion?(.failure(.writeFailed(error.localizedDescription)))
                    self.writeCompletion = nil
                }
                session.invalidate()
                return
            }

            // If we're writing, write the tag
            if session == self.writeSession, let tagData = self.dataToWrite {
                self.writeToTag(tag: tag, tagData: tagData, session: session)
            } else {
                // Reading is handled by didDetectNDEFs
                NSLog("ADVANCEAPP-NFC: 📖 Tag connected for reading")
            }
        }
    }

    // MARK: - Write to Tag Helper
    private func writeToTag(tag: NFCNDEFTag, tagData: NFCTagData, session: NFCNDEFReaderSession) {
        tag.queryNDEFStatus { [weak self] status, capacity, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("ADVANCEAPP-NFC: ❌ Query status error: \(error.localizedDescription)")
                self.writeCompletion?(.failure(.writeFailed(error.localizedDescription)))
                self.writeCompletion = nil
                session.invalidate()
                return
            }

            NSLog("ADVANCEAPP-NFC: 📊 Tag status: \(status.rawValue), capacity: \(capacity) bytes")

            guard status == .readWrite else {
                NSLog("ADVANCEAPP-NFC: ❌ Tag is not writable (status: \(status.rawValue))")
                self.writeCompletion?(.failure(.writeFailed("Tag is not writable")))
                self.writeCompletion = nil
                session.alertMessage = "Tag is not writable"
                session.invalidate()
                return
            }

            guard let message = self.createNDEFMessage(from: tagData) else {
                self.writeCompletion?(.failure(.writeFailed("Failed to create NDEF message")))
                self.writeCompletion = nil
                session.invalidate()
                return
            }

            NSLog("ADVANCEAPP-NFC: ✍️ Writing NDEF message to tag...")

            tag.writeNDEF(message) { error in
                if let error = error {
                    NSLog("ADVANCEAPP-NFC: ❌ Write error: \(error.localizedDescription)")
                    self.writeCompletion?(.failure(.writeFailed(error.localizedDescription)))
                    self.writeCompletion = nil
                    session.alertMessage = "Failed to write tag"
                    session.invalidate()
                    return
                }

                NSLog("ADVANCEAPP-NFC: ✅ Successfully wrote coordinating key to tag")
                self.writeCompletion?(.success(()))
                self.writeCompletion = nil
                self.dataToWrite = nil

                session.alertMessage = "Successfully wrote coordinating key!"
                session.invalidate()
            }
        }
    }
}
