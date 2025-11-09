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

import fetch from 'node-fetch';
import { URL } from 'url';

// Default Glyphenge service URL
const DEFAULT_GLYPHENGE_URL = 'http://localhost:5125';

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
  console.log(`
🌳 Linktree Importer - Convert Linktree pages to Glyphenge BDOs

Usage:
  linktree-importer <linktree-url> [--glyphenge-url=<glyphenge-service-url>]

Arguments:
  linktree-url            The linktr.ee URL to import (required)

Options:
  --glyphenge-url=<url>   Glyphenge service URL (default: ${DEFAULT_GLYPHENGE_URL})
  --help, -h              Show this help message

Examples:
  linktree-importer https://linktr.ee/amiintrouble
  linktree-importer https://linktr.ee/negativebliss
  linktree-importer https://linktr.ee/stevewiener --glyphenge-url=http://localhost:3010
`);
  process.exit(0);
}

// Extract arguments
let linktreeUrl = null;
let glyphengeServiceUrl = DEFAULT_GLYPHENGE_URL;

for (const arg of args) {
  if (arg.startsWith('--glyphenge-url=')) {
    glyphengeServiceUrl = arg.split('=')[1];
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
console.log(`🌐 Glyphenge Service: ${glyphengeServiceUrl}\n`);

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

    // 2. Send to Glyphenge service to create BDO
    console.log('📦 Sending to Glyphenge service...');

    const username = linktreeUrl.split('/').pop();

    const glyphengePayload = {
      title: `${username}'s Links`,
      links: links,
      source: 'linktree',
      sourceUrl: linktreeUrl
    };

    const response = await fetch(`${glyphengeServiceUrl}/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(glyphengePayload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Glyphenge service error: ${errorText}`);
    }

    const result = await response.json();

    console.log('✅ Glyphenge BDO created!\n');

    // Display results
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✨ Glyphenge BDO Created from Linktree!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('🎨 Emojicode:');
    console.log(`   ${result.emojicode}\n`);

    console.log('📋 Details:');
    console.log(`   UUID: ${result.uuid}`);
    console.log(`   PubKey: ${result.pubKey}`);
    console.log(`   Title: ${username}'s Links`);
    console.log(`   Links: ${links.length} imported\n`);

    console.log('🔗 View Your Tapestry:');
    console.log(`   ${result.url}\n`);

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
