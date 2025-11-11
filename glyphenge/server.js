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
import fetch from 'node-fetch';
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
 * Large cards, vertical stack - DARK MODE WITH GLOW
 */
function generateCompactSVG(links) {
    const height = Math.max(400, links.length * 110 + 60);

    const linkElements = links.map((link, index) => {
        const y = 60 + (index * 110);
        const title = escapeXML(link.title || 'Untitled');
        const url = escapeXML(link.url || '#');
        const truncatedTitle = title.length > 30 ? title.substring(0, 30) + '...' : title;

        // Magical glowing gradients
        const gradients = [
            ['#10b981', '#059669'],  // Emerald glow
            ['#3b82f6', '#2563eb'],  // Sapphire glow
            ['#8b5cf6', '#7c3aed'],  // Amethyst glow
            ['#ec4899', '#db2777'],  // Ruby glow
            ['#fbbf24', '#f59e0b'],  // Topaz glow
            ['#06b6d4', '#0891b2']   // Aquamarine glow
        ];
        const gradient = gradients[index % gradients.length];
        const gradId = `grad${index}`;
        const glowId = `glow${index}`;

        return `
        <defs>
            <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
                <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
            </linearGradient>
            <filter id="${glowId}" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="8" result="coloredBlur"/>
                <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                </feMerge>
            </filter>
        </defs>

        <a href="${url}" target="_blank">
            <g filter="url(#${glowId})">
                <rect x="50" y="${y}" width="600" height="90" rx="15"
                      fill="url(#${gradId})" opacity="0.15"/>
                <rect x="50" y="${y}" width="600" height="90" rx="15"
                      fill="none" stroke="url(#${gradId})" stroke-width="2" opacity="0.8"/>
            </g>
            <text x="90" y="${y + 40}" fill="${gradient[0]}" font-size="20" font-weight="bold"
                  style="filter: drop-shadow(0 0 8px ${gradient[0]});">${truncatedTitle}</text>
            <text x="90" y="${y + 65}" fill="rgba(167, 139, 250, 0.7)" font-size="14">✨ Tap to open</text>
            <text x="600" y="${y + 50}" fill="${gradient[0]}" font-size="30"
                  style="filter: drop-shadow(0 0 6px ${gradient[0]});">→</text>
        </a>`;
    }).join('\n');

    return `
<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
        <radialGradient id="bgGrad" cx="50%" cy="50%">
            <stop offset="0%" style="stop-color:#1a0033;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#0a001a;stop-opacity:1" />
        </radialGradient>
    </defs>

    <rect width="700" height="${height}" fill="url(#bgGrad)"/>

    <!-- Magical particles -->
    <circle cx="100" cy="20" r="2" fill="#fbbf24" opacity="0.6">
        <animate attributeName="opacity" values="0.3;0.8;0.3" dur="3s" repeatCount="indefinite"/>
    </circle>
    <circle cx="600" cy="30" r="1.5" fill="#a78bfa" opacity="0.5">
        <animate attributeName="opacity" values="0.2;0.7;0.2" dur="4s" repeatCount="indefinite"/>
    </circle>
    <circle cx="350" cy="15" r="1" fill="#10b981" opacity="0.4">
        <animate attributeName="opacity" values="0.2;0.6;0.2" dur="5s" repeatCount="indefinite"/>
    </circle>

    <text x="350" y="35" fill="#fbbf24" font-size="24" font-weight="bold" text-anchor="middle"
          style="filter: drop-shadow(0 0 10px #fbbf24);">
        ✨ My Links ✨
    </text>

    ${linkElements}
</svg>`;
}

