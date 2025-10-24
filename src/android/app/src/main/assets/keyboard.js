// AdvanceKey Keyboard JavaScript

(function() {
    'use strict';

    console.log('🎹 AdvanceKey keyboard loaded');

    let currentMode = 'standard';
    let postedBDOs = [];
    let clipboardText = '';

    // Mode button handling
    const modeButtons = document.querySelectorAll('.mode-button');
    modeButtons.forEach(button => {
        button.addEventListener('click', () => {
            const mode = button.dataset.mode;
            switchMode(mode);
        });
    });

    function switchMode(mode) {
        console.log('🔀 Switching to mode:', mode);
        currentMode = mode;

        // Update button selection
        modeButtons.forEach(btn => {
            if (btn.dataset.mode === mode) {
                btn.classList.add('selected');
            } else {
                btn.classList.remove('selected');
            }
        });

        // Render content for selected mode
        renderContent(mode);
    }

    function renderContent(mode) {
        const contentArea = document.getElementById('contentArea');

        switch(mode) {
            case 'standard':
                renderStandardKeyboard(contentArea);
                break;
            case 'demoji':
                renderDemojiPanel(contentArea);
                break;
            case 'magic':
                renderMagicPanel(contentArea);
                break;
            case 'save':
                renderSavePanel(contentArea);
                break;
            case 'bdo':
                renderBDOPanel(contentArea);
                break;
        }
    }

    // Standard keyboard rendering
    function renderStandardKeyboard(container) {
        const rows = [
            ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
            ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
            ['Z', 'X', 'C', 'V', 'B', 'N', 'M']
        ];

        let html = '';
        rows.forEach(row => {
            html += '<div class="keyboard-row">';
            row.forEach(key => {
                html += `<button class="key-button" data-key="${key}">${key}</button>`;
            });
            html += '</div>';
        });

        // Space and delete row
        html += '<div class="keyboard-row">';
        html += '<button class="key-button wide" data-key=" ">Space</button>';
        html += '<button class="key-button" data-key="BACKSPACE">←</button>';
        html += '<button class="key-button" data-key="ENTER">↵</button>';
        html += '</div>';

        container.innerHTML = html;

        // Add click handlers for keys
        container.querySelectorAll('.key-button').forEach(button => {
            button.addEventListener('click', () => {
                const key = button.dataset.key;
                handleKeyPress(key);
            });
        });
    }

    function handleKeyPress(key) {
        console.log('⌨️ Key pressed:', key);

        if (key === 'BACKSPACE') {
            if (window.Android && window.Android.deleteText) {
                window.Android.deleteText();
            }
        } else if (key === 'ENTER') {
            // Send newline
            if (window.Android && window.Android.insertText) {
                window.Android.insertText('\n');
            }
        } else {
            // Insert character
            if (window.Android && window.Android.insertText) {
                window.Android.insertText(key);
            }
        }
    }

    // DEMOJI panel rendering
    function renderDemojiPanel(container) {
        const hasClipboard = clipboardText && clipboardText.trim().length > 0;

        container.innerHTML = `
            <div id="demojiPanel">
                <h3 class="panel-header demoji">DEMOJI - Decode Emojicode</h3>
                <div class="clipboard-text">
                    ${hasClipboard ? `Clipboard: ${clipboardText}` : 'No emojicode in clipboard'}
                </div>
                <button class="decode-button" ${!hasClipboard ? 'disabled' : ''} onclick="decodeEmojicode()">
                    Decode & Insert
                </button>
            </div>
        `;
    }

    window.decodeEmojicode = function() {
        console.log('🔍 Decoding emojicode:', clipboardText);
        if (window.Android && window.Android.decodeEmojicode) {
            window.Android.decodeEmojicode(clipboardText);
        }
    };

    // MAGIC panel rendering
    function renderMagicPanel(container) {
        const spells = [
            { name: 'arethaUserPurchase', description: 'Purchase with nineum' },
            { name: 'teleport', description: 'Teleport to location' },
            { name: 'grant', description: 'Grant experience' }
        ];

        let html = `
            <div id="magicPanel">
                <h3 class="panel-header magic">MAGIC - Cast Spells</h3>
        `;

        spells.forEach(spell => {
            html += `
                <div class="spell-button" onclick="castSpell('${spell.name}')">
                    <div class="spell-name">${spell.name}</div>
                    <div class="spell-description">${spell.description}</div>
                </div>
            `;
        });

        html += '</div>';
        container.innerHTML = html;
    }

    window.castSpell = function(spellName) {
        console.log('🪄 Casting spell:', spellName);
        if (window.Android && window.Android.castSpell) {
            window.Android.castSpell(spellName);
        }
    };

    // SAVE panel rendering
    function renderSavePanel(container) {
        // Get current BDO from clipboard or latest decoded BDO
        const hasBDO = clipboardText && clipboardText.trim().length > 0;

        // Collection icons mapping
        const collectionIcons = {
            'cookbook': '🍳',
            'apothecary': '🧪',
            'gallery': '🖼️',
            'bookshelf': '📚',
            'familiarPen': '🐾',
            'machinery': '⚙️',
            'metallics': '💎',
            'music': '🎵',
            'oracular': '🔮',
            'greenHouse': '🌿',
            'closet': '👔',
            'games': '🎮',
            'events': '🎫',
            'contracts': '📜',
            'stacks': '🏠'
        };

        // Determine collection from clipboard emojicode
        let targetCollection = 'music'; // default
        let collectionIcon = collectionIcons[targetCollection];

        let html = `
            <div id="savePanel">
                <h3 class="panel-header save">SAVE - Save to Carrier Bag</h3>
                <div class="save-info">
                    ${hasBDO ?
                        'Ready to save the current item to your carrier bag!' :
                        'Copy an emojicode or decode a BDO first'}
                </div>
        `;

        if (hasBDO) {
            html += `
                <div class="collection-preview">
                    <div class="collection-icon-preview">${collectionIcon}</div>
                    <div class="collection-name-preview">→ ${targetCollection}</div>
                </div>
            `;
        }

        html += `
                <button class="save-button" ${!hasBDO ? 'disabled' : ''} onclick="saveToCarrierBag()">
                    💾 Save to Carrier Bag
                </button>
            </div>
        `;

        container.innerHTML = html;
    }

    window.saveToCarrierBag = function() {
        console.log('💾 Saving to carrier bag');
        if (window.Android && window.Android.saveToCarrierBag) {
            window.Android.saveToCarrierBag(clipboardText);
        }
    };

    // Collection type mapping (matches iOS logic)
    function determineCollection(bdoData) {
        const type = bdoData.type || '';

        // Type-to-collection mapping
        if (type === 'recipe' || type === 'food') return 'cookbook';
        if (type === 'potion' || type === 'remedy') return 'apothecary';
        if (type === 'artwork' || type === 'image') return 'gallery';
        if (type === 'book' || type === 'literature') return 'bookshelf';
        if (type === 'pet' || type === 'familiar') return 'familiarPen';
        if (type === 'tool' || type === 'machine') return 'machinery';
        if (type === 'gem' || type === 'metal') return 'metallics';
        if (type === 'music' || type === 'song' || type === 'canimus-feed') return 'music';
        if (type === 'prophecy' || type === 'divination') return 'oracular';
        if (type === 'plant' || type === 'botanical') return 'greenHouse';
        if (type === 'clothing' || type === 'garment') return 'closet';
        if (type === 'game' || type === 'entertainment') return 'games';
        if (type === 'event' || type === 'popup') return 'events';
        if (type === 'contract' || type === 'covenant') return 'contracts';
        if (type === 'room' || type === 'space') return 'stacks';

        // Default to appropriate collection based on content
        return 'stacks';
    }

    // BDO panel rendering
    function renderBDOPanel(container) {
        if (!postedBDOs || postedBDOs.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No BDOs Posted Yet</h3>
                    <p>Post a BDO from the main screen to see it here</p>
                </div>
            `;
            return;
        }

        let html = `
            <div id="bdoList">
                <h3 class="panel-header bdo">Your Posted BDOs</h3>
        `;

        postedBDOs.forEach((bdo, index) => {
            html += `
                <div class="bdo-card" onclick="insertEmojicode(${index})">
                    <div class="bdo-text">${bdo.text}</div>
                    <div class="bdo-emojicode">${bdo.emojicode}</div>
                    <div class="bdo-timestamp">${bdo.timestamp}</div>
                </div>
            `;
        });

        html += '</div>';
        container.innerHTML = html;
    }

    window.insertEmojicode = function(index) {
        const bdo = postedBDOs[index];
        console.log('📋 Inserting emojicode:', bdo.emojicode);
        if (window.Android && window.Android.insertText) {
            window.Android.insertText(bdo.emojicode);
        }
    };

    // Function called from native code to update posted BDOs
    window.updatePostedBDOs = function(bdosJson) {
        console.log('📦 Updating posted BDOs:', bdosJson);
        try {
            postedBDOs = JSON.parse(bdosJson);
            console.log('✅ Loaded', postedBDOs.length, 'posted BDOs');

            // If currently showing BDO panel, refresh it
            if (currentMode === 'bdo') {
                renderBDOPanel(document.getElementById('contentArea'));
            }
        } catch (e) {
            console.error('❌ Failed to parse BDOs:', e);
        }
    };

    // Function called from native code to update clipboard
    window.updateClipboard = function(text) {
        console.log('📋 Clipboard updated:', text);
        clipboardText = text;

        // If currently showing DEMOJI panel, refresh it
        if (currentMode === 'demoji') {
            renderDemojiPanel(document.getElementById('contentArea'));
        }
    };

    // Initialize with standard keyboard
    renderContent('standard');

    // Request initial data from Android
    if (window.Android) {
        if (window.Android.getPostedBDOs) {
            const bdosJson = window.Android.getPostedBDOs();
            if (bdosJson) {
                window.updatePostedBDOs(bdosJson);
            }
        }
        if (window.Android.getClipboardText) {
            const clipboard = window.Android.getClipboardText();
            if (clipboard) {
                window.updateClipboard(clipboard);
            }
        }
    }

    console.log('✅ AdvanceKey keyboard initialized');
})();
