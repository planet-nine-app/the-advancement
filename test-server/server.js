/**
 * The Advancement Test Server
 * 
 * Demonstrates complete Planet Nine purchase flow:
 * - Website with teleported product feeds
 * - Multi-pubKey system (site owner, product creator, base)
 * - Stripe integration via The Advancement extension
 * - Addie payment processing at user's home base
 */

import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import path from 'path';
import crypto from 'crypto';
import gateway from 'magic-gateway-js';
import sessionless from 'sessionless-node';
import fount from 'fount-js';
import { fileURLToPath } from 'url';

// ES module equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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

// Mock menu catalog products (these create complete menus when combined)
const MENU_CATALOG_PRODUCTS = [
    // Menu structure definition (uploaded with menu catalog)
    {
        id: 'menu_structure_1',
        title: 'Menu Structure - Café Luna',
        description: 'Menu structure definition for Café Luna',
        price: 0, // Structure products are free
        currency: 'usd',
        type: 'menu_structure',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            isMenuStructure: true,
            created_at: '2024-01-25T10:00:00Z',
            menuData: {
                title: 'Café Luna Menu',
                description: 'Fresh coffee, pastries, and light meals',
                menus: {
                    beverages: {
                        title: 'Beverages',
                        products: ['coffee_espresso', 'coffee_latte', 'tea_green', 'smoothie_berry']
                    },
                    food: {
                        title: 'Food',
                        submenus: {
                            breakfast: {
                                title: 'Breakfast',
                                products: ['bagel_everything', 'muffin_blueberry']
                            },
                            lunch: {
                                title: 'Lunch',
                                products: ['sandwich_turkey', 'salad_caesar']
                            }
                        }
                    }
                }
            }
        },
        teleport_signature: 'mock_menu_signature_1'
    },
    // Individual menu items (regular products with menu metadata)
    {
        id: 'coffee_espresso',
        title: 'Espresso',
        description: 'Rich, bold espresso shot',
        price: 250, // $2.50 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'beverages',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_1'
    },
    {
        id: 'coffee_latte',
        title: 'Caffe Latte',
        description: 'Espresso with steamed milk and a light foam',
        price: 450, // $4.50 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'beverages',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_2'
    },
    {
        id: 'tea_green',
        title: 'Green Tea',
        description: 'Premium loose leaf green tea',
        price: 300, // $3.00 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'beverages',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_3'
    },
    {
        id: 'smoothie_berry',
        title: 'Mixed Berry Smoothie',
        description: 'Blended berries with yogurt and honey',
        price: 550, // $5.50 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'beverages',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_4'
    },
    {
        id: 'bagel_everything',
        title: 'Everything Bagel',
        description: 'Fresh bagel with cream cheese',
        price: 350, // $3.50 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'breakfast',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_5'
    },
    {
        id: 'muffin_blueberry',
        title: 'Blueberry Muffin',
        description: 'House-made blueberry muffin',
        price: 300, // $3.00 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'breakfast',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_6'
    },
    {
        id: 'sandwich_turkey',
        title: 'Turkey Club Sandwich',
        description: 'Sliced turkey, bacon, lettuce, tomato on sourdough',
        price: 850, // $8.50 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'lunch',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_7'
    },
    {
        id: 'salad_caesar',
        title: 'Caesar Salad',
        description: 'Crisp romaine with parmesan and croutons',
        price: 750, // $7.50 in cents
        currency: 'usd',
        type: 'menu_item',
        creator: 'creator1',
        base: 'dev',
        metadata: {
            menuCatalogId: 'cafe_luna_menu',
            category: 'lunch',
            created_at: '2024-01-25T10:30:00Z'
        },
        teleport_signature: 'mock_menu_item_8'
    }
];

// ========================================
// MAGIC Protocol Setup
// ========================================

// Key storage functions for test environment
const saveKeys = (keys) => {
    console.log('🔑 MAGIC: Saving keys for test environment');
    // In production, this would persist to secure storage
    global.testServerKeys = keys;
    return keys;
};

const getKeys = () => {
    console.log('🔑 MAGIC: Retrieving keys for test environment');
    return global.testServerKeys || null;
};

// Set up sessionless for test environment
sessionless.generateKeys(saveKeys, getKeys).then(() => {
    console.log('🔐 MAGIC: Test server keys initialized');
}).catch(err => {
    console.log('🔐 MAGIC: Using existing keys or creating new ones');
});

// Configure fount for test environment
fount.baseURL = 'http://127.0.0.1:5117/'; // Test environment fount

// Global fount user for MAGIC protocol (will be created in initializeGateway)
global.fountUser = null;

