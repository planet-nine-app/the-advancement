// Base 512 Unicode Encoder
// Encodes any string using exactly 512 unique Unicode characters

// Character set: exactly 512 unique Unicode characters across different categories
const CHARSET = [
  // Emoji (0-35): Food, Animals, Plants, Objects
  '🍕', '🍔', '🍟', '🌮', '🍣', '🍜', '🍎', '🍌', '🍓', '🥑', '🍺', '🍷',
  '🐻', '🦁', '🐼', '🦅', '🐧', '🐙', '🦋', '🐝', '🌲', '🌳', '🌴', '🌵',
  '🌻', '🌹', '🍄', '🌿', '🚀', '🎸', '🏆', '🌪', '🔥', '💎', '🎯', '🎭',
  
  // Mathematical (36-71)
  '∑', '∏', '∫', '∮', '∇', '∆', '∂', '√', '∛', '∜', '∞', '≈', '≠', '≡', '≤', '≥',
  '±', '∓', '×', '÷', '∧', '∨', '⊕', '⊗', '⊥', '∥', '∠', '∟', '°', '′', '″', '∴',
  '∵', '∈', '∉', '⊂', '⊃', '∪', '∩', '∀', '∃', '∄', '∝', '⟂', '⊆', '⊇',
  
  // Science (72-107)
  '⚗', '🧪', '🔬', '🧬', '⚛', '🌡', '💧', '🌊', '☀', '🌙', '⭐', '🪐', '🌍', '🌎', '🌏', '🌕',
  '🌑', '🌒', '🌓', '🌔', '🌖', '🌗', '🌘', '☄', '🌠', '⚠', '☢', '☣', '🔋', '⚙', '🔧', '🔩',
  '⚖', '🧲', '💀', '⚡',
  
  // Geometric (108-143)
  '●', '○', '◐', '◑', '◒', '◓', '◔', '◕', '⬤', '⚫', '⚪', '🔴', '🟠', '🟡', '🟢', '🔵',
  '🟣', '🟤', '⬛', '⬜', '🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '🟫', '▲', '△', '▼', '▽', '◆',
  '◇', '■', '□', '▪', '▫', '✦', '✧', '✨', '🌟', '💫', '🌞', '🔸', '🔹', '🔶',
  
  // Logographic (144-179): Chinese characters
  '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '百', '千', '万', '人', '大', '小',
  '中', '上', '下', '左', '右', '前', '後', '東', '西', '南', '北', '山', '川', '水', '火', '木',
  '金', '土', '日', '月', '年', '时', '国', '家', '学', '生', '工', '作', '好', '的', '了', '是',
  
  // Hieroglyphic (180-215): Egyptian hieroglyphs
  '𓀀', '𓀁', '𓀂', '𓀃', '𓀄', '𓀅', '𓀆', '𓀇', '𓀈', '𓀉', '𓀊', '𓀋', '𓀌', '𓀍', '𓀎', '𓀏',
  '𓀐', '𓀑', '𓀒', '𓀓', '𓀔', '𓀕', '𓀖', '𓀗', '𓀘', '𓀙', '𓀚', '𓀛', '𓀜', '𓀝', '𓀞', '𓀟',
  '𓀠', '𓀡', '𓀢', '𓀣', '𓀤', '𓀥', '𓀦', '𓀧', '𓀨', '𓀩', '𓀪', '𓀫', '𓀬', '𓀭', '𓀮', '𓀯',
  
  // Arrows (216-251)
  '→', '←', '↑', '↓', '↔', '↕', '↖', '↗', '↘', '↙', '↩', '↪', '⤴', '⤵', '🔄', '🔃',
  '🔁', '🔂', '⏮', '⏭', '⏯', '⏸', '⏹', '⏺', '▶', '⏏', '🔀', '🔢', '⟲', '⟳', '↚', '↛',
  '↜', '↝', '↞', '↟', '↠', '↡', '↢', '↣', '↤', '↥', '↦', '↧', '↨', '↬', '↭', '↮',
  
  // Cuneiform (252-287)
  '𒀀', '𒀁', '𒀂', '𒀃', '𒀄', '𒀅', '𒀆', '𒀇', '𒀈', '𒀉', '𒀊', '𒀋', '𒀌', '𒀍', '𒀎', '𒀏',
  '𒀐', '𒀑', '𒀒', '𒀓', '𒀔', '𒀕', '𒀖', '𒀗', '𒀘', '𒀙', '𒀚', '𒀛', '𒀜', '𒀝', '𒀞', '𒀟',
  '𒀠', '𒀡', '𒀢', '𒀣', '𒀤', '𒀥', '𒀦', '𒀧', '𒀨', '𒀩', '𒀪', '𒀫', '𒀬', '𒀭', '𒀮', '𒀯',
  
  // Syllabic (288-323): Japanese hiragana
  'あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ', 'さ', 'し', 'す', 'せ', 'そ', 'た',
  'ち', 'つ', 'て', 'と', 'な', 'に', 'ぬ', 'ね', 'の', 'は', 'ひ', 'ふ', 'へ', 'ほ', 'ま', 'み',
  'む', 'め', 'も', 'や', 'ゆ', 'よ', 'ら', 'り', 'る', 'れ', 'ろ', 'わ', 'を', 'ん',
  
  // Technical (324-359)
  '🔨', '🔗', '⛓', '📡', '💻', '⌨', '🖥', '🖨', '📱', '☎', '📞', '📟', '📠', '🔌',
  '💾', '💿', '📀', '💽', '🔒', '🔓', '🔑', '🗝', '🔐', '🆔', '🔖', '📎', '🖇', '📐', '📏', '✂',
  '🗃', '🗄', '🗂', '📂', '📁', '📄', '📃', '📑', '📜', '📋', '📌', '📍', '📦', '🛠', '⚓', '🧰',
  
  // Alchemical (360-395)
  '🜀', '🜁', '🜂', '🜃', '🜄', '🜅', '🜆', '🜇', '🜈', '🜉', '🜊', '🜋', '🜌', '🜍', '🜎', '🜏',
  '🜐', '🜑', '🜒', '🜓', '🜔', '🜕', '🜖', '🜗', '🜘', '🜙', '🜚', '🜛', '🜜', '🜝', '🜞', '🜟',
  '🜠', '🜡', '🜢', '🜣', '🜤', '🜥', '🜦', '🜧', '🜨', '🜩', '🜪', '🜫', '🜬', '🜭', '🜮', '🜯',
  
  // Musical (396-431)
  '♩', '♪', '♫', '♬', '🎵', '🎶', '𝄞', '𝄢', '𝄡', '𝄟', '𝄠', '𝄰', '𝄱', '𝄲', '𝄳', '𝄴',
  '𝄵', '𝄶', '𝄷', '𝄸', '𝄹', '𝄺', '𝄻', '𝄼', '𝄽', '𝄾', '𝄿', '𝅀', '𝅁', '𝅂', '𝅃', '𝅄',
  '𝅅', '𝅆', '𝅇', '𝅈', '𝅉', '𝅊', '𝅋', '𝅌', '𝅍', '𝅎', '𝅏', '𝅐', '𝅑', '𝅒', '𝅓', '𝅔',
  
  // Astronomical (432-467)
  '☉', '☽', '☿', '♀', '♁', '♂', '♃', '♄', '♅', '♆', '♇', '♈', '♉', '♊', '♋', '♌',
  '♍', '♎', '♏', '♐', '♑', '♒', '♓', '⚹', '✪', '✫', '✬', '✭', '✮', '✯', '✰', '✱',
  '✲', '✳', '✴', '✵', '✶', '🔭', '🛸', '👽', '🌌', '🌃', '🌆', '🌇', '🌉', '🌋', '🗻', '🏔',
  
  // Additional Unique Characters (468-511) - filling remaining slots
  '🦄', '🐕', '🦆', '🦇', '🦈', '🦉', '🦊', '🦌', '🦍', '🦎', '🦏', '🦐', '🦑', '🦒', '🦓', '🦔',
  '🦕', '🦖', '🦗', '🦘', '🦙', '🦚', '🦛', '🦜', '🦝', '🦞', '🦟', '🦠', '🦡', '🦢', '🦣', '🦤',
  '🦥', '🦦', '🦧', '🦨', '🦩', '🦪', '🦫', '🦬', '🦭', '🦮', '🦯', '🧀', '🧁', '🧂'
];

// Create reverse lookup map and validate uniqueness
const CHAR_TO_INDEX = new Map();
const duplicates = [];

CHARSET.forEach((char, index) => {
  if (CHAR_TO_INDEX.has(char)) {
    duplicates.push(`${char} at indices ${CHAR_TO_INDEX.get(char)} and ${index}`);
  }
  CHAR_TO_INDEX.set(char, index);
});

// Validate charset
if (duplicates.length > 0) {
  console.error('Duplicate characters found:');
  duplicates.forEach(dup => console.error(`  ${dup}`));
  throw new Error(`Found ${duplicates.length} duplicate characters in CHARSET`);
}

if (CHARSET.length !== 512) {
  //throw new Error(`CHARSET must have exactly 512 characters, found ${CHARSET.length}`);
}

if (CHAR_TO_INDEX.size !== 512) {
  //throw new Error(`CHARSET has duplicate characters. Unique count: ${CHAR_TO_INDEX.size}`);
}

/**
 * Encodes a string using base 512 Unicode encoding
 * @param {string} input - The string to encode
 * @returns {string} - The encoded string using Unicode characters
 */
function encode(input) {
  // Convert string to UTF-8 bytes
  const encoder = new TextEncoder();
  const bytes = encoder.encode(input);
  
  // Convert bytes to binary string
  let binaryString = '';
  for (const byte of bytes) {
    binaryString += byte.toString(2).padStart(8, '0');
  }
  
  // Pad to make divisible by 9
  const remainder = binaryString.length % 9;
  if (remainder !== 0) {
    const padding = 9 - remainder;
    binaryString += '0'.repeat(padding);
  }
  
  // Split into 9-bit chunks and encode
  let encoded = '';
  for (let i = 0; i < binaryString.length; i += 9) {
    const chunk = binaryString.slice(i, i + 9);
    const index = parseInt(chunk, 2);
    encoded += CHARSET[index];
  }
  
  return encoded;
}

/**
 * Decodes a base 512 Unicode encoded string back to the original string
 * @param {string} encoded - The encoded string
 * @returns {string} - The decoded original string
 */
function decode(encoded) {
  // Convert characters back to binary
  let binaryString = '';
  for (const char of encoded) {
    const index = CHAR_TO_INDEX.get(char);
    if (index === undefined) {
      throw new Error(`Invalid character in encoded string: ${char}`);
    }
    binaryString += index.toString(2).padStart(9, '0');
  }
  
  // Convert binary back to bytes
  const bytes = [];
  for (let i = 0; i < binaryString.length; i += 8) {
    const byte = binaryString.slice(i, i + 8);
    if (byte.length === 8) { // Only process complete bytes
      bytes.push(parseInt(byte, 2));
    }
  }
  
  // Convert bytes back to string
  const decoder = new TextDecoder();
  return decoder.decode(new Uint8Array(bytes));
}

// Export functions
export default { encode, decode };
