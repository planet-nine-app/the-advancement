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
import fetch from 'node-fetch';
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
// Service Integration - Fetch from Prof and Sanora
// ========================================

// Service URLs for the test environment
const SERVICE_URLS = {
    prof: 'http://localhost:5123',  // Prof in Base 1 docker environment
    sanora: 'http://localhost:5121',
    bdo: 'http://localhost:5114',
    joan: 'http://localhost:5115'
};

// Fetch authors from prof service
async function fetchAuthorsFromProf() {
    try {
        console.log('📝 Attempting to fetch authors from prof...');

        // Use the actual author UUIDs we created in prof via seeding script
        const authorUUIDs = [
            'e74c9ca3-639a-44b2-8429-fc5004e5e104', // Sarah Mitchell
            'bb75ce7d-6230-4ae5-9b7c-06943840b5b8', // Delores Swigert Sullivan
            '0e5b42c6-89a5-4b70-80b9-f788561f96c2', // Marcus Chen
            '426e73ed-9f6e-43ca-ad4c-002e17732455'  // Isabella Rodriguez
        ];

        console.log(`📝 Using ${authorUUIDs.length} real author UUIDs from prof`);

        // Try to fetch each author profile from prof
        const authors = [];
        for (const uuid of authorUUIDs) {
            try {
                console.log(`📝 Attempting to fetch profile for UUID: ${uuid}`);
                const profileResponse = await fetch(`${SERVICE_URLS.prof}/user/${uuid}/profile`);

                if (profileResponse.ok) {
                    const response = await profileResponse.json();
                    const profile = response.profile; // Extract the profile data from the response
                    console.log(`✅ Found profile for ${profile.name || uuid}`);
                    authors.push(profile);
                } else {
                    console.log(`❌ No profile found for UUID: ${uuid} (${profileResponse.status})`);
                }
            } catch (profileError) {
                console.log(`❌ Error fetching profile for ${uuid}:`, profileError.message);
            }
        }

        if (authors.length > 0) {
            console.log(`✅ Successfully fetched ${authors.length} author profiles from prof`);
            return authors;
        } else {
            console.log('📝 No author profiles found in prof, using mock data');
            return MOCK_AUTHORS;
        }

    } catch (error) {
        console.error('❌ Failed to fetch authors from prof:', error);
        return MOCK_AUTHORS; // Fallback to mock data
    }
}

// Fetch books from sanora service
async function fetchBooksFromSanora() {
    try {
        console.log('📚 Fetching books from sanora...');
        const response = await fetch(`${SERVICE_URLS.sanora}/products/base`);
        const sanoraProducts = await response.json();

        // Transform sanora format to our expected format
        const books = sanoraProducts.map(productWrapper => {
            const productKey = Object.keys(productWrapper)[0];
            const product = productWrapper[productKey];

            return {
                id: product.productId || productKey,
                title: product.title,
                description: product.description,
                price: product.price || 0,
                category: product.category || 'product',
                authorUUID: product.uuid,
                uuid: product.uuid,
                productId: product.productId,
                timestamp: product.timestamp,
                signature: product.signature
            };
        });

        console.log(`✅ Fetched ${books.length} books from sanora`);
        return books;
    } catch (error) {
        console.error('❌ Failed to fetch books from sanora:', error);
        return MOCK_BOOKS; // Fallback to mock data
    }
}

// ========================================
// Joan Authentication Functions
// ========================================

// Key storage functions for joan integration
const joanKeyStorage = {};

const saveJoanKeys = (keys) => {
    joanKeyStorage.keys = keys;
    console.log('🔑 Joan keys saved for authentication');
};

const getJoanKeys = () => {
    return joanKeyStorage.keys || null;
};