// Spellbook definition for this test server
const getSpellbook = () => {
    return {
        spellTest: {
            cost: 400,
            destinations: [
                { 
                    stopName: 'test-server', 
                    stopURL: 'http://127.0.0.1:3456/' 
                },
                { 
                    stopName: 'fount', 
                    stopURL: 'http://127.0.0.1:5117/resolve/' 
                }
            ],
            resolver: 'fount',
            mp: true
        }
    };
};

// Gateway configuration
const myStopName = 'test-server';
const extraForGateway = (spellName) => {
    console.log(`🪄 MAGIC Gateway: Extra config for spell "${spellName}"`);
    return {};
};

const onSuccess = (req, res, result) => {
    console.log(`✅ MAGIC: Spell "${req.body.spell}" completed successfully`);
    console.log('the actual result of the spell is: ', result);
    result.testServerResponse = { 
        message: 'Hello from the test server!',
        timestamp: new Date().toISOString(),
        serverName: 'The Advancement Test Server'
    };
    res.json(result);
};

// ========================================
// Routes
// ========================================

// Serve the test website
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Signature verification demo page
app.get('/signature-demo', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'signature-demo.html'));
});

// Serve favicon
app.get('/favicon.ico', (req, res) => {
    res.sendFile(path.join(__dirname, 'favicon.png'));
});

// API: Sign function with arity 2
app.post('/api/sign', (req, res) => {
    const { keys, message } = req.body;

    const signature = sign(keys, message);

    res.json({
        success: true,
        signature: signature
    });
});

// Sign function that takes two arguments: keys and message, returns "SIGNATURE"
function sign(keys, message) {
    return "SIGNATURE";
}

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

// API: Simulate teleported product feed from a base (includes menu detection)
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

        // Filter regular products from this base
        const baseProducts = TELEPORTED_PRODUCTS.filter(product => product.base === baseId);
        
        // Filter menu catalog products from this base
        const menuProducts = MENU_CATALOG_PRODUCTS.filter(product => product.base === baseId);
        
        // Detect and reconstruct menu catalogs
        const menuCatalogs = detectAndReconstructMenus(menuProducts);
        
        // Combine all products (regular + menu items for individual ordering)
        const allProducts = [
            ...baseProducts,
            ...menuProducts.filter(p => p.type === 'menu_item') // Include individual menu items for ordering
        ];
        
        // Simulate teleportation validation (in production, this would verify signatures)
        const teleportedContent = {
            base: base,
            products: allProducts.map(product => ({
                ...product,
                creator_info: PRODUCT_CREATORS[product.creator],
                base_info: base,
                teleport_verified: true,
                teleport_timestamp: new Date().toISOString()
            })),
            menuCatalogs: menuCatalogs.map(catalog => ({
                ...catalog,
                creator_info: PRODUCT_CREATORS[catalog.creator],
                base_info: base,
                teleport_verified: true,
                teleport_timestamp: new Date().toISOString()
            })),
            teleport_metadata: {
                requested_by_pubkey: pubKey,
                base_pubkey: base.pubKey,
                timestamp: new Date().toISOString(),
                signature_valid: true,
                total_products: allProducts.length,
                total_menu_catalogs: menuCatalogs.length
            }
        };

        console.log(`✅ Teleported ${allProducts.length} products and ${menuCatalogs.length} menu catalogs from ${base.name}`);
        
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

/**
 * Detect menu products and reconstruct complete menu catalogs
 * @param {Array} products - Array of products to analyze
 * @returns {Array} Array of reconstructed menu catalogs
 */
function detectAndReconstructMenus(products) {
    const menuCatalogs = [];
    
    // Group products by menuCatalogId
    const menuGroups = new Map();
    
    products.forEach(product => {
        const catalogId = product.metadata?.menuCatalogId;
        if (!catalogId) return;
        
        if (!menuGroups.has(catalogId)) {
            menuGroups.set(catalogId, {
                structure: null,
                items: [],
                catalog: null
            });
        }
        
        const group = menuGroups.get(catalogId);
        
        if (product.metadata?.isMenuStructure) {
            group.structure = product.metadata.menuData;
            group.catalog = product;
        } else if (product.type === 'menu_item') {
            group.items.push({
                id: product.id,
                name: product.title,
                description: product.description,
                price: product.price,
                currency: product.currency,
                category: product.metadata?.category
            });
        }
    });
    
    // Reconstruct complete menu catalogs
    menuGroups.forEach((group, catalogId) => {
        if (!group.structure || !group.catalog) {
            console.warn(`⚠️ Incomplete menu catalog: ${catalogId}`);
            return;
        }
        
        const reconstructedMenu = {
            id: catalogId,
            title: group.structure.title,
            description: group.structure.description,
            type: 'menu_catalog',
            creator: group.catalog.creator,
            base: group.catalog.base,
            menus: {},
            products: group.items,
            metadata: {
                totalProducts: group.items.length,
                menuCount: Object.keys(group.structure.menus || {}).length,
                created_at: group.catalog.metadata?.created_at,
                menuCatalogId: catalogId
            },
            teleport_signature: group.catalog.teleport_signature
        };
        
        // Rebuild menu structure with product references
        if (group.structure.menus) {
            Object.entries(group.structure.menus).forEach(([menuKey, menu]) => {
                reconstructedMenu.menus[menuKey] = {
                    title: menu.title,
                    products: menu.products || []
                };
                
                // Handle submenus
                if (menu.submenus) {
                    reconstructedMenu.menus[menuKey].submenus = {};
                    Object.entries(menu.submenus).forEach(([submenuKey, submenu]) => {
                        reconstructedMenu.menus[menuKey].submenus[submenuKey] = {
                            title: submenu.title,
                            products: submenu.products || []
                        };
                    });
                }
            });
        }
        
        menuCatalogs.push(reconstructedMenu);
        console.log(`🍽️ Reconstructed menu catalog: ${reconstructedMenu.title} (${group.items.length} items)`);
    });
    
    return menuCatalogs;
}

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

