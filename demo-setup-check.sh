#!/bin/bash

# The Advancement Demo Setup Verification Script
# Run this before the demo to ensure all components are ready

echo "🎬 The Advancement Demo Setup Verification"
echo "=========================================="
echo

# Check if we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_DIR="/Users/zachbabb/Work/planet-nine/the-advancement"

if [[ "$SCRIPT_DIR" != "$EXPECTED_DIR" ]]; then
    echo "❌ Script must be run from: $EXPECTED_DIR"
    echo "   Current location: $SCRIPT_DIR"
    exit 1
fi

echo "✅ Working directory verified"

# Check required directories exist
REQUIRED_DIRS=(
    "/Users/zachbabb/Work/planet-nine/the-advancement/test-server"
    "/Users/zachbabb/Work/planet-nine/the-nullary/nexus/server"
    "/Users/zachbabb/Work/planet-nine/allyabase/deployment/docker"
)

echo
echo "📁 Checking required directories..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "✅ Found: $dir"
    else
        echo "❌ Missing: $dir"
        exit 1
    fi
done

# Check if Node.js dependencies are installed
echo
echo "📦 Checking Node.js dependencies..."

# Test Server
if [[ -f "test-server/package.json" ]] && [[ -d "test-server/node_modules" ]]; then
    echo "✅ Test Server dependencies installed"
else
    echo "⚠️  Test Server dependencies may need installation"
    echo "   Run: cd test-server && npm install"
fi

# Nexus Server
if [[ -f "/Users/zachbabb/Work/planet-nine/the-nullary/nexus/server/package.json" ]]; then
    if [[ -d "/Users/zachbabb/Work/planet-nine/the-nullary/nexus/server/node_modules" ]]; then
        echo "✅ Nexus Server dependencies installed"
    else
        echo "⚠️  Nexus Server dependencies may need installation"
        echo "   Run: cd /Users/zachbabb/Work/planet-nine/the-nullary/nexus/server && npm install"
    fi
else
    echo "❌ Nexus Server package.json not found"
fi

# Check if key files exist
echo
echo "📋 Checking demo files..."

