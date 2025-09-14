#!/usr/bin/env swift

//
//  test-magicard-generation.swift
//  Planet Nine MagiCard Testing
//
//  Created by Claude AI on 9/13/25.
//

import Foundation

// Simple test script to generate MagiCard files for testing

print("🌍 Planet Nine MagiCard Generator Test")
print("=====================================")

// Test 1: Generate a complete MagiCard with the BDO data we've been using
let testPubKey = "03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a"

let testSVG = """
<svg width="400" height="300" viewBox="0 0 400 300" xmlns="http://www.w3.org/2000/svg">
    <defs>
        <linearGradient id="testGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
        </linearGradient>
    </defs>

    <rect width="400" height="300" fill="url(#testGrad)" rx="20"/>

    <circle cx="200" cy="80" r="35" fill="rgba(255,255,255,0.3)"/>
    <text x="200" y="95" text-anchor="middle" fill="white" font-size="32">🌍</text>

    <text x="200" y="140" text-anchor="middle" fill="white" font-size="24" font-weight="bold">Test MagiCard</text>
    <text x="200" y="165" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-size="14">Generated for testing QuickLook</text>

    <g spell="testSpell">
        <rect x="50" y="200" width="100" height="35" fill="rgba(255,255,255,0.2)" rx="18"/>
        <text x="100" y="222" text-anchor="middle" fill="white" font-size="12">✨ Test Spell</text>
    </g>

    <g data-bdo-pubkey="03a08b9b2a57c8b4f3e5a7d9c2b1e8f4a6c9e2d5b8a1f4e7c9b2a5d8f1e4b7c0">
        <rect x="250" y="200" width="100" height="35" fill="rgba(40,167,69,0.3)" rx="18"/>
        <text x="300" y="222" text-anchor="middle" fill="white" font-size="12">🧭 Navigate</text>
    </g>

    <text x="200" y="270" text-anchor="middle" fill="rgba(255,255,255,0.6)" font-size="9" font-family="monospace">
        \(testPubKey)
    </text>
</svg>
"""

let magiCardJSON = """
{
  "type": "magicard",
  "version": "1.0",
  "pubKey": "\(testPubKey)",
  "svgContent": "\(testSVG.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\"", with: "\\\""))",
  "metadata": {
    "title": "Test MagiCard",
    "description": "A test MagiCard generated for QuickLook testing",
    "spells": ["testSpell"],
    "signature": "3045022100abcdef123456789012345678901234567890123456789012345678901234567890123456789002203456789012345678901234567890123456789012345678901234567890123456789"
  }
}
"""

// Test 2: Generate a simple BDO reference file
let bdoReference = """
bdoPubKey: \(testPubKey)
title: Test Planet Nine Card
description: This is a test card for QuickLook extension development
spells: testSpell, navigate

Get The Advancement app to interact with this card:
https://apps.apple.com/app/the-advancement
"""

print("1. Generated complete MagiCard JSON (\(magiCardJSON.count) characters)")
print("2. Generated BDO reference file (\(bdoReference.count) characters)")

// Write test files
do {
    let currentDir = FileManager.default.currentDirectoryPath
    let testDir = URL(fileURLWithPath: currentDir).appendingPathComponent("test-magicards")

    try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

    // Write complete MagiCard
    let completeCardURL = testDir.appendingPathComponent("test-complete.magicard")
    try magiCardJSON.write(to: completeCardURL, atomically: true, encoding: .utf8)
    print("✅ Wrote complete MagiCard: \(completeCardURL.path)")

    // Write BDO reference
    let bdoRefURL = testDir.appendingPathComponent("test-bdo-reference.magicard")
    try bdoReference.write(to: bdoRefURL, atomically: true, encoding: .utf8)
    print("✅ Wrote BDO reference: \(bdoRefURL.path)")

    print("\n🎉 Test files generated successfully!")
    print("\nTo test:")
    print("1. Build The Advancement app with QuickLook extension")
    print("2. Share test-complete.magicard via AirDrop or Discord")
    print("3. Tap the file on iOS to see QuickLook preview")
    print("4. Verify the Planet Nine branding and call-to-action appear")

} catch {
    print("❌ Error creating test files: \(error)")
}

print("\n📱 QuickLook Extension Features:")
print("- Beautiful Planet Nine themed previews")
print("- SVG card rendering")
print("- Spell detection and counting")
print("- Verification badge display")
print("- App Store call-to-action for non-users")
print("- Support for both JSON cards and BDO references")