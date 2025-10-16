#!/usr/bin/env node

/**
 * Seed Ecosystem Script
 *
 * Seeds the entire Planet Nine test ecosystem with:
 * - Events with tickets and emojiShortcodes
 * - (Future: Authors, books, products, etc.)
 */

import sessionless from 'sessionless-node';
import fetch from 'node-fetch';
import crypto from 'crypto';
import { events, generateEventSVG } from './examples/events.js';

// Configuration for test environment
const BDO_URL = 'http://127.0.0.1:5114'; // BDO on Base 1

// Generate test keys for seeding using crypto directly
const testKeys = {
  privateKey: crypto.randomBytes(32).toString('hex'),
  publicKey: 'test-public-key-' + crypto.randomBytes(16).toString('hex')
};

console.log('🌱 Starting ecosystem seeding...');
console.log('Using test key:', testKeys.publicKey);

// Helper function to create simple signature for testing
function createSignature(data, timestamp) {
  const message = `${data}-${timestamp}`;
  return crypto.createHash('sha256').update(message + testKeys.privateKey).digest('hex');
}

// Helper function to make request to BDO
async function bdoRequest(endpoint, method, data = null) {
  const timestamp = Date.now();
  const signature = createSignature(testKeys.publicKey, timestamp);

  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };

  if (method === 'GET') {
    const params = new URLSearchParams({
      timestamp: timestamp.toString(),
      signature,
      pubKey: testKeys.publicKey
    });
    const response = await fetch(`${BDO_URL}${endpoint}?${params}`);
    return response.json();
  } else {
    options.body = JSON.stringify({
      ...data,
      timestamp,
      signature,
      pubKey: testKeys.publicKey
    });
    const response = await fetch(`${BDO_URL}${endpoint}`, options);
    return response.json();
  }
}

// Seed events as BDOs
async function seedEvents() {
  console.log('\n🎫 Creating events as BDOs...');

  for (const event of events) {
    try {
      console.log(`Creating event: ${event.title}...`);

      // Generate SVG with purchase buttons
      const svgContent = generateEventSVG(event);

      // Create BDO data
      const eventBDO = {
        type: 'event',
        title: event.title,
        description: event.description,
        eventDate: event.eventDate,
        location: event.location,
        eventType: event.type,
        category: event.category,
        creatorName: event.creatorName,
        tickets: event.tickets,
        metadata: event.metadata,
        svgContent: svgContent,
        emojiShortcode: event.emojiShortcode,
        created: new Date().toISOString()
      };

      // Create public BDO with emojiShortcode
      const result = await bdoRequest('/bdo', 'POST', {
        object: eventBDO,
        metadata: {
          type: 'event',
          public: true,
          emojiShortcode: event.emojiShortcode,
          description: `Event: ${event.title}`
        }
      });

      if (result.uuid || result.pubKey) {
        console.log(`✅ Created event: ${event.title}`);
        console.log(`   🎨 EmojiShortcode: ${event.emojiShortcode}`);
        console.log(`   🔑 UUID: ${result.uuid || 'N/A'}`);
        console.log(`   🔑 PubKey: ${result.pubKey || 'N/A'}`);
      } else {
        console.log(`❌ Failed to create event ${event.title}:`, result.error || result);
      }
    } catch (error) {
      console.error(`❌ Error creating event ${event.title}:`, error.message);
    }
  }
}

// Main seeding function
async function main() {
  try {
    console.log('🚀 Starting ecosystem seeding process...');
    console.log('Target services:');
    console.log(`  BDO: ${BDO_URL}`);

    await seedEvents();

    console.log('\n🎉 Ecosystem seeding completed!');
    console.log('\n📋 Summary:');
    console.log(`  Events created: ${events.length}`);

    console.log('\n🎫 Events with emojiShortcodes:');
    events.forEach(event => {
      console.log(`  ${event.emojiShortcode} - ${event.title}`);
      console.log(`    📅 ${new Date(event.eventDate).toLocaleDateString()}`);
      console.log(`    🎟️  ${event.tickets.length} ticket types available`);
    });

    console.log('\n🎯 To test:');
    console.log('  1. Copy an emojiShortcode (e.g., 🌮🎪🔥🎉🍹🎭🌶️✨)');
    console.log('  2. Paste it in any app');
    console.log('  3. Tap DEMOJI in AdvanceKey');
    console.log('  4. Tap a ticket button to purchase!');

  } catch (error) {
    console.error('❌ Ecosystem seeding failed:', error);
    process.exit(1);
  }
}

// Run the seeding
main();