REQUIRED_FILES=(
    "test-server/recipe-bdo.json"
    "test-server/server.js"
    "test-server/public/main.js"
    "src/The Advancement/Shared (App)/NexusViewController.swift"
    "src/The Advancement/AdvanceKey/KeyboardViewController.swift"
    "DEMO-SCRIPT.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

# Check for emojicoded product pages
echo
echo "🛍️ Checking emojicoded product pages..."
if [[ -f "test-server/public/peace-love-tshirt.html" ]]; then
    echo "✅ Peace Love T-shirt product page found"
else
    echo "❌ Peace Love T-shirt product page not found"
    exit 1
fi

if [[ -f "test-server/public/recipe-blog.html" ]]; then
    echo "✅ Recipe blog page found"
else
    echo "❌ Recipe blog page not found"
    exit 1
fi

# Check for contract signing page
if [[ -f "test-server/public/website-dev-contract.html" ]]; then
    echo "✅ Website Development Contract page found"
else
    echo "❌ Website Development Contract page not found"
    exit 1
fi

# Check for emojicoded content
if grep -q "✨" test-server/public/peace-love-tshirt.html; then
    echo "✅ Emojicode found in product page"
else
    echo "❌ Emojicode not found in product page"
    exit 1
fi

# Check for magical wands in server.js
echo
echo "🪄 Checking magical wand products..."
if grep -q "wand_fire\|wand_ice\|wand_lightning" test-server/server.js; then
    echo "✅ Magical wands configured in test server"
else
    echo "❌ Magical wands not found in test server"
    exit 1
fi

# Check for castSpell function in main.js
if grep -q "window.castSpell" test-server/public/main.js; then
    echo "✅ castSpell function found in main.js"
else
    echo "❌ castSpell function not found in main.js"
    exit 1
fi

# Check for cart management in SharedUserDefaults
if grep -q "addToCart\|getCart\|covenantUserUUID" src/The\ Advancement/Shared\ \(App\)/SharedUserDefaults.swift; then
    echo "✅ Cart and Covenant user management found in SharedUserDefaults"
else
    echo "❌ Cart management functions not found in SharedUserDefaults"
    exit 1
fi

# Check for contract signing in KeyboardViewController
if grep -q "signContract\|handleSignContractMessage" src/The\ Advancement/AdvanceKey/KeyboardViewController.swift; then
    echo "✅ Contract signing functions found in keyboard extension"
else
    echo "❌ Contract signing functions not found in keyboard extension"
    exit 1
fi

# Check for NexusViewController
if grep -q "NexusViewController" src/The\ Advancement/Shared\ \(App\)/NexusViewController.swift; then
    echo "✅ NexusViewController implementation found"
else
    echo "❌ NexusViewController implementation not found"
    exit 1
fi

echo
echo "🚀 Starting services for demo..."
echo

# Function to check if a port is in use
check_port() {
    local port=$1
    local service_name=$2

    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
        echo "✅ $service_name running on port $port"
        return 0
    else
        echo "⚠️  $service_name not running on port $port"
        return 1
    fi
}

# Check required services
echo "🔍 Checking service status..."

# Test Server (should be running already)
if check_port 3456 "Test Server"; then
    echo "   → http://localhost:3456"
else
    echo "   → Start with: cd test-server && npm start"
fi

# Nexus Server
if check_port 3333 "Nexus Server"; then
    echo "   → http://127.0.0.1:3333"
else
    echo "   → Start with: cd /Users/zachbabb/Work/planet-nine/the-nullary/nexus/server && npm start"
fi

# Covenant Server
if check_port 3011 "Covenant Server"; then
    echo "   → http://localhost:3011"
else
    echo "   → Start with: cd /Users/zachbabb/Work/planet-nine/covenant/src/server/node && node covenant.js"
fi

# Optional: Allyabase test ecosystem
if check_port 5111 "Allyabase Base 1"; then
    echo "✅ Allyabase test ecosystem running"
    echo "   → Three bases on ports 5111-5146"
else
    echo "ℹ️  Allyabase test ecosystem not running (optional for demo)"
    echo "   → Start with: cd /Users/zachbabb/Work/planet-nine/allyabase/deployment/docker && ./run-test-ecosystem.sh"
fi

echo
echo "📱 iOS App & Extension Setup"
echo "=============================="
echo "Manual steps required:"
echo
echo "1. 📱 Build The Advancement App:"
echo "   → Open Xcode: src/The Advancement/The Advancement.xcodeproj"
echo "   → Build and run on iOS Simulator"
echo
echo "2. 🦎 Install Safari Extension:"
echo "   → Safari → Settings → Extensions"
echo "   → Enable 'The Advancement' extension"
echo
echo "3. ⌨️  Install Keyboard Extension:"
echo "   → iOS Settings → General → Keyboard → Keyboards"
echo "   → Add 'AdvanceKey' keyboard"
echo "   → Grant Full Access permission"

echo
echo "🎯 Demo Readiness Checklist"
echo "============================"
echo "Before starting the demo, verify:"
echo
echo "✅ Test Server running (http://localhost:3456)"
echo "   - Peace Love T-shirt: http://localhost:3456/peace-love-tshirt.html"
echo "   - Recipe Blog: http://localhost:3456/recipe-blog.html"
echo "   - Contract: http://localhost:3456/website-dev-contract.html"
echo "✅ Nexus Server running (http://127.0.0.1:3333)"
echo "✅ Covenant Server running (http://localhost:3011)"
echo "✅ The Advancement iOS app built and running"
echo "✅ Safari extension installed and enabled"
echo "✅ AdvanceKey keyboard installed with Full Access"
echo "✅ DEMO-SCRIPT.md reviewed and ready"

echo
echo "🎬 Ready to Demo!"
echo "================="
echo "Open DEMO-SCRIPT.md for the complete step-by-step walkthrough."
echo "Estimated demo time: 15-20 minutes"
echo
echo "Quick start command for presenter:"
echo "open DEMO-SCRIPT.md"

echo
echo "🐛 If issues occur during demo:"
echo "==============================="
echo "1. Check all services are running with this script"
echo "2. Restart The Advancement app"
echo "3. Clear Safari cache and restart"
echo "4. Check iOS keyboard settings"
echo "5. Review troubleshooting section in DEMO-SCRIPT.md"