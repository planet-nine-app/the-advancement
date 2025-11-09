#!/usr/bin/env node

/**
 * Glyphenge - Planet Nine's Mystical Link Tapestry
 *
 * Weaves user's links into beautiful runic SVG layouts
 * Public access via emojicode - no authentication required for viewers
 *
 * Enchantment Flow:
 * 1. User casts Glyphenge enchantment via The Enchantment Emporium
 * 2. Enchanted BDO made public → generates emojicode rune
 * 3. Anyone can view the tapestry: glyphenge?emojicode=😀🔗💎🌟...
 * 4. Glyphenge weaves links from BDO into mystical patterns
 */

import express from 'express';
import fountLib from 'fount-js';
import bdoLib from 'bdo-js';
import sessionless from 'sessionless-node';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3010;

// Configuration
const FOUNT_BASE_URL = process.env.FOUNT_BASE_URL || 'https://plr.allyabase.com/plugin/allyabase/fount/';
const BDO_BASE_URL = process.env.BDO_BASE_URL || 'https://plr.allyabase.com/plugin/allyabase/bdo/';

// Configure SDKs
fountLib.baseURL = FOUNT_BASE_URL.endsWith('/') ? FOUNT_BASE_URL : `${FOUNT_BASE_URL}/`;
bdoLib.baseURL = BDO_BASE_URL.endsWith('/') ? BDO_BASE_URL : `${BDO_BASE_URL}/`;

console.log('✨ Glyphenge - Mystical Link Tapestry');
console.log('====================================');
console.log(`📍 Fount URL: ${fountLib.baseURL}`);
console.log(`📍 BDO URL: ${bdoLib.baseURL}`);

// Middleware
app.use(express.static(join(__dirname, 'public')));
app.use(express.json());

/**
 * Main route - Displays user's links
 *
 * Query params (Method 1 - Emojicode):
 * - emojicode: 8-emoji identifier for Glyphenge BDO
 *
 * Query params (Method 2 - Legacy Authentication):
 * - pubKey: User's public key
 * - timestamp: Request timestamp
 * - signature: Sessionless signature (timestamp + pubKey)
 */