/**
 * Template 2: Grid layout (7-13 links)
 * 2-column grid with medium cards - DARK MODE WITH GLOW
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
            ['#10b981', '#059669'],  // Emerald
            ['#3b82f6', '#2563eb'],  // Sapphire
            ['#8b5cf6', '#7c3aed'],  // Amethyst
            ['#ec4899', '#db2777'],  // Ruby
            ['#fbbf24', '#f59e0b'],  // Topaz
            ['#06b6d4', '#0891b2']   // Aquamarine
        ];
        const gradient = gradients[index % gradients.length];
        const gradId = `grad${index}`;
        const glowId = `glow${index}`;

        return `
        <defs>
            <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
                <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
            </linearGradient>
            <filter id="${glowId}" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="6" result="coloredBlur"/>
                <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                </feMerge>
            </filter>
        </defs>

        <a href="${url}" target="_blank">
            <g filter="url(#${glowId})">
                <rect x="${x}" y="${y}" width="290" height="80" rx="12"
                      fill="url(#${gradId})" opacity="0.15"/>
                <rect x="${x}" y="${y}" width="290" height="80" rx="12"
                      fill="none" stroke="url(#${gradId})" stroke-width="2" opacity="0.8"/>
            </g>
            <text x="${x + 20}" y="${y + 35}" fill="${gradient[0]}" font-size="16" font-weight="bold"
                  style="filter: drop-shadow(0 0 6px ${gradient[0]});">${truncatedTitle}</text>
            <text x="${x + 20}" y="${y + 55}" fill="rgba(167, 139, 250, 0.7)" font-size="12">✨ Click</text>
        </a>`;
    }).join('\n');

    return `
<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
        <radialGradient id="bgGrad" cx="50%" cy="50%">
            <stop offset="0%" style="stop-color:#1a0033;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#0a001a;stop-opacity:1" />
        </radialGradient>
    </defs>

    <rect width="700" height="${height}" fill="url(#bgGrad)"/>

    <!-- Magical particles -->
    <circle cx="120" cy="25" r="2" fill="#fbbf24" opacity="0.6">
        <animate attributeName="opacity" values="0.3;0.8;0.3" dur="3s" repeatCount="indefinite"/>
    </circle>
    <circle cx="580" cy="35" r="1.5" fill="#a78bfa" opacity="0.5">
        <animate attributeName="opacity" values="0.2;0.7;0.2" dur="4s" repeatCount="indefinite"/>
    </circle>
    <circle cx="350" cy="20" r="1" fill="#10b981" opacity="0.4">
        <animate attributeName="opacity" values="0.2;0.6;0.2" dur="5s" repeatCount="indefinite"/>
    </circle>
    <circle cx="200" cy="30" r="1.5" fill="#ec4899" opacity="0.5">
        <animate attributeName="opacity" values="0.3;0.7;0.3" dur="3.5s" repeatCount="indefinite"/>
    </circle>

    <text x="350" y="40" fill="#fbbf24" font-size="24" font-weight="bold" text-anchor="middle"
          style="filter: drop-shadow(0 0 10px #fbbf24);">
        ✨ My Links ✨
    </text>

    ${linkElements}
</svg>`;
}

/**
 * Template 3: Dense layout (14-20 links)
 * 3-column grid with compact cards - DARK MODE WITH GLOW
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
            ['#10b981', '#059669'],  // Emerald
            ['#3b82f6', '#2563eb'],  // Sapphire
            ['#8b5cf6', '#7c3aed'],  // Amethyst
            ['#ec4899', '#db2777'],  // Ruby
            ['#fbbf24', '#f59e0b'],  // Topaz
            ['#06b6d4', '#0891b2']   // Aquamarine
        ];
        const gradient = gradients[index % gradients.length];
        const gradId = `grad${index}`;
        const glowId = `glow${index}`;

        return `
        <defs>
            <linearGradient id="${gradId}" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
                <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
            </linearGradient>
            <filter id="${glowId}" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="5" result="coloredBlur"/>
                <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                </feMerge>
            </filter>
        </defs>

        <a href="${url}" target="_blank">
            <g filter="url(#${glowId})">
                <rect x="${x}" y="${y}" width="190" height="65" rx="10"
                      fill="url(#${gradId})" opacity="0.15"/>
                <rect x="${x}" y="${y}" width="190" height="65" rx="10"
                      fill="none" stroke="url(#${gradId})" stroke-width="2" opacity="0.8"/>
            </g>
            <text x="${x + 15}" y="${y + 30}" fill="${gradient[0]}" font-size="14" font-weight="bold"
                  style="filter: drop-shadow(0 0 5px ${gradient[0]});">${truncatedTitle}</text>
            <text x="${x + 15}" y="${y + 48}" fill="rgba(167, 139, 250, 0.7)" font-size="11">✨</text>
        </a>`;
    }).join('\n');

    return `
<svg width="700" height="${height}" viewBox="0 0 700 ${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
        <radialGradient id="bgGrad" cx="50%" cy="50%">
            <stop offset="0%" style="stop-color:#1a0033;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#0a001a;stop-opacity:1" />
        </radialGradient>
    </defs>

    <rect width="700" height="${height}" fill="url(#bgGrad)"/>

    <!-- Magical particles -->
    <circle cx="100" cy="25" r="2" fill="#fbbf24" opacity="0.6">
        <animate attributeName="opacity" values="0.3;0.8;0.3" dur="3s" repeatCount="indefinite"/>
    </circle>
    <circle cx="350" cy="20" r="1.5" fill="#a78bfa" opacity="0.5">
        <animate attributeName="opacity" values="0.2;0.7;0.2" dur="4s" repeatCount="indefinite"/>
    </circle>
    <circle cx="600" cy="30" r="1" fill="#10b981" opacity="0.4">
        <animate attributeName="opacity" values="0.2;0.6;0.2" dur="5s" repeatCount="indefinite"/>
    </circle>
    <circle cx="200" cy="35" r="1.5" fill="#ec4899" opacity="0.5">
        <animate attributeName="opacity" values="0.3;0.7;0.3" dur="3.5s" repeatCount="indefinite"/>
    </circle>
    <circle cx="500" cy="28" r="1" fill="#06b6d4" opacity="0.4">
        <animate attributeName="opacity" values="0.2;0.6;0.2" dur="4.5s" repeatCount="indefinite"/>
    </circle>

    <text x="350" y="40" fill="#fbbf24" font-size="22" font-weight="bold" text-anchor="middle"
          style="filter: drop-shadow(0 0 10px #fbbf24);">
        ✨ My Links ✨
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

        // Create BDO via bdo-js (handles signing automatically)
        const hash = 'Glyphenge';
        console.log(`🌐 Creating BDO with hash: ${hash}`);

        const bdoUUID = await bdoLib.createUser(hash, glyphengeBDO, saveKeys, getKeys);
        console.log(`✅ BDO created: ${bdoUUID}`);

        // Make BDO public to get emojicode (using bdo-js)
        console.log(`🌍 Making BDO public...`);
        const updatedBDO = await bdoLib.updateBDO(bdoUUID, hash, glyphengeBDO, true);
        const emojicode = updatedBDO.emojiShortcode;

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

/**
 * POST /magic/spell/:spellName - MAGIC Protocol Endpoint
 *
 * Handles spell casting for Glyphenge creation with integrated payment processing.
 *
 * Available Spells:
 * - glyphenge: Create tapestry from carrierBag links
 * - glyphtree: Create tapestry from Linktree URL
 */
