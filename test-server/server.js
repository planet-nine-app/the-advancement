/**
 * The Advancement Test Server
 * 
 * Demonstrates complete Planet Nine purchase flow:
 * - Website with teleported product feeds
 * - Multi-pubKey system (site owner, product creator, base)
 * - Stripe integration via The Advancement extension
 * - Addie payment processing at user's home base
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3456;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// ========================================
// Mock Data - In Production This Comes From Real Services
// ========================================

// Website Owner (this test site)
const SITE_OWNER = {
    name: 'Planet Nine Test Store',
    pubKey: '0x1234567890abcdef1234567890abcdef12345678901234567890abcdef12345678',
    address: '0x1234567890abcdef12345678',
    description: 'Test website for The Advancement purchase flow',
    stripe_account_id: 'acct_test_website_owner'
};

// Product Creators (users who uploaded products to bases)
const PRODUCT_CREATORS = {
    'creator1': {
        name: 'Alice Creator',
        pubKey: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab',
        address: '0xabcdef1234567890abcdef12',
        description: 'Digital content creator specializing in ebooks',
        stripe_account_id: 'acct_test_creator_alice'
    },
    'creator2': {
        name: 'Bob Developer',
        pubKey: '0x567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456',
        address: '0x567890abcdef1234567890ab',
        description: 'Software developer creating educational courses',
        stripe_account_id: 'acct_test_creator_bob'
    }
};

// Planet Nine Bases (where products are hosted)
const PLANET_NINE_BASES = {
    'dev': {
        name: 'DEV',
        description: 'Development Planet Nine base',
        pubKey: '0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
        address: '0xfedcba0987654321fedcba09',
        dns: {
            bdo: 'dev.bdo.allyabase.com',
            sanora: 'dev.sanora.allyabase.com',
            dolores: 'dev.dolores.allyabase.com',
            fount: 'dev.fount.allyabase.com',
            addie: 'dev.addie.allyabase.com'
        },
        stripe_account_id: 'acct_test_base_dev'
    },
    'local': {
        name: 'LOCAL',
        description: 'Local development base',
        pubKey: '0x0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba09',
        address: '0x0987654321fedcba09876543',
        dns: {
            bdo: 'localhost:3003',
            sanora: 'localhost:7243',
            dolores: 'localhost:3007'
        },
        stripe_account_id: 'acct_test_base_local'
    }
};

// Mock teleported products (normally from Sanora)
const TELEPORTED_PRODUCTS = [
    {
        id: 'prod_1',
        title: 'The Complete Guide to Planet Nine',
        description: 'Comprehensive ebook covering the entire Planet Nine ecosystem, from Sessionless authentication to MAGIC transactions.',
        price: 1999, // $19.99 in cents
        currency: 'usd',
        type: 'ebook',
        creator: 'creator1',
        base: 'dev',
        image_url: '/images/ebook-planet-nine.jpg',
        preview_url: '/previews/planet-nine-preview.pdf',
        metadata: {
            pages: 247,
            format: 'PDF + EPUB',
            file_size: '15.2 MB',
            created_at: '2024-01-15T10:30:00Z'
        },
        teleport_signature: 'mock_signature_1',
        download_url: 'https://dev.sanora.allyabase.com/products/prod_1/download'
    },
    {
        id: 'prod_2',
        title: 'Advanced Sessionless Development',
        description: 'Video course teaching advanced Sessionless authentication patterns and integration techniques.',
        price: 4999, // $49.99 in cents
        currency: 'usd',
        type: 'course',
        creator: 'creator2',
        base: 'dev',
        image_url: '/images/course-sessionless.jpg',
        preview_url: '/previews/sessionless-preview.mp4',
        metadata: {
            duration: '8 hours 30 minutes',
            lessons: 42,
            level: 'Advanced',
            format: 'Video + Code Examples',
            created_at: '2024-01-20T14:15:00Z'
        },
        teleport_signature: 'mock_signature_2',
        access_url: 'https://dev.sanora.allyabase.com/courses/prod_2'
    },
    {
        id: 'prod_3',
        title: 'Planet Nine Sticker Pack',
        description: 'Official Planet Nine sticker pack featuring logos and mascots from across the ecosystem.',
        price: 899, // $8.99 in cents
        currency: 'usd',
        type: 'physical',
        creator: 'creator1',
        base: 'local',
        image_url: '/images/stickers-planet-nine.jpg',
        metadata: {
            quantity: 12,
            size: '3x3 inches',
            material: 'Waterproof vinyl',
            shipping_weight: '0.1 lbs',
            created_at: '2024-01-10T09:00:00Z'
        },
        teleport_signature: 'mock_signature_3',
        shipping_required: true
    }
];

// ========================================
// Routes
// ========================================

// Serve the test website
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API: Get website owner info (for The Advancement)
app.get('/api/site-owner', (req, res) => {
    res.json({
        success: true,
        data: SITE_OWNER
    });
});

// API: Get available Planet Nine bases
app.get('/api/bases', (req, res) => {
    res.json({
        success: true,
        data: PLANET_NINE_BASES
    });
});

// API: Simulate teleported product feed from a base
app.get('/api/teleport/:baseId', async (req, res) => {
    const { baseId } = req.params;
    const { pubKey } = req.query;
    
    console.log(`🔍 Teleporting products from base: ${baseId}, with pubKey: ${pubKey}`);
    
    try {
        const base = PLANET_NINE_BASES[baseId];
        if (!base) {
            return res.status(404).json({
                success: false,
                error: 'Base not found'
            });
        }

        // Filter products from this base
        const baseProducts = TELEPORTED_PRODUCTS.filter(product => product.base === baseId);
        
        // Simulate teleportation validation (in production, this would verify signatures)
        const teleportedContent = {
            base: base,
            products: baseProducts.map(product => ({
                ...product,
                creator_info: PRODUCT_CREATORS[product.creator],
                base_info: base,
                teleport_verified: true,
                teleport_timestamp: new Date().toISOString()
            })),
            teleport_metadata: {
                requested_by_pubkey: pubKey,
                base_pubkey: base.pubKey,
                timestamp: new Date().toISOString(),
                signature_valid: true,
                total_products: baseProducts.length
            }
        };

        console.log(`✅ Teleported ${baseProducts.length} products from ${base.name}`);
        
        res.json({
            success: true,
            data: teleportedContent
        });
        
    } catch (error) {
        console.error('Teleportation failed:', error);
        res.status(500).json({
            success: false,
            error: 'Teleportation failed'
        });
    }
});

// API: Get product details (for purchase)
app.get('/api/product/:productId', (req, res) => {
    const { productId } = req.params;
    
    const product = TELEPORTED_PRODUCTS.find(p => p.id === productId);
    if (!product) {
        return res.status(404).json({
            success: false,
            error: 'Product not found'
        });
    }

    const enrichedProduct = {
        ...product,
        creator_info: PRODUCT_CREATORS[product.creator],
        base_info: PLANET_NINE_BASES[product.base],
        site_owner: SITE_OWNER
    };

    res.json({
        success: true,
        data: enrichedProduct
    });
});

// API: Create purchase intent (for The Advancement to process)
app.post('/api/purchase/intent', async (req, res) => {
    const { productId, buyerPubKey, homeBase } = req.body;
    
    console.log(`💳 Creating purchase intent for product: ${productId}`);
    console.log(`🔑 Buyer pubKey: ${buyerPubKey}`);
    console.log(`🏠 Home base: ${homeBase}`);
    
    try {
        const product = TELEPORTED_PRODUCTS.find(p => p.id === productId);
        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }

        const creator = PRODUCT_CREATORS[product.creator];
        const base = PLANET_NINE_BASES[product.base];
        const userBase = PLANET_NINE_BASES[homeBase] || PLANET_NINE_BASES['dev'];

        // Calculate payment splits (Planet Nine pattern)
        const totalAmount = product.price;
        const creatorShare = Math.floor(totalAmount * 0.70); // 70% to creator
        const baseShare = Math.floor(totalAmount * 0.20);   // 20% to hosting base
        const siteShare = totalAmount - creatorShare - baseShare; // 10% to site owner

        const purchaseIntent = {
            id: `pi_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            product: product,
            buyer: {
                pubKey: buyerPubKey,
                homeBase: userBase
            },
            payment_splits: [
                {
                    recipient: 'creator',
                    pubKey: creator.pubKey,
                    address: creator.address,
                    amount: creatorShare,
                    stripe_account: creator.stripe_account_id,
                    description: `Payment to ${creator.name} for "${product.title}"`
                },
                {
                    recipient: 'base',
                    pubKey: base.pubKey,
                    address: base.address,
                    amount: baseShare,
                    stripe_account: base.stripe_account_id,
                    description: `Base hosting fee to ${base.name}`
                },
                {
                    recipient: 'site',
                    pubKey: SITE_OWNER.pubKey,
                    address: SITE_OWNER.address,
                    amount: siteShare,
                    stripe_account: SITE_OWNER.stripe_account_id,
                    description: `Site commission for ${SITE_OWNER.name}`
                }
            ],
            total_amount: totalAmount,
            currency: product.currency,
            addie_endpoint: `${userBase.dns.addie}/payment/process`,
            metadata: {
                created_at: new Date().toISOString(),
                expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // 15 minutes
                teleport_verified: true
            }
        };

        console.log(`✅ Purchase intent created: ${purchaseIntent.id}`);
        console.log(`💰 Payment splits: Creator $${(creatorShare/100).toFixed(2)}, Base $${(baseShare/100).toFixed(2)}, Site $${(siteShare/100).toFixed(2)}`);

        res.json({
            success: true,
            data: purchaseIntent
        });
        
    } catch (error) {
        console.error('Failed to create purchase intent:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create purchase intent'
        });
    }
});

// API: Process payment (simulated - The Advancement would handle Stripe)
app.post('/api/purchase/process', async (req, res) => {
    const { intentId, stripePaymentMethod, sessionlessSignature } = req.body;
    
    console.log(`⚡ Processing payment for intent: ${intentId}`);
    
    try {
        // In production, this would:
        // 1. Validate the sessionless signature
        // 2. Process payment via Stripe with splits
        // 3. Coordinate with Addie at user's home base
        // 4. Trigger product delivery
        
        // Simulate successful payment processing
        const paymentResult = {
            id: `payment_${Date.now()}`,
            status: 'succeeded',
            intent_id: intentId,
            stripe_payment_id: `pi_mock_${Math.random().toString(36).substr(2, 9)}`,
            processed_at: new Date().toISOString(),
            delivery: {
                status: 'ready',
                download_url: '/api/download/mock_download_token',
                access_granted: true
            }
        };

        console.log(`✅ Payment processed successfully: ${paymentResult.id}`);

        res.json({
            success: true,
            data: paymentResult
        });
        
    } catch (error) {
        console.error('Payment processing failed:', error);
        res.status(500).json({
            success: false,
            error: 'Payment processing failed'
        });
    }
});

// API: Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'advancement-test-server',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        features: [
            'teleportation',
            'multi-pubkey',
            'stripe-integration',
            'addie-coordination'
        ]
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 The Advancement Test Server running on port ${PORT}`);
    console.log(`🌐 Website: http://localhost:${PORT}`);
    console.log(`📡 API: http://localhost:${PORT}/api/*`);
    console.log(`\n🎯 Features:`);
    console.log(`   - Teleported product feeds from Planet Nine bases`);
    console.log(`   - Multi-pubKey system (site, creator, base)`);
    console.log(`   - Stripe payment processing via The Advancement`);
    console.log(`   - Addie coordination at user's home base`);
    console.log(`\n🔧 Test this with The Advancement Safari extension!`);
});

module.exports = app;