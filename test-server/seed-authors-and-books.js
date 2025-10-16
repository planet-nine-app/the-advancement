#!/usr/bin/env node

import sessionless from 'sessionless-node';
import fetch from 'node-fetch';
import crypto from 'crypto';

// Configuration for test environment
const BASE_URL = 'http://localhost:5123'; // Prof on Base 1
const SANORA_URL = 'http://localhost:5121'; // Sanora on Base 1  
const BDO_URL = 'http://localhost:5114'; // BDO on Base 1

// Generate test keys for seeding using crypto directly
const testKeys = {
  privateKey: crypto.randomBytes(32).toString('hex'),
  publicKey: 'test-public-key-' + crypto.randomBytes(16).toString('hex')
};

console.log('🌱 Starting author and book seeding...');
console.log('Using test key:', testKeys.publicKey);

// Author data
const authors = [
  {
    uuid: sessionless.generateUUID(),
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
    uuid: sessionless.generateUUID(),
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
    uuid: sessionless.generateUUID(),
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
  // Marcus Chen's books
  {
    id: 'digital-consciousness-003',
    title: 'Digital Consciousness',
    author: 'Marcus Chen',
    authorUUID: authors[1].uuid,
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
    authorUUID: authors[1].uuid,
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
    authorUUID: authors[2].uuid,
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
    authorUUID: authors[2].uuid,
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

// Helper function to create simple signature for testing
function createSignature(uuid, timestamp) {
  // Create a simple signature for testing (not cryptographically secure)
  const data = `${uuid}-${timestamp}`;
  return crypto.createHash('sha256').update(data + testKeys.privateKey).digest('hex');
}

// Helper function to make authenticated request to prof
async function profRequest(endpoint, method, uuid, data = null) {
  const timestamp = Date.now();
  const signature = createSignature(uuid, timestamp);
  
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };

  const params = new URLSearchParams({
    uuid,
    timestamp: timestamp.toString(),
    signature
  });

  if (method === 'GET') {
    const response = await fetch(`${BASE_URL}${endpoint}?${params}`);
    return response.json();
  } else {
    options.body = JSON.stringify({
      ...data,
      uuid,
      timestamp,
      signature
    });
    const response = await fetch(`${BASE_URL}${endpoint}`, options);
    return response.json();
  }
}

// Helper function to make authenticated request to sanora
async function sanoraRequest(endpoint, method, data = null) {
  const timestamp = Date.now();
  const signature = createSignature(testKeys.publicKey, timestamp);
  
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
      pubKey: testKeys.publicKey
    });
    const response = await fetch(`${SANORA_URL}${endpoint}`, options);
    return response.json();
  }
}

// Helper function to make request to BDO
async function bdoRequest(endpoint, method, data = null) {
  const timestamp = Date.now();
  const signature = createSignature(testKeys.publicKey, timestamp);
  
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
      pubKey: testKeys.publicKey
    });
    const response = await fetch(`${BDO_URL}${endpoint}?${params}`);
    return response.json();
  } else {
    options.body = JSON.stringify({
      ...data,
      timestamp,
      signature,
      pubKey: testKeys.publicKey
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
      const result = await profRequest('/user/' + author.uuid + '/profile', 'POST', author.uuid, author);
      
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
  
  for (const book of books) {
    try {
      console.log(`Creating book: ${book.title}...`);
      const result = await sanoraRequest('/products', 'POST', book);
      
      if (result.success || result.uuid) {
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
    console.log(`  Prof: ${BASE_URL}`);
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