// Onboarding JavaScript - Shared between iOS and Android
// Platform-specific message handlers should be set up by the native code

(function() {
    'use strict';

    // Platform detection (needs to be at top scope for joinAdvancement)
    const platform = detectPlatform();

    try {
        console.log('🔧 Starting onboarding.js initialization...');
        console.log('📱 Platform detected:', platform);

        // Override console.log to send to native
        setupConsoleLogging(platform);

        console.log('🚀 Onboarding view loaded');

        // Check if SVG elements exist
        const svg = document.getElementById('onboardingSVG');
        const yesButton = document.getElementById('yesButton');
        const hellYesButton = document.getElementById('hellYesButton');

        // FIX: Android WebView doesn't handle percentage heights well
        // Set explicit pixel dimensions based on viewport
        if (svg && platform === 'android') {
            const viewportWidth = window.innerWidth;
            const viewportHeight = window.innerHeight;

            // Force SVG to exact viewport dimensions
            svg.style.width = viewportWidth + 'px';
            svg.style.height = viewportHeight + 'px';
            svg.style.position = 'fixed';
            svg.style.top = '0';
            svg.style.left = '0';
        }

        if (!yesButton || !hellYesButton) {
            console.error('❌ Button elements not found!');
            return;
        }

        // Button click handlers
        yesButton.addEventListener('click', joinAdvancement);
        hellYesButton.addEventListener('click', joinAdvancement);

        console.log('✅ Event listeners attached successfully');

    } catch (error) {
        console.error('❌ JavaScript initialization error:', error.message, error.stack);
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

    function joinAdvancement() {
        console.log('🎯 Starting advancement join process');
        document.getElementById('yesButton').style.display = 'none';
        document.getElementById('hellYesButton').style.display = 'none';
        document.getElementById('loadingState').setAttribute('opacity', '1');

        // Send message to native code
        if (platform === 'ios' && window.webkit?.messageHandlers?.onboarding) {
            window.webkit.messageHandlers.onboarding.postMessage({action: 'join'});
        } else if (platform === 'android' && window.Android?.joinAdvancement) {
            window.Android.joinAdvancement();
        }
    }

    // Expose functions for native code to call
    window.updateLoadingText = function(text) {
        document.getElementById('loadingText').textContent = text;
    };

    window.showError = function(errorMessage) {
        document.getElementById('loadingState').setAttribute('opacity', '0');
        document.getElementById('errorState').setAttribute('opacity', '1');
        document.getElementById('errorText').textContent = 'Error: ' + errorMessage;
        setTimeout(function() {
            document.getElementById('yesButton').style.display = 'block';
            document.getElementById('hellYesButton').style.display = 'block';
            document.getElementById('errorState').setAttribute('opacity', '0');
        }, 3000);
    };

    // Global error handler
    window.onerror = function(message, source, lineno, colno, error) {
        console.error('❌ Global error:', message, 'at', source + ':' + lineno);
        return false;
    };

    console.log('🎉 Onboarding JavaScript fully loaded and ready');
})();
