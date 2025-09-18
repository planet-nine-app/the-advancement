#!/usr/bin/env node

import sessionless from 'sessionless-node';
import fetch from 'node-fetch';
import crypto from 'crypto';

// Configuration for test environment - Base 1
// Using actual running ports in current test environment
const PROF_URL = 'http://localhost:5123'; // Prof on Base 1 (verified running)
const SANORA_URL = 'http://localhost:5121'; // Sanora on Base 1 (verified running)
const BDO_URL = 'http://localhost:5114'; // BDO on Base 1 (verified running)

// Set up deterministic test key storage for seeding
const testUsers = new Map();

// Helper function to create deterministic test users
const createTestUser = async (seed) => {
  // Check if we already created this user
  if (testUsers.has(seed)) {
    return testUsers.get(seed);
  }

  // Create deterministic keys from seed
  const hash = crypto.createHash('sha256').update(seed).digest('hex');
  const privateKey = hash.substring(0, 64);

  // Create deterministic public key using secp256k1
  try {
    // Import secp256k1 directly
    const { secp256k1 } = await import('ethereum-cryptography/secp256k1');
    const { bytesToHex } = await import('ethereum-cryptography/utils.js');

    const pubKey = bytesToHex(secp256k1.getPublicKey(privateKey));
    const uuid = sessionless.generateUUID();

    const user = {
      uuid,
      pubKey,
      privateKey
    };

    testUsers.set(seed, user);
    return user;

  } catch (error) {
    console.log(`⚠️  Using simple fallback key generation for ${seed}`);
    // Simple fallback
    const uuid = crypto.createHash('sha256').update(seed + 'uuid').digest('hex').substring(0, 32);
    const pubKey = crypto.createHash('sha256').update(seed + 'pubkey').digest('hex');

    const user = {
      uuid,
      pubKey,
      privateKey
    };

    testUsers.set(seed, user);
    return user;
  }
};

// Custom sign function that matches the working seed-ecosystem.js exactly
const signMessage = async (privateKey, message) => {
  const { secp256k1 } = await import('ethereum-cryptography/secp256k1');
  const { keccak256 } = await import('ethereum-cryptography/keccak.js');
  const { utf8ToBytes } = await import('ethereum-cryptography/utils.js');

  const messageHash = keccak256(utf8ToBytes(message));
  const signatureAsBigInts = secp256k1.sign(messageHash, privateKey);
  const signature = signatureAsBigInts.toCompactHex();
  return signature;
};

console.log('🌱 Starting author and book seeding...');

// Author data - will use createTestUser() to generate users
const authorData = [
  {
    name: 'Sarah Mitchell',
    email: 'sarah@writersworld.com',
    bio: 'Award-winning fantasy author with over 15 years of experience crafting immersive worlds and unforgettable characters.',
    location: 'Portland, Oregon',
    website: 'https://sarahmitchell.com',
    profileImage: '/images/sarah-mitchell.svg',
    genres: ['Fantasy', 'Adventure', 'Young Adult'],
    awards: ['Hugo Award 2023', 'World Fantasy Award 2022']
  },
  {
    name: 'Delores Swigert Sullivan',
    email: 'deloressullivan2@gmail.com',
    bio: 'Delores Swigert grew up in rural Missouri during the 1950s and 1960s, an era marked by significant race and gender inequality. Her powerful memoir chronicles her journey from adversity to international modeling and adoption reform activism.',
    location: 'Oregon',
    profileImage: '/images/delores-sullivan.png',
    genres: ['Memoir']
  },
  {
    name: 'Marcus Chen',
    email: 'marcus@techwriters.net',
    bio: 'Technology journalist and sci-fi novelist exploring the intersection of humanity and artificial intelligence.',
    location: 'San Francisco, California',
    website: 'https://marcuschen.dev',
    profileImage: '/images/marcus-chen.svg',
    genres: ['Science Fiction', 'Thriller', 'Technology'],
    specialties: ['AI Ethics', 'Future Technology', 'Cyberpunk']
  },
  {
    name: 'Isabella Rodriguez',
    email: 'isabella@historicalfiction.org',
    bio: 'Historian turned novelist, bringing forgotten stories from Latin American history to vivid life.',
    location: 'Mexico City, Mexico',
    website: 'https://isabellarodriguez.mx',
    profileImage: '/images/isabella-rodriguez.svg',
    genres: ['Historical Fiction', 'Literary Fiction', 'Cultural Heritage'],
    languages: ['Spanish', 'English', 'Portuguese']
  }
];

