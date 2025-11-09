#!/usr/bin/env node

/**
 * Linktree Importer - Convert Linktree pages to Glyphenge BDOs
 *
 * Usage:
 *   linktree-importer <linktree-url> [--bdo-url=<bdo-service-url>]
 *
 * Examples:
 *   linktree-importer https://linktr.ee/amiintrouble
 *   linktree-importer https://linktr.ee/negativebliss
 *   linktree-importer https://linktr.ee/stevewiener --bdo-url=http://localhost:3003
 */

import bdoLib from 'bdo-js';
import sessionless from 'sessionless-node';
import fetch from 'node-fetch';
import * as cheerio from 'cheerio';
import { URL } from 'url';

// Default BDO service URL
const DEFAULT_BDO_URL = 'https://plr.allyabase.com/plugin/allyabase/bdo/';

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
  console.log(`
🌳 Linktree Importer - Convert Linktree pages to Glyphenge BDOs

Usage:
  linktree-importer <linktree-url> [--bdo-url=<bdo-service-url>]

Arguments:
  linktree-url            The linktr.ee URL to import (required)

Options:
  --bdo-url=<url>         BDO service URL (default: ${DEFAULT_BDO_URL})
  --help, -h              Show this help message

Examples:
  linktree-importer https://linktr.ee/amiintrouble
  linktree-importer https://linktr.ee/negativebliss
  linktree-importer https://linktr.ee/stevewiener --bdo-url=http://localhost:3003
`);
  process.exit(0);
}

// Extract arguments
let linktreeUrl = null;
let bdoServiceUrl = DEFAULT_BDO_URL;

for (const arg of args) {
  if (arg.startsWith('--bdo-url=')) {
    bdoServiceUrl = arg.split('=')[1];
  } else if (!linktreeUrl) {
    linktreeUrl = arg;
  }
}

if (!linktreeUrl) {
  console.error('❌ Error: Linktree URL is required');
  console.error('Run "linktree-importer --help" for usage information');
  process.exit(1);
}

// Validate Linktree URL
try {
  const parsedUrl = new URL(linktreeUrl);
  if (!parsedUrl.hostname.includes('linktr.ee')) {
    console.error('❌ Error: URL must be a linktr.ee URL');
    process.exit(1);
  }
} catch (error) {
  console.error(`❌ Error: Invalid URL: ${linktreeUrl}`);
  process.exit(1);
}

console.log('🌳 Linktree Importer - Convert to Glyphenge BDO');
console.log('===============================================\n');

console.log(`📎 Linktree URL: ${linktreeUrl}`);
console.log(`🌐 BDO Service: ${bdoServiceUrl}\n`);