app.post('/magic/spell/:spellName', async (req, res) => {
    try {
        const { spellName } = req.params;
        const { caster, payload } = req.body;

        console.log(`✨ MAGIC: Casting spell "${spellName}"`);

        // Validate caster authentication
        if (!caster || !caster.pubKey || !caster.timestamp || !caster.signature) {
            return res.status(403).json({
                success: false,
                error: 'Missing caster authentication'
            });
        }

        // Verify caster signature (timestamp + pubKey)
        const message = caster.timestamp + caster.pubKey;
        const isValid = sessionless.verifySignature(caster.signature, message, caster.pubKey);

        if (!isValid) {
            return res.status(403).json({
                success: false,
                error: 'Invalid caster signature'
            });
        }

        // Route to spell resolver
        let result;
        if (spellName === 'glyphenge') {
            result = await resolveGlyphengeSpell(caster, payload);
        } else if (spellName === 'glyphtree') {
            result = await resolveGlyphtreeSpell(caster, payload);
        } else {
            return res.status(404).json({
                success: false,
                error: `Unknown spell: ${spellName}`
            });
        }

        res.json(result);

    } catch (error) {
        console.error('❌ MAGIC spell error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * Resolve glyphenge spell
 * Creates tapestry from carrierBag links with payment processing
 */
async function resolveGlyphengeSpell(caster, payload) {
    console.log('🎨 Resolving glyphenge spell...');

    const { paymentMethod, links, title } = payload;

    // Validate required spell components
    if (!links || !Array.isArray(links) || links.length === 0) {
        return { success: false, error: 'Missing or invalid links array' };
    }

    if (!paymentMethod || (paymentMethod !== 'mp' && paymentMethod !== 'money')) {
        return { success: false, error: 'Invalid payment method (must be mp or money)' };
    }

    // Process payment
    const paymentResult = await processSpellPayment(caster, paymentMethod, 100); // $1.00
    if (!paymentResult.success) {
        return paymentResult;
    }

    // Generate SVG using existing template logic
    const linkCount = links.length;
    const svgTemplate = chooseSVGTemplate(linkCount);
    const svgContent = svgTemplate(links);

    console.log(`✅ Generated SVG (${svgContent.length} characters)`);

    // Build complete BDO with svgContent
    const glyphengeBDO = {
        title: title || 'My Glyphenge',
        type: 'glyphenge',
        svgContent: svgContent,
        links: links,
        source: 'emporium-spell',
        createdAt: new Date().toISOString()
    };

    // Generate temporary keys for BDO
    const saveKeys = (keys) => { tempKeys = keys; };
    const getKeys = () => tempKeys;
    let tempKeys = null;

    const keys = await sessionless.generateKeys(saveKeys, getKeys);
    const pubKey = keys.pubKey;

    console.log(`🔑 Generated BDO keys: ${pubKey.substring(0, 16)}...`);

    // Create BDO via bdo-js (handles signing automatically)
    const hash = 'Glyphenge';
    console.log(`🌐 Creating BDO with hash: ${hash}`);

    const bdoUUID = await bdoLib.createUser(hash, glyphengeBDO, saveKeys, getKeys);
    console.log(`✅ BDO created: ${bdoUUID}`);

    // Make BDO public to get emojicode
    console.log(`🌍 Making BDO public...`);
    const updatedBDO = await bdoLib.updateBDO(bdoUUID, hash, glyphengeBDO, true);
    const emojicode = updatedBDO.emojiShortcode;

    console.log(`✅ Emojicode generated: ${emojicode}`);

    // Save to carrierBag "store" collection
    const carrierBagResult = await saveToCarrierBag(caster.pubKey, 'store', {
        title: glyphengeBDO.title,
        type: 'glyphenge',
        emojicode: emojicode,
        bdoPubKey: pubKey,
        createdAt: glyphengeBDO.createdAt
    });

    if (!carrierBagResult.success) {
        console.warn('⚠️ Failed to save to carrierBag, but spell succeeded');
    }

    return {
        success: true,
        emojicode: emojicode,
        url: `http://localhost:${PORT}?emojicode=${encodeURIComponent(emojicode)}`,
        bdoUrl: `${bdoLib.baseURL}emoji/${encodeURIComponent(emojicode)}`,
        payment: paymentResult.payment
    };
}

/**
 * Resolve glyphtree spell
 * Creates tapestry from Linktree URL with payment processing
 */
async function resolveGlyphtreeSpell(caster, payload) {
    console.log('🌳 Resolving glyphtree spell...');

    const { paymentMethod, linktreeUrl } = payload;

    // Validate required spell components
    if (!linktreeUrl || !linktreeUrl.includes('linktr.ee')) {
        return { success: false, error: 'Invalid Linktree URL' };
    }

    if (!paymentMethod || (paymentMethod !== 'mp' && paymentMethod !== 'money')) {
        return { success: false, error: 'Invalid payment method (must be mp or money)' };
    }

    // Fetch and parse Linktree page
    console.log(`🌐 Fetching Linktree page: ${linktreeUrl}`);

    const response = await fetch(linktreeUrl, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }
    });

    if (!response.ok) {
        return { success: false, error: `Failed to fetch Linktree page: ${response.statusText}` };
    }

    const html = await response.text();

    // Extract __NEXT_DATA__ from page
    const nextDataMatch = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
    if (!nextDataMatch) {
        return { success: false, error: 'Could not find __NEXT_DATA__ in Linktree page' };
    }

    const nextData = JSON.parse(nextDataMatch[1]);
    const pageProps = nextData.props?.pageProps?.account;

    if (!pageProps || !pageProps.links) {
        return { success: false, error: 'Invalid Linktree page structure' };
    }

    // Extract links
    const links = pageProps.links.map(link => ({
        title: link.title,
        url: link.url
    }));

    const title = `${pageProps.username}'s Links` || 'Linktree Import';

    console.log(`✅ Extracted ${links.length} links from Linktree`);

    // Process payment
    const paymentResult = await processSpellPayment(caster, paymentMethod, 100); // $1.00
    if (!paymentResult.success) {
        return paymentResult;
    }

    // Generate SVG using existing template logic
    const linkCount = links.length;
    const svgTemplate = chooseSVGTemplate(linkCount);
    const svgContent = svgTemplate(links);

    console.log(`✅ Generated SVG (${svgContent.length} characters)`);

    // Build complete BDO with svgContent
    const glyphengeBDO = {
        title: title,
        type: 'glyphenge',
        svgContent: svgContent,
        links: links,
        source: 'linktree',
        sourceUrl: linktreeUrl,
        createdAt: new Date().toISOString()
    };

    // Generate temporary keys for BDO
    const saveKeys = (keys) => { tempKeys = keys; };
    const getKeys = () => tempKeys;
    let tempKeys = null;

    const keys = await sessionless.generateKeys(saveKeys, getKeys);
    const pubKey = keys.pubKey;

    console.log(`🔑 Generated BDO keys: ${pubKey.substring(0, 16)}...`);

    // Create BDO via bdo-js (handles signing automatically)
    const hash = 'Glyphenge';
    console.log(`🌐 Creating BDO with hash: ${hash}`);

    const bdoUUID = await bdoLib.createUser(hash, glyphengeBDO, saveKeys, getKeys);
    console.log(`✅ BDO created: ${bdoUUID}`);

    // Make BDO public to get emojicode
    console.log(`🌍 Making BDO public...`);
    const updatedBDO = await bdoLib.updateBDO(bdoUUID, hash, glyphengeBDO, true);
    const emojicode = updatedBDO.emojiShortcode;

    console.log(`✅ Emojicode generated: ${emojicode}`);

    // Save to carrierBag "store" collection
    const carrierBagResult = await saveToCarrierBag(caster.pubKey, 'store', {
        title: glyphengeBDO.title,
        type: 'glyphenge',
        emojicode: emojicode,
        bdoPubKey: pubKey,
        sourceUrl: linktreeUrl,
        createdAt: glyphengeBDO.createdAt
    });

    if (!carrierBagResult.success) {
        console.warn('⚠️ Failed to save to carrierBag, but spell succeeded');
    }

    return {
        success: true,
        emojicode: emojicode,
        url: `http://localhost:${PORT}?emojicode=${encodeURIComponent(emojicode)}`,
        bdoUrl: `${bdoLib.baseURL}emoji/${encodeURIComponent(emojicode)}`,
        linkCount: links.length,
        payment: paymentResult.payment
    };
}

/**
 * Process payment for spell casting
 *
 * Note: Word of power validation happens CLIENT-SIDE using SHA256 hash comparison.
 * This function does not validate or require word of power - that check is done
 * in the browser before the spell is cast.
 */
async function processSpellPayment(caster, paymentMethod, amountCents) {
    console.log(`💰 Processing ${paymentMethod} payment...`);

    if (paymentMethod === 'mp') {
        // MP payment through Fount
        // TODO: Call Fount /resolve with deductMP spell
        // For now, return simulated success
        return {
            success: true,
            payment: {
                method: 'mp',
                amount: amountCents / 100,
                message: 'MP payment simulated (TODO: integrate with Fount)'
            }
        };

    } else if (paymentMethod === 'money') {
        // Money payment through Addie
        // TODO: Call Addie /charge-with-saved-method
        // For now, return simulated success
        return {
            success: true,
            payment: {
                method: 'money',
                amount: amountCents / 100,
                message: 'Money payment simulated (TODO: integrate with Addie)'
            }
        };

    } else {
        return {
            success: false,
            error: 'Unknown payment method'
        };
    }
}

/**
 * Save item to user's carrierBag collection
 */
async function saveToCarrierBag(userPubKey, collection, item) {
    console.log(`💼 Saving to carrierBag collection: ${collection}`);

    try {
        // Fetch user's Fount BDO (which contains carrierBag)
        const userBDO = await fountLib.getBDO(userPubKey);
        const bdo = userBDO.bdo || userBDO;
        const carrierBag = bdo.carrierBag || bdo.data?.carrierBag || {};

        // Add item to collection
        if (!carrierBag[collection]) {
            carrierBag[collection] = [];
        }
        carrierBag[collection].push(item);

        // Update carrierBag
        // TODO: This requires authentication - need to handle signing
        // For now, log success but don't actually update
        console.log(`✅ Would save to carrierBag ${collection} collection`);
        console.log(`   Item: ${JSON.stringify(item).substring(0, 100)}...`);

        return { success: true };

    } catch (error) {
        console.error('❌ Failed to save to carrierBag:', error);
        return { success: false, error: error.message };
    }
}

// Start server
app.listen(PORT, () => {
    console.log(`\n✅ Glyphenge tapestry weaver active on port ${PORT}`);
    console.log(`🌐 View demo: http://localhost:${PORT}`);
    console.log(`\n📝 Viewing Modes:`);
    console.log(`   Demo tapestry: http://localhost:${PORT}`);
    console.log(`   By emojicode rune: http://localhost:${PORT}?emojicode=😀🔗💎🌟...`);
    console.log(`   Legacy auth: http://localhost:${PORT}?pubKey=YOUR_PUBKEY&timestamp=TIMESTAMP&signature=SIGNATURE`);
    console.log(`\n📝 Creation Endpoints:`);
    console.log(`   POST /create - Create new Glyphenge with auto-generated SVG`);
    console.log(`   POST /magic/spell/glyphenge - Cast glyphenge spell (carrierBag links)`);
    console.log(`   POST /magic/spell/glyphtree - Cast glyphtree spell (Linktree URL)`);
    console.log('');
});
