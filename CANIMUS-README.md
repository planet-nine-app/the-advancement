# Canimus Feed for Bury the Needle

This directory contains a **Canimus** feed implementation for the artist "Bury the Needle" from Mirlo.

## What is Canimus?

[Canimus](https://github.com/PlaidWeb/Canimus) is a syndication format for federated music discovery - like RSS for music. It enables:

- **Platform-agnostic** music distribution
- **Decentralized** streaming without corporate platforms
- **Direct support** for independent musicians
- **Open standards** for music discovery

## Files Created

### 1. `canimus-feed.json`
The main Canimus feed file following the official specification:

```json
{
  "type": "feed",
  "name": "Bury the Needle - Music Feed",
  "url": "https://mirlo.space/bury-the-needle/releases",
  "children": [
    {
      "type": "artist",
      "name": "Bury the Needle",
      "children": [
        {
          "type": "album",
          "name": "Album Title",
          "children": [
            {
              "type": "track",
              "name": "Track Title",
              "media": [...]
            }
          ]
        }
      ]
    }
  ]
}
```

### 2. `canimus-discovery.html`
HTML page demonstrating proper Canimus feed discovery:

- Includes `<link rel="alternate">` tags for feed discovery
- Documentation for developers and listeners
- Example of how to implement on a website

### 3. `src/tools/mirlo-to-canimus.js`
Conversion tool (template) for fetching Mirlo data and converting to Canimus format:

```bash
node src/tools/mirlo-to-canimus.js bury-the-needle
```

**Note**: Currently a template - needs actual Mirlo API endpoints once available.

## How to Populate with Real Data

### Option 1: Manual Entry

1. Visit https://mirlo.space/bury-the-needle/releases
2. For each album, copy:
   - Album title, release date, cover image URL
   - Track titles, durations, audio URLs
3. Update `canimus-feed.json` following the template structure

### Option 2: Mirlo API (when available)

If Mirlo provides a public API, update `src/tools/mirlo-to-canimus.js`:

```javascript
async function fetchMirloData(artistSlug) {
  const response = await fetch(`https://mirlo.space/api/artists/${artistSlug}`);
  const data = await response.json();
  return data;
}
```

### Option 3: Web Scraping

Since Mirlo requires JavaScript, you could use a headless browser:

```javascript
const puppeteer = require('puppeteer');

async function scrapeMirloPage(artistSlug) {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto(`https://mirlo.space/${artistSlug}/releases`);

  const albums = await page.evaluate(() => {
    // Extract album data from DOM
    // Return structured data
  });

  await browser.close();
  return albums;
}
```

## Canimus Feed Structure

Based on the [official spec](https://github.com/PlaidWeb/Canimus/blob/main/feed.md):

### Required Fields (all entities)
- `type` - Entity type (feed, artist, album, track)
- At least one of: `url` or `uid`

### Common Fields
- `name` - Human-readable title
- `url` - Web URL for the entity
- `release-date` - ISO 8601 date
- `images` - Array of image objects
- `summary` / `description` - Text descriptions
- `children` - Nested entities

### Track-specific Fields
- `media` - Array of audio sources (required)
  - `type` - MIME type (audio/mpeg, audio/ogg, etc.)
  - `src` - Audio file URL
- `duration` - Length in seconds
- `lyrics` - Song lyrics (optional)

### Album-specific Fields
- `artist` - Artist name(s)
- `genre` - Array of genre strings

## Feed Discovery

### HTML Link Tag
```html
<link rel="alternate"
      type="application/canimus+json"
      title="Artist Music Feed"
      href="/feed.json">
```

### HTTP Header
```
Link: </feed.json>; rel="alternate"; type="application/canimus+json"
```

## Usage Examples

### Subscribe in Music Player
1. Copy feed URL: `https://mirlo.space/bury-the-needle/feed.json`
2. Paste into Canimus-compatible music player
3. Stream music directly from the feed

### Embed in Website
```html
<!DOCTYPE html>
<html>
<head>
    <link rel="alternate"
          type="application/canimus+json"
          href="feed.json">
</head>
<body>
    <!-- Your content -->
</body>
</html>
```

### Parse Programmatically
```javascript
const response = await fetch('canimus-feed.json');
const feed = await response.json();

const artist = feed.children[0];
const albums = artist.children;

albums.forEach(album => {
  console.log(`Album: ${album.name}`);
  album.children.forEach(track => {
    console.log(`  Track: ${track.name} (${track.duration}s)`);
    console.log(`  Audio: ${track.media[0].src}`);
  });
});
```

## Integration with The Advancement

This Canimus feed could integrate with The Advancement in several ways:

1. **CarrierBag Music Collection**: Save tracks/albums to user's music collection
2. **MAGIC Protocol**: Cast spells to purchase albums using nineum
3. **BDO Storage**: Store album metadata as BDOs with emojicodes
4. **Cross-Platform Sync**: Sync music library across devices via Julia

## Next Steps

1. **Get Real Data**: Fetch actual album/track data from Mirlo
2. **Automate Updates**: Set up script to regenerate feed when new releases appear
3. **Host Feed**: Serve `canimus-feed.json` from public URL
4. **Test with Players**: Validate feed works with Canimus-compatible clients
5. **Add Features**:
   - Pagination for large catalogs
   - Playlists
   - Purchase links
   - Artist bio/links

## Resources

- **Canimus Spec**: https://github.com/PlaidWeb/Canimus
- **Mirlo Platform**: https://mirlo.space
- **Artist Page**: https://mirlo.space/bury-the-needle/releases
- **Mirlo GitHub**: https://github.com/funmusicplace/mirlo

## License

This implementation follows the Canimus open specification. Artist content belongs to Bury the Needle.
