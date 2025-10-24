/**
 * Canimus Feed BDO Example
 * Generates a BDO with a mix tape SVG for sharing Canimus audio feeds
 * Designed for AdvanceKey/AdvanceShare interaction
 */

export function generateCanimusFeedBDO({
  feedUrl,
  feedTitle = 'Sockpuppet Canimus Feed',
  artist = 'Sockpuppet',
  width = 400,
  height = 250
}) {
  // The mix tape SVG with embedded save button
  const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 250" width="${width}" height="${height}"
    spell="save" spell-components='{"feedUrl":"${feedUrl}","collection":"music","type":"canimus-feed"}'>
  <!-- Cassette body -->
  <defs>
    <linearGradient id="cassetteGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#FF6B9D;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#C239B3;stop-opacity:1" />
    </linearGradient>

    <linearGradient id="labelGradient" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#FFE5EC;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#FFC2D4;stop-opacity:1" />
    </linearGradient>

    <radialGradient id="reelGradient">
      <stop offset="0%" style="stop-color:#1a1a1a;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#000000;stop-opacity:1" />
    </radialGradient>
  </defs>

  <!-- Outer cassette shell -->
  <rect x="20" y="30" width="360" height="200" rx="8" ry="8"
        fill="url(#cassetteGradient)"
        stroke="#8B1874" stroke-width="2"/>

  <!-- Label area (white rectangle at top) -->
  <rect x="40" y="50" width="320" height="80" rx="4" ry="4"
        fill="url(#labelGradient)"
        stroke="#FF6B9D" stroke-width="1"/>

  <!-- Label text lines -->
  <line x1="60" y1="75" x2="340" y2="75" stroke="#C239B3" stroke-width="1.5" opacity="0.5"/>
  <line x1="60" y1="90" x2="340" y2="90" stroke="#C239B3" stroke-width="1.5" opacity="0.5"/>
  <line x1="60" y1="105" x2="200" y2="105" stroke="#C239B3" stroke-width="1.5" opacity="0.5"/>

  <!-- "MIX TAPE" text -->
  <text x="200" y="67" font-family="Arial, sans-serif" font-size="14" font-weight="bold"
        fill="#8B1874" text-anchor="middle">MIX TAPE</text>

  <!-- Artist/Title text -->
  <text x="200" y="100" font-family="Arial, sans-serif" font-size="12"
        fill="#8B1874" text-anchor="middle">${feedTitle}</text>
  <text x="200" y="115" font-family="Arial, sans-serif" font-size="10"
        fill="#8B1874" text-anchor="middle">${artist}</text>

  <!-- Left reel -->
  <circle cx="120" cy="170" r="35" fill="url(#reelGradient)" stroke="#333" stroke-width="1.5"/>
  <circle cx="120" cy="170" r="28" fill="none" stroke="#444" stroke-width="1"/>
  <circle cx="120" cy="170" r="20" fill="none" stroke="#555" stroke-width="1"/>
  <circle cx="120" cy="170" r="12" fill="none" stroke="#666" stroke-width="1"/>
  <circle cx="120" cy="170" r="8" fill="#8B1874"/>

  <!-- Left reel spokes -->
  <line x1="120" y1="150" x2="120" y2="190" stroke="#666" stroke-width="1.5"/>
  <line x1="100" y1="170" x2="140" y2="170" stroke="#666" stroke-width="1.5"/>
  <line x1="106" y1="156" x2="134" y2="184" stroke="#666" stroke-width="1.5"/>
  <line x1="106" y1="184" x2="134" y2="156" stroke="#666" stroke-width="1.5"/>

  <!-- Right reel -->
  <circle cx="280" cy="170" r="35" fill="url(#reelGradient)" stroke="#333" stroke-width="1.5"/>
  <circle cx="280" cy="170" r="28" fill="none" stroke="#444" stroke-width="1"/>
  <circle cx="280" cy="170" r="20" fill="none" stroke="#555" stroke-width="1"/>
  <circle cx="280" cy="170" r="12" fill="none" stroke="#666" stroke-width="1"/>
  <circle cx="280" cy="170" r="8" fill="#8B1874"/>

  <!-- Right reel spokes -->
  <line x1="280" y1="150" x2="280" y2="190" stroke="#666" stroke-width="1.5"/>
  <line x1="260" y1="170" x2="300" y2="170" stroke="#666" stroke-width="1.5"/>
  <line x1="266" y1="156" x2="294" y2="184" stroke="#666" stroke-width="1.5"/>
  <line x1="266" y1="184" x2="294" y2="156" stroke="#666" stroke-width="1.5"/>

  <!-- Tape between reels (visible magnetic tape) -->
  <rect x="155" y="163" width="90" height="14" fill="#3d2817" opacity="0.8"/>
  <rect x="155" y="165" width="90" height="2" fill="#5a3d2a" opacity="0.6"/>
  <rect x="155" y="173" width="90" height="2" fill="#5a3d2a" opacity="0.6"/>

  <!-- Screws in corners -->
  <circle cx="50" cy="60" r="4" fill="#999"/>
  <circle cx="350" cy="60" r="4" fill="#999"/>
  <circle cx="50" cy="210" r="4" fill="#999"/>
  <circle cx="350" cy="210" r="4" fill="#999"/>

  <!-- Screw details -->
  <line x1="48" y1="60" x2="52" y2="60" stroke="#666" stroke-width="0.5"/>
  <line x1="50" y1="58" x2="50" y2="62" stroke="#666" stroke-width="0.5"/>
  <line x1="348" y1="60" x2="352" y2="60" stroke="#666" stroke-width="0.5"/>
  <line x1="350" y1="58" x2="350" y2="62" stroke="#666" stroke-width="0.5"/>
  <line x1="48" y1="210" x2="52" y2="210" stroke="#666" stroke-width="0.5"/>
  <line x1="50" y1="208" x2="50" y2="212" stroke="#666" stroke-width="0.5"/>
  <line x1="348" y1="210" x2="352" y2="210" stroke="#666" stroke-width="0.5"/>
  <line x1="350" y1="208" x2="350" y2="212" stroke="#666" stroke-width="0.5"/>

  <!-- Bottom viewing window -->
  <rect x="160" y="145" width="80" height="50" rx="4" ry="4"
        fill="rgba(0,0,0,0.3)"
        stroke="#8B1874" stroke-width="1"/>

  <!-- Music note icon on label -->
  <g transform="translate(300, 85)">
    <circle cx="0" cy="15" r="8" fill="#C239B3"/>
    <circle cx="15" cy="18" r="8" fill="#C239B3"/>
    <rect x="7" y="-5" width="3" height="20" fill="#C239B3"/>
    <rect x="22" y="-2" width="3" height="20" fill="#C239B3"/>
    <path d="M 10 -5 Q 15 -8 25 -2" fill="none" stroke="#C239B3" stroke-width="3"/>
  </g>

  <!-- Save button (uses AdvanceKey spell system) -->
  <g spell="save" spell-components='{"feedUrl":"${feedUrl}","collection":"music","type":"canimus-feed"}'>
    <rect x="140" y="225" width="120" height="20" rx="6" fill="#8b5cf6" stroke="#6d28d9" stroke-width="2" cursor="pointer">
      <title>Save to Music Collection</title>
    </rect>
    <text x="200" y="239" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="white" text-anchor="middle" pointer-events="none">
      💾 Save Feed
    </text>
  </g>
</svg>`;

  return {
    title: `${feedTitle} - Canimus Feed`,
    type: 'canimus-feed',
    svgContent,
    metadata: {
      feedUrl,
      feedTitle,
      artist,
      createdAt: Date.now(),
      version: '1.0.0',
      feedType: 'canimus'
    },
    description: `${feedTitle} by ${artist} - Save this Canimus audio feed to your music collection`
  };
}

/**
 * Default Sockpuppet Canimus feed
 */
export const sockpuppetCanimusFeed = {
  feedUrl: 'https://sockpuppet.band/canimus.json',
  feedTitle: 'Sockpuppet Canimus Feed',
  artist: 'Sockpuppet'
};