// API: Get nineum balance from fount user
app.get('/api/nineum-balance', async (req, res) => {
    try {
        // Ensure we have a fount user
        if (!global.fountUser) {
            console.log('⚡ MAGIC: Creating fount user for nineum balance check...');
            global.fountUser = await fount.createUser(saveKeys, getKeys);
            console.log(`⚡ MAGIC: Fount user created - ${global.fountUser.uuid}`);
        }

        // Get the latest fount user data (including nineum count)
        const latestFountUser = await fount.getUserByUUID(global.fountUser.uuid, saveKeys, getKeys);
        
        console.log(`⭐ Nineum balance requested - User: ${latestFountUser.uuid}, Balance: ${latestFountUser.nineumCount || 0}`);
        
        res.json({
            success: true,
            data: {
                nineumCount: latestFountUser.nineumCount || 0,
                uuid: latestFountUser.uuid,
                lastUpdated: new Date().toISOString()
            }
        });
        
    } catch (error) {
        console.error('❌ Failed to get nineum balance:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get nineum balance',
            fallbackBalance: 0
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
            'addie-coordination',
            'magic-protocol'
        ]
    });
});

// Debug endpoint to check spellbook structure
app.get('/debug/spellbook', (req, res) => {
    const spellbook = getSpellbook();
    res.json({
        success: true,
        spellbook: spellbook,
        keys: Object.keys(spellbook),
        hasSpellTest: !!spellbook.spellTest
    });
});

// ========================================
// MAGIC Gateway Integration
// ========================================

// Initialize MAGIC gateway after routes are defined but before error handlers
const initializeGateway = async () => {
    try {
        // Ensure we have a fount user
        if (!global.fountUser) {
            console.log('⚡ MAGIC: Creating fount user for gateway initialization...');
            global.fountUser = await fount.createUser(saveKeys, getKeys);
            console.log(`⚡ MAGIC: Fount user created - ${global.fountUser.uuid}`);
        }

        // Set up the gateway with our Express app
        console.log('🪄 MAGIC: Initializing gateway...');
        gateway.expressApp(
            app, 
            global.fountUser, 
            getSpellbook(), 
            myStopName, 
            sessionless, 
            extraForGateway, 
            onSuccess
        );
        console.log('✅ MAGIC: Gateway initialized successfully');
        console.log('🔮 MAGIC routes added to Express app');
        
        // Add error handlers AFTER gateway routes
        addErrorHandlers();
        
    } catch (error) {
        console.error('❌ MAGIC: Gateway initialization failed:', error);
        console.log('⚠️  MAGIC: Server will run without MAGIC protocol support');
        
        // Still add error handlers even if gateway failed
        addErrorHandlers();
    }
};

// Error handlers - called after gateway initialization
function addErrorHandlers() {
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
        console.log(`❌ 404: ${req.method} ${req.path}`);
        res.status(404).json({
            success: false,
            error: 'Endpoint not found'
        });
    });
}

// Start server
app.listen(PORT, async () => {
    console.log(`🚀 The Advancement Test Server running on port ${PORT}`);
    console.log(`🌐 Website: http://localhost:${PORT}`);
    console.log(`📡 API: http://localhost:${PORT}/api/*`);
    console.log(`\n🎯 Features:`);
    console.log(`   - Teleported product feeds from Planet Nine bases`);
    console.log(`   - Multi-pubKey system (site, creator, base)`);
    console.log(`   - Stripe payment processing via The Advancement`);
    console.log(`   - Addie coordination at user's home base`);
    console.log(`   - MAGIC protocol support with spellTest`);
    console.log(`\n🔧 Test this with The Advancement Safari extension!`);
    
    // Initialize MAGIC gateway
    await initializeGateway();
    console.log(`\n🪄 MAGIC spellTest endpoint: http://localhost:${PORT}/spellTest`);
});

export default app;