// Create authors array with real users
const authors = [];
for (let i = 0; i < authorData.length; i++) {
  const user = await createTestUser(`author-${authorData[i].name}`);
  authors.push({
    ...user,
    ...authorData[i]
  });
}

// Book data
const books = [
  // Sarah Mitchell's books
  {
    id: 'crystal-prophecy-001',
    title: 'The Crystal Prophecy',
    author: 'Sarah Mitchell',
    authorUUID: authors[0].uuid,
    description: 'In a world where magic flows through ancient crystals, young Lyra must unite the scattered kingdoms before darkness consumes everything she holds dear.',
    price: 1299, // $12.99 in cents
    category: 'ebook',
    genres: ['Fantasy', 'Adventure', 'Young Adult'],
    pages: 384,
    isbn: '978-1-234567-89-0',
    published: '2024-03-15',
    rating: 4.8,
    coverImage: 'https://via.placeholder.com/300x450/4a90e2/ffffff?text=The+Crystal+Prophecy'
  },
  {
    id: 'shadows-realm-002', 
    title: 'Shadows of the Forgotten Realm',
    author: 'Sarah Mitchell',
    authorUUID: authors[0].uuid,
    description: 'The epic sequel to The Crystal Prophecy. Lyra faces her greatest challenge yet as she ventures into the Forgotten Realm to save her world.',
    price: 1399, // $13.99 in cents
    category: 'ebook',
    genres: ['Fantasy', 'Adventure', 'Young Adult'],
    pages: 412,
    isbn: '978-1-234567-90-6',
    published: '2024-08-22',
    rating: 4.9,
    coverImage: 'https://via.placeholder.com/300x450/6a4c93/ffffff?text=Shadows+of+the+Forgotten+Realm'
  },
  // Delores Sullivan's books
  {
    id: 'a-good-place-to-live',
    title: 'A Good Place To Live',
    subTitle: 'A Girl Comes of Age in the Rural Midwest',
    author: 'Delores Sullivan',
    authorUUID: authors[1].uuid,
    description: `"A Good Place to Live" chronicles a mixed-race girl growing up in rural Missouri during the 1950s/60s. As her family disintegrates, DeeDee is forced to raise herself with the help of kind townspeople. She emerges from the trauma of a teen pregnancy and the surrender of her child for adoption to join the international elite of the fashion world. But the lingering wound from the loss of her son spurs her first to a search for him, and then to social activism, as she becomes the face of the adoption reform movement.
Delores Sullivan has a master's degree in social work. She is married to author Randall Sullivan, and they live on the Oregon Coast.`,
    price: 1299, // $12.99 in cents
    category: 'ebook',
    genres: ['Memoir'],
    pages: 384,
    isbn: '979-8-9860138-9-3',
    published: '2025-09-15',
    rating: 100,
    coverImage: '/images/a-good-place-to-live.png'
  },
  // Marcus Chen's books
  {
    id: 'digital-consciousness-003',
    title: 'Digital Consciousness',
    author: 'Marcus Chen',
    authorUUID: authors[2].uuid,
    description: 'When AI achieves true consciousness, the line between human and machine blurs. A thrilling exploration of what it means to be alive.',
    price: 1499, // $14.99 in cents
    category: 'ebook',
    genres: ['Science Fiction', 'Thriller', 'Technology'],
    pages: 356,
    isbn: '978-1-234567-91-3',
    published: '2024-01-10',
    rating: 4.7,
    coverImage: 'https://via.placeholder.com/300x450/e74c3c/ffffff?text=Digital+Consciousness'
  },
  {
    id: 'quantum-paradox-004',
    title: 'The Quantum Paradox',
    author: 'Marcus Chen',
    authorUUID: authors[2].uuid,
    description: 'A quantum physicist discovers that reality itself is programmable, leading to a race against time to prevent digital apocalypse.',
    price: 1599, // $15.99 in cents
    category: 'ebook',
    genres: ['Science Fiction', 'Thriller', 'Technology'],
    pages: 398,
    isbn: '978-1-234567-92-0',
    published: '2024-06-05',
    rating: 4.6,
    coverImage: 'https://via.placeholder.com/300x450/f39c12/ffffff?text=The+Quantum+Paradox'
  },
  // Isabella Rodriguez's books
  {
    id: 'aztec-dreams-005',
    title: 'Dreams of the Aztec Empire',
    author: 'Isabella Rodriguez',
    authorUUID: authors[3].uuid,
    description: 'Follow the untold story of Itzel, a young Aztec woman who becomes a bridge between two worlds during the Spanish conquest.',
    price: 1199, // $11.99 in cents
    category: 'ebook', 
    genres: ['Historical Fiction', 'Cultural Heritage', 'Drama'],
    pages: 445,
    isbn: '978-1-234567-93-7',
    published: '2024-02-28',
    rating: 4.9,
    coverImage: 'https://via.placeholder.com/300x450/27ae60/ffffff?text=Dreams+of+the+Aztec+Empire'
  },
  {
    id: 'colonial-echoes-006',
    title: 'Colonial Echoes',
    author: 'Isabella Rodriguez',
    authorUUID: authors[3].uuid,
    description: 'A sweeping saga of three generations of women fighting to preserve their heritage during the colonial period in New Spain.',
    price: 1299, // $12.99 in cents
    category: 'ebook',
    genres: ['Historical Fiction', 'Literary Fiction', 'Family Saga'],
    pages: 523,
    isbn: '978-1-234567-94-4',
    published: '2024-07-18', 
    rating: 4.8,
    coverImage: 'https://via.placeholder.com/300x450/8e44ad/ffffff?text=Colonial+Echoes'
  }
];