app.get('/', async (req, res) => {
    try {
        const { emojicode, pubKey, timestamp, signature } = req.query;

        let links = [];
        let userName = 'Anonymous';
        let authenticated = false;

        // Method 1: Fetch by emojicode (PUBLIC - no auth required)
        if (emojicode) {
            console.log(`😀 Fetching Glyphenge by emojicode: ${emojicode}`);

            try {
                // Fetch Glyphenge BDO by emojicode
                const linkHubBDO = await bdoLib.getBDOByEmojicode(emojicode);

                console.log('📦 Glyphenge BDO fetched:', JSON.stringify(linkHubBDO).substring(0, 200));

                // Extract links from BDO data
                const bdoData = linkHubBDO.bdo || linkHubBDO;
                if (bdoData.links && Array.isArray(bdoData.links)) {
                    links = bdoData.links;
                    console.log(`🔗 Found ${links.length} links in Glyphenge BDO`);
                } else {
                    console.log('⚠️ No links array found in Glyphenge BDO');
                }

                // Get user name from BDO
                userName = bdoData.title || bdoData.name || 'My Links';
                authenticated = false; // Public access via emojicode

            } catch (error) {
                console.error('❌ Failed to fetch Glyphenge BDO by emojicode:', error.message);
                // Continue with empty links array
            }
        }
        // Method 2: Legacy authentication (for backward compatibility)
        else if (pubKey && timestamp && signature) {
            console.log(`🔐 Authenticating request for pubKey: ${pubKey.substring(0, 16)}...`);

            // Verify signature
            const message = timestamp + pubKey;
            const isValid = sessionless.verifySignature(signature, message, pubKey);

            if (isValid) {
                console.log('✅ Signature valid, fetching user BDO...');
                authenticated = true;

                try {
                    // Fetch user's Fount BDO (which contains carrierBag)
                    const userBDO = await fountLib.getBDO(pubKey);

                    console.log('📦 User BDO fetched:', JSON.stringify(userBDO).substring(0, 200));

                    // Extract carrierBag from BDO
                    const bdo = userBDO.bdo || userBDO;
                    const carrierBag = bdo.carrierBag || bdo.data?.carrierBag;

                    if (carrierBag && carrierBag.links) {
                        links = carrierBag.links;
                        console.log(`🔗 Found ${links.length} links in carrierBag`);
                    } else {
                        console.log('⚠️ No links collection found in carrierBag');
                    }

                    // Try to get user name from BDO
                    userName = bdo.name || bdo.title || 'My Links';

                } catch (error) {
                    console.error('❌ Failed to fetch user BDO:', error.message);
                    // Continue with empty links array
                }
            } else {
                console.log('❌ Invalid signature');
            }
        } else {
            console.log('ℹ️ No emojicode or authentication provided, showing demo');
        }

        // If no links, show demo links
        if (links.length === 0) {
            links = getDemoLinks();
            userName = 'Demo Links';
        }

        // Limit to 20 links
        const displayLinks = links.slice(0, 20);

        // Generate HTML page
        const html = generateGlyphengePage(displayLinks, userName, authenticated, pubKey);

        res.send(html);

    } catch (error) {
        console.error('❌ Server error:', error);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Glyphenge Error</title>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        min-height: 100vh;
                        margin: 0;
                        padding: 20px;
                    }
                    .error {
                        background: rgba(255,255,255,0.1);
                        padding: 40px;
                        border-radius: 20px;
                        text-align: center;
                    }
                </style>
            </head>
            <body>
                <div class="error">
                    <h1>⚠️ Error</h1>
                    <p>${error.message}</p>
                </div>
            </body>
            </html>
        `);
    }
});

/**
 * Generate the main Glyphenge HTML page
 */
function generateGlyphengePage(links, userName, authenticated, pubKey) {
    const linkCount = links.length;
    const svgTemplate = chooseSVGTemplate(linkCount);

    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${userName} - Glyphenge</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 40px 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .header {
            text-align: center;
            margin-bottom: 40px;
        }

        .header h1 {
            color: white;
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-shadow: 0 2px 10px rgba(0,0,0,0.2);
        }

        .header .badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 10px;
        }

        .links-container {
            max-width: 600px;
            width: 100%;
            margin-bottom: 40px;
        }

        .link-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 15px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
            cursor: pointer;
            text-decoration: none;
            display: block;
        }

        .link-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 30px rgba(0,0,0,0.15);
        }

        .link-card .title {
            font-size: 1.2rem;
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
        }

        .link-card .url {
            font-size: 0.9rem;
            color: #666;
            word-break: break-all;
        }

        .svg-container {
            max-width: 800px;
            width: 100%;
            margin-bottom: 40px;
            background: white;
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }

        .cta-container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            border-radius: 20px;
            padding: 40px;
            max-width: 600px;
            width: 100%;
            backdrop-filter: blur(10px);
        }

        .cta-container h2 {
            color: white;
            margin-bottom: 20px;
            font-size: 1.8rem;
        }

        .cta-container p {
            color: rgba(255,255,255,0.9);
            margin-bottom: 25px;
            font-size: 1.1rem;
            line-height: 1.6;
        }

        .cta-button {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 15px 40px;
            border-radius: 30px;
            text-decoration: none;
            font-weight: 600;
            font-size: 1.1rem;
            display: inline-block;
            transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 4px 20px rgba(16, 185, 129, 0.3);
        }

        .cta-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 30px rgba(16, 185, 129, 0.4);
        }

        .footer {
            margin-top: 40px;
            text-align: center;
            color: rgba(255,255,255,0.7);
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>${userName}</h1>
        ${authenticated ? '<div class="badge">🔐 Authenticated</div>' : '<div class="badge">👁️ Demo Mode</div>'}
    </div>

    <div class="svg-container">
        ${svgTemplate(links)}
    </div>

    <div class="cta-container">
        <h2>✨ Weave Your Own Glyphenge</h2>
        <p>Cast the Glyphenge enchantment to create your mystical link tapestry. Visit The Enchantment Emporium in The Advancement app.</p>
        <a href="#purchase" class="cta-button" onclick="handlePurchase()">
            Visit The Enchantment Emporium
        </a>
        <p style="font-size: 0.9rem; margin-top: 20px; opacity: 0.8;">
            ✨ Privacy-first • 🔐 Cryptographically secure • 🎨 Mystically beautiful
        </p>
    </div>

    <div class="footer">
        <p>Woven by <strong>Planet Nine</strong></p>
        <p style="margin-top: 5px;">The Enchantment Emporium • Glyphenge Tapestries</p>
    </div>

    <script>
        function handlePurchase() {
            // TODO: Implement Enchantment Emporium integration
            alert('Visit The Enchantment Emporium in The Advancement app to cast the Glyphenge enchantment!');
            console.log('Redirecting to Enchantment Emporium');

            // Future implementation:
            // 1. Deep link to The Advancement app
            // 2. Open Enchantment Emporium
            // 3. Show Glyphenge enchantment
            // 4. Guide user through enchantment casting
        }

        // Make links clickable
        document.querySelectorAll('.link-card').forEach(card => {
            card.addEventListener('click', function(e) {
                const url = this.dataset.url;
                if (url) {
                    window.open(url, '_blank');
                }
            });
        });
    </script>
</body>
</html>`;
}

/**
 * Choose SVG template based on link count
 */
function chooseSVGTemplate(linkCount) {
    if (linkCount <= 6) {
        return generateCompactSVG;
    } else if (linkCount <= 13) {
        return generateGridSVG;
    } else {
        return generateDenseSVG;
    }
}

/**
 * Template 1: Compact layout (1-6 links)
 * Large cards, vertical stack
 */
function generateCompactSVG(links) {
    const height = Math.max(400, links.length * 110 + 60);

    const linkElements = links.map((link, index) => {
        const y = 60 + (index * 110);
        const title = escapeXML(link.title || 'Untitled');
        const url = escapeXML(link.url || '#');
        const truncatedTitle = title.length > 30 ? title.substring(0, 30) + '...' : title;

        // Random gradient for each link
        const gradients = [
            ['#10b981', '#059669'],
            ['#3b82f6', '#2563eb'],
            ['#8b5cf6', '#7c3aed'],
            ['#ec4899', '#db2777'],
            ['#f59e0b', '#d97706'],
            ['#ef4444', '#dc2626']
        ];
        const gradient = gradients[index % gradients.length];
        const gradId = `grad${index}`;

        return `
        <defs>
            <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
                <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
            </linearGradient>
        </defs>

        <a href="${url}" target="_blank">
            <rect x="50" y="${y}" width="600" height="90" rx="15" fill="url(#${gradId})" opacity="0.9"/>
            <text x="90" y="${y + 40}" fill="white" font-size="20" font-weight="bold">${truncatedTitle}</text>
            <text x="90" y="${y + 65}" fill="rgba(255,255,255,0.8)" font-size="14">🔗 Tap to open</text>
            <text x="600" y="${y + 50}" fill="white" font-size="30">→</text>
        </a>`;
    }).join('\n');

    return `
<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="700" height="${height}" fill="#f9fafb"/>

    <text x="350" y="35" fill="#1f2937" font-size="24" font-weight="bold" text-anchor="middle">
        My Links
    </text>

    ${linkElements}
</svg>`;
}

/**
 * Template 2: Grid layout (7-13 links)
 * 2-column grid with medium cards
 */
function generateGridSVG(links) {
    const rows = Math.ceil(links.length / 2);
    const height = Math.max(400, rows * 100 + 100);

    const linkElements = links.map((link, index) => {
        const col = index % 2;
        const row = Math.floor(index / 2);
        const x = col === 0 ? 40 : 370;
        const y = 80 + (row * 100);

        const title = escapeXML(link.title || 'Untitled');
        const url = escapeXML(link.url || '#');
        const truncatedTitle = title.length > 15 ? title.substring(0, 15) + '...' : title;

        const gradients = [
            ['#10b981', '#059669'],
            ['#3b82f6', '#2563eb'],
            ['#8b5cf6', '#7c3aed'],
            ['#ec4899', '#db2777'],
            ['#f59e0b', '#d97706'],
            ['#ef4444', '#dc2626']
        ];
        const gradient = gradients[index % gradients.length];
        const gradId = `grad${index}`;

        return `
        <defs>
            <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
                <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
            </linearGradient>
        </defs>

        <a href="${url}" target="_blank">
            <rect x="${x}" y="${y}" width="290" height="80" rx="12" fill="url(#${gradId})" opacity="0.9"/>
            <text x="${x + 20}" y="${y + 35}" fill="white" font-size="16" font-weight="bold">${truncatedTitle}</text>
            <text x="${x + 20}" y="${y + 55}" fill="rgba(255,255,255,0.8)" font-size="12">🔗 Click</text>
        </a>`;
    }).join('\n');

    return `
<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="700" height="${height}" fill="#f9fafb"/>

    <text x="350" y="40" fill="#1f2937" font-size="24" font-weight="bold" text-anchor="middle">
        My Links
    </text>

    ${linkElements}
</svg>`;
}

/**
 * Template 3: Dense layout (14-20 links)
 * 3-column grid with compact cards
 */
function generateDenseSVG(links) {
    const rows = Math.ceil(links.length / 3);
    const height = Math.max(400, rows * 80 + 100);

    const linkElements = links.map((link, index) => {
        const col = index % 3;
        const row = Math.floor(index / 3);
        const x = 30 + (col * 220);
        const y = 80 + (row * 80);

        const title = escapeXML(link.title || 'Untitled');
        const url = escapeXML(link.url || '#');
        const truncatedTitle = title.length > 12 ? title.substring(0, 12) + '...' : title;

        const gradients = [
            ['#10b981', '#059669'],
            ['#3b82f6', '#2563eb'],
            ['#8b5cf6', '#7c3aed'],
            ['#ec4899', '#db2777'],
            ['#f59e0b', '#d97706'],
            ['#ef4444', '#dc2626']
        ];
        const gradient = gradients[index % gradients.length];
        const gradId = `grad${index}`;

        return `
        <defs>
            <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
                <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
            </linearGradient>
        </defs>

        <a href="${url}" target="_blank">
            <rect x="${x}" y="${y}" width="190" height="65" rx="10" fill="url(#${gradId})" opacity="0.9"/>
            <text x="${x + 15}" y="${y + 30}" fill="white" font-size="14" font-weight="bold">${truncatedTitle}</text>
            <text x="${x + 15}" y="${y + 48}" fill="rgba(255,255,255,0.8)" font-size="11">🔗</text>
        </a>`;
    }).join('\n');

    return `
<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <rect width="700" height="${height}" fill="#f9fafb"/>

    <text x="350" y="40" fill="#1f2937" font-size="22" font-weight="bold" text-anchor="middle">
        My Links
    </text>

    ${linkElements}
</svg>`;
}

/**
 * Get demo links for unauthenticated users
 */
function getDemoLinks() {
    return [
        { title: 'GitHub', url: 'https://github.com/planet-nine-app' },
        { title: 'Planet Nine', url: 'https://planetnine.app' },
        { title: 'Documentation', url: 'https://docs.planetnine.app' },
        { title: 'Twitter', url: 'https://twitter.com/planetnine' },
        { title: 'Discord', url: 'https://discord.gg/planetnine' },
        { title: 'Blog', url: 'https://blog.planetnine.app' }
    ];
}

/**
 * Escape XML special characters
 */
function escapeXML(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

/**
 * POST /create - Create Glyphenge BDO
 *
 * Flow:
 * 1. Receive raw BDO data with links from client
 * 2. Generate composite SVG based on link count
 * 3. Add svgContent to BDO
 * 4. Forward complete BDO to BDO service
 * 5. Return emojicode to client
 *
 * Body:
 * {
 *   "title": "My Links",
 *   "links": [{"title": "...", "url": "..."}, ...],
 *   "source": "linktree" | "manual" (optional),
 *   "sourceUrl": "https://..." (optional)
 * }
 */
app.post('/create', async (req, res) => {
    try {
        console.log('🎨 Creating Glyphenge BDO...');

        const { title, links, source, sourceUrl } = req.body;

        // Validate input
        if (!links || !Array.isArray(links) || links.length === 0) {
            return res.status(400).json({
                error: 'Missing or invalid links array'
            });
        }

        console.log(`📊 Received ${links.length} links`);
        console.log(`📝 Title: ${title || 'My Links'}`);

        // Generate composite SVG
        const linkCount = links.length;
        const svgTemplate = chooseSVGTemplate(linkCount);
        const svgContent = svgTemplate(links);

        console.log(`✅ Generated SVG (${svgContent.length} characters)`);

        // Build complete BDO with svgContent
        const glyphengeBDO = {
            title: title || 'My Links',
            type: 'glyphenge',
            svgContent: svgContent,  // Added by Glyphenge!
            links: links,
            createdAt: new Date().toISOString()
        };

        // Add optional metadata
        if (source) glyphengeBDO.source = source;
        if (sourceUrl) glyphengeBDO.sourceUrl = sourceUrl;

        // Generate temporary keys for BDO
        const saveKeys = (keys) => { tempKeys = keys; };
        const getKeys = () => tempKeys;
        let tempKeys = null;

        const keys = await sessionless.generateKeys(saveKeys, getKeys);
        const pubKey = keys.pubKey;

        console.log(`🔑 Generated keys: ${pubKey.substring(0, 16)}...`);

        // Create BDO via BDO service
        const timestamp = Date.now().toString();
        const hash = 'Glyphenge';
        const message = timestamp + pubKey + hash;
        const signature = sessionless.sign(message, keys.privateKey);

        const createEndpoint = `${bdoLib.baseURL}user/create`;
        console.log(`🌐 Creating BDO at: ${createEndpoint}`);

        const createResponse = await fetch(createEndpoint, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                timestamp: timestamp,
                pubKey: pubKey,
                hash: hash,
                signature: signature,
                bdo: glyphengeBDO
            })
        });

        if (!createResponse.ok) {
            const errorText = await createResponse.text();
            console.error('❌ BDO creation failed:', errorText);
            return res.status(500).json({
                error: 'Failed to create BDO',
                details: errorText
            });
        }

        const createData = await createResponse.json();
        const bdoUUID = createData.uuid;

        console.log(`✅ BDO created: ${bdoUUID}`);

        // Make BDO public to get emojicode
        const updateTimestamp = Date.now().toString();
        const updateMessage = updateTimestamp + bdoUUID + hash;
        const updateSignature = sessionless.sign(updateMessage, keys.privateKey);

        const updateEndpoint = `${bdoLib.baseURL}user/${bdoUUID}/bdo`;
        console.log(`🌍 Making BDO public...`);

        const updateResponse = await fetch(updateEndpoint, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                timestamp: updateTimestamp,
                pubKey: pubKey,
                hash: hash,
                signature: updateSignature,
                bdo: glyphengeBDO,
                public: true  // Generate emojicode!
            })
        });

        if (!updateResponse.ok) {
            const errorText = await updateResponse.text();
            console.error('❌ Failed to make BDO public:', errorText);
            return res.status(500).json({
                error: 'Failed to generate emojicode',
                details: errorText
            });
        }

        const updateData = await updateResponse.json();
        const emojicode = updateData.emojiShortcode;

        console.log(`✅ Emojicode generated: ${emojicode}`);

        // Return complete response
        res.json({
            success: true,
            uuid: bdoUUID,
            pubKey: pubKey,
            emojicode: emojicode,
            url: `http://localhost:${PORT}?emojicode=${encodeURIComponent(emojicode)}`,
            bdoUrl: `${bdoLib.baseURL}emoji/${encodeURIComponent(emojicode)}`
        });

    } catch (error) {
        console.error('❌ Error creating Glyphenge:', error);
        res.status(500).json({
            error: error.message
        });
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`\n✅ Glyphenge tapestry weaver active on port ${PORT}`);
    console.log(`🌐 View demo: http://localhost:${PORT}`);
    console.log(`\n📝 Viewing Modes:`);
    console.log(`   Demo tapestry: http://localhost:${PORT}`);
    console.log(`   By emojicode rune: http://localhost:${PORT}?emojicode=😀🔗💎🌟...`);
    console.log(`   Legacy auth: http://localhost:${PORT}?pubKey=YOUR_PUBKEY&timestamp=TIMESTAMP&signature=SIGNATURE`);
    console.log(`\n📝 Creation Endpoint:`);
    console.log(`   POST /create - Create new Glyphenge with auto-generated SVG`);
    console.log('');
});
