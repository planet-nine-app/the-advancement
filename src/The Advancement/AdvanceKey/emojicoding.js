/**
 * Emoji Base-64/128 Hex Encoder/Decoder
 * Extracted from MAGIC/src/utils/emojicoding.html
 *
 * Provides functions to encode hex strings as emoji and decode emoji back to hex
 * with optional magic delimiters for enhanced detection and visual appeal.
 */

// Ultra-reliable base-64 emoji set - maximum cross-platform compatibility
// Using only the most universally supported emoji from Unicode 6.0-7.0
const EMOJI_SET_64 = [
    // Core smileys (16) - universally supported
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '😊', '😉', '😍', '😘', '😋', '😎', '😐', '😑', '😔',

    // Hearts & love (8) - extremely reliable
    '❤️', '💛', '💚', '💙', '💜', '💔', '💕', '💖',

    // Basic hands (8) - well supported
    '👍', '👎', '👌', '✌️', '👈', '👉', '👆', '👇',

    // Nature & weather (8) - stable Unicode 6.0
    '☀️', '🌙', '⭐', '⚡', '☁️', '❄️', '🔥', '💧',

    // Animals (8) - highly compatible
    '🐶', '🐱', '🐭', '🐰', '🐻', '🐯', '🐸', '🐧',

    // Objects & symbols (8) - basic Unicode
    '💎', '🔑', '🎁', '🎉', '🏠', '🚗', '📱', '⚽',

    // Food (8) - reliable classics
    '🍎', '🍊', '🍌', '🍕', '🍔', '🍰', '☕', '🍺'
];

const EMOJI_SET_128 = [
    // All of base-64 set
    ...EMOJI_SET_64,

    // Extended smileys (16)
    '😇', '🙂', '🙃', '😌', '😏', '😒', '😞', '😟', '😤', '😢', '😭', '😱', '😨', '😰', '😡', '🤔',

    // More hearts & symbols (16)
    '💗', '💘', '💝', '💞', '💟', '❣️', '💌', '💐', '🌹', '🌺', '🌻', '🌷', '🌸', '💮', '🏵️', '🌼',

    // Extended hands & gestures (16)
    '☝️', '✋', '🤚', '🖐️', '🖖', '👏', '🙌', '👐', '🤝', '🙏', '✍️', '💅', '🤳', '💪', '👂', '👃',

    // More nature (16)
    '🌈', '🌍', '🌎', '🌏', '🌕', '🌖', '🌗', '🌘', '🌑', '🌒', '🌓', '🌔', '⛄', '🌟', '💫', '✨'
];

// Magic delimiter options
const MAGIC_DELIMITERS = {
    'none': { start: '', end: '' },
    'sparkles': { start: '✨', end: '✨' },
    'crystal': { start: '🔮', end: '🔮' },
    'stars': { start: '⭐', end: '⭐' },
    'lightning': { start: '⚡', end: '⚡' },
    'triple': { start: '✨✨✨', end: '✨✨✨' }
};

/**
 * Configuration object for encoding options
 */
const EmojicodingConfig = {
    base: 64,           // 64 or 128
    bitsPerChar: 6,     // 6 for base-64, 7 for base-128
    emojiSet: EMOJI_SET_64,
    magicMode: 'sparkles'
};

/**
 * Set the encoding base (64 or 128)
 */
function setEmojiBase(base) {
    if (base === 64) {
        EmojicodingConfig.base = 64;
        EmojicodingConfig.bitsPerChar = 6;
        EmojicodingConfig.emojiSet = EMOJI_SET_64;
    } else if (base === 128) {
        EmojicodingConfig.base = 128;
        EmojicodingConfig.bitsPerChar = 7;
        EmojicodingConfig.emojiSet = EMOJI_SET_128;
    }
}

/**
 * Set the magic delimiter mode
 */
function setMagicMode(mode) {
    if (MAGIC_DELIMITERS[mode]) {
        EmojicodingConfig.magicMode = mode;
    }
}

/**
 * Convert hex string to binary
 */
function hexToBinary(hex) {
    return hex.split('').map(h =>
        parseInt(h, 16).toString(2).padStart(4, '0')
    ).join('');
}

/**
 * Convert binary string to hex
 */
