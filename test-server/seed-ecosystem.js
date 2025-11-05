#!/usr/bin/env node

/**
 * Enhanced Seed Ecosystem Script
 *
 * Seeds the entire Planet Nine test ecosystem across multiple bases with:
 * - All example BDOs distributed by category mapping
 * - SVG generation for each BDO
 * - EmojiShortcodes for shareable content
 * - Multi-base federation support
 */

import sessionless from 'sessionless-node';
import fetch from 'node-fetch';
import crypto from 'crypto';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs/promises';

// ES module equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load mapping configuration
const mappingPath = path.join(__dirname, 'example-base-mapping.json');
const mappingData = JSON.parse(await fs.readFile(mappingPath, 'utf-8'));

// Generate test keys for seeding using crypto directly
const testKeys = {
  privateKey: crypto.randomBytes(32).toString('hex'),
  publicKey: 'test-public-key-' + crypto.randomBytes(16).toString('hex')
};

console.log('🌱 Starting enhanced ecosystem seeding...');
console.log('Using test key:', testKeys.publicKey);

// Helper function to create simple signature for testing
function createSignature(data, timestamp) {
  const message = `${data}-${timestamp}`;
  return crypto.createHash('sha256').update(message + testKeys.privateKey).digest('hex');
}

// Helper function to make request to BDO
async function bdoRequest(baseURL, endpoint, method, data = null) {
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
    const response = await fetch(`${baseURL}${endpoint}?${params}`);
    return response.json();
  } else {
    options.body = JSON.stringify({
      ...data,
      timestamp,
      signature,
      pubKey: testKeys.publicKey
    });
    const response = await fetch(`${baseURL}${endpoint}`, options);
    return response.json();
  }
}

// Module configuration (from server.js)
const moduleConfigs = [
  { dir: 'apothecary', file: 'apothecary.js', generators: ['generateCosmeticSVG', 'generateRemedySVG'], data: 'apothecaryPosts' },
  { dir: 'bundles', file: 'bundles.js', generators: ['generateBundleSVG'], data: 'bundlesPosts' },
  { dir: 'closet', file: 'closet.js', generators: ['generateClothingSVG'], data: 'closetPosts' },
  { dir: 'cookbook', file: 'cookbook.js', generators: ['generateRecipeSVG'], data: 'cookbookPosts' },
  { dir: 'events', file: 'events.js', generators: ['generateEventSVG'], data: 'events' },
  { dir: 'familiarPen', file: 'familiarPen.js', generators: ['generateFamiliarSVG'], data: 'familiarPenPosts' },
  { dir: 'gallery', file: 'gallery.js', generators: ['generateArtworkSVG', 'generateMarketplaceLogosSVG', 'generatePoliticalArtSVG'], data: 'galleryPosts' },
  { dir: 'games', file: 'games.js', generators: ['generateGameSVG', 'generateFTPSVG'], data: 'gamesPosts' },
  { dir: 'geometry', file: 'geometry.js', generators: ['generateEuclidPostulatesSVG', 'generateNonEuclideanSVG', 'generateGeneralRelativitySVG', 'generateGravitationalLensingSVG'], data: 'geometryPosts' },
  { dir: 'greenHouse', file: 'greenHouse.js', generators: ['generatePlantSVG'], data: 'greenHousePosts' },
  { dir: 'idothis', file: 'idothis.js', generators: ['generateIdothisBookNowSVG'], data: 'idothisPosts' },
  { dir: 'literary', file: 'literary.js', generators: ['generateBookTwoButtonSVG', 'generateLiteraryOneButtonSVG'], data: 'literaryPosts' },
  { dir: 'machinery', file: 'machinery.js', generators: ['generateMachinerySVG'], data: 'machineryPosts' },
  { dir: 'metallics', file: 'metallics.js', generators: ['generateGemstoneSVG', 'generateJewelrySVG'], data: 'metallicsPosts' },
  { dir: 'music', file: 'music-bdo.js', generators: ['generateMusicBDO', 'generateMirloBDO', 'generateBandcampBDO'], data: 'exampleMusicTracks' },
  { dir: 'network-topology', file: 'network-topology.js', generators: ['generateHubSpokeSVG', 'generateFederatedNetworkSVG', 'generateFFXIVServersSVG', 'generateOverlayNetworkSVG'], data: 'networkTopologyPosts' },
  { dir: 'oracular', file: 'oracular.js', generators: ['generateTarotSVG', 'generateAstrologySVG'], data: 'oracularPosts' },
  { dir: 'popups', file: 'popups.js', generators: ['generatePopupTwoButtonSVG', 'generateLocationViewSVG'], data: 'popupPosts' },
  { dir: 'simulations', file: 'simulations.js', generators: ['generateGalaxyCollisionSVG', 'generatePlanetNineSpaceshipSVG'], data: 'simulationsPosts' },
  { dir: 'trading-cards', file: 'trading-cards.js', generators: ['generateSTEMPioneerCardSVG'], data: 'tradingCardsPosts' },
  { dir: 'food-banks', file: 'food-banks.js', generators: ['generateFoodBankSVG', 'generateSNAPBenefitsSVG', 'generateSNAPProcessSVG'], data: 'foodBanksPosts' },
  { dir: 'social', file: 'social.js', generators: ['generateMarketplaceSVG', 'generateTravelingMerchantSVG'], data: 'socialPosts' },
  { dir: 'products', file: 'products.js', generators: ['generateProductSVG'], data: 'productsPosts' }
];

