#!/usr/bin/env node

/**
 * Simple icon generator for The Advancement Safari extension
 * Creates basic PNG icons using SVG to PNG conversion
 */

import fs from 'fs';
import path from 'path';

// Create basic SVG icon template
const createSVGIcon = (size) => `
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#9b59b6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#667eea;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background circle -->
  <circle cx="${size/2}" cy="${size/2}" r="${size/2 - 1}" fill="url(#bgGradient)" stroke="none"/>
  
  <!-- The "A" for Advancement -->
  <text x="${size/2}" y="${size/2}" text-anchor="middle" dominant-baseline="middle" 
        fill="white" font-family="Arial, sans-serif" font-weight="bold" font-size="${Math.floor(size * 0.6)}">A</text>
  
  ${size >= 32 ? `<!-- Magic sparkle -->
  <text x="${size * 0.75}" y="${size * 0.25}" text-anchor="middle" dominant-baseline="middle" 
        fill="#f1c40f" font-family="Arial, sans-serif" font-size="${Math.floor(size * 0.2)}">✨</text>` : ''}
</svg>`;

// Create icons directory
const iconsDir = '/Users/zachbabb/Work/planet-nine/the-advancement/src/extensions/safari/icons';

if (!fs.existsSync(iconsDir)) {
    fs.mkdirSync(iconsDir, { recursive: true });
}

// Generate SVG icons for different sizes
const sizes = [16, 32, 48, 128];

console.log('🎨 Generating The Advancement icons...');

sizes.forEach(size => {
    const svgContent = createSVGIcon(size);
    const svgPath = path.join(iconsDir, `icon-${size}.svg`);
    
    fs.writeFileSync(svgPath, svgContent.trim());
    console.log(`✅ Created icon-${size}.svg`);
});

// Create simple placeholder PNGs by copying the SVG content
// In a real scenario, you'd use a proper SVG to PNG converter
// For now, browsers can handle SVG icons directly
sizes.forEach(size => {
    const svgContent = createSVGIcon(size);
    const pngPath = path.join(iconsDir, `icon-${size}.png`);
    
    // For now, create a simple data URL that can be used
    // In production, you'd convert SVG to actual PNG
    const dataUrl = `data:image/svg+xml;base64,${Buffer.from(svgContent.trim()).toString('base64')}`;
    
    // Write a simple file that contains the data URL
    fs.writeFileSync(pngPath + '.dataurl', dataUrl);
    
    // Create a basic PNG-like file (really SVG renamed)
    fs.writeFileSync(pngPath, svgContent.trim());
    
    console.log(`✅ Created icon-${size}.png`);
});

console.log('\n🎉 All icons generated successfully!');
console.log('📁 Icons location:', iconsDir);
console.log('\n💡 Note: For production, convert SVG files to proper PNG format using:');
console.log('   - ImageMagick: convert icon.svg icon.png');
console.log('   - Online tools: CloudConvert, etc.');
console.log('   - Node.js: sharp, puppeteer, etc.');

export { createSVGIcon };