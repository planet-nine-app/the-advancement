#!/usr/bin/env node

const readline = require('readline');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Simple sessionless key generation (matching the test configs)
function generateSessionlessKeys() {
  const privateKey = crypto.randomBytes(32).toString('hex');
  // In production, this would use proper secp256k1 key derivation
  // For now, using a simple implementation matching test configs
  const pubKey = '02' + crypto.createHash('sha256').update(privateKey).digest('hex').substring(0, 62);

  return {
    pubKey,
    privateKey
  };
}

async function promptUser(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer);
    });
  });
}

async function configureOwner(options = {}) {
  console.log('\n=================================');
  console.log('Fedwiki Owner Configuration');
  console.log('=================================\n');

  const name = await promptUser('Wiki owner name (e.g., "john-doe"): ');
  const locationEmoji = await promptUser('Location emoji (3 emoji, e.g., "☮️🌙🎸"): ');
  const federationEmoji = await promptUser('Federation emoji (1 emoji, e.g., "💚"): ');

  let domainName = null;
  if (!options.skipDomain) {
    const domainResponse = await promptUser('Domain name (optional, press enter to skip): ');
    if (domainResponse.trim()) {
      domainName = domainResponse.trim();
    }
  }

  // Generate sessionless keys
  const keys = generateSessionlessKeys();

  const ownerData = {
    name,
    sessionlessKeys: {
      pubKey: keys.pubKey,
      privateKey: keys.privateKey
    },
    pubKey: keys.pubKey,
    locationEmoji,
    federationEmoji
  };

  if (domainName) {
    ownerData.domain = domainName;
  }

  const outputPath = path.join(__dirname, 'owner.json');
  fs.writeFileSync(outputPath, JSON.stringify(ownerData, null, 2));

  console.log('\n✅ Configuration saved to:', outputPath);
  console.log('\nOwner Details:');
  console.log('  Name:', name);
  console.log('  Location Emoji:', locationEmoji);
  console.log('  Federation Emoji:', federationEmoji);
  console.log('  Public Key:', keys.pubKey);
  if (domainName) {
    console.log('  Domain:', domainName);
  }
  console.log('\n');

  return ownerData;
}

if (require.main === module) {
  configureOwner()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Configuration failed:', err);
      process.exit(1);
    });
}

module.exports = { configureOwner };
