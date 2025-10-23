#!/usr/bin/env node
/**
 * Debug Album Page Structure
 * Helps identify the three-dot menu and track list structure
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const ARTIST_SLUG = 'bury-the-needle';
const ALBUM_SLUG = 'bury-the-needle'; // First album
const MIRLO_BASE_URL = 'https://mirlo.space';

async function debugAlbumPage() {
  console.log('🔍 Debugging album page structure...\n');

  const browser = await puppeteer.launch({
    headless: false, // Show browser so we can see what happens
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });

  const url = `${MIRLO_BASE_URL}/${ARTIST_SLUG}/release/${ALBUM_SLUG}`;
  console.log(`📡 Loading: ${url}\n`);

  await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
  await delay(3000);

  // Take screenshot before clicking
  await page.screenshot({ path: 'album-before.png', fullPage: true });
  console.log('📸 Screenshot saved: album-before.png');

  // Look for three-dot menu / disclosure buttons
  const pageData = await page.evaluate(() => {
    const data = {
      title: document.title,
      buttons: Array.from(document.querySelectorAll('button')).map(btn => ({
        text: btn.textContent.trim(),
        ariaLabel: btn.getAttribute('aria-label'),
        className: btn.className,
        html: btn.outerHTML.substring(0, 200)
      })),
      lists: Array.from(document.querySelectorAll('ol, ul')).map(list => ({
        tag: list.tagName,
        itemCount: list.querySelectorAll('li').length,
        firstItemText: list.querySelector('li')?.textContent.trim(),
        html: list.outerHTML.substring(0, 500)
      })),
      h2: Array.from(document.querySelectorAll('h2')).map(h => h.textContent.trim()),
      svg: Array.from(document.querySelectorAll('svg')).map(svg => ({
        ariaLabel: svg.getAttribute('aria-label'),
        className: svg.className.baseVal || svg.className,
        parent: svg.parentElement?.tagName
      }))
    };
    return data;
  });

  console.log('\n=== Buttons on page ===');
  pageData.buttons.forEach((btn, i) => {
    if (btn.text.includes('...') || btn.text.includes('⋮') || btn.ariaLabel?.includes('menu') || btn.ariaLabel?.includes('Menu')) {
      console.log(`\n🎯 POTENTIAL THREE-DOT MENU #${i}:`);
      console.log(`   Text: "${btn.text}"`);
      console.log(`   Aria-label: ${btn.ariaLabel}`);
      console.log(`   Class: ${btn.className}`);
      console.log(`   HTML: ${btn.html}`);
    }
  });

  console.log(`\n=== Lists on page: ${pageData.lists.length} ===`);
  pageData.lists.forEach((list, i) => {
    console.log(`\nList ${i + 1}: <${list.tag}> with ${list.itemCount} items`);
    console.log(`   First item: ${list.firstItemText}`);
  });

  console.log(`\n=== H2 headings: ${pageData.h2.length} ===`);
  pageData.h2.forEach(h => console.log(`   - ${h}`));

  // Save full data
  fs.writeFileSync('album-debug.json', JSON.stringify(pageData, null, 2));
  console.log('\n📊 Full data saved: album-debug.json');

  // Try to find and click disclosure buttons
  console.log('\n🔍 Looking for disclosure buttons...');

  const disclosureButtons = await page.$$('button, summary, [role="button"]');
  console.log(`Found ${disclosureButtons.length} interactive elements`);

  // Try clicking buttons that might reveal tracks
  for (let i = 0; i < Math.min(disclosureButtons.length, 20); i++) {
    const btnText = await page.evaluate(el => el.textContent.trim(), disclosureButtons[i]);
    const ariaExpanded = await page.evaluate(el => el.getAttribute('aria-expanded'), disclosureButtons[i]);

    if (btnText.includes('Track') || ariaExpanded === 'false' || btnText.length < 5) {
      console.log(`\n💡 Trying to click: "${btnText}" (aria-expanded: ${ariaExpanded})`);

      try {
        await disclosureButtons[i].click();
        await delay(1000);

        // Take screenshot after click
        await page.screenshot({ path: `album-after-click-${i}.png` });
        console.log(`   📸 Screenshot: album-after-click-${i}.png`);
      } catch (err) {
        console.log(`   ✗ Click failed: ${err.message}`);
      }
    }
  }

  console.log('\n✅ Debug complete! Check the screenshots and album-debug.json');
  console.log('Press Ctrl+C to close browser...');

  // Keep browser open for manual inspection
  await delay(60000);
  await browser.close();
}

debugAlbumPage().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
