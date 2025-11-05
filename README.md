# The Advancement

Privacy-first mobile apps for passwordless authentication, decentralized commerce, and ad-free browsing.

## What It Is

**The Advancement** is the consumer-facing application of the [Planet Nine](https://github.com/planet-nine-app/planet-nine) ecosystem. Native iOS and Android apps that provide:

- **Passwordless Authentication** - Cryptographic keys via [Sessionless](https://github.com/planet-nine-app/sessionless), no passwords ever
- **Decentralized Commerce** - Buy and sell without intermediaries using [MAGIC](https://github.com/planet-nine-app/MAGIC) protocol
- **Ad Covering** - Cover ads with peaceful ficus plants instead of blocking them (creators still get paid)
- **CarrierBag System** - Personal data storage across 15 collections (recipes, music, contracts, etc.)
- **Payment Processing** - Stripe-powered payments with instant affiliate payouts to debit cards
- **AdvanceKey Keyboard** - System keyboard for posting BDOs, decoding emojicodes, and casting spells

## Key Features

### For Users
- No email or password required
- Save payment cards for instant checkout
- Receive instant payouts (~30 minutes) to your debit card
- Share your service info with base administrators to receive payments
- Post and save BDOs (Basic Data Objects) to your carrier bag
- Sign contracts using cryptographic keys

### For Base Administrators
- Users can share their Fount, Covenant, and Addie UUIDs with you
- Look up users by any service UUID to verify payout capability
- Set up instant affiliate payouts without complex onboarding

### For Developers
- Full MAGIC protocol integration for spell casting
- Sessionless authentication SDK
- WebView-based architecture for rapid iteration
- Works with the entire Planet Nine allyabase ecosystem

## Running the Apps

### iOS App

**Requirements**: macOS with Xcode 15+

```bash
cd src/The\ Advancement
open The\ Advancement.xcodeproj

# Build and run to iOS Simulator or device
# Select "The Advancement" scheme and press Cmd+R
```

**AdvanceKey Keyboard Extension**:
- Settings → General → Keyboard → Keyboards → Add New Keyboard → AdvanceKey
- Grant "Full Access" when prompted

### Android App

**Requirements**: Android Studio with Kotlin support

```bash
cd src/android
./gradlew :app:assembleDebug

# Or open in Android Studio:
# File → Open → select the-advancement/src/android
# Run → Run 'app'
```

**AdvanceKey Keyboard**:
- Settings → System → Languages & Input → On-screen keyboard → Manage keyboards
- Enable "AdvanceKey"

**Version Bumping** (for Play Store):
```kotlin
// Edit app/build.gradle.kts
versionCode = 3      // Increment by 1
versionName = "1.2"  // Update version string

// Build release bundle
./gradlew :app:bundleRelease
# Upload: app/build/outputs/bundle/release/app-release.aab
```

### Test Environment

**Requirements**: Docker, Node.js 18+

```bash
cd test-server
npm install
npm start

# Open http://localhost:3456
# Test complete Planet Nine purchase flow with Stripe test keys
```

## Architecture

```
the-advancement/
├── src/
│   ├── The Advancement/        # iOS app (Swift)
│   │   ├── iOS (App)/         # Main iOS app
│   │   ├── AdvanceKey/        # iOS keyboard extension
│   │   └── Shared (App)/      # Shared code & HTML/JS
│   ├── android/               # Android app (Kotlin)
│   │   └── app/src/main/
│   │       ├── assets/        # WebView HTML/JS
│   │       ├── java/.../ime/  # AdvanceKey keyboard
│   │       └── java/.../ui/   # Main app activities
│   └── extensions/
│       ├── chrome/            # Chrome extension
│       └── safari/            # Safari extension
├── test-server/               # Complete test environment
└── docs/                      # Detailed documentation
```

## Documentation

- **[Complete Documentation](CLAUDE.md)** - Full technical details, architecture, and implementation
- **[Ad Covering System](docs/AD-COVERING-SYSTEM.md)** - Ficus ad covering with slime monster gaming
- **[Payment Processing](docs/PAYMENT-PROCESSING.md)** - Stripe integration and instant payouts
- **[MAGIC Protocol](docs/MAGIC-PROTOCOL.md)** - Spell casting implementation
- **[Test Environment](docs/TEST-ENVIRONMENT.md)** - Comprehensive testing infrastructure

## The Lore

Benevolent aliens watch humanity from Planet Nine, waiting for us to join their galactic federation called **The Advancement**. We're close, but our collective tendency to divide ourselves into groups holds us back.

One major driver of division? The $600+ billion digital advertising industry that tracks you everywhere online.

We're building an alternative: privacy-first apps that let you navigate the internet without surveillance, passwords, or email. And if you must see ads, at least you can cover them with [peaceful ficus plants](https://github.com/planet-nine-app/the-advancement/blob/main/resources/ficus.jpg?raw=true).

## Current Status (January 2025)

✅ **Production Ready**:
- iOS app (App Store)
- Android app (Google Play)
- Stripe payment processing with instant payouts
- CarrierBag system with 15 collections
- AdvanceKey keyboard extensions
- Service Info for base administrators
- Contract signing via Covenant

🚧 **In Development**:
- Browser extensions (Chrome, Safari)
- Cross-base commerce
- Ad covering system enhancements

## Contributing

See companion docs for detailed guides:

| Dev | UX | Product | Non-Technical |
|-----|----|---------|--------------|
| [README-DEV](./README-DEV.md) | [README-UX](./README-UX.md) | Coming Soon | [README-NT](./README-NT.md) |

---

**The Advancement**: Because humanity deserves better than surveillance capitalism.
