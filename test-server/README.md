# The Advancement Test Server

## Overview

This test server demonstrates the complete Planet Nine purchase flow with The Advancement Safari extension. It provides a realistic environment for testing teleported product feeds, multi-pubKey authentication, Stripe payment processing, and Addie coordination.

## Features

### 🌍 **Complete Planet Nine Integration**
- **Teleported Product Feeds** - Products discovered from user's selected home base
- **Menu Catalog Teleportation** - Complete restaurant menus from Planet Nine bases ✨ **NEW**
- **Multi-PubKey System** - Site owner, product creator, and base public key verification
- **Stripe Payment Processing** - Secure payments via The Advancement extension
- **Addie Coordination** - Payment processing through user's home base
- **Sessionless Authentication** - Cryptographic signing for all transactions

### 💳 **Payment Flow Testing**
- **3-Party Payment Splits** - Creator (70%), Base (20%), Site (10%)
- **Real Stripe Integration** - Test cards and payment methods
- **Home Base Processing** - Payments routed through user's selected Planet Nine base
- **Fallback Handling** - Graceful degradation when services unavailable

### 🔐 **Security Features**
- **Sessionless Signatures** - All purchases cryptographically signed
- **PubKey Verification** - Multiple public keys validated for each transaction
- **Secure Communication** - Extension-to-website communication via events
- **Error Handling** - Comprehensive error handling and user feedback

## Quick Start

### Prerequisites
- **The Advancement Safari Extension** installed and configured
- **Home base selected** in The Advancement popup
- **Node.js 16+** installed
- **Sessionless keys generated** in The Advancement

### Installation

1. **Install dependencies**:
   ```bash
   cd the-advancement/test-server
   npm install
   ```

2. **Start the test server**:
   ```bash
   npm start
   # Server will run on http://localhost:3456
   ```

3. **Open in Safari** with The Advancement extension enabled:
   ```
   http://localhost:3456
   ```

### Testing the Complete Flow

1. **Configure The Advancement**:
   - Open The Advancement popup in Safari
   - Go to "🔐 Keys" tab and generate keys if needed
   - Go to "🏠 Home Base" tab and select a Planet Nine base
   - Ensure status shows "🟢 The Advancement Connected"

2. **Load the Test Website**:
   - Navigate to `http://localhost:3456`
   - Verify that "The Advancement Connected" status appears
   - Check that your home base is displayed
   - Wait for teleported products to load in the right column

3. **Browse Teleported Content**:
   - Regular products appear as standard product cards
   - Menu catalogs appear with 🍽️ icon and "MENU CATALOG" badge
   - Click menu catalogs to view complete restaurant menus
   - Individual menu items can be ordered directly

4. **Make a Test Purchase**:
   - Click any product or menu item in the teleported feed
   - Review the purchase modal with multi-pubKey verification
   - Accept terms and click "Complete Purchase"
   - Payment will be processed via The Advancement extension

## API Endpoints

### Core APIs

#### `GET /api/site-owner`
Returns website owner information including pubKey for verification.

**Response**:
```json
{
  "success": true,
  "data": {
    "name": "Planet Nine Test Store",
    "pubKey": "0x1234567890abcdef...",
    "address": "0x1234567890abcdef12345678",
    "description": "Test website for The Advancement purchase flow"
  }
}
```

#### `GET /api/teleport/:baseId?pubKey=<userPubKey>`
Simulates teleported product feed from a Planet Nine base.

**Parameters**:
- `baseId` - Base identifier (e.g., 'dev', 'local')
- `pubKey` - User's public key for teleportation validation

**Response**:
```json
{
  "success": true,
  "data": {
    "base": {
      "name": "DEV",
      "pubKey": "0xfedcba0987654321...",
      "dns": { "bdo": "dev.bdo.allyabase.com" }
    },
    "products": [
      {
        "id": "prod_1",
        "title": "The Complete Guide to Planet Nine",
        "price": 1999,
        "creator_info": {
          "name": "Alice Creator",
          "pubKey": "0xabcdef1234567890..."
        },
        "teleport_verified": true
      }
    ],
    "menuCatalogs": [
      {
        "id": "cafe_luna_menu",
        "title": "Café Luna Menu", 
        "type": "menu_catalog",
        "menus": {
          "beverages": {
            "title": "Beverages",
            "products": ["coffee_espresso", "coffee_latte"]
          }
        },
        "products": [
          {
            "id": "coffee_espresso",
            "name": "Espresso",
            "price": 250
          }
        ],
        "teleport_verified": true
      }
    ]
  }
}
```

#### `POST /api/purchase/intent`
Creates a purchase intent with payment splits and multi-pubKey verification.

**Request**:
```json
{
  "productId": "prod_1",
  "buyerPubKey": "0x...",
  "homeBase": "dev"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "pi_1234567890",
    "payment_splits": [
      {
        "recipient": "creator",
        "pubKey": "0xabcdef...",
        "amount": 1399,
        "description": "Payment to Alice Creator"
      },
      {
        "recipient": "base", 
        "amount": 400,
        "description": "Base hosting fee to DEV"
      },
      {
        "recipient": "site",
        "amount": 200,
        "description": "Site commission"
      }
    ],
    "addie_endpoint": "https://dev.addie.allyabase.com/payment/process"
  }
}
```

#### `POST /api/purchase/process`
Processes payment with Sessionless signature validation.

**Request**:
```json
{
  "intentId": "pi_1234567890",
  "stripePaymentMethod": "pm_card_visa",
  "sessionlessSignature": "0x..."
}
```

## Test Data

### Mock Products
The server includes 3 test products:

1. **"The Complete Guide to Planet Nine"** - $19.99 ebook
   - Creator: Alice Creator
   - Base: DEV
   - Type: Digital download

2. **"Advanced Sessionless Development"** - $49.99 video course
   - Creator: Bob Developer  
   - Base: DEV
   - Type: Online course

3. **"Planet Nine Sticker Pack"** - $8.99 physical product
   - Creator: Alice Creator
   - Base: LOCAL
   - Type: Physical shipping required

4. **"Café Luna Menu"** - Complete restaurant menu catalog ✨ **NEW**
   - Creator: Alice Creator
   - Base: DEV
   - Type: Menu catalog with 8 items across beverages, breakfast, and lunch categories

### PubKeys for Testing
```javascript
// Site Owner
siteOwnerPubKey: "0x1234567890abcdef1234567890abcdef12345678901234567890abcdef12345678"

// Product Creators
aliceCreatorPubKey: "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab"
bobDeveloperPubKey: "0x567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456"

// Planet Nine Bases
devBasePubKey: "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
localBasePubKey: "0x0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba09"
```

## Integration with The Advancement

### Extension Detection
The website automatically detects The Advancement extension:

```javascript
// Check for extension
if (window.AdvancementExtension) {
  console.log('✅ The Advancement detected');
  // Enable Planet Nine features
}

// Check for Stripe integration
if (window.AdvancementStripeIntegration) {
  console.log('💳 Payment processing available');
  // Enable secure checkout
}
```

### Payment Processing
Payments are processed via custom events:

```javascript
// Trigger payment via The Advancement
document.dispatchEvent(new CustomEvent('planetnine-payment-request', {
  detail: {
    purchaseIntent: intent,
    sessionlessSignature: signature
  }
}));

// Listen for payment result
document.addEventListener('planetnine-payment-success', (event) => {
  console.log('Payment successful:', event.detail);
});
```

### Home Base Integration
The website reads the user's home base from The Advancement:

```javascript
// Get user's selected home base
const homeBase = JSON.parse(localStorage.getItem('advancement-home-base'));
console.log('User home base:', homeBase.name);

// Use home base for Addie coordination
const addieEndpoint = `${homeBase.dns.addie}/payment/process`;
```

## Development Features

### Debug Console Commands
Available in browser console:

```javascript
// Debug application state
debugTestStore()

// Refresh application status  
refreshTestStore()

// Get detailed debug info
testStoreApp.getDebugInfo()

// Check payment capabilities
window.AdvancementStripeIntegration?.getCapabilities()
```

### Environment Variables
```bash
PORT=3456                    # Server port (default: 3456)
NODE_ENV=development         # Environment mode
STRIPE_TEST_KEY=pk_test_...  # Stripe test public key
```

### Logging
Comprehensive logging throughout the flow:

```
🚀 The Advancement Test Server running on port 3456
🔍 Teleporting products from base: dev, with pubKey: 0x...
💳 Creating purchase intent for product: prod_1
✅ Purchase intent created: pi_1234567890
💳 Processing payment via The Advancement Stripe integration
🏠 Processing payment via Addie at: https://dev.addie.allyabase.com/payment/process
✅ Payment processed successfully
```

## Troubleshooting

### Common Issues

#### The Advancement Not Detected
- Ensure The Advancement Safari extension is installed and enabled
- Check Safari's extension preferences
- Reload the page after installing the extension
- Look for console errors in Safari Developer Tools

#### No Home Base Selected
- Open The Advancement popup (click toolbar icon)
- Go to "🏠 Home Base" tab
- Select a Planet Nine base from the list
- Refresh the test website

#### Teleported Products Not Loading
- Verify home base is selected in The Advancement
- Check browser console for network errors
- Ensure test server is running on port 3456
- Try refreshing the teleported feed (🔄 button)

#### Payment Processing Fails
- Verify Sessionless keys are generated in The Advancement
- Check that Stripe integration loaded properly
- Look for payment-related console errors
- Ensure all required pubKeys are available

### Browser Console Debugging
Open Safari Developer Tools and check for:

```javascript
// Extension status
window.AdvancementExtension        // Should be defined
window.Sessionless               // Should be defined  
window.AdvancementStripeIntegration // Should be defined

// Home base status
localStorage.getItem('advancement-home-base') // Should return base JSON

// Debug commands
debugTestStore()  // Shows complete application state
```

## Production Considerations

### Security
- Replace test Stripe keys with production keys
- Implement proper signature verification
- Add rate limiting and fraud detection
- Use HTTPS in production

### Scalability  
- Replace mock data with real database
- Implement proper base discovery via BDO
- Add caching for teleported content
- Monitor payment processing performance

### Integration
- Connect to real Addie endpoints
- Implement actual Sanora product feeds
- Add real user authentication
- Integrate with production Planet Nine bases

## Next Steps

This test server demonstrates the complete Planet Nine purchase flow. To deploy in production:

1. **Replace test endpoints** with real Planet Nine services
2. **Implement real base discovery** via BDO API
3. **Add production Stripe keys** and real payment processing
4. **Integrate with live Addie instances** at user home bases
5. **Add comprehensive error handling** and monitoring
6. **Implement proper teleportation signature verification**

The architecture and patterns established here provide a solid foundation for building real Planet Nine commerce applications with The Advancement extension.