// Determine which base(s) a category should be seeded to
function getBasesForCategory(category) {
  const bases = [];

  // Check if it's an "all bases" category
  if (mappingData.allBases.categories.includes(category)) {
    return ['base1', 'base2', 'base3'];
  }

  // Find which base owns this category
  for (const [baseId, baseInfo] of Object.entries(mappingData.bases)) {
    if (baseInfo.categories.includes(category)) {
      bases.push(baseId);
    }
  }

  return bases;
}

// Check if category should have emojiShortcodes
function shouldHaveEmojiShortcode(category) {
  return mappingData.emojiShortcodes.categories.includes(category);
}

// Seed all examples to their designated bases
async function seedAllExamples() {
  console.log('\n📦 Loading and seeding all example modules...\n');

  const examplesDir = path.join(__dirname, '../../allyabase/deployment/docker/examples');
  const stats = {
    totalBDOs: 0,
    base1: 0,
    base2: 0,
    base3: 0,
    byCategory: {}
  };

  for (const config of moduleConfigs) {
    try {
      console.log(`\n📁 Processing category: ${config.dir}`);

      // Determine which bases this category goes to
      const targetBases = getBasesForCategory(config.dir);

      if (targetBases.length === 0) {
        console.log(`⏭️  Skipping ${config.dir} - not mapped to any base`);
        continue;
      }

      // Load the module
      const modulePath = path.join(examplesDir, config.dir, config.file);
      const module = await import('file://' + modulePath);
      const posts = module[config.data] || [];

      console.log(`   Found ${posts.length} posts`);
      console.log(`   Target bases: ${targetBases.join(', ')}`);

      stats.byCategory[config.dir] = 0;

      // Seed each post to its designated base(s)
      for (const post of posts) {
        for (const baseId of targetBases) {
          const baseInfo = mappingData.bases[baseId];
          const baseURL = baseInfo.url;

          // Try each generator until one works
          let svgContent = null;
          for (const generatorName of config.generators) {
            const generator = module[generatorName];
            if (generator) {
              try {
                const dummyPubKey = `example_${config.dir}_${post.id}`;
                const result = generator(post, dummyPubKey);
                if (result) {
                  svgContent = result;
                  break;
                }
              } catch (err) {
                // Generator not suitable for this post type, try next
              }
            }
          }

          if (!svgContent) {
            console.log(`   ⚠️  No SVG generated for ${post.id}`);
            continue;
          }

          // Create BDO data
          const bdoData = {
            type: config.dir,
            title: post.title || post.name || post.id,
            description: post.description || post.subtitle || '',
            category: post.category || config.dir,
            svgContent: svgContent,
            created: new Date().toISOString(),
            ...post // Include all original post data
          };

          // For products, ensure price/payees structure is preserved
          if (config.dir === 'products') {
            bdoData.price = post.price;
            bdoData.currency = post.currency;
            bdoData.creator = post.creator;
            bdoData.payees = post.payees || [];
          }

          // Generate emojiShortcode if appropriate
          const metadata = {
            type: config.dir,
            public: true,
            description: `${config.dir}: ${post.title || post.name || post.id}`
          };

          if (shouldHaveEmojiShortcode(config.dir) && post.emojiShortcode) {
            metadata.emojiShortcode = post.emojiShortcode;
          }

          // Create public BDO
          try {
            const result = await bdoRequest(baseURL, '/bdo', 'POST', {
              object: bdoData,
              metadata: metadata
            });

            if (result.uuid || result.pubKey) {
              console.log(`   ✅ [${baseId.toUpperCase()}] ${post.title || post.name || post.id}`);
              if (metadata.emojiShortcode) {
                console.log(`      🎨 ${metadata.emojiShortcode}`);
              }
              stats.totalBDOs++;
              stats[baseId]++;
              stats.byCategory[config.dir]++;
            } else {
              console.log(`   ❌ [${baseId.toUpperCase()}] Failed: ${post.title || post.name || post.id}`);
            }
          } catch (error) {
            console.error(`   ❌ [${baseId.toUpperCase()}] Error creating BDO: ${error.message}`);
          }
        }
      }

    } catch (error) {
      console.error(`❌ Error processing ${config.dir}:`, error.message);
    }
  }

  return stats;
}

// Main seeding function
async function main() {
  try {
    console.log('🚀 Starting enhanced ecosystem seeding process...\n');
    console.log('📍 Target bases:');
    for (const [baseId, baseInfo] of Object.entries(mappingData.bases)) {
      console.log(`   ${baseId.toUpperCase()}: ${baseInfo.name} (${baseInfo.url})`);
      console.log(`      ${baseInfo.baseEmoji} - ${baseInfo.categories.length} categories`);
    }
    console.log(`\n🌐 Shared across all bases: ${mappingData.allBases.categories.join(', ')}`);

    const stats = await seedAllExamples();

    console.log('\n\n🎉 Ecosystem seeding completed!');
    console.log('\n📊 Summary:');
    console.log(`   Total BDOs created: ${stats.totalBDOs}`);
    console.log(`   BASE1: ${stats.base1} BDOs`);
    console.log(`   BASE2: ${stats.base2} BDOs`);
    console.log(`   BASE3: ${stats.base3} BDOs`);

    console.log('\n📁 By category:');
    for (const [category, count] of Object.entries(stats.byCategory)) {
      if (count > 0) {
        console.log(`   ${category}: ${count} BDOs`);
      }
    }

    console.log('\n🎯 Next steps:');
    console.log('   1. Start the test server: npm start');
    console.log('   2. Navigate to http://localhost:3456');
    console.log('   3. Use The Advancement extension to interact with seeded BDOs');
    console.log('   4. Try teleporting content from different bases!');

  } catch (error) {
    console.error('❌ Ecosystem seeding failed:', error);
    process.exit(1);
  }
}

// Run the seeding
main();
