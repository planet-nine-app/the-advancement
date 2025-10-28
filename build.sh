#!/bin/bash

# Build script for The Advancement
# No external dependencies - just Gradle and Xcodebuild

set -e  # Exit on error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONFIGURATION CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_configuration() {
    local has_ios_team_id=false
    local has_android_keystore=false
    local ios_team_id=""
    local android_keystore=""
    local android_keystore_alias=""

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  🔍 Configuration Check${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Check iOS Team ID
    if [ -f "src/The Advancement/ExportOptions.plist" ]; then
        ios_team_id=$(grep -A 1 "<key>teamID</key>" "src/The Advancement/ExportOptions.plist" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

        if [ "$ios_team_id" != "YOUR_TEAM_ID" ] && [ -n "$ios_team_id" ]; then
            has_ios_team_id=true
            echo -e "${GREEN}✅ iOS Team ID configured: $ios_team_id${NC}"
        else
            echo -e "${RED}❌ iOS Team ID not configured${NC}"
            echo -e "${YELLOW}   Edit: src/The Advancement/ExportOptions.plist${NC}"
            echo -e "${YELLOW}   Find your Team ID: Xcode → Settings → Accounts → Your Apple ID${NC}"
        fi
    else
        echo -e "${RED}❌ ExportOptions.plist not found${NC}"
    fi

    # Check Android Keystore
    if [ -f "src/android/app/build.gradle.kts" ]; then
        # Look for keystore configuration
        if grep -q "signingConfigs" "src/android/app/build.gradle.kts"; then
            # Try to extract keystore path
            android_keystore=$(grep -A 5 "signingConfigs" "src/android/app/build.gradle.kts" | grep "storeFile" | sed 's/.*file("\(.*\)").*/\1/' | head -1)
            android_keystore_alias=$(grep -A 5 "signingConfigs" "src/android/app/build.gradle.kts" | grep "keyAlias" | sed 's/.*"\(.*\)".*/\1/' | head -1)

            if [ -n "$android_keystore" ] && [ "$android_keystore" != "path/to/your/keystore.jks" ]; then
                has_android_keystore=true
                echo -e "${GREEN}✅ Android Keystore configured: $android_keystore${NC}"
                if [ -n "$android_keystore_alias" ]; then
                    echo -e "${GREEN}   Key Alias: $android_keystore_alias${NC}"
                fi
            else
                echo -e "${RED}❌ Android Keystore not configured${NC}"
                echo -e "${YELLOW}   Edit: src/android/app/build.gradle.kts${NC}"
                echo -e "${YELLOW}   Add signing config with your keystore path${NC}"
            fi
        else
            echo -e "${RED}❌ Android signing config not found${NC}"
            echo -e "${YELLOW}   Edit: src/android/app/build.gradle.kts${NC}"
            echo -e "${YELLOW}   Add signingConfigs section${NC}"
        fi
    else
        echo -e "${RED}❌ build.gradle.kts not found${NC}"
    fi

    echo ""

    # Exit if configuration is incomplete
    if [ "$has_ios_team_id" = false ] || [ "$has_android_keystore" = false ]; then
        echo -e "${YELLOW}⚠️  Configuration incomplete. Please update the missing values above.${NC}"
        echo ""
        exit 1
    else
        echo -e "${GREEN}✨ All configuration looks good!${NC}"
        echo ""
    fi
}

# Run configuration check for build commands
case "$1" in
    android|ios|both|"")
        check_configuration
        ;;
esac

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

build_android() {
    print_header "🤖 Building Android Release"

    cd src/android

    echo -e "${YELLOW}Running Gradle bundle...${NC}"
    ./gradlew bundleRelease

    echo ""
    echo -e "${GREEN}✅ Android build complete!${NC}"
    echo -e "${GREEN}📦 AAB: src/android/app/build/outputs/bundle/release/app-release.aab${NC}"

    cd ../..
}