function binaryToHex(binary) {
    // Pad to multiple of 4 bits
    while (binary.length % 4 !== 0) {
        binary = '0' + binary;
    }

    let hex = '';
    for (let i = 0; i < binary.length; i += 4) {
        hex += parseInt(binary.substr(i, 4), 2).toString(16);
    }
    return hex;
}

/**
 * Encode a hex string as emoji
 * @param {string} hexString - Hex string to encode (without 0x prefix)
 * @param {object} options - Optional configuration
 * @returns {string} Emoji-encoded string with optional magic delimiters
 */
function encodeHexToEmoji(hexString, options = {}) {
    // Apply options
    const config = { ...EmojicodingConfig, ...options };

    // Clean hex input
    const cleanHex = hexString.replace(/[^0-9a-fA-F]/g, '').toLowerCase();

    if (!cleanHex) {
        throw new Error('Invalid hex string');
    }

    try {
        // Convert hex to binary
        const binary = hexToBinary(cleanHex);

        // Pad to multiple of bitsPerChar
        let paddedBinary = binary;
        while (paddedBinary.length % config.bitsPerChar !== 0) {
            paddedBinary = '0' + paddedBinary;
        }

        // Convert to emoji
        let emoji = '';
        for (let i = 0; i < paddedBinary.length; i += config.bitsPerChar) {
            const bits = paddedBinary.substr(i, config.bitsPerChar);
            const index = parseInt(bits, 2);
            emoji += config.emojiSet[index];
        }

        // Add magic delimiters
        const delimiters = MAGIC_DELIMITERS[config.magicMode];
        return delimiters.start + emoji + delimiters.end;

    } catch (error) {
        throw new Error('Failed to encode hex to emoji: ' + error.message);
    }
}

/**
 * Decode emoji string back to hex
 * @param {string} emojiString - Emoji string to decode
 * @param {object} options - Optional configuration
 * @returns {object} Object with hex result and detected magic info
 */
function decodeEmojiToHex(emojiString, options = {}) {
    console.log('🔍 EMOJICODING: decodeEmojiToHex called with:', emojiString);
    console.log('🔍 EMOJICODING: Input length:', emojiString.length);
    console.log('🔍 EMOJICODING: Input chars:', Array.from(emojiString));

    // Apply options
    const config = { ...EmojicodingConfig, ...options };
    console.log('🔍 EMOJICODING: Using config base:', config.base, 'bitsPerChar:', config.bitsPerChar);

    if (!emojiString) {
        console.error('❌ EMOJICODING: Empty emoji string');
        throw new Error('Empty emoji string');
    }

    try {
        console.log('🔍 EMOJICODING: Starting magic delimiter detection...');
        // Strip magic delimiters if present and detect which ones
        let strippedInput = emojiString;
        let detectedMagic = null;

        for (const [mode, delimiters] of Object.entries(MAGIC_DELIMITERS)) {
            if (delimiters.start && delimiters.end) {
                if (emojiString.startsWith(delimiters.start) && emojiString.endsWith(delimiters.end)) {
                    strippedInput = emojiString.slice(delimiters.start.length, -delimiters.end.length);
                    detectedMagic = mode;
                    console.log('✅ EMOJICODING: Detected magic:', mode, 'stripped to:', strippedInput);
                    break;
                }
            }
        }

        if (!detectedMagic) {
            console.log('🔍 EMOJICODING: No magic delimiters found, using input as-is');
        }

        console.log('🔍 EMOJICODING: Converting emoji to binary...');
        let binary = '';

        // Convert each emoji character to binary
        for (const char of strippedInput) {
            const index = config.emojiSet.indexOf(char);
            if (index === -1) {
                console.log('⚠️ EMOJICODING: Skipping unknown char:', char);
                // Skip unknown characters (like variation selectors)
                continue;
            }
            const bits = index.toString(2).padStart(config.bitsPerChar, '0');
            binary += bits;
            console.log('🔍 EMOJICODING: Char', char, '→ index', index, '→ bits', bits);
        }

        console.log('🔍 EMOJICODING: Final binary:', binary);

        if (binary === '') {
            console.error('❌ EMOJICODING: No valid emoji found in string');
            throw new Error('No valid emoji found in string');
        }

        console.log('🔍 EMOJICODING: Converting binary to hex...');
        // Convert binary to hex
        const hex = binaryToHex(binary).toUpperCase();
        console.log('✅ EMOJICODING: Final hex:', hex);

        const result = {
            hex: hex,
            detectedMagic: detectedMagic,
            strippedInput: strippedInput
        };

        console.log('✅ EMOJICODING: Returning result:', result);
        return result;

    } catch (error) {
        console.error('❌ EMOJICODING: Exception during decode:', error.message);
        console.error('❌ EMOJICODING: Stack trace:', error.stack);
        throw new Error('Failed to decode emoji to hex: ' + error.message);
    }
}