// Fetch and parse Linktree page
async function fetchLinktreeLinks(url) {
  console.log('🌐 Fetching Linktree page...');

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch Linktree page: ${response.status} ${response.statusText}`);
  }

  const html = await response.text();

  console.log('✅ Page fetched successfully');
  console.log('🔍 Extracting embedded JSON data...\n');

  // Linktree uses Next.js and embeds data in __NEXT_DATA__ script tag
  const nextDataMatch = html.match(/<script id="__NEXT_DATA__"[^>]*>(.*?)<\/script>/s);

  if (!nextDataMatch) {
    throw new Error('Could not find __NEXT_DATA__ in page - Linktree may have changed their format');
  }

  const nextData = JSON.parse(nextDataMatch[1]);

  // Navigate to the links array in the JSON structure
  // Structure: props.pageProps.account.links
  const account = nextData?.props?.pageProps?.account;

  if (!account) {
    throw new Error('Could not find account data in page JSON');
  }

  const linktreeLinks = account.links || [];

  if (linktreeLinks.length === 0) {
    throw new Error('No links found in Linktree account');
  }

  console.log(`📊 Account: ${account.username || 'Unknown'}`);
  console.log(`📝 Title: ${account.pageTitle || account.username || 'My Links'}\n`);

  const links = [];

  linktreeLinks.forEach((link, i) => {
    const title = link.title || link.url;
    const url = link.url;

    if (url && title) {
      links.push({
        title: title,
        url: url,
        savedAt: new Date().toISOString()
      });

      console.log(`   ${i + 1}. ${title}`);
      console.log(`      → ${url}`);
    }
  });

  return links;
}

// Generate composite SVG (same logic as iOS EnchantmentEmporiumViewController)
function generateGlyphengeSVG(links) {
  const linkCount = links.length;

  if (linkCount <= 6) {
    return generateCompactSVG(links);
  } else if (linkCount <= 13) {
    return generateGridSVG(links);
  } else {
    return generateDenseSVG(links);
  }
}

function generateCompactSVG(links) {
  const height = Math.max(400, links.length * 110 + 60);
  const gradients = [
    ['#10b981', '#059669'],
    ['#3b82f6', '#2563eb'],
    ['#8b5cf6', '#7c3aed'],
    ['#ec4899', '#db2777'],
    ['#f59e0b', '#d97706'],
    ['#a78bfa', '#8b5cf6']
  ];

  let linkElements = '';
  links.forEach((link, index) => {
    const y = 60 + (index * 110);
    const title = link.title || 'Untitled';
    const url = link.url || '#';
    const truncatedTitle = title.length > 30 ? title.substring(0, 30) + '...' : title;

    const gradient = gradients[index % gradients.length];
    const gradId = `grad${index}`;

    linkElements += `
    <defs>
        <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
            <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
        </linearGradient>
    </defs>

    <a href="${escapeXML(url)}" target="_blank">
        <rect x="50" y="${y}" width="600" height="90" rx="15" fill="url(#${gradId})" opacity="0.9"/>
        <text x="90" y="${y + 40}" fill="white" font-size="20" font-weight="bold">${escapeXML(truncatedTitle)}</text>
        <text x="90" y="${y + 65}" fill="rgba(255,255,255,0.8)" font-size="14">🔗 Tap to open</text>
        <text x="600" y="${y + 50}" fill="white" font-size="30">→</text>
    </a>
    `;
  });

  return `<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="700" height="${height}" fill="#f9fafb"/>

    <text x="350" y="35" fill="#1f2937" font-size="24" font-weight="bold" text-anchor="middle">
        My Links
    </text>

    ${linkElements}
</svg>`;
}

function generateGridSVG(links) {
  const rows = Math.ceil(links.length / 2);
  const height = Math.max(400, rows * 100 + 100);
  const gradients = [
    ['#10b981', '#059669'],
    ['#3b82f6', '#2563eb'],
    ['#8b5cf6', '#7c3aed'],
    ['#ec4899', '#db2777'],
    ['#f59e0b', '#d97706'],
    ['#a78bfa', '#8b5cf6']
  ];

  let linkElements = '';
  links.forEach((link, index) => {
    const col = index % 2;
    const row = Math.floor(index / 2);
    const x = col === 0 ? 40 : 370;
    const y = 80 + (row * 100);

    const title = link.title || 'Untitled';
    const url = link.url || '#';
    const truncatedTitle = title.length > 15 ? title.substring(0, 15) + '...' : title;

    const gradient = gradients[index % gradients.length];
    const gradId = `grad${index}`;

    linkElements += `
    <defs>
        <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
            <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
        </linearGradient>
    </defs>

    <a href="${escapeXML(url)}" target="_blank">
        <rect x="${x}" y="${y}" width="290" height="80" rx="12" fill="url(#${gradId})" opacity="0.9"/>
        <text x="${x + 20}" y="${y + 35}" fill="white" font-size="16" font-weight="bold">${escapeXML(truncatedTitle)}</text>
        <text x="${x + 20}" y="${y + 55}" fill="rgba(255,255,255,0.8)" font-size="12">🔗 Click</text>
    </a>
    `;
  });

  return `<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="700" height="${height}" fill="#f9fafb"/>

    <text x="350" y="40" fill="#1f2937" font-size="24" font-weight="bold" text-anchor="middle">
        My Links
    </text>

    ${linkElements}
</svg>`;
}

function generateDenseSVG(links) {
  const rows = Math.ceil(links.length / 3);
  const height = Math.max(400, rows * 80 + 100);
  const gradients = [
    ['#10b981', '#059669'],
    ['#3b82f6', '#2563eb'],
    ['#8b5cf6', '#7c3aed'],
    ['#ec4899', '#db2777'],
    ['#f59e0b', '#d97706'],
    ['#a78bfa', '#8b5cf6']
  ];

  let linkElements = '';
  links.forEach((link, index) => {
    const col = index % 3;
    const row = Math.floor(index / 3);
    const x = 30 + (col * 220);
    const y = 80 + (row * 80);

    const title = link.title || 'Untitled';
    const url = link.url || '#';
    const truncatedTitle = title.length > 12 ? title.substring(0, 12) + '...' : title;

    const gradient = gradients[index % gradients.length];
    const gradId = `grad${index}`;

    linkElements += `
    <defs>
        <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
            <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
        </linearGradient>
    </defs>

    <a href="${escapeXML(url)}" target="_blank">
        <rect x="${x}" y="${y}" width="190" height="65" rx="10" fill="url(#${gradId})" opacity="0.9"/>
        <text x="${x + 15}" y="${y + 30}" fill="white" font-size="14" font-weight="bold">${escapeXML(truncatedTitle)}</text>
        <text x="${x + 15}" y="${y + 48}" fill="rgba(255,255,255,0.8)" font-size="11">🔗</text>
    </a>
    `;
  });

  return `<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="700" height="${height}" fill="#f9fafb"/>

    <text x="350" y="40" fill="#1f2937" font-size="22" font-weight="bold" text-anchor="middle">
        My Links
    </text>

    ${linkElements}
</svg>`;
}

function escapeXML(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
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
async function importLinktree() {
  try {
    // 1. Fetch and parse Linktree page
    const links = await fetchLinktreeLinks(linktreeUrl);

    if (links.length === 0) {
      console.error('\n❌ No links found on Linktree page');
      process.exit(1);
    }

    console.log(`\n✅ Found ${links.length} links\n`);

    // 2. Generate composite SVG
    console.log('🎨 Generating composite SVG...');
    const compositeSVG = generateGlyphengeSVG(links);
    console.log(`✅ SVG generated (${compositeSVG.length} characters)\n`);

    // 3. Generate sessionless keys
    console.log('🔑 Generating sessionless keys...');
    bdoLib.baseURL = bdoServiceUrl.endsWith('/') ? bdoServiceUrl : `${bdoServiceUrl}/`;
    const keys = await sessionless.generateKeys(saveKeys, getKeys);
    const pubKey = keys.pubKey;
    console.log(`✅ Keys generated`);
    console.log(`   PubKey: ${pubKey.substring(0, 16)}...\n`);

    // 4. Create Glyphenge BDO
    console.log('📦 Creating Glyphenge BDO...');

    const username = linktreeUrl.split('/').pop();
    const bdoData = {
      title: `${username}'s Links`,
      type: 'glyphenge',
      svgContent: compositeSVG,
      links: links,
      source: 'linktree',
      sourceUrl: linktreeUrl,
      createdAt: new Date().toISOString()
    };

    const hash = 'Linktree Importer';

    // Create BDO user
    const bdoUUID = await bdoLib.createUser(hash, bdoData, saveKeys, getKeys);
    console.log(`✅ BDO user created: ${bdoUUID}`);

    // 5. Make BDO public (generates emojicode)
    const updatedBDO = await bdoLib.updateBDO(bdoUUID, hash, bdoData, true);
    console.log('✅ BDO made public!\n');

    // Get emojicode
    const emojicode = updatedBDO.emojiShortcode;

    // Display results
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✨ Glyphenge BDO Created from Linktree!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('🎨 Emojicode:');
    console.log(`   ${emojicode}\n`);

    console.log('📋 Details:');
    console.log(`   UUID: ${bdoUUID}`);
    console.log(`   PubKey: ${pubKey}`);
    console.log(`   Title: ${username}'s Links`);
    console.log(`   Links: ${links.length} imported\n`);

    console.log('🔗 Access:');
    console.log(`   By UUID: ${bdoServiceUrl}/user/${bdoUUID}/bdo`);
    console.log(`   By Emojicode: ${bdoServiceUrl}/emoji/${encodeURIComponent(emojicode)}\n`);

    console.log('🌐 Glyphenge:');
    console.log(`   http://localhost:5125?emojicode=${encodeURIComponent(emojicode)}\n`);

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  } catch (error) {
    console.error('\n❌ Error importing Linktree:');
    console.error(`   ${error.message}`);

    if (error.stack) {
      console.error('\nStack trace:');
      console.error(error.stack);
    }

    process.exit(1);
  }
}

// Run the tool
importLinktree();
