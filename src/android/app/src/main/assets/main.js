// Main screen JavaScript - Shared between iOS and Android
// Platform-specific message handlers should be set up by the native code

(function() {
    'use strict';

    // Platform detection
    const platform = detectPlatform();

    // Override console.log to send to native
    setupConsoleLogging(platform);

    console.log('🚀 Main view loaded');

    // FIX: Android WebView doesn't handle percentage heights well
    // Set explicit pixel dimensions based on viewport
    const mainSVG = document.getElementById('mainSVG');
    const inputContainer = document.getElementById('inputContainer');

    if (mainSVG && platform === 'android') {
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;

        // Force SVG to exact viewport dimensions
        mainSVG.style.width = viewportWidth + 'px';
        mainSVG.style.height = viewportHeight + 'px';
        mainSVG.style.position = 'fixed';
        mainSVG.style.top = '0';
        mainSVG.style.left = '0';

        // Position input container based on viewBox coordinates
        // Input area is at y=102 in viewBox (0 0 100 140)
        // Calculate pixel position: (102/140) * viewportHeight
        const inputTop = (102 / 140) * viewportHeight;
        const inputHeight = (10 / 140) * viewportHeight;
        const inputLeft = (10 / 100) * viewportWidth;
        const inputWidth = (80 / 100) * viewportWidth;

        inputContainer.style.top = inputTop + 'px';
        inputContainer.style.left = inputLeft + 'px';
        inputContainer.style.width = inputWidth + 'px';
        inputContainer.style.height = inputHeight + 'px';

        console.log('Input positioned at:', {
            top: inputTop,
            left: inputLeft,
            width: inputWidth,
            height: inputHeight
        });
    }

    const textInput = document.getElementById('textInput');

    console.log('✅ Text input element:', textInput);

    // Log input changes
    textInput.addEventListener('input', function(e) {
        console.log('✏️ Input changed:', textInput.value);
        console.log('✏️ Input event:', e);

        // Debug: Check visual state
        const rect = textInput.getBoundingClientRect();
        const style = window.getComputedStyle(textInput);
        console.log('🔍 Input visual state:', {
            value: textInput.value,
            valueLength: textInput.value.length,
            width: rect.width,
            height: rect.height,
            fontSize: style.fontSize,
            color: style.color,
            visibility: style.visibility,
            display: style.display,
            scrollLeft: textInput.scrollLeft,
            scrollWidth: textInput.scrollWidth
        });
    });

    textInput.addEventListener('keydown', function(e) {
        console.log('⌨️ Keydown:', e.key, e.keyCode);

        // Handle backspace manually on Android (but not IME composition)
        if (platform === 'android' && e.keyCode !== 229 && (e.key === 'Backspace' || e.keyCode === 8)) {
            e.preventDefault();
            if (textInput.value.length > 0) {
                textInput.value = textInput.value.slice(0, -1);
                // Manually trigger input event
                const inputEvent = new Event('input', { bubbles: true });
                textInput.dispatchEvent(inputEvent);
            }
        }
    });

    textInput.addEventListener('keypress', function(e) {
        console.log('⌨️ Keypress:', e.key, e.keyCode);

        // Manually handle text input on Android (but not IME composition)
        // IME composition uses keyCode 229 and should be left alone
        if (platform === 'android' && e.keyCode !== 229) {
            e.preventDefault();

            // Only add printable characters
            if (e.key && e.key.length === 1) {
                textInput.value += e.key;
                console.log('✍️ Manually added character:', e.key, 'New value:', textInput.value);

                // Manually trigger input event
                const inputEvent = new Event('input', { bubbles: true });
                textInput.dispatchEvent(inputEvent);

                // Force focus to stay on input
                setTimeout(() => {
                    if (document.activeElement !== textInput) {
                        console.log('⚠️ Input lost focus, refocusing');
                        textInput.focus();
                    }
                }, 10);
            } else if (e.keyCode === 13 || e.key === 'Enter') {
                // Handle Enter key - trigger POST button
                console.log('↵ Enter pressed');
                document.getElementById('postButton').click();
            }
        }
    });

    textInput.addEventListener('keyup', function(e) {
        console.log('⌨️ Keyup:', e.key, e.keyCode);
    });

    textInput.addEventListener('focus', function() {
        console.log('🎯 Input focused');
        console.log('🎯 Active element:', document.activeElement);
        console.log('🎯 Input value:', textInput.value);

        // Request keyboard on Android
        if (platform === 'android' && window.Android?.showKeyboard) {
            window.Android.showKeyboard();
        }
    });

    textInput.addEventListener('blur', function(e) {
        console.log('👋 Input blurred');
        console.log('👋 Blur relatedTarget:', e.relatedTarget);

        // On Android, try to prevent unwanted blur if keyboard is still showing
        if (platform === 'android') {
            console.log('⚠️ Android blur detected, will refocus on next interaction');
        }
    });

    textInput.addEventListener('click', function(e) {
        console.log('🖱️ Input clicked');
        e.stopPropagation();
        textInput.focus();
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

    // BAG button click handler
    document.getElementById('bagButton').addEventListener('click', function() {
        console.log('🎒 BAG button clicked');

        // Send to native code
        if (platform === 'ios' && window.webkit?.messageHandlers?.mainApp) {
            window.webkit.messageHandlers.mainApp.postMessage({
                action: 'openCarrierBag'
            });
        } else if (platform === 'android' && window.Android?.openCarrierBag) {
            window.Android.openCarrierBag();
        }
    });

    // Keyboard switch button (Android only)
    const keyboardSwitchButton = document.getElementById('keyboardSwitchButton');
    if (keyboardSwitchButton) {
        if (platform === 'android') {
            keyboardSwitchButton.addEventListener('click', function() {
                console.log('⌨️ Keyboard switch button clicked');
                if (window.Android?.showKeyboardPicker) {
                    // First focus the input
                    textInput.focus();

                    // Show keyboard picker
                    window.Android.showKeyboardPicker();

                    // Refocus input after a short delay to trigger keyboard
                    setTimeout(() => {
                        console.log('⌨️ Refocusing input to trigger keyboard');
                        textInput.blur();
                        setTimeout(() => {
                            textInput.focus();
                            if (window.Android?.showKeyboard) {
                                window.Android.showKeyboard();
                            }
                        }, 100);
                    }, 500);
                } else {
                    console.warn('⚠️ Keyboard picker not available');
                }
            });
        } else {
            // Hide on iOS
            keyboardSwitchButton.style.display = 'none';
        }
    }

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

        // Calculate positions differently for Android (use pixels instead of vh)
        let topPosition, fontSize;
        if (platform === 'android') {
            const viewportHeight = window.innerHeight;
            const pixelTop = (totalYOffset / 140) * viewportHeight + (12 / 100) * viewportHeight;
            topPosition = pixelTop + 'px';
            fontSize = '36px'; // Fixed pixel size instead of 4vh
        } else {
            topPosition = `calc(${totalYOffset} / 140 * 100vh + 12vh)`;
            fontSize = '4vh';
        }

        emojiOverlay.style.cssText = `
            position: absolute;
            top: ${topPosition};
            left: 50%;
            transform: translateX(-50%);
            color: #fbbf24;
            font-family: -apple-system;
            font-size: ${fontSize};
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