// Base64 to emoji mapping (64 chars + padding)
const BASE64_TO_EMOJI = {
    'A': '😀', 'B': '😃', 'C': '😄', 'D': '😁', 'E': '😆', 'F': '😅', 'G': '😂', 'H': '😊',
    'I': '😉', 'J': '😍', 'K': '😘', 'L': '😋', 'M': '😎', 'N': '😐', 'O': '😑', 'P': '😔',
    'Q': '❤️', 'R': '💛', 'S': '💚', 'T': '💙', 'U': '💜', 'V': '💔', 'W': '💕', 'X': '💖',
    'Y': '👍', 'Z': '👎', 'a': '👌', 'b': '✌️', 'c': '👈', 'd': '👉', 'e': '👆', 'f': '👇',
    'g': '☀️', 'h': '🌙', 'i': '⭐', 'j': '⚡', 'k': '☁️', 'l': '❄️', 'm': '🔥', 'n': '💧',
    'o': '🐶', 'p': '🐱', 'q': '🐭', 'r': '🐰', 's': '🐻', 't': '🐯', 'u': '🐸', 'v': '🐧',
    'w': '💎', 'x': '🔑', 'y': '🎁', 'z': '🎉', '0': '🏠', '1': '🚗', '2': '📱', '3': '⚽',
    '4': '🍎', '5': '🍊', '6': '🍌', '7': '🍕', '8': '🍔', '9': '🍰', '+': '☕', '/': '🍺',
    '=': '🌿' // Padding character
};

// Reverse mapping
const EMOJI_TO_BASE64 = {};
for (const [base64Char, emoji] of Object.entries(BASE64_TO_EMOJI)) {
    EMOJI_TO_BASE64[emoji] = base64Char;
}

/**
 * Simple hex to emoji encoding using built-in base64
 * @param {string} hexString - Hex string to encode
 * @returns {string} Emoji-encoded string with magic delimiters
 */
function simpleEncodeHex(hexString) {
    console.log('🔍 SIMPLE: Starting encode of hex:', hexString);

    try {
        // Convert hex to binary string for btoa
        const binaryString = hexString.match(/.{2}/g).map(hex =>
            String.fromCharCode(parseInt(hex, 16))
        ).join('');

        console.log('🔍 SIMPLE: Binary string length:', binaryString.length);

        // Encode to base64
        const base64 = btoa(binaryString);
        console.log('🔍 SIMPLE: Base64 result:', base64);

        // Convert base64 to emoji
        const emoji = base64.split('').map(char => BASE64_TO_EMOJI[char] || char).join('');
        console.log('🔍 SIMPLE: Emoji result:', emoji);

        // Add magic delimiters
        const result = '✨' + emoji + '✨';
        console.log('🔍 SIMPLE: Final result with magic:', result);

        return result;
    } catch (error) {
        console.error('❌ SIMPLE: Encode error:', error);
        throw new Error('Simple encode failed: ' + error.message);
    }
}

/**
 * Simple emoji to hex decoding using built-in base64
 * @param {string} emojiString - Emoji string to decode
 * @returns {object} Object with hex result
 */