// Helper function to make authenticated request to prof
async function profRequest(endpoint, method, user, data = null) {
  const timestamp = Date.now();
  const hash = sessionless.generateUUID();
  const message = user.uuid + timestamp;
  const signature = await signMessage(user.privateKey, message);

  console.log(`🔍 Debug prof request for ${data?.name}:`);
  console.log(`   UUID: ${user.uuid}`);
  console.log(`   Timestamp: ${timestamp}`);
  console.log(`   Message: "${message}"`);
  console.log(`   Signature: ${signature}`);
  console.log(`   Hash: ${hash}`);

  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };

  if (method === 'GET') {
    const params = new URLSearchParams({
      uuid: user.uuid,
      timestamp: timestamp.toString(),
      hash,
      signature
    });
    const response = await fetch(`${PROF_URL}${endpoint}?${params}`);
    return response.json();
  } else {
    // Extract only the profile fields, not the crypto fields
    const { uuid, pubKey, privateKey, ...profileFields } = data;

    const requestBody = {
      uuid: user.uuid,
      timestamp,
      hash,
      signature,
      profileData: JSON.stringify({
        ...profileFields,
        additional_fields: profileFields.additional_fields || {}
      })
    };

    console.log(`   Request body keys: ${Object.keys(requestBody).join(', ')}`);
    console.log(`   ProfileData: ${requestBody.profileData}`);

    options.body = JSON.stringify(requestBody);
    const response = await fetch(`${PROF_URL}${endpoint}`, options);

    console.log(`   Response status: ${response.status}`);
    const result = await response.json();
    console.log(`   Response: ${JSON.stringify(result)}`);

    return result;
  }
}

// Global seeding user for sanora and BDO
let seedingUser = null;

// Helper function to get seeding user
async function getSeedingUser() {
  if (!seedingUser) {
    seedingUser = await createTestUser('seeding-user');
  }
  return seedingUser;
}

// Helper function to create sanora user
async function createSanoraUser() {
  const user = await getSeedingUser();
  const timestamp = Date.now();
  const signature = await signMessage(user.privateKey, user.pubKey + timestamp);

  const response = await fetch(`${SANORA_URL}/user/create`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      pubKey: user.pubKey,
      timestamp,
      signature
    })
  });

  const result = await response.json();
  console.log('Sanora user result:', result);
  return result.uuid || user.uuid;
}

// Helper function to make authenticated request to sanora
async function sanoraRequest(endpoint, method, data = null) {
  const user = await getSeedingUser();
  const userUUID = await createSanoraUser(); // Ensure user exists

  const timestamp = Date.now();
  const signature = await signMessage(user.privateKey, user.pubKey + timestamp);

  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };

  if (method === 'GET') {
    const response = await fetch(`${SANORA_URL}${endpoint}`);
    return response.json();
  } else {
    options.body = JSON.stringify({
      ...data,
      timestamp,
      signature,
      pubKey: user.pubKey
    });
    const response = await fetch(`${SANORA_URL}${endpoint}`, options);
    return response.json();
  }
}

// Helper function to make request to BDO
async function bdoRequest(endpoint, method, data = null) {
  const user = await getSeedingUser();
  const timestamp = Date.now();
  const signature = await signMessage(user.privateKey, timestamp + user.uuid);

  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };

  if (method === 'GET') {
    const params = new URLSearchParams({
      timestamp: timestamp.toString(),
      signature,
      pubKey: user.pubKey
    });
    const response = await fetch(`${BDO_URL}${endpoint}?${params}`);
    return response.json();
  } else {
    options.body = JSON.stringify({
      ...data,
      timestamp,
      signature,
      pubKey: user.pubKey
    });
    const response = await fetch(`${BDO_URL}${endpoint}`, options);
    return response.json();
  }
}

// Seed author profiles
async function seedProfiles() {
  console.log('\n📝 Creating author profiles...');

  for (const author of authors) {
    try {
      console.log(`Creating profile for ${author.name}...`);
      const result = await profRequest('/user/' + author.uuid + '/profile', 'POST', author, author);

      if (result.success) {
        console.log(`✅ Created profile for ${author.name}`);
      } else {
        console.log(`❌ Failed to create profile for ${author.name}:`, result.error);
      }
    } catch (error) {
      console.error(`❌ Error creating profile for ${author.name}:`, error.message);
    }
  }
}

// Seed books in sanora
async function seedBooks() {
  console.log('\n📚 Creating books in sanora...');

  const userUUID = await createSanoraUser();
  console.log(`Using sanora user UUID: ${userUUID}`);

  // Update book authorUUIDs to match the created authors
  for (let i = 0; i < books.length; i++) {
    const book = books[i];
    if (book.author === 'Sarah Mitchell') {
      book.authorUUID = authors[0].uuid;
    } else if (book.author === 'Delores Sullivan') {
      book.authorUUID = authors[1].uuid;
    } else if (book.author === 'Marcus Chen') {
      book.authorUUID = authors[2].uuid;
    } else if (book.author === 'Isabella Rodriguez') {
      book.authorUUID = authors[3].uuid;
    }
  }

  for (const book of books) {
    try {
      console.log(`Creating book: ${book.title}...`);

      // Use the sanora PUT endpoint format: /user/:uuid/product/:title
      const endpoint = `/user/${userUUID}/product/${encodeURIComponent(book.title)}`;
      const result = await sanoraRequest(endpoint, 'PUT', {
        title: book.title,
        description: book.description,
        price: book.price.toString(),
        category: book.category || 'ebook'
      });

      if (result.success || result.uuid || result.productId) {
        console.log(`✅ Created book: ${book.title}`);
      } else {
        console.log(`❌ Failed to create book ${book.title}:`, result.error || result);
      }
    } catch (error) {
      console.error(`❌ Error creating book ${book.title}:`, error.message);
    }
  }
}

// Create BDO associations
async function createAssociations() {
  console.log('\n🔗 Creating author-book associations in BDO...');
  
  // Create associations object
  const associations = {
    type: 'author-book-associations',
    description: 'Maps author profile UUIDs to their book product IDs',
    created: new Date().toISOString(),
    authors: authors.map(author => ({
      profileUUID: author.uuid,
      name: author.name,
      bookIds: books
        .filter(book => book.authorUUID === author.uuid)
        .map(book => book.id)
    }))
  };

  try {
    console.log('Storing associations in BDO...');
    const result = await bdoRequest('/bdo', 'POST', {
      object: associations,
      metadata: {
        type: 'author-book-associations',
        public: true,
        description: 'Author and book associations for carousel demo'
      }
    });
    
    if (result.uuid) {
      console.log(`✅ Created BDO associations with UUID: ${result.uuid}`);
      console.log('🎯 Save this UUID for the carousel site:', result.uuid);
      return result.uuid;
    } else {
      console.log('❌ Failed to create BDO associations:', result);
    }
  } catch (error) {
    console.error('❌ Error creating BDO associations:', error.message);
  }
}

// Main seeding function
async function main() {
  try {
    console.log('🚀 Starting seeding process...');
    console.log('Target services:');
    console.log(`  Prof: ${PROF_URL}`);
    console.log(`  Sanora: ${SANORA_URL}`);
    console.log(`  BDO: ${BDO_URL}`);
    
    await seedProfiles();
    await seedBooks();
    const associationsUUID = await createAssociations();
    
    console.log('\n🎉 Seeding completed!');
    console.log('\n📋 Summary:');
    console.log(`  Authors created: ${authors.length}`);
    console.log(`  Books created: ${books.length}`);
    console.log(`  BDO UUID: ${associationsUUID || 'Failed to create'}`);
    
    console.log('\n📖 Authors and their books:');
    authors.forEach(author => {
      const authorBooks = books.filter(book => book.authorUUID === author.uuid);
      console.log(`  ${author.name}: ${authorBooks.map(b => b.title).join(', ')}`);
    });
    
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

// Run the seeding
main();