// Joan client functions (adapted from joan.js)
const joanClient = {
    baseURL: SERVICE_URLS.joan + '/',

    createUser: async (hash) => {
        try {
            const keys = getJoanKeys() || await sessionless.generateKeys(saveJoanKeys, getJoanKeys);

            const payload = {
                timestamp: new Date().getTime() + '',
                pubKey: keys.pubKey,
                hash
            };

            // Set up sessionless for signing
            sessionless.getKeys = getJoanKeys;
            const message = payload.timestamp + payload.hash + payload.pubKey;
            console.log('🔍 Signing message:', message);
            console.log('🔍 Keys used:', keys);
            payload.signature = await sessionless.sign(message);
            console.log('🔍 Generated signature:', payload.signature);

            // Test self-verification
            const selfVerify = sessionless.verifySignature(payload.signature, message, keys.pubKey);
            console.log('🔍 Self-verification test:', selfVerify);

            const response = await fetch(`${joanClient.baseURL}user/create`, {
                method: 'PUT',
                body: JSON.stringify(payload),
                headers: {'Content-Type': 'application/json'}
            });

            const user = await response.json();
            console.log('📝 Joan response:', user);

            // Check if joan returned an error
            if (user.error) {
                throw new Error('Joan authentication failed: ' + user.error);
            }

            console.log('✅ Joan user created successfully:', user);
            return user;
        } catch (error) {
            console.error('❌ Failed to create joan user:', error);
            throw error;
        }
    },

    reenter: async (hash) => {
        try {
            const keys = getJoanKeys();
            if (!keys) {
                throw new Error('No keys available for reentry');
            }

            const timestamp = new Date().getTime() + '';
            sessionless.getKeys = getJoanKeys;
            const signature = await sessionless.sign(timestamp + hash + keys.pubKey);

            const response = await fetch(`${joanClient.baseURL}user/${hash}/pubKey/${keys.pubKey}?timestamp=${timestamp}&signature=${signature}`);
            const user = await response.json();

            console.log('📝 Joan reentry response:', user);

            // Check if joan returned an error
            if (user.error) {
                throw new Error('Joan reentry failed: ' + user.error);
            }

            console.log('✅ Joan reentry successful:', user);
            return user;
        } catch (error) {
            console.error('❌ Failed to reenter joan:', error);
            throw error;
        }
    },

    updateHash: async (uuid, hash, newHash) => {
        try {
            const timestamp = new Date().getTime() + '';
            sessionless.getKeys = getJoanKeys;
            const signature = await sessionless.sign(timestamp + uuid + hash + newHash);

            const payload = {timestamp, uuid, hash, newHash, signature};

            const response = await fetch(`${joanClient.baseURL}user/${uuid}/update-hash`, {
                method: 'PUT',
                body: JSON.stringify(payload),
                headers: {'Content-Type': 'application/json'}
            });

            console.log('✅ Joan hash updated');
            return response.status === 202;
        } catch (error) {
            console.error('❌ Failed to update joan hash:', error);
            throw error;
        }
    },

    deleteUser: async (uuid, hash) => {
        try {
            const timestamp = new Date().getTime() + '';
            sessionless.getKeys = getJoanKeys;
            const signature = await sessionless.sign(timestamp + uuid + hash);

            const payload = {timestamp, uuid, hash, signature};

            const response = await fetch(`${joanClient.baseURL}user/${uuid}`, {
                method: 'DELETE',
                body: JSON.stringify(payload),
                headers: {'Content-Type': 'application/json'}
            });

            console.log('✅ Joan user deleted');
            return response.status === 200;
        } catch (error) {
            console.error('❌ Failed to delete joan user:', error);
            throw error;
        }
    }
};

// ========================================
// Mock Data - Fallback When Services Unavailable
// ========================================

// Website Owner (this test site)
const SITE_OWNER = {
    name: 'Planet Nine Test Store',
    pubKey: '0x1234567890abcdef1234567890abcdef12345678901234567890abcdef12345678',
    address: '0x1234567890abcdef12345678',
    description: 'Test website for The Advancement purchase flow',
    stripe_account_id: 'acct_test_website_owner'
};

