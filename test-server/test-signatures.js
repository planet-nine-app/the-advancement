#!/usr/bin/env node

/**
 * Test script to verify signature generation matches between
 * browser implementation and keyboard extension
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Test keys for Bob and Alice
const ALICE_KEYS = {
    privateKey: '574102268f66ae19bda4c4fb08fa4fe705381b68e608f17516e70ce20f60e66d',
    pubKey: '027f68e0f4dfa964ebca3b9f90a15b8ffde8e91ebb0e2e36907fb0cc7aec48448e'
};

const BOB_KEYS = {
    privateKey: 'c40daae8754f2401bcac69d2b8620a743d6af132b2db7abcda5fe61396870979',
    pubKey: '035084ff6af66fe4c6e1525021994dbdd8069037ad1e80e8d7e553b322d61c4549'
};

// Demo signature generation (matching browser and Swift implementations)
function generateDemoSignature(privateKey, message) {
    const combinedInput = privateKey + message;

    let hash = 0;
    for (let i = 0; i < combinedInput.length; i++) {
        const char = combinedInput.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
    }

    const baseSignature = Math.abs(hash).toString(16).padStart(8, '0');
    const messageHex = message.split('').map(c => c.charCodeAt(0).toString(16)).join('').substring(0, 32);

    const signature = (baseSignature + privateKey.substring(0, 56) + baseSignature + messageHex)
                      .substring(0, 128).padEnd(128, '0');

    return signature;
}

// Test message
const testMessage = "Demo message 1234 at 1673456789000";

console.log('🧪 Testing Signature Generation');
console.log('================================');
console.log(`Message: "${testMessage}"`);
console.log('');

// Generate Alice's signature
const aliceSignature = generateDemoSignature(ALICE_KEYS.privateKey, testMessage);
console.log(`👩‍💻 Alice's Signature:`);
console.log(`   Private Key: ${ALICE_KEYS.privateKey}`);
console.log(`   Public Key:  ${ALICE_KEYS.pubKey}`);
console.log(`   Signature:   ${aliceSignature}`);
console.log('');

// Generate Bob's signature
const bobSignature = generateDemoSignature(BOB_KEYS.privateKey, testMessage);
console.log(`👨‍💻 Bob's Signature:`);
console.log(`   Private Key: ${BOB_KEYS.privateKey}`);
console.log(`   Public Key:  ${BOB_KEYS.pubKey}`);
console.log(`   Signature:   ${bobSignature}`);
console.log('');

// Verify signatures
function verifySignature(expectedPrivateKey, message, signature) {
    const expectedSignature = generateDemoSignature(expectedPrivateKey, message);
    return signature === expectedSignature;
}

console.log('🔍 Verification Tests:');
console.log(`   Alice signature with Alice key: ${verifySignature(ALICE_KEYS.privateKey, testMessage, aliceSignature) ? '✅' : '❌'}`);
console.log(`   Bob signature with Alice key:   ${verifySignature(ALICE_KEYS.privateKey, testMessage, bobSignature) ? '✅' : '❌'}`);
console.log(`   Alice signature with Bob key:   ${verifySignature(BOB_KEYS.privateKey, testMessage, aliceSignature) ? '✅' : '❌'}`);
console.log(`   Bob signature with Bob key:     ${verifySignature(BOB_KEYS.privateKey, testMessage, bobSignature) ? '✅' : '❌'}`);
console.log('');

console.log('🎯 Expected Keyboard Results:');
console.log('   Alice signatures → 🟢 GREEN (valid with Alice\'s key)');
console.log('   Bob signatures   → 🔴 RED (invalid with Alice\'s key)');
console.log('');

console.log('📱 Test Instructions:');
console.log('1. Start test server: npm start');
console.log('2. Visit: http://localhost:3456/signature-demo');
console.log('3. Generate signatures using the demo page');
console.log('4. Highlight signatures and test with the keyboard extension');
console.log('5. Verify red/green light feedback matches expectations');