build_ios() {
    print_header "🍎 Building iOS Release"

    cd "src/The Advancement"

    # Get current build number
    CURRENT_BUILD=$(agvtool what-version -terse)
    echo -e "${YELLOW}Current build number: $CURRENT_BUILD${NC}"

    # Create archive
    echo -e "${YELLOW}Creating archive...${NC}"
    xcodebuild \
        -workspace "The Advancement.xcworkspace" \
        -scheme "The Advancement (iOS)" \
        -configuration Release \
        -archivePath "./build/TheAdvancement.xcarchive" \
        clean archive \
        CODE_SIGN_STYLE=Automatic

    # Export IPA
    echo -e "${YELLOW}Exporting IPA...${NC}"
    xcodebuild \
        -exportArchive \
        -archivePath "./build/TheAdvancement.xcarchive" \
        -exportPath "./build" \
        -exportOptionsPlist "./ExportOptions.plist"

    echo ""
    echo -e "${GREEN}✅ iOS build complete!${NC}"
    echo -e "${GREEN}📦 IPA: src/The Advancement/build/The Advancement.ipa${NC}"

    cd ../..
}

show_versions() {
    print_header "📋 Current Versions"

    # Android version
    cd src/android
    ANDROID_VERSION_NAME=$(grep 'versionName' app/build.gradle.kts | sed 's/.*"\(.*\)".*/\1/')
    ANDROID_VERSION_CODE=$(grep 'versionCode' app/build.gradle.kts | grep -o '[0-9]*')
    echo -e "Android: ${GREEN}$ANDROID_VERSION_NAME${NC} (code: $ANDROID_VERSION_CODE)"
    cd ../..

    # iOS version
    cd "src/The Advancement"
    IOS_VERSION=$(agvtool what-marketing-version -terse1)
    IOS_BUILD=$(agvtool what-version -terse)
    echo -e "iOS:     ${GREEN}$IOS_VERSION${NC} (build: $IOS_BUILD)"
    cd ../..
}

bump_android() {
    print_header "🤖 Bumping Android Version"

    cd src/android

    CURRENT_CODE=$(grep 'versionCode' app/build.gradle.kts | grep -o '[0-9]*')
    NEW_CODE=$((CURRENT_CODE + 1))

    echo "Current version code: $CURRENT_CODE"
    echo "New version code: $NEW_CODE"

    # Increment version code
    sed -i '' "s/versionCode = $CURRENT_CODE/versionCode = $NEW_CODE/" app/build.gradle.kts

    echo -e "${GREEN}✅ Android version code bumped to $NEW_CODE${NC}"
    echo -e "${YELLOW}💡 To change version name, edit: src/android/app/build.gradle.kts${NC}"

    cd ../..
}

bump_ios() {
    print_header "🍎 Bumping iOS Version"

    cd "src/The Advancement"

    CURRENT_BUILD=$(agvtool what-version -terse)

    # Increment build number
    agvtool next-version -all > /dev/null

    NEW_BUILD=$(agvtool what-version -terse)

    echo "Build number: $CURRENT_BUILD → $NEW_BUILD"
    echo -e "${GREEN}✅ iOS build number bumped to $NEW_BUILD${NC}"
    echo -e "${YELLOW}💡 To change version number, run: agvtool new-marketing-version <version>${NC}"

    cd ../..
}

show_help() {
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  android       Build Android release AAB"
    echo "  ios           Build iOS release IPA"
    echo "  both          Build both platforms (default)"
    echo "  bump-android  Increment Android version code"
    echo "  bump-ios      Increment iOS build number"
    echo "  versions      Show current versions"
    echo "  help          Show this help"
    echo ""
    echo "Examples:"
    echo "  ./build.sh android        # Build Android only"
    echo "  ./build.sh bump-ios       # Bump iOS build number"
    echo "  ./build.sh                # Build both platforms"
}

# Main script
case "$1" in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    both|"")
        build_android
        build_ios
        ;;
    bump-android)
        bump_android
        ;;
    bump-ios)
        bump_ios
        ;;
    versions)
        show_versions
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