// Mock Authors for fallback
const MOCK_AUTHORS = [
    {
        uuid: 'author-uuid-1',
        name: 'Alice Creator',
        email: 'alice@example.com',
        bio: 'Digital content creator specializing in ebooks',
        location: 'San Francisco, CA',
        genres: ['Fantasy', 'Science Fiction']
    },
    {
        uuid: 'author-uuid-2',
        name: 'Bob Developer',
        email: 'bob@example.com',
        bio: 'Software developer creating educational courses',
        location: 'Seattle, WA',
        genres: ['Technology', 'Programming']
    }
];

// Mock Books for fallback
const MOCK_BOOKS = [
    {
        id: 'book-1',
        title: 'Sample Book 1',
        description: 'A sample book for testing',
        price: 1299,
        category: 'ebook',
        authorUUID: 'author-uuid-1'
    },
    {
        id: 'book-2',
        title: 'Sample Book 2',
        description: 'Another sample book for testing',
        price: 1499,
        category: 'ebook',
        authorUUID: 'author-uuid-2'
    }
];

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

app.get('/author-platform', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'author-platform.html'));
});

// Serve favicon
app.get('/favicon.ico', (req, res) => {
    res.sendFile(path.join(__dirname, 'favicon.png'));
});

// API: Sign function with arity 2
app.post('/api/sign', async (req, res) => {
    const { keys, message } = req.body;

    const signature = await sign(keys, message);

    res.json({
        success: true,
        signature: signature
    });
});

// Sign function that takes two arguments: keys and message, returns "SIGNATURE"
async function sign(keys, message) {
console.log('here is what keys looks like: ', keys);
    await sessionless.generateKeys(() => {}, () => keys);
    sessionless.getKeys = () => keys;
    const signature = await sessionless.sign('foobar');
console.log('here is what the signature thing looks like...', signature);
    return signature;
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

// ========================================
// Joan Authentication API Endpoints
// ========================================

// API: Create new user account with joan
app.post('/api/auth/create-user', async (req, res) => {
    try {
        const { hash } = req.body;

        if (!hash) {
            return res.status(400).json({
                success: false,
                error: 'Hash is required'
            });
        }

        const user = await joanClient.createUser(hash);

        res.json({
            success: true,
            data: user,
            message: 'User created successfully'
        });
    } catch (error) {
        console.error('❌ Failed to create user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create user account'
        });
    }
});

// API: Login/reenter existing user
app.post('/api/auth/login', async (req, res) => {
    try {
        const { hash } = req.body;

        if (!hash) {
            return res.status(400).json({
                success: false,
                error: 'Hash is required'
            });
        }

        const user = await joanClient.reenter(hash);

        res.json({
            success: true,
            data: user,
            message: 'Login successful'
        });
    } catch (error) {
        console.error('❌ Failed to login:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to login'
        });
    }
});

// API: Update user hash
app.put('/api/auth/update-hash', async (req, res) => {
    try {
        const { uuid, hash, newHash } = req.body;

        if (!uuid || !hash || !newHash) {
            return res.status(400).json({
                success: false,
                error: 'UUID, hash, and newHash are required'
            });
        }

        const success = await joanClient.updateHash(uuid, hash, newHash);

        res.json({
            success,
            message: success ? 'Hash updated successfully' : 'Failed to update hash'
        });
    } catch (error) {
        console.error('❌ Failed to update hash:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update hash'
        });
    }
});

// API: Delete user account
app.delete('/api/auth/delete-user', async (req, res) => {
    try {
        const { uuid, hash } = req.body;

        if (!uuid || !hash) {
            return res.status(400).json({
                success: false,
                error: 'UUID and hash are required'
            });
        }

        const success = await joanClient.deleteUser(uuid, hash);

        res.json({
            success,
            message: success ? 'User deleted successfully' : 'Failed to delete user'
        });
    } catch (error) {
        console.error('❌ Failed to delete user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete user'
        });
    }
});

