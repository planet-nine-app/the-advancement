#!/usr/bin/env node

/**
 * Linkifier - Create shareable link BDOs for Planet Nine
 *
 * Usage:
 *   linkifier <url> [title] [--bdo-url=<bdo-service-url>]
 *
 * Examples:
 *   linkifier https://github.com/planet-nine
 *   linkifier https://github.com/planet-nine "Planet Nine GitHub"
 *   linkifier https://example.com --bdo-url=http://localhost:3003
 */

import bdoLib from 'bdo-js';
import sessionless from 'sessionless-node';
import { URL } from 'url';

// Default BDO service URL (can be overridden with --bdo-url flag)
//const DEFAULT_BDO_URL = 'http://localhost:3003';
const DEFAULT_BDO_URL = 'https://plr.allyabase.com/plugin/allyabase/bdo/';

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
  console.log(`
🔗 Linkifier - Create shareable link BDOs for Planet Nine

Usage:
  linkifier <url> [title] [--bdo-url=<bdo-service-url>]

Arguments:
  url                     The URL to create a BDO for (required)
  title                   Optional title (defaults to domain name)

Options:
  --bdo-url=<url>         BDO service URL (default: ${DEFAULT_BDO_URL})
  --help, -h              Show this help message

Examples:
  linkifier https://github.com/planet-nine
  linkifier https://github.com/planet-nine "Planet Nine GitHub"
  linkifier https://example.com --bdo-url=http://localhost:3003
  linkifier https://plr.allyabase.com --bdo-url=https://plr.bdo.allyabase.com
`);
  process.exit(0);
}

// Extract arguments
let url = null;
let title = null;
let bdoServiceUrl = DEFAULT_BDO_URL;

for (const arg of args) {
  if (arg.startsWith('--bdo-url=')) {
    bdoServiceUrl = arg.split('=')[1];
  } else if (!url) {
    url = arg;
  } else if (!title) {
    title = arg;
  }
}

if (!url) {
  console.error('❌ Error: URL is required');
  console.error('Run "linkifier --help" for usage information');
  process.exit(1);
}

// Validate URL
try {
  const parsedUrl = new URL(url);

  // Auto-generate title from hostname if not provided
  if (!title) {
    title = parsedUrl.hostname.replace('www.', '');
  }
} catch (error) {
  console.error(`❌ Error: Invalid URL: ${url}`);
  process.exit(1);
}

console.log('🔗 Linkifier - Planet Nine Link BDO Creator');
console.log('==========================================\n');

console.log(`📎 URL: ${url}`);
console.log(`📝 Title: ${title}`);
console.log(`🌐 BDO Service: ${bdoServiceUrl}\n`);

// Generate SVG for the link
function generateLinkSVG(title, url) {
  const escapedUrl = url.replace(/"/g, '&quot;');
  const escapedTitle = title.replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const displayTitle = escapedTitle.length > 25
    ? escapedTitle.substring(0, 25) + '...'
    : escapedTitle;

  return `<svg width="320" height="100" viewBox="0 0 320 100" xmlns="http://www.w3.org/2000/svg">
  <!-- Background gradient -->
  <defs>
    <linearGradient id="linkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#10b981;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#059669;stop-opacity:1" />
    </linearGradient>
  </defs>

  <rect fill="url(#linkGrad)" width="320" height="100" rx="12"/>

  <!-- Link icon -->
  <text x="30" y="60" fill="white" font-size="36">🔗</text>

  <!-- Title -->
  <text x="75" y="50" fill="white" font-size="16" font-weight="bold">
    ${displayTitle}
  </text>

  <!-- Tap to open text -->
  <text x="75" y="70" fill="rgba(255,255,255,0.8)" font-size="12">
    Tap to open link
  </text>

  <!-- Clickable area that opens in default browser -->
  <a href="${escapedUrl}" target="_blank">
    <rect x="0" y="0" width="320" height="100" fill="transparent" cursor="pointer">
      <title>Open ${escapedTitle}</title>
    </rect>
  </a>
</svg>`;
}

// Track current user keys for sessionless signing
let currentUserKeys = null;

// In-memory key storage for sessionless
const saveKeys = (keys) => {
  currentUserKeys = keys;
};

const getKeys = () => {
  return currentUserKeys;
};

// Main function
async function createLinkBDO() {
  try {
    console.log('🔑 Generating sessionless keys...');

    // Configure BDO SDK base URL
    bdoLib.baseURL = bdoServiceUrl.endsWith('/') ? bdoServiceUrl : `${bdoServiceUrl}/`;

    // Generate keys using sessionless
    const keys = await sessionless.generateKeys(saveKeys, getKeys);

    const pubKey = keys.pubKey;

    console.log(`✅ Keys generated`);
    console.log(`   PubKey: ${pubKey.substring(0, 16)}...`);

    console.log('\n📦 Creating BDO...');

    // Create BDO data
    const bdoData = {
      title: title,
      type: 'link',
      contentType: 'external-link',
      url: url,
      description: `Link to ${url}`,
      svgContent: generateLinkSVG(title, url),
      metadata: {
        createdAt: new Date().toISOString(),
        originalUrl: url,
        createdBy: 'Linkifier CLI'
      }
    };

    const hash = 'Linkifier';

    // Create BDO user (this creates the BDO but not public yet)
    const bdoUUID = await bdoLib.createUser(hash, bdoData, saveKeys, getKeys);

    console.log(`✅ BDO user created: ${bdoUUID}`);

    // Update BDO to make it public (this generates the emojicode)
    const updatedBDO = await bdoLib.updateBDO(bdoUUID, hash, bdoData, true);

    console.log('✅ BDO made public!\n');

    // Get emojicode from response
    const emojicode = updatedBDO.emojiShortcode;
    const uuid = bdoUUID;

    // Display results
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✨ Link BDO Created!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('🎨 Emojicode:');
    console.log(`   ${emojicode}\n`);

    console.log('📋 Details:');
    console.log(`   UUID: ${uuid}`);
    console.log(`   PubKey: ${pubKey}`);
    console.log(`   Title: ${title}`);
    console.log(`   URL: ${url}\n`);

    console.log('🔗 Access:');
    console.log(`   By UUID: ${bdoServiceUrl}/user/${uuid}/bdo`);
    console.log(`   By Emojicode: ${bdoServiceUrl}/emoji/${encodeURIComponent(emojicode)}\n`);

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  } catch (error) {
    console.error('\n❌ Error creating link BDO:');
    console.error(`   ${error.message}`);

    if (error.stack) {
      console.error('\nStack trace:');
      console.error(error.stack);
    }

    process.exit(1);
  }
}

// Run the tool
createLinkBDO();
