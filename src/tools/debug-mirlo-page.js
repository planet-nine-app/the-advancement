#!/usr/bin/env node
/**
 * Debug Mirlo Page Structure
 *
 * Takes a screenshot and dumps the HTML structure to help identify selectors
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

const ARTIST_SLUG = process.argv[2] || 'bury-the-needle';
const MIRLO_BASE_URL = 'https://mirlo.space';

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function debugPage() {
  console.log('🔍 Debugging Mirlo page structure...\n');

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage'
    ]
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

  const url = `${MIRLO_BASE_URL}/${ARTIST_SLUG}/releases`;
  console.log(`📡 Loading: ${url}\n`);

  await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
  await delay(3000);

  // Take screenshot
  const screenshotPath = `mirlo-debug-${ARTIST_SLUG}.png`;
  await page.screenshot({ path: screenshotPath, fullPage: true });
  console.log(`📸 Screenshot saved: ${screenshotPath}`);

  // Get page structure
  const pageData = await page.evaluate(() => {
    const data = {
      title: document.title,
      url: window.location.href,
      h1: Array.from(document.querySelectorAll('h1')).map(el => el.textContent.trim()),
      h2: Array.from(document.querySelectorAll('h2')).map(el => el.textContent.trim()),
      h3: Array.from(document.querySelectorAll('h3')).map(el => el.textContent.trim()),
      links: Array.from(document.querySelectorAll('a[href*="release"]')).map(el => ({
        text: el.textContent.trim(),
        href: el.href
      })),
      images: Array.from(document.querySelectorAll('img')).map(el => ({
        alt: el.alt,
        src: el.src,
        parent: el.parentElement?.tagName
      })),
      dataTestIds: Array.from(document.querySelectorAll('[data-testid]')).map(el => ({
        testId: el.getAttribute('data-testid'),
        tag: el.tagName,
        text: el.textContent.trim().substring(0, 100)
      })),
      articles: Array.from(document.querySelectorAll('article')).map(el => ({
        html: el.outerHTML.substring(0, 500)
      })),
      divs: Array.from(document.querySelectorAll('div[class*="release"], div[class*="album"], div[class*="track"]')).map(el => ({
        className: el.className,
        html: el.outerHTML.substring(0, 500)
      }))
    };

    return data;
  });

  // Save HTML
  const html = await page.content();
  const htmlPath = `mirlo-debug-${ARTIST_SLUG}.html`;
  fs.writeFileSync(htmlPath, html);
  console.log(`📄 HTML saved: ${htmlPath}`);

  // Save structured data
  const dataPath = `mirlo-debug-${ARTIST_SLUG}.json`;
  fs.writeFileSync(dataPath, JSON.stringify(pageData, null, 2));
  console.log(`📊 Page data saved: ${dataPath}\n`);

  // Print summary
  console.log('=== Page Summary ===');
  console.log(`Title: ${pageData.title}`);
  console.log(`URL: ${pageData.url}`);
  console.log(`\nHeadings (h1): ${pageData.h1.length}`);
  pageData.h1.forEach(text => console.log(`  - ${text}`));
  console.log(`\nHeadings (h2): ${pageData.h2.length}`);
  pageData.h2.slice(0, 10).forEach(text => console.log(`  - ${text}`));
  console.log(`\nRelease links: ${pageData.links.length}`);
  pageData.links.slice(0, 10).forEach(link => console.log(`  - ${link.text}`));
  console.log(`\nImages: ${pageData.images.length}`);
  console.log(`Data-testid elements: ${pageData.dataTestIds.length}`);
  console.log(`Articles: ${pageData.articles.length}`);
  console.log(`Release/Album divs: ${pageData.divs.length}`);

  await browser.close();
  console.log('\n✅ Debug complete!');
}

debugPage().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
