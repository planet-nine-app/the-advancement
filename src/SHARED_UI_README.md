# Shared UI Architecture - The Advancement

## Overview

The Advancement iOS and Android apps now share the same HTML/CSS/JavaScript for their UI, enabling:
- **Single source of truth** for UI across platforms
- **Consistent look and feel** between iOS and Android
- **Easier maintenance** - update once, deploy everywhere

## Architecture

### Shared HTML/CSS/JS Location
```
the-advancement/src/shared/html/
├── onboarding.html    # Onboarding screen UI
├── onboarding.js      # Onboarding screen logic
├── main.html          # Main screen UI
└── main.js            # Main screen logic
```

### Platform Integration

#### Android ✅ (Fully Integrated)
- **Location**: `android/app/src/main/assets/` (copies from shared/)
- **Loading**: `WebView` loads from `file:///android_asset/`
- **JavaScript Bridge**: `@JavascriptInterface` methods in Kotlin
- **Screens**:
  - `OnboardingWebViewScreen.kt` - Loads `onboarding.html`
  - `MainWebViewScreen.kt` - Loads `main.html`

#### iOS (Currently Inline HTML)
- **Current**: HTML embedded as Swift strings in ViewControllers
- **Future**: Can load from app bundle for full sharing

## Shared Features

### Onboarding Screen (`onboarding.html` + `onboarding.js`)
- Dark sci-fi aesthetic with radial gradient background
- Animated particles floating around screen
- Corner brackets in different colors (green, pink, yellow, purple)
- "GREETINGS HUMAN" title
- "Would you like to join THE ADVANCEMENT?" prompt
- YES and HELL YES buttons with glow animations
- Loading state with spinning circle
- Error state with auto-reset
- Console logging bridge to native code

### Main Screen (`main.html` + `main.js`)
- "THE ADVANCEMENT" title at top
- Posted BDOs display area (dynamically populated)
- Text input styled as purple glowing rectangle
- POST button with green glow animation
- Selectable emojicodes displayed above each BDO
- Dynamic SVG height adjustment as BDOs are added
- Console logging bridge to native code

## JavaScript ↔ Native Communication

### Platform Detection
```javascript
const platform = detectPlatform(); // 'ios' or 'android'
```

### Console Logging
Both platforms receive console.log/error/warn:
- **iOS**: `window.webkit.messageHandlers.console.postMessage()`
- **Android**: `window.Android.log()`

### Onboarding Actions
- **iOS**: `window.webkit.messageHandlers.onboarding.postMessage({action: 'join'})`
- **Android**: `window.Android.joinAdvancement()`

### Main Screen Actions
- **iOS**: `window.webkit.messageHandlers.mainApp.postMessage({action: 'post', text: text})`
- **Android**: `window.Android.postBDO(text)`

### Native → JavaScript
Both platforms can call:
```javascript
window.updateLoadingText(text)  // Update loading message
window.addPostedBDO(bdoData)    // Add BDO to display
window.showError(message)       // Show error message
```

## Color Palette (Shared Across Platforms)

```css
Green:  #10b981  (titles, success)
Purple: #8b5cf6  (inputs, secondary)
Pink:   #ec4899  (BDO cards, accents)
Yellow: #fbbf24  (emojicodes, highlights)
```

## File Sizes
- `onboarding.html`: ~3.5 KB
- `onboarding.js`: ~3.0 KB
- `main.html`: ~2.8 KB
- `main.js`: ~5.5 KB
- **Total**: ~15 KB uncompressed

## Benefits

1. **Consistency**: Both platforms render identical UI
2. **Maintainability**: Fix bugs once, benefit everywhere
3. **Velocity**: Design changes deploy to both platforms simultaneously
4. **Testing**: UI bugs found on one platform fixed for both
5. **Designer-Friendly**: HTML/CSS easier to modify than native code

## Adding to iOS (Optional)

To complete the iOS integration:

1. In Xcode, add the 4 files from `shared/html/` to iOS app target
2. Update `OnboardingViewController.swift`:
   ```swift
   private func loadOnboardingPage() {
       guard let htmlPath = Bundle.main.path(forResource: "onboarding", ofType: "html"),
             let htmlString = try? String(contentsOfFile: htmlPath) else {
           return
       }

       let baseURL = URL(fileURLWithPath: htmlPath).deletingLastPathComponent()
       webView.loadHTMLString(htmlString, baseURL: baseURL)
   }
   ```
3. Update `MainViewController.swift` similarly for `main.html`

## Future Enhancements

- Add CSS file separation from HTML
- Add TypeScript for type-safe JavaScript
- Create build tooling to minify/bundle for production
- Add hot-reload for development
- Version the HTML files with app updates

---

**Status**: Android fully integrated ✅ | iOS compatible (inline HTML) ✅