function simpleDecodeEmoji(emojiString) {
    console.log('🔍 SIMPLE: Starting decode of emoji:', emojiString);

    try {
        // Strip magic delimiters
        let stripped = emojiString;
        if (stripped.startsWith('✨') && stripped.endsWith('✨')) {
            stripped = stripped.slice(1, -1);
            console.log('🔍 SIMPLE: Stripped magic delimiters:', stripped);
        }

        // Convert emoji back to base64, checking each character
        const base64Chars = [];

        // Use Array.from() to properly split emojis (handles surrogate pairs)
        const emojiArray = Array.from(stripped);

        for (let i = 0; i < emojiArray.length; i++) {
            let emoji = emojiArray[i];

            // Check if next character is a variation selector (U+FE0F or U+FE0E)
            if (i + 1 < emojiArray.length) {
                const nextChar = emojiArray[i + 1];
                const nextCodePoint = nextChar.codePointAt(0);
                if (nextCodePoint === 0xFE0F || nextCodePoint === 0xFE0E) {
                    // Combine emoji with variation selector
                    emoji = emoji + nextChar;
                    i++; // Skip the variation selector in next iteration
                    console.log(`🔍 SIMPLE: Combined emoji with variation selector: "${emoji}"`);
                }
            }

            // Try to normalize the emoji first
            const normalizedEmoji = emoji.normalize('NFC');
            let base64Char = EMOJI_TO_BASE64[emoji] || EMOJI_TO_BASE64[normalizedEmoji];

            console.log(`🔍 SIMPLE: Processing emoji ${i}: "${emoji}" → "${base64Char}"`);

            if (base64Char) {
                base64Chars.push(base64Char);
            } else {
                // Try alternative normalization forms
                const nfdForm = emoji.normalize('NFD');
                const nfkcForm = emoji.normalize('NFKC');
                const nfkdForm = emoji.normalize('NFKD');

                base64Char = EMOJI_TO_BASE64[nfdForm] || EMOJI_TO_BASE64[nfkcForm] || EMOJI_TO_BASE64[nfkdForm];

                if (base64Char) {
                    console.log(`🔍 SIMPLE: Found via normalization: "${emoji}" → "${base64Char}"`);
                    base64Chars.push(base64Char);
                } else {
                    console.error('❌ SIMPLE: Unknown emoji at position', i, ':', emoji);
                    console.error('❌ SIMPLE: Emoji code points:', [...emoji].map(c => c.codePointAt(0).toString(16)));
                    console.error('❌ SIMPLE: Normalized forms tried:', [emoji, normalizedEmoji, nfdForm, nfkcForm, nfkdForm]);
                    console.error('❌ SIMPLE: Available mappings sample:', Object.entries(EMOJI_TO_BASE64).slice(0, 5));

                    // Instead of throwing, skip this emoji and continue
                    console.warn(`⚠️ SIMPLE: Skipping unknown emoji at position ${i}, continuing decode...`);
                    continue;
                }
            }
        }

        const base64 = base64Chars.join('');
        console.log('🔍 SIMPLE: Recovered base64:', base64);

        // Decode from base64
        const binaryString = atob(base64);
        console.log('🔍 SIMPLE: Binary string length:', binaryString.length);

        // Convert binary string back to hex
        const hex = binaryString.split('').map(char =>
            char.charCodeAt(0).toString(16).padStart(2, '0')
        ).join('').toUpperCase();

        console.log('🔍 SIMPLE: Final hex result:', hex);

        return {
            hex: hex,
            detectedMagic: 'sparkles',
            strippedInput: stripped
        };
    } catch (error) {
        console.error('❌ SIMPLE: Decode error:', error);
        throw new Error('Simple decode failed: ' + error.message);
    }
}

/**
 * Quick encode with default settings (base-64, sparkles magic)
 * @param {string} hexString - Hex string to encode
 * @returns {string} Emoji-encoded string
 */
function quickEncodeHex(hexString) {
    // Use simple encoding instead of complex binary approach
    return simpleEncodeHex(hexString);
}

/**
 * Quick decode with automatic magic detection
 * @param {string} emojiString - Emoji string to decode
 * @returns {string} Hex string
 */
function quickDecodeEmoji(emojiString) {
    const result = decodeEmojiToHex(emojiString);
    return result.hex;
}

// Export functions for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    // Node.js environment
    module.exports = {
        encodeHexToEmoji,
        decodeEmojiToHex,
        quickEncodeHex,
        quickDecodeEmoji,
        simpleEncodeHex,
        simpleDecodeEmoji,
        setEmojiBase,
        setMagicMode,
        EmojicodingConfig,
        EMOJI_SET_64,
        EMOJI_SET_128,
        MAGIC_DELIMITERS
    };
} else {
    // Browser environment - add to global scope
    window.Emojicoding = {
        encodeHexToEmoji,
        decodeEmojiToHex,
        quickEncodeHex,
        quickDecodeEmoji,
        simpleEncodeHex,
        simpleDecodeEmoji,
        setEmojiBase,
        setMagicMode,
        EmojicodingConfig,
        EMOJI_SET_64,
        EMOJI_SET_128,
        MAGIC_DELIMITERS
    };
}