// API: Get current user keys (for debugging)
app.get('/api/auth/keys', (req, res) => {
    const keys = getJoanKeys();
    res.json({
        success: true,
        hasKeys: !!keys,
        pubKey: keys?.pubKey || null
    });
});

// ========================================
// Prof Profile Management API Endpoints
// ========================================

// API: Create or update user profile in prof
app.post('/api/profile/create', async (req, res) => {
    try {
        const { name, email, bio, location, genres, userUUID } = req.body;

        if (!name || !email || !userUUID) {
            return res.status(400).json({
                success: false,
                error: 'Name, email, and userUUID are required'
            });
        }

        // Create profile in real prof service using sessionless authentication
        try {
            const keys = getJoanKeys();
            if (!keys) {
                throw new Error('No authentication keys available');
            }

            const timestamp = Date.now().toString();
            sessionless.getKeys = getJoanKeys;

            // Create the profile data
            const profilePayload = {
                name,
                email,
                bio: bio || '',
                location: location || '',
                genres: genres || ''
            };

            // Sign the request
            const message = timestamp + userUUID;
            const signature = await sessionless.sign(message);

            console.log('📝 Creating profile in prof service:', profilePayload);

            // Make the API call to prof
            const profResponse = await fetch(`${SERVICE_URLS.prof}/user/${userUUID}/profile`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    ...profilePayload,
                    timestamp,
                    signature
                })
            });

            if (!profResponse.ok) {
                const errorText = await profResponse.text();
                console.error('Prof API error:', profResponse.status, errorText);
                throw new Error(`Prof service returned ${profResponse.status}: ${errorText}`);
            }

            const profResult = await profResponse.json();
            console.log('✅ Prof service response:', profResult);

            res.json({
                success: true,
                data: profResult,
                message: 'Profile created successfully in prof service'
            });

        } catch (profError) {
            console.error('❌ Failed to create profile in prof:', profError);
            res.status(500).json({
                success: false,
                error: 'Failed to create profile: ' + profError.message
            });
        }
    } catch (error) {
        console.error('❌ Failed to create profile:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create profile'
        });
    }
});

// API: Get user profile from prof
app.get('/api/profile/:userUUID', async (req, res) => {
    try {
        const { userUUID } = req.params;

        // In production, this would fetch from prof service
        // For now, return success indicating the endpoint exists
        console.log('📝 Fetching profile from prof for UUID:', userUUID);

        res.json({
            success: true,
            data: null,
            message: 'Profile endpoint ready - prof integration available with proper auth'
        });
    } catch (error) {
        console.error('❌ Failed to fetch profile:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch profile'
        });
    }
});

// API: Update user profile in prof
app.put('/api/profile/:userUUID', async (req, res) => {
    try {
        const { userUUID } = req.params;
        const { name, bio, location, genres } = req.body;

        if (!name) {
            return res.status(400).json({
                success: false,
                error: 'Name is required'
            });
        }

        const profileData = {
            uuid: userUUID,
            name,
            bio: bio || '',
            location: location || '',
            genres: genres ? genres.split(',').map(g => g.trim()) : [],
            updatedAt: new Date().toISOString()
        };

        console.log('📝 Updating profile in prof (simulated):', profileData);

        res.json({
            success: true,
            data: profileData,
            message: 'Profile updated successfully',
            note: 'Currently using local storage - prof integration available with proper auth'
        });
    } catch (error) {
        console.error('❌ Failed to update profile:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update profile'
        });
    }
});

// ========================================
// Sanora Book Management API Endpoints
// ========================================

// API: Create new book/product in sanora
app.post('/api/books/create', async (req, res) => {
    try {
        const { title, description, price, redirectURL, userUUID } = req.body;

        if (!title || !description || !userUUID || price === undefined) {
            return res.status(400).json({
                success: false,
                error: 'Title, description, price, and userUUID are required'
            });
        }

        // Create product in real sanora service using sessionless authentication
        try {
            const keys = getJoanKeys();
            if (!keys) {
                throw new Error('No authentication keys available');
            }

            const timestamp = Date.now().toString();
            sessionless.getKeys = getJoanKeys;

            // Create the product data for sanora API
            const productPayload = {
                title,
                description,
                price: parseFloat(price).toString(), // Sanora expects price as string
                redirectURL: redirectURL || '',
                timestamp,
                signature: await sessionless.sign(timestamp + userUUID + title)
            };

            console.log('📚 Creating product in sanora service:', productPayload);

            // Make the API call to sanora - using PUT as per sanora API
            const sanoraResponse = await fetch(`${SERVICE_URLS.sanora}/user/${userUUID}/product/${encodeURIComponent(title)}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(productPayload)
            });

            if (!sanoraResponse.ok) {
                const errorText = await sanoraResponse.text();
                console.error('Sanora API error:', sanoraResponse.status, errorText);
                throw new Error(`Sanora service returned ${sanoraResponse.status}: ${errorText}`);
            }

            const sanoraResult = await sanoraResponse.json();
            console.log('✅ Sanora service response:', sanoraResult);

            res.json({
                success: true,
                data: sanoraResult,
                message: 'Product created successfully in sanora service'
            });

        } catch (sanoraError) {
            console.error('❌ Failed to create product in sanora:', sanoraError);
            res.status(500).json({
                success: false,
                error: 'Failed to create product: ' + sanoraError.message
            });
        }
    } catch (error) {
        console.error('❌ Failed to create book:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create book'
        });
    }
});

// API: Get user's books from sanora
app.get('/api/books/user/:userUUID', async (req, res) => {
    try {
        const { userUUID } = req.params;

        console.log('📚 Fetching user books from sanora for UUID:', userUUID);

        // In production, this would fetch from sanora service
        // For now, return empty array with success message
        res.json({
            success: true,
            data: [],
            message: 'Books endpoint ready - sanora integration available with proper auth'
        });
    } catch (error) {
        console.error('❌ Failed to fetch user books:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch user books'
        });
    }
});

// API: Update book in sanora
app.put('/api/books/:productId', async (req, res) => {
    try {
        const { productId } = req.params;
        const { title, description, price, category } = req.body;

        if (!title || !category || price === undefined) {
            return res.status(400).json({
                success: false,
                error: 'Title, category, and price are required'
            });
        }

        const productData = {
            productId,
            title,
            description: description || '',
            price: parseFloat(price),
            category,
            updatedAt: new Date().toISOString()
        };

        console.log('📚 Updating book in sanora (simulated):', productData);

        res.json({
            success: true,
            data: productData,
            message: 'Book updated successfully',
            note: 'Currently using local storage - sanora integration available with proper auth'
        });
    } catch (error) {
        console.error('❌ Failed to update book:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update book'
        });
    }
});

// API: Delete book from sanora
app.delete('/api/books/:productId', async (req, res) => {
    try {
        const { productId } = req.params;

        console.log('📚 Deleting book from sanora (simulated):', productId);

        res.json({
            success: true,
            message: 'Book deleted successfully',
            note: 'Currently using local storage - sanora integration available with proper auth'
        });
    } catch (error) {
        console.error('❌ Failed to delete book:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete book'
        });
    }
});

// API: Get authors from prof service
app.get('/api/authors', async (req, res) => {
    try {
        const authors = await fetchAuthorsFromProf();
        res.json({
            success: true,
            data: authors,
            source: 'prof'
        });
    } catch (error) {
        console.error('Failed to fetch authors:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch authors',
            fallback: MOCK_AUTHORS
        });
    }
});

// API: Get books from sanora service
app.get('/api/books', async (req, res) => {
    try {
        const books = await fetchBooksFromSanora();
        res.json({
            success: true,
            data: books,
            source: 'sanora'
        });
    } catch (error) {
        console.error('Failed to fetch books:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch books',
            fallback: MOCK_BOOKS
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
            'magic-protocol',
            'prof-integration',
            'sanora-integration'
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
