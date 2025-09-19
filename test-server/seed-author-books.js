#!/usr/bin/env node

/**
 * Author-Book Association Seeder
 *
 * This script:
 * 1. Fetches existing authors from prof service
 * 2. Creates relevant books for each author in sanora service
 * 3. Stores author-book associations in BDO service
 *
 * Usage: node seed-author-books.js
 */

import sessionless from 'sessionless-node';
import fetch from 'node-fetch';
import crypto from 'crypto';

// Service URLs for Docker test environment
const SERVICES = {
    prof: 'http://localhost:5123',
    sanora: 'http://localhost:5121',
    bdo: 'http://localhost:5114'
};

// Test user creation helper (from original seed script)
const testUsers = new Map();

const createTestUser = async (seed) => {
    if (testUsers.has(seed)) {
        return testUsers.get(seed);
    }

    const hash = crypto.createHash('sha256').update(seed).digest('hex');
    const privateKey = hash.substring(0, 64);

    try {
        const { secp256k1 } = await import('ethereum-cryptography/secp256k1');
        const { bytesToHex } = await import('ethereum-cryptography/utils.js');

        const pubKey = bytesToHex(secp256k1.getPublicKey(privateKey));
        const uuid = sessionless.generateUUID();

        const user = { uuid, pubKey, privateKey };
        testUsers.set(seed, user);
        return user;

    } catch (error) {
        console.log(`⚠️  Using simple fallback key generation for ${seed}`);
        const uuid = crypto.createHash('sha256').update(seed + 'uuid').digest('hex').substring(0, 32);
        const pubKey = crypto.createHash('sha256').update(seed + 'pubkey').digest('hex');

        const user = { uuid, pubKey, privateKey };
        testUsers.set(seed, user);
        return user;
    }
};

const signMessage = async (privateKey, message) => {
    try {
        const { secp256k1 } = await import('ethereum-cryptography/secp256k1');
        const { keccak256 } = await import('ethereum-cryptography/keccak.js');
        const { utf8ToBytes } = await import('ethereum-cryptography/utils.js');

        const messageHash = keccak256(utf8ToBytes(message));
        const signatureAsBigInts = secp256k1.sign(messageHash, privateKey);
        const signature = signatureAsBigInts.toCompactHex();
        return signature;
    } catch (error) {
        console.log(`⚠️  Using fallback signature for message`);
        return crypto.createHash('sha256').update(privateKey + message).digest('hex');
    }
};

// Book templates for each author based on their expertise
const AUTHOR_BOOKS = {
    'Alice Developer': [
        {
            title: 'React Mastery: From Hooks to Production',
            description: 'Complete guide to modern React development, covering hooks, context, performance optimization, and deployment strategies.',
            price: 4999, // $49.99
            category: 'ebook',
            tags: ['react', 'javascript', 'frontend', 'web-development']
        },
        {
            title: 'Full-Stack JavaScript Architecture',
            description: 'Master the art of building scalable full-stack applications with Node.js, Express, and modern frontend frameworks.',
            price: 5999, // $59.99
            category: 'ebook',
            tags: ['javascript', 'nodejs', 'fullstack', 'architecture']
        }
    ],
    'Bob Designer': [
        {
            title: 'UI/UX Design Systems Masterclass',
            description: 'Learn to create consistent, scalable design systems that improve user experience and developer productivity.',
            price: 3999, // $39.99
            category: 'course',
            tags: ['design-systems', 'ui-ux', 'figma', 'design']
        },
        {
            title: 'Modern Interface Design Principles',
            description: 'Comprehensive guide to creating beautiful, intuitive interfaces that users love.',
            price: 2999, // $29.99
            category: 'ebook',
            tags: ['ui-design', 'user-interface', 'design-principles', 'creativity']
        }
    ],
    'Charlie Analytics': [
        {
            title: 'Data Science with Python: A Practical Guide',
            description: 'From data collection to machine learning deployment, master the complete data science workflow.',
            price: 6999, // $69.99
            category: 'course',
            tags: ['python', 'data-science', 'machine-learning', 'analytics']
        },
        {
            title: 'Business Intelligence Dashboard Design',
            description: 'Create powerful, actionable business dashboards that drive data-driven decision making.',
            price: 4499, // $44.99
            category: 'ebook',
            tags: ['business-intelligence', 'dashboards', 'data-visualization', 'tableau']
        }
    ],
    'Diana Marketing': [
        {
            title: 'Content Marketing Strategy Blueprint',
            description: 'Build a comprehensive content marketing strategy that attracts, engages, and converts your target audience.',
            price: 3499, // $34.99
            category: 'course',
            tags: ['content-marketing', 'digital-marketing', 'strategy', 'seo']
        },
        {
            title: 'SEO Mastery: Organic Growth Guide',
            description: 'Master the art and science of SEO to drive sustainable organic traffic growth.',
            price: 2999, // $29.99
            category: 'ebook',
            tags: ['seo', 'organic-growth', 'google-analytics', 'marketing']
        }
    ],
    'Eve Security': [
        {
            title: 'Cybersecurity Assessment Framework',
            description: 'Professional framework for conducting comprehensive security assessments and penetration testing.',
            price: 7999, // $79.99
            category: 'toolkit',
            tags: ['cybersecurity', 'penetration-testing', 'security-audit', 'enterprise']
        },
        {
            title: 'Network Security Best Practices',
            description: 'Essential guide to securing modern network infrastructure against evolving threats.',
            price: 5499, // $54.99
            category: 'ebook',
            tags: ['network-security', 'infrastructure', 'security-practices', 'incident-response']
        }
    ],
    'Frank Project Manager': [
        {
            title: 'Agile Project Management Toolkit',
            description: 'Complete set of templates, processes, and best practices for successful agile project delivery.',
            price: 4999, // $49.99
            category: 'toolkit',
            tags: ['agile', 'project-management', 'scrum', 'team-leadership']
        },
        {
            title: 'Remote Team Leadership Guide',
            description: 'Master the art of leading and coordinating distributed teams for maximum productivity.',
            price: 3999, // $39.99
            category: 'ebook',
            tags: ['remote-work', 'team-leadership', 'project-management', 'productivity']
        }
    ],
    'Grace DevOps': [
        {
            title: 'Docker & Kubernetes Production Guide',
            description: 'Deploy and manage containerized applications at scale with industry best practices.',
            price: 6999, // $69.99
            category: 'course',
            tags: ['docker', 'kubernetes', 'devops', 'containers']
        },
        {
            title: 'CI/CD Pipeline Architecture',
            description: 'Design and implement robust continuous integration and deployment pipelines.',
            price: 5999, // $59.99
            category: 'ebook',
            tags: ['ci-cd', 'devops', 'automation', 'infrastructure']
        }
    ],
    'Henry Writer': [
        {
            title: 'Technical Writing for Developers',
            description: 'Create documentation that developers actually want to read and use.',
            price: 3499, // $34.99
            category: 'ebook',
            tags: ['technical-writing', 'documentation', 'developer-experience', 'communication']
        },
        {
            title: 'API Documentation Masterclass',
            description: 'Learn to create comprehensive, user-friendly API documentation that reduces support tickets.',
            price: 4499, // $44.99
            category: 'course',
            tags: ['api-documentation', 'technical-writing', 'developer-tools', 'documentation']
        }
    ],
    'Iris Consultant': [
        {
            title: 'Startup Growth Strategy Playbook',
            description: 'Proven strategies and frameworks for scaling early-stage startups to sustainable growth.',
            price: 5999, // $59.99
            category: 'ebook',
            tags: ['startup', 'business-strategy', 'growth', 'entrepreneurship']
        },
        {
            title: 'Business Process Optimization Guide',
            description: 'Systematic approach to identifying and eliminating inefficiencies in business operations.',
            price: 4999, // $49.99
            category: 'toolkit',
            tags: ['business-consulting', 'process-optimization', 'operations', 'efficiency']
        }
    ]
};

class SanoraClient {
    constructor(baseURL) {
        this.baseURL = baseURL;
    }

