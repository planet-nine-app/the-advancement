# Test Environment ✅

The Advancement includes a comprehensive test server demonstrating the complete Planet Nine purchase flow, MAGIC protocol integration, and ecosystem interactions.

## Overview

**Location**: `test-server/`
**Purpose**: Test teleported product feeds, multi-pubKey verification, Stripe integration, Addie coordination, MAGIC protocol spell casting, and complete ecosystem demonstrations

## Quick Start Testing

```bash
# Start test environment
cd the-advancement/test-server
npm install && npm start

# Open in Safari with The Advancement extension
open http://localhost:3456

# Configure home base in The Advancement popup
# Test complete purchase flow with teleported products
```

## Test Server Features

### Express.js API
- **Complete Backend**: Full Planet Nine service simulation
- **RESTful Endpoints**: Comprehensive API for testing all features
- **CORS Support**: Cross-origin requests for extension testing
- **Static Serving**: HTML, CSS, and JavaScript asset delivery

### Mock Planet Nine Services
```javascript
// Simulated service integration
const services = {
    sanora: 'http://localhost:7243',    // Product hosting
    bdo: 'http://localhost:3003',       // Object storage
    addie: 'http://localhost:3005',     // Payment processing
    fount: 'http://localhost:5116'      // MAGIC protocol
};
```

### Multi-PubKey System
```javascript
// Three-tier verification system
const publicKeys = {
    siteOwner: '04a1b2c3d4e5f6...',     // Website owner verification
    productCreator: '02f1e2d3c4b5a6...', // Product creator verification
    baseServer: '03c1d2e3f4a5b6...'      // Base server verification
};
```

## Complete Commerce Testing

### Stripe Integration
- **Real Payment Processing**: Live Stripe integration with test cards
- **Payment Elements**: Proper Stripe Elements implementation
- **3D Secure Testing**: Support for authentication flows
- **Payment Splits**: Automatic 70% creator, 20% base, 10% site distribution

### Test Products
```javascript
const testProducts = [
    {
        id: 'ebook_001',
        name: 'Advanced JavaScript Techniques',
        price: 2999, // $29.99
        creator: 'Alice Creator',
        creatorPubKey: '02a1b2c3...',
        type: 'ebook'
    },
    {
        id: 'course_001',
        name: 'Complete Planet Nine Development',
        price: 9999, // $99.99
        creator: 'Bob Developer',
        creatorPubKey: '03d4e5f6...',
        type: 'course'
    },
    {
        id: 'physical_001',
        name: 'Planet Nine T-Shirt',
        price: 1999, // $19.99
        creator: 'Charlie Designer',
        creatorPubKey: '04g7h8i9...',
        type: 'physical'
    }
];
```

### Payment Flow Testing
1. **Home Base Configuration**: Select base in extension popup
2. **Product Discovery**: Browse teleported product feeds
3. **Purchase Initiation**: Click buy buttons to start payment
4. **Multi-PubKey Verification**: Validate all three public keys
5. **Stripe Processing**: Complete payment with test cards
6. **Payment Splitting**: Verify automatic revenue distribution
7. **Transaction Confirmation**: Receive purchase confirmation

## MAGIC Protocol Gateway ✅

### Complete Integration
```javascript
// magic-gateway-js integration
const gateway = require('magic-gateway-js').default;
const sessionless = require('sessionless-node');
const fount = require('fount-js').default;

// Spellbook configuration
const spellbook = {
    spellTest: {
        cost: 400,
        destinations: [
            { stopName: 'test-server', stopURL: 'http://127.0.0.1:3456/' },
            { stopName: 'fount', stopURL: 'http://127.0.0.1:5116/magic/spell/' }
        ],
        resolver: 'fount',
        mp: true
    }
};
```

### Spell Casting Testing
- **Element Detection**: Click elements with `spell="spellTest"` attributes
- **Background Processing**: Extension fetches spellbook from BDO
- **Cryptographic Signing**: Swift signs MAGIC payloads
- **Gateway Forwarding**: Test server acts as MAGIC gateway
- **Fount Resolution**: Final spell resolution through fount service

### Real Nineum Balance ✅
```javascript
// Live nineum balance integration
app.get('/api/nineum-balance', async (req, res) => {
    try {
        const balance = await fount.getUserByUUID(fountUser.uuid);
        res.json({
            balance: balance.nineum || 0,
            uuid: fountUser.uuid,
            lastUpdated: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch balance' });
    }
});
```

## Author-Book Carousel Implementation ✅

### Complete Ecosystem Demonstration
The test server includes a comprehensive author-book carousel showcasing integration across prof, sanora, BDO, and dolores services.

#### Features
- **Author Profiles**: 3 mock authors with detailed bios, locations, and genres
- **Book Catalog**: 6 ebooks with descriptions, pricing, and visual covers
- **PostWidget Integration**: Uses dolores post-widget.js for consistent styling
- **Dual Implementation**: Custom CSS and PostWidget versions for comparison

#### Access Points
```bash
# Author carousel demonstrations
http://localhost:3456/authors.html        # Custom implementation
http://localhost:3456/authors-widget.html # PostWidget integration
http://localhost:3456/                    # Main test site
```

#### PostWidget Integration Pattern
```javascript
// Individual PostWidget instances for each content item
const postWidget = new window.PostWidget(postContainer, { debug: false });

// Author customization
postWidget.addElement('name', author.name);
postWidget.addElement('description', author.bio);
// + location 📍 and genres 🏷️ metadata

// Book customization
postWidget.addElement('name', book.title);
postWidget.addElement('description', book.description);
// + visual covers, price 💰, genre 📚 metadata
```

#### Planet Nine Integration Pattern
- **prof**: Author profiles with sessionless authentication
- **sanora**: Ebook product hosting and marketplace endpoints
- **BDO**: Associations mapping authors to their books
- **dolores**: PostWidget for consistent UI components

## Test Cases

### Core Extension Features
```bash
# Input detection testing
open http://localhost:3456/forms.html
# Test on various form types and field configurations

# Typing simulation testing
# Verify natural timing and event sequences

# Dynamic content testing
# Test single-page application compatibility
```

### Planet Nine Integration Testing
```bash
# Home base selection testing
# 1. Open extension popup
# 2. Test base discovery across DEV/TEST/LOCAL environments
# 3. Verify persistent selection

# Payment processing testing
# 1. Select products from teleported feeds
# 2. Complete purchase with Stripe test cards
# 3. Verify payment splits and transaction confirmation

# Multi-PubKey verification testing
# 1. Validate site owner, creator, and base public keys
# 2. Test error handling for invalid keys
# 3. Verify signature validation throughout flow
```

### MAGIC Protocol Testing
```bash
# Spell casting testing
# 1. Click elements with spell attributes
# 2. Verify spellbook retrieval from BDO
# 3. Test cryptographic signing through Swift
# 4. Confirm gateway processing and fount resolution

# Nineum balance testing
# 1. Monitor real-time balance updates
# 2. Test spell cost deduction
# 3. Verify balance persistence across sessions
```

## Error Handling Testing

### Service Unavailability
```javascript
// Test graceful degradation
const testScenarios = [
    'Sanora service offline',
    'BDO service unavailable',
    'Addie payment processing down',
    'Fount MAGIC service unreachable',
    'Network connectivity issues'
];
```

### Payment Error Scenarios
```javascript
// Stripe test cards for error conditions
const testCards = {
    declined: '4000000000000002',
    insufficientFunds: '4000000000009995',
    expired: '4000000000000069',
    invalidCVC: '4000000000000127'
};
```

## File Structure

```
test-server/
├── README.md                  # Test server documentation
├── package.json              # Node.js dependencies
├── server.js                 # Express.js test server
├── public/
│   ├── index.html            # Main test website
│   ├── styles.css            # Planet Nine styling
│   ├── main.js               # Application coordinator
│   ├── teleportation-client.js # Product discovery
│   ├── purchase-flow.js      # Payment processing
│   ├── magic-client.js       # MAGIC protocol integration
│   ├── authors.html          # Custom author carousel
│   ├── authors.js            # Custom carousel logic
│   ├── authors-widget.html   # PostWidget demonstration
│   ├── authors-widget.js     # PostWidget integration
│   ├── post-widget.js        # From dolores (19KB)
│   └── seed-authors-and-books.js # Seeding script
└── logs/
    └── test-results.log      # Automated test outputs
```

## Environment Configuration

### Three-Environment Testing
- **DEV**: Test against production dev servers (dev.*.allyabase.com)
- **TEST**: Test with local 3-base ecosystem (127.0.0.1:5114-5118)
- **LOCAL**: Test with standard local services (localhost:3000-3008)

### Service Discovery
```javascript
// Automatic service URL resolution
const getServiceConfig = (environment) => {
    switch (environment) {
        case 'DEV':
            return {
                bdo: 'https://dev.bdo.allyabase.com',
                sanora: 'https://dev.sanora.allyabase.com',
                addie: 'https://dev.addie.allyabase.com'
            };
        case 'TEST':
            return {
                bdo: 'http://127.0.0.1:5117',
                sanora: 'http://127.0.0.1:5118',
                addie: 'http://127.0.0.1:5116'
            };
        case 'LOCAL':
            return {
                bdo: 'http://localhost:3003',
                sanora: 'http://localhost:7243',
                addie: 'http://localhost:3005'
            };
    }
};
```

## Automated Testing

### Test Scripts
```bash
# Run complete test suite
npm run test:complete

# Test specific components
npm run test:payments     # Payment processing only
npm run test:magic       # MAGIC protocol only
npm run test:teleport    # Product discovery only
```

### Continuous Integration
```javascript
// Automated test scenarios
const automatedTests = [
    'Extension loads correctly',
    'Home base selection persists',
    'Product feeds load from all environments',
    'Payment processing completes successfully',
    'MAGIC spells cast and resolve properly',
    'Error conditions handled gracefully'
];
```

## Performance Monitoring

### Metrics Collection
```javascript
// Performance tracking
const metrics = {
    pageLoadTime: performance.now(),
    productFeedLoad: 0,
    paymentProcessingTime: 0,
    spellCastingLatency: 0,
    extensionResponseTime: 0
};
```

### Load Testing
```bash
# Simulate concurrent users
npx artillery quick --count 10 --num 5 http://localhost:3456

# Test payment processing under load
npm run test:load:payments

# Test MAGIC protocol performance
npm run test:load:magic
```

The test environment provides comprehensive validation of all Planet Nine ecosystem components, enabling developers to verify functionality, test error conditions, and ensure production readiness across the entire platform.