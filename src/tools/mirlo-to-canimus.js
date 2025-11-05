#!/usr/bin/env node
/**
 * Mirlo to Canimus Feed Converter
 *
 * Fetches artist data from Mirlo using Puppeteer and converts to Canimus feed format
 *
 * Usage: node mirlo-to-canimus.js <artist-slug> [output-file]
 * Example: node mirlo-to-canimus.js bury-the-needle canimus-feed.json
 *
 * Requirements:
 *   npm install puppeteer
 */

const fs = require('fs');
const path = require('path');

const MIRLO_BASE_URL = 'https://mirlo.space';
const ARTIST_SLUG = process.argv[2] || 'bury-the-needle';
const OUTPUT_FILE = process.argv[3] || 'canimus-feed.json';

/**
 * Delay helper
 */
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Fetch artist data from Mirlo using Puppeteer
 */
async function fetchMirloData(artistSlug) {
  let puppeteer;
  try {
    puppeteer = require('puppeteer');
  } catch (err) {
    console.error('Error: Puppeteer not installed');
    console.error('Run: npm install puppeteer');
    process.exit(1);
  }

  console.log(`\n🌐 Launching browser...`);
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process'
    ]
  }).catch(err => {
    console.error('Failed to launch browser:', err.message);
    throw err;
  });

  const page = await browser.newPage();

  // Set viewport and user agent for consistent rendering
  await page.setViewport({ width: 1920, height: 1080 });
  await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

  const artistUrl = `${MIRLO_BASE_URL}/${artistSlug}/releases`;
  console.log(`📡 Navigating to: ${artistUrl}`);

  try {
    const response = await page.goto(artistUrl, {
      waitUntil: 'networkidle2',
      timeout: 30000
    }).catch(err => {
      console.error('Navigation failed:', err.message);
      throw new Error(`Failed to load ${artistUrl}: ${err.message}`);
    });

    if (!response || !response.ok()) {
      throw new Error(`HTTP ${response?.status() || 'error'} when loading ${artistUrl}`);
    }

    console.log('⏳ Waiting for content to load...');

    // Wait for release links to render (Mirlo's actual structure)
    await page.waitForSelector('a[href*="/release/"]', {
      timeout: 10000
    }).catch(() => {
      console.log('⚠️  Could not find release links, continuing anyway...');
    });

    // Give extra time for dynamic content and images
    await delay(3000);

    console.log('🔍 Extracting artist and album data...\n');

    // Extract data from the page
    const data = await page.evaluate((baseUrl) => {
      const result = {
        artist: {
          name: '',
          slug: '',
          bio: '',
          image: ''
        },
        albums: []
      };

      // Extract artist name from h1
      const h1Elements = document.querySelectorAll('h1');
      for (const h1 of h1Elements) {
        const text = h1.textContent.trim();
        if (text && text.length > 0) {
          result.artist.name = text;
          break;
        }
      }

      // Extract artist avatar
      const artistAvatarEl = document.querySelector('img[alt*="Artist avatar"], img[alt*="artist avatar"]');
      if (artistAvatarEl) {
        result.artist.image = artistAvatarEl.src;
      }

      // Find all release links
      const releaseLinks = Array.from(document.querySelectorAll('a[href*="/release/"]'));

      // Group links by href (Mirlo has duplicate links for each album)
      const uniqueReleases = {};
      releaseLinks.forEach(link => {
        const href = link.href;
        const text = link.textContent.trim();

        if (href && !uniqueReleases[href]) {
          uniqueReleases[href] = { href, text };
        } else if (href && text && text.length > 0 && !uniqueReleases[href].text) {
          uniqueReleases[href].text = text;
        }
      });

      // Get all images to match with albums
      const images = Array.from(document.querySelectorAll('img'));

      // Process each unique release
      Object.values(uniqueReleases).forEach((release) => {
        if (!release.text || release.text.length === 0) return;

        const album = {
          title: release.text,
          slug: '',
          releaseDate: '',
          coverImage: '',
          description: '',
          genres: [],
          tracks: []
        };

        // Extract slug from URL
        const match = release.href.match(/\/release\/([^/?]+)/);
        if (match) {
          album.slug = match[1];
        }

        // Find cover image by matching alt text with album title
        const coverImg = images.find(img =>
          img.alt && img.alt.includes(album.title)
        );
        if (coverImg) {
          album.coverImage = coverImg.src;
        }

        result.albums.push(album);
      });

      return result;
    }, MIRLO_BASE_URL);

    // Fill in slug from URL if not found
    data.artist.slug = artistSlug;

    console.log(`✅ Found artist: ${data.artist.name || artistSlug}`);
    console.log(`✅ Found ${data.albums.length} album(s)\n`);

    // Now visit each album page to get tracks
    console.log('🎵 Fetching track data from album pages...\n');

    for (let i = 0; i < data.albums.length; i++) {
      const album = data.albums[i];
      console.log(`   ${i + 1}. ${album.title}...`);

      try {
        const albumUrl = `${MIRLO_BASE_URL}/${artistSlug}/release/${album.slug}`;
        await page.goto(albumUrl, {
          waitUntil: 'networkidle2',
          timeout: 30000
        });

        await delay(2000);

        // Extract track data - tracks are already visible!
        const tracks = await page.evaluate(() => {
          const trackList = [];

          // Find all "Track options" buttons - each represents one track
          const trackOptionButtons = Array.from(document.querySelectorAll('button[aria-label="Track options"]'));

          trackOptionButtons.forEach((button, index) => {
            // The button's parent or ancestor contains the track info
            let trackContainer = button.closest('tr, div[class*="track"], li, [role="listitem"]');
            if (!trackContainer) {
              trackContainer = button.parentElement;
              while (trackContainer && trackContainer.querySelectorAll('button').length < 2) {
                trackContainer = trackContainer.parentElement;
              }
            }

            if (!trackContainer) return;

            const track = {
              id: `track-${index + 1}`,
              title: '',
              duration: 0,
              audioUrl: ''
            };

            // Look for the specific div that contains the track title
            // Based on debug output: DIV.css-18e58a9 contains the title
            const titleDiv = trackContainer.querySelector('div[class*="css-18e58a9"], div[class*="css-1ves5i"] > div:first-child');

            if (titleDiv) {
              // Get direct text content (not including children)
              const directText = Array.from(titleDiv.childNodes)
                .filter(node => node.nodeType === Node.TEXT_NODE)
                .map(node => node.textContent.trim())
                .filter(text => text.length > 0)
                .join(' ');

              if (directText) {
                track.title = directText;
              } else {
                // Fallback: get text content and remove duration
                let text = titleDiv.textContent.trim();
                // Remove duration pattern if present
                text = text.replace(/\d+:\d{2}$/, '').trim();
                track.title = text;
              }
            }

            // If we didn't find a title yet, try alternative methods
            if (!track.title) {
              // Look for any div that contains the title (excluding duration)
              const allDivs = Array.from(trackContainer.querySelectorAll('div'));
              for (const div of allDivs) {
                const text = div.textContent.trim();
                // Check if this might be a title (not just a number, not a duration)
                if (text &&
                    text.length > 0 &&
                    text.length < 200 &&
                    !text.match(/^\d+$/) && // Not just a number
                    !text.match(/^\d+:\d{2}$/) && // Not just a duration
                    !text.includes('Track options') &&
                    !text.includes('Play')) {

                  // Get direct text only (not including nested elements)
                  const directText = Array.from(div.childNodes)
                    .filter(node => node.nodeType === Node.TEXT_NODE)
                    .map(node => node.textContent.trim())
                    .filter(t => t.length > 0)
                    .join(' ');

                  if (directText && directText.length > 0 && !directText.match(/^\d+:\d{2}$/)) {
                    track.title = directText;
                    break;
                  }
                }
              }
            }

            // Look for duration pattern (MM:SS or M:SS)
            const durationDiv = trackContainer.querySelector('div[class*="css-1pamk5i"]');
            if (durationDiv) {
              const durationText = durationDiv.textContent.trim();
              const durationMatch = durationText.match(/(\d+):(\d{2})/);
              if (durationMatch) {
                const minutes = parseInt(durationMatch[1], 10);
                const seconds = parseInt(durationMatch[2], 10);
                track.duration = minutes * 60 + seconds;
              }
            }

            // Try to find audio element
            const audio = trackContainer.querySelector('audio, audio source');
            if (audio) {
              track.audioUrl = audio.src || audio.querySelector('source')?.src || '';
            }

            // Use track number as fallback if no title found
            if (!track.title || track.title.length === 0) {
              track.title = `Track ${index + 1}`;
            }

            trackList.push(track);
          });

          return trackList;
        });

        album.tracks = tracks;
        console.log(`      ✓ Found ${tracks.length} track(s)`);

      } catch (error) {
        console.log(`      ✗ Error fetching tracks: ${error.message}`);
      }

      await delay(1000);
    }

    await browser.close();

    console.log(`\n✅ Total tracks found: ${data.albums.reduce((sum, a) => sum + a.tracks.length, 0)}\n`);

    return data;

  } catch (error) {
    await browser.close();
    throw error;
  }
}

/**
 * Convert Mirlo data to Canimus feed format
 */
function convertToCanimus(mirloData) {
  const { artist, albums } = mirloData;

  const artistName = artist.name || 'Unknown Artist';

  const feed = {
    type: 'feed',
    name: `${artistName} - Music Feed`,
    url: `${MIRLO_BASE_URL}/${artist.slug}/releases`,
    'updated-date': new Date().toISOString(),
    description: artist.bio || `Music releases from ${artistName} on Mirlo`,
    links: [
      {
        rel: 'self',
        type: 'application/canimus+json',
        href: `${MIRLO_BASE_URL}/${artist.slug}/feed.json`
      },
      {
        rel: 'alternate',
        type: 'text/html',
        href: `${MIRLO_BASE_URL}/${artist.slug}/releases`
      }
    ],
    children: [
      {
        type: 'artist',
        uid: artist.slug,
        name: artistName,
        url: `${MIRLO_BASE_URL}/${artist.slug}`,
        ...(artist.image && {
          images: [{
            src: artist.image,
            width: 600,
            height: 600
          }]
        }),
        ...(artist.bio && { summary: artist.bio }),
        children: albums.map(album => {
          const albumData = {
            type: 'album',
            uid: album.slug,
            name: album.title,
            artist: artistName,
            url: `${MIRLO_BASE_URL}/${artist.slug}/release/${album.slug}`,
            ...(album.releaseDate && { 'release-date': album.releaseDate }),
            ...(album.coverImage && {
              images: [{
                src: album.coverImage,
                width: 600,
                height: 600
              }]
            }),
            ...(album.genres && album.genres.length > 0 && { genre: album.genres }),
            ...(album.description && { summary: album.description })
          };

          // Add tracks if available
          if (album.tracks && album.tracks.length > 0) {
            albumData.children = album.tracks.map(track => ({
              type: 'track',
              uid: track.id,
              name: track.title,
              artist: artistName,
              ...(track.duration && { duration: track.duration }),
              url: `${MIRLO_BASE_URL}/${artist.slug}/release/${album.slug}#${track.id}`,
              ...(track.audioUrl && {
                media: [{
                  type: 'audio/mpeg',
                  src: track.audioUrl
                }]
              })
            }));
          }

          return albumData;
        })
      }
    ]
  };

  return feed;
}

// Main execution
async function main() {
  try {
    console.log('╔════════════════════════════════════════╗');
    console.log('║  Mirlo → Canimus Feed Converter       ║');
    console.log('╚════════════════════════════════════════╝');

    if (!ARTIST_SLUG) {
      console.error('\n❌ Error: Artist slug required');
      console.error('Usage: node mirlo-to-canimus.js <artist-slug> [output-file]');
      console.error('Example: node mirlo-to-canimus.js bury-the-needle');
      process.exit(1);
    }

    console.log(`\n🎵 Artist: ${ARTIST_SLUG}`);
    console.log(`📁 Output: ${OUTPUT_FILE}`);

    // Fetch data from Mirlo
    const mirloData = await fetchMirloData(ARTIST_SLUG);

    if (!mirloData.albums || mirloData.albums.length === 0) {
      console.log('\n⚠️  Warning: No albums found!');
      console.log('This could mean:');
      console.log('  1. The page structure has changed');
      console.log('  2. The artist has no releases');
      console.log('  3. The page hasn\'t fully loaded');
      console.log('\nSaving empty feed anyway...');
    }

    // Convert to Canimus format
    console.log('\n🔄 Converting to Canimus format...');
    const canimusFeed = convertToCanimus(mirloData);

    // Ensure output directory exists
    const outputDir = path.dirname(OUTPUT_FILE);
    if (outputDir && outputDir !== '.') {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // Write feed to file
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(canimusFeed, null, 2));

    console.log(`\n✅ Feed created successfully!`);
    console.log(`📄 File: ${OUTPUT_FILE}`);
    console.log(`📊 Size: ${(fs.statSync(OUTPUT_FILE).size / 1024).toFixed(2)} KB`);

    // Summary
    console.log('\n📈 Summary:');
    console.log(`   Artist: ${canimusFeed.children[0].name}`);
    console.log(`   Albums: ${canimusFeed.children[0].children.length}`);

    let totalTracks = 0;
    canimusFeed.children[0].children.forEach(album => {
      const trackCount = album.children ? album.children.length : 0;
      totalTracks += trackCount;
      console.log(`     - ${album.name} (${trackCount} tracks)`);
    });
    console.log(`   Total Tracks: ${totalTracks}`);

    console.log('\n🎉 Done!\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('\nStack trace:');
    console.error(error.stack);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { fetchMirloData, convertToCanimus };
