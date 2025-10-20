// Main screen JavaScript - Shared between iOS and Android
// Platform-specific message handlers should be set up by the native code

(function() {
    'use strict';

    // Platform detection
    const platform = detectPlatform();

    // Override console.log to send to native
    setupConsoleLogging(platform);

    console.log('🚀 Main view loaded');

    const textInput = document.getElementById('textInput');

    console.log('✅ Text input element:', textInput);

    // Log input changes
    textInput.addEventListener('input', function() {
        console.log('✏️ Input changed:', textInput.value);
    });

    textInput.addEventListener('focus', function() {
        console.log('🎯 Input focused');
    });

    textInput.addEventListener('blur', function() {
        console.log('👋 Input blurred');
    });

    // POST button click handler
    document.getElementById('postButton').addEventListener('click', function() {
        console.log('🔘 POST button clicked');
        const text = textInput.value.trim();
        if (!text) {
            console.warn('⚠️ No text entered');
            alert('Please enter some text first');
            return;
        }

        console.log('📤 Posting text:', text);

        // Send to native code
        if (platform === 'ios' && window.webkit?.messageHandlers?.mainApp) {
            window.webkit.messageHandlers.mainApp.postMessage({
                action: 'post',
                text: text
            });
        } else if (platform === 'android' && window.Android?.postBDO) {
            window.Android.postBDO(text);
        }

        // Clear input
        textInput.value = '';
    });

    function detectPlatform() {
        const ua = navigator.userAgent;
        if (/iPhone|iPad|iPod/.test(ua)) {
            return 'ios';
        } else if (/Android/.test(ua)) {
            return 'android';
        }
        return 'unknown';
    }

    function setupConsoleLogging(platform) {
        const originalLog = console.log;
        const originalError = console.error;
        const originalWarn = console.warn;

        console.log = function(...args) {
            const message = args.map(arg =>
                typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
            ).join(' ');

            if (platform === 'ios' && window.webkit?.messageHandlers?.console) {
                window.webkit.messageHandlers.console.postMessage({level: 'log', message: message});
            } else if (platform === 'android' && window.Android?.log) {
                window.Android.log(message);
            }

            originalLog.apply(console, args);
        };

        console.error = function(...args) {
            const message = args.map(arg =>
                typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
            ).join(' ');

            if (platform === 'ios' && window.webkit?.messageHandlers?.console) {
                window.webkit.messageHandlers.console.postMessage({level: 'error', message: message});
            } else if (platform === 'android' && window.Android?.logError) {
                window.Android.logError(message);
            }

            originalError.apply(console, args);
        };

        console.warn = function(...args) {
            const message = args.map(arg =>
                typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
            ).join(' ');

            if (platform === 'ios' && window.webkit?.messageHandlers?.console) {
                window.webkit.messageHandlers.console.postMessage({level: 'warn', message: message});
            } else if (platform === 'android' && window.Android?.logWarn) {
                window.Android.logWarn(message);
            }

            originalWarn.apply(console, args);
        };
    }

    // Function called from native to add posted BDO to display
    window.addPostedBDO = function(bdoData) {
        const displayArea = document.getElementById('bdoDisplayArea');
        const currentBDOs = displayArea.querySelectorAll('g').length;
        const yOffset = currentBDOs * 25;

        // Create SVG for this BDO
        const bdoGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        bdoGroup.setAttribute('transform', `translate(0, ${yOffset})`);

        // BDO Container
        const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
        rect.setAttribute('x', '10');
        rect.setAttribute('y', '0');
        rect.setAttribute('width', '80');
        rect.setAttribute('height', '20');
        rect.setAttribute('rx', '1');
        rect.setAttribute('fill', 'rgba(236, 72, 153, 0.15)');
        rect.setAttribute('stroke', '#ec4899');
        rect.setAttribute('stroke-width', '0.25');
        rect.setAttribute('filter', 'url(#pinkGlow)');
        bdoGroup.appendChild(rect);

        // BDO Text
        const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', '50');
        text.setAttribute('y', '8');
        text.setAttribute('text-anchor', 'middle');
        text.setAttribute('style', 'font-family: -apple-system; font-size: 3px; font-weight: 600;');
        text.setAttribute('fill', '#ec4899');
        text.textContent = bdoData.text;
        bdoGroup.appendChild(text);

        displayArea.appendChild(bdoGroup);

        // Add HTML overlay for selectable emojicode
        const emojiOverlay = document.createElement('div');
        const totalYOffset = 32 + yOffset; // Base offset (32 for BDO display area) + BDO offset
        emojiOverlay.style.cssText = `
            position: absolute;
            top: calc(${totalYOffset} / 140 * 100vh + 12vh);
            left: 50%;
            transform: translateX(-50%);
            color: #fbbf24;
            font-family: -apple-system;
            font-size: 4vh;
            font-weight: 400;
            text-align: center;
            user-select: text;
            -webkit-user-select: text;
            pointer-events: auto;
            filter: drop-shadow(0 0 8px rgba(251, 191, 36, 0.6));
            letter-spacing: 0.2em;
        `;
        emojiOverlay.textContent = bdoData.emojicode || '🌟';
        document.body.appendChild(emojiOverlay);

        // Update SVG height to accommodate new BDO
        const newHeight = 140 + (currentBDOs * 10);
        document.getElementById('mainSVG').setAttribute('viewBox', `0 0 100 ${newHeight}`);

        console.log('✅ BDO added to display:', bdoData);
    };
})();
