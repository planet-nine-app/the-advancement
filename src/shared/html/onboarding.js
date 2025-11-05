// Onboarding JavaScript - Shared between iOS and Android
// Platform-specific message handlers should be set up by the native code

(function() {
    'use strict';

    // Platform detection
    const platform = detectPlatform();

    // Override console.log to send to native
    setupConsoleLogging(platform);

    console.log('🚀 Onboarding view loaded');

    // Button click handlers
    document.getElementById('yesButton').addEventListener('click', joinAdvancement);
    document.getElementById('hellYesButton').addEventListener('click', joinAdvancement);

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
})();
