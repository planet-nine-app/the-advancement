#!/usr/bin/env node
/**
 * Debug Single Track Structure
 * Helps identify where the actual track title is stored
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const ARTIST_SLUG = 'bury-the-needle';
const ALBUM_SLUG = 'bury-the-needle';
const MIRLO_BASE_URL = 'https://mirlo.space';

async function debugTrack() {
  console.log('🔍 Debugging single track structure...\n');

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });

  const url = `${MIRLO_BASE_URL}/${ARTIST_SLUG}/release/${ALBUM_SLUG}`;
  console.log(`📡 Loading: ${url}\n`);

  await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
  await delay(3000);

  // Extract detailed track structure
  const trackData = await page.evaluate(() => {
    const tracks = [];

    // Find all "Track options" buttons
    const trackButtons = Array.from(document.querySelectorAll('button[aria-label="Track options"]'));

    trackButtons.slice(0, 3).forEach((button, index) => {
      const trackInfo = {
        index: index + 1,
        buttonHTML: button.outerHTML.substring(0, 300),
        parentHTML: button.parentElement?.outerHTML.substring(0, 500),
        grandparentHTML: button.parentElement?.parentElement?.outerHTML.substring(0, 800)
      };

      // Try different container strategies
      let container = button.parentElement;
      while (container && container.querySelectorAll('button').length < 2) {
        container = container.parentElement;
      }

      if (container) {
        trackInfo.containerHTML = container.outerHTML.substring(0, 1500);
        trackInfo.containerText = container.textContent;

        // Get all children of container
        trackInfo.containerChildren = Array.from(container.children).map(child => ({
          tag: child.tagName,
          className: child.className,
          text: child.textContent.trim().substring(0, 200),
          html: child.outerHTML.substring(0, 300)
        }));

        // Look for all text-containing elements
        trackInfo.allTextElements = Array.from(container.querySelectorAll('*')).map(el => {
          const text = el.textContent.trim();
          if (text && text.length > 0 && text.length < 100 && !text.includes('Track options')) {
            return {
              tag: el.tagName,
              className: el.className,
              text: text,
              directText: Array.from(el.childNodes)
                .filter(n => n.nodeType === Node.TEXT_NODE)
                .map(n => n.textContent.trim())
                .filter(t => t.length > 0)
            };
          }
          return null;
        }).filter(Boolean);
      }

      tracks.push(trackInfo);
    });

    return tracks;
  });

  // Save detailed structure
  fs.writeFileSync('track-debug.json', JSON.stringify(trackData, null, 2));
  console.log('📊 Track structure saved: track-debug.json\n');

  // Print summary
  trackData.forEach((track, i) => {
    console.log(`=== Track ${i + 1} ===`);
    console.log(`Container text: ${track.containerText?.substring(0, 200)}`);
    console.log(`\nAll text elements:`);
    track.allTextElements?.forEach(el => {
      console.log(`  ${el.tag}.${el.className?.substring(0, 30)}: "${el.text}"`);
      if (el.directText && el.directText.length > 0) {
        console.log(`    Direct text: ${JSON.stringify(el.directText)}`);
      }
    });
    console.log('\n');
  });

  await browser.close();
  console.log('✅ Debug complete!');
}

debugTrack().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