    async createUser(seed) {
        const keys = await createTestUser(seed);
        const timestamp = new Date().getTime();
        const signature = await signMessage(keys.privateKey, timestamp + keys.pubKey);

        try {
            const response = await fetch(`${this.baseURL}/user/create`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    timestamp: timestamp.toString(),
                    pubKey: keys.pubKey,
                    signature
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${await response.text()}`);
            }

            const result = await response.json();
            return {
                uuid: result.uuid,
                pubKey: keys.pubKey,
                privateKey: keys.privateKey
            };
        } catch (error) {
            console.error('Failed to create Sanora user:', error.message);
            return null;
        }
    }

    async createProduct(user, productData, authorUUID) {
        try {
            const timestamp = new Date().getTime();
            const message = timestamp + user.uuid + productData.title + productData.description + productData.price;
            const signature = await signMessage(user.privateKey, message);

            const response = await fetch(`${this.baseURL}/user/${user.uuid}/product/${encodeURIComponent(productData.title)}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    ...productData,
                    authorUUID, // Add author UUID as metadata
                    timestamp: timestamp.toString(),
                    signature
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${await response.text()}`);
            }

            return await response.json();
        } catch (error) {
            console.error(`Failed to create product ${productData.title}:`, error.message);
            return null;
        }
    }
}

class BDOClient {
    constructor(baseURL) {
        this.baseURL = baseURL;
    }

    async createUser(seed) {
        const keys = await createTestUser(seed);
        const timestamp = new Date().getTime();
        const hash = sessionless.generateUUID();
        const signature = await signMessage(keys.privateKey, timestamp + keys.pubKey + hash);

        try {
            const response = await fetch(`${this.baseURL}/user/create`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    timestamp: timestamp.toString(),
                    pubKey: keys.pubKey,
                    hash,
                    signature,
                    bdo: { authorBooks: {} }
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${await response.text()}`);
            }

            const result = await response.text();
            return {
                uuid: result,
                pubKey: keys.pubKey,
                privateKey: keys.privateKey,
                hash
            };
        } catch (error) {
            console.error('Failed to create BDO user:', error.message);
            return null;
        }
    }

    async createAuthorBooksBDO(user, authorUUID, bookUUIDs) {
        try {
            const timestamp = new Date().getTime();
            const bdoContent = {
                authorUUID: authorUUID,
                bookUUIDs: bookUUIDs,
                createdAt: new Date().toISOString()
            };

            const signature = await signMessage(user.privateKey, timestamp + user.uuid + user.hash + JSON.stringify(bdoContent));

            const response = await fetch(`${this.baseURL}/user/${user.uuid}/bdo`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    timestamp: timestamp.toString(),
                    uuid: user.uuid,
                    hash: user.hash,
                    signature,
                    bdo: bdoContent
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${await response.text()}`);
            }

            // Get the BDO pubKey from response (should be user.hash)
            const bdoPubKey = user.hash;
            console.log(`✅ Created BDO for author ${authorUUID} with pubKey: ${bdoPubKey}`);
            return bdoPubKey;
        } catch (error) {
            console.error('❌ Failed to create author-books BDO:', error.message);
            return null;
        }
    }
}

// Add a ProfClient class to update author profiles
class ProfClient {
    constructor(baseURL) {
        this.baseURL = baseURL;
    }

    async updateAuthorWithBDO(authorUUID, bdoPubKey) {
        try {
            // We'll need to simulate prof profile update with BDO metadata
            // For now, we'll just log the association
            console.log(`📝 Would update author ${authorUUID} with BDO pubKey: ${bdoPubKey}`);
            // TODO: Implement actual prof profile update when we have the endpoint
            return true;
        } catch (error) {
            console.error('❌ Failed to update author profile:', error.message);
            return false;
        }
    }
}

async function fetchAuthors() {
    try {
        console.log('📝 Fetching authors from prof service...');
        const response = await fetch(`${SERVICES.prof}/profiles?tags=author`);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${await response.text()}`);
        }

        const data = await response.json();
        if (!data.success) {
            throw new Error(data.error || 'Unknown error');
        }

        const authors = data.profiles || [];
        console.log(`✅ Found ${authors.length} authors`);
        return authors;
    } catch (error) {
        console.error('❌ Failed to fetch authors:', error.message);
        return [];
    }
}

async function seedAuthorBooks() {
    console.log('📚 Starting Author-Book Association Seeding');
    console.log('==========================================\n');

    // 1. Fetch existing authors
    const authors = await fetchAuthors();
    if (authors.length === 0) {
        console.log('❌ No authors found. Please run the main seeding script first.');
        return;
    }

    // 2. Create Sanora client
    const sanoraClient = new SanoraClient(SERVICES.sanora);
    const sanoraUser = await sanoraClient.createUser('author-books-sanora-user');
    if (!sanoraUser) {
        console.log('❌ Failed to create Sanora user');
        return;
    }

    // 3. Create BDO client
    const bdoClient = new BDOClient(SERVICES.bdo);
    const bdoUser = await bdoClient.createUser('author-books-bdo-user');
    if (!bdoUser) {
        console.log('❌ Failed to create BDO user');
        return;
    }

    // 4. Create Prof client
    const profClient = new ProfClient(SERVICES.prof);

    // 5. Create books for each author and BDO associations
    let totalBooks = 0;
    let totalBDOs = 0;

    for (const author of authors) {
        const authorName = author.name;
        const books = AUTHOR_BOOKS[authorName];

        if (!books) {
            console.log(`⚠️  No books defined for ${authorName}, skipping...`);
            continue;
        }

        console.log(`\n📖 Creating books for ${authorName}:`);
        const bookUUIDs = [];

        // Create books for this author
        for (const bookData of books) {
            const product = await sanoraClient.createProduct(sanoraUser, bookData, author.uuid);
            if (product) {
                const bookUUID = product.uuid || product.id;
                bookUUIDs.push(bookUUID);
                console.log(`  ✅ Created: ${bookData.title} ($${(bookData.price / 100).toFixed(2)}) - UUID: ${bookUUID}`);
                totalBooks++;
            }
        }

        // Create BDO association for this author
        if (bookUUIDs.length > 0) {
            console.log(`\n🔗 Creating BDO association for ${authorName}...`);
            const bdoPubKey = await bdoClient.createAuthorBooksBDO(bdoUser, author.uuid, bookUUIDs);

            if (bdoPubKey) {
                // Update author profile with BDO pubKey
                await profClient.updateAuthorWithBDO(author.uuid, bdoPubKey);
                totalBDOs++;
                console.log(`  📝 Associated ${bookUUIDs.length} books with author via BDO`);
            }
        }
    }

    console.log(`\n🎉 Seeding complete!`);
    console.log(`📊 Created ${totalBooks} books for ${authors.length} authors`);
    console.log(`🔗 Created ${totalBDOs} BDO associations for easy retrieval`);
}

// Run the seeder
seedAuthorBooks().catch(error => {
    console.error('💥 Unhandled error:', error);
    process.exit(1);
});