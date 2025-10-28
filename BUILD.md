# Building The Advancement

Simple command-line builds for Android and iOS with no external dependencies.

## Quick Start

```bash
# Make script executable (one time)
chmod +x build.sh

# Build both platforms
./build.sh

# Build just Android
./build.sh android

# Build just iOS
./build.sh ios
```

## One-Time Setup

### iOS: Update Team ID

1. Find your Team ID in App Store Connect or Xcode
2. Edit `src/The Advancement/ExportOptions.plist`
3. Replace `YOUR_TEAM_ID` with your actual team ID

### Android: Signing Configuration

Make sure your signing config is set in `src/android/app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("path/to/your/keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "your-password"
            keyAlias = "your-key-alias"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "your-password"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## Version Management

### Check Current Versions

```bash
./build.sh versions
```

Output:
```
Android: 1.0.0 (code: 1)
iOS:     1.0.0 (build: 1)
```

### Bump Version Codes/Build Numbers

```bash
# Increment Android version code (1 → 2)
./build.sh bump-android

# Increment iOS build number (1 → 2)
./build.sh bump-ios
```

### Change Version Names

**Android** - Edit `src/android/app/build.gradle.kts`:
```kotlin
defaultConfig {
    versionCode = 2
    versionName = "1.1.0"  // ← Change this
}
```

**iOS** - Use agvtool:
```bash
cd "src/The Advancement"
agvtool new-marketing-version 1.1.0
```

Or manually edit `Info.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.1.0</string>
```

## Build Outputs

**Android:**
- AAB: `src/android/app/build/outputs/bundle/release/app-release.aab`
- Upload to: Google Play Console

**iOS:**
- IPA: `src/The Advancement/build/The Advancement.ipa`
- Upload to: App Store Connect (via Transporter app or Xcode)

## Upload to Stores

### Google Play Console

1. Go to: https://play.google.com/console
2. Select "The Advancement"
3. Production → Create new release
4. Upload AAB: `src/android/app/build/outputs/bundle/release/app-release.aab`

### App Store Connect

**Option 1: Transporter App (Easiest)**
1. Download Transporter from Mac App Store
2. Drag and drop IPA file
3. Click "Deliver"

**Option 2: Command Line**
```bash
xcrun altool --upload-app \
  --type ios \
  --file "src/The Advancement/build/The Advancement.ipa" \
  --username "your-apple-id@email.com" \
  --password "app-specific-password"
```

**Option 3: Xcode**
1. Open Xcode
2. Window → Organizer
3. Select the archive
4. Click "Distribute App"

## Common Issues

### iOS: "No signing certificate found"

Make sure you're signed in to Xcode with your Apple ID:
```bash
# Check current account
xcrun notarytool store-credentials --list

# Or open Xcode preferences
# Xcode → Settings → Accounts → Add Apple ID
```

### Android: "Task assembleRelease failed"

Make sure your keystore path is correct in `build.gradle.kts`:
```kotlin
storeFile = file("${project.rootDir}/keystore.jks")  // Update this path
```

### iOS: "Team ID not found"

Update `ExportOptions.plist` with your team ID:
```bash
# Find your team ID
xcrun altool --list-providers -u "your-apple-id@email.com"
```

## Full Workflow Example

```bash
# 1. Check current versions
./build.sh versions

# 2. Bump versions
./build.sh bump-android
./build.sh bump-ios

# 3. Build both platforms
./build.sh

# 4. Upload to stores (manually via web consoles)
```

## Environment Variables (Optional)

For CI/CD or to avoid storing passwords in code:

```bash
# Android
export KEYSTORE_PASSWORD="your-keystore-password"
export KEY_PASSWORD="your-key-password"

# Then build
./build.sh android
```

## Requirements

- **Android**: JDK 17+, Android SDK (via Android Studio)
- **iOS**: Xcode 15+, macOS
- **Both**: No additional dependencies needed!

## Script Commands

```bash
./build.sh                # Build both platforms
./build.sh android        # Build Android only
./build.sh ios            # Build iOS only
./build.sh bump-android   # Increment Android version code
./build.sh bump-ios       # Increment iOS build number
./build.sh versions       # Show current versions
./build.sh help           # Show help
```
