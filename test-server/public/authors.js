// Authors and Books Carousel Implementation
// Using Planet Nine services: Prof (profiles), Sanora (products), BDO (associations)

class AuthorsCarousel {
    constructor() {
        this.baseUrls = {
            prof: 'http://localhost:5123',
            sanora: 'http://localhost:5121', 
            bdo: 'http://localhost:5114'
        };
        this.container = document.getElementById('authorsContainer');
        this.associationsUUID = null; // Will be set when BDO associations are found
        this.init();
    }

    async init() {
        try {
            // Fetch live data from API endpoints
            await this.renderLiveData();
        } catch (error) {
            console.error('Failed to load from API, falling back to mock data:', error);
            await this.renderMockData();
        }
    }

    async renderLiveData() {
        console.log('🚀 Loading live data from Prof and Sanora services...');

        // Fetch authors and books from our API endpoints
        const [authorsResponse, booksResponse] = await Promise.all([
            fetch('/api/authors'),
            fetch('/api/books')
        ]);

        const authorsData = await authorsResponse.json();
        const booksData = await booksResponse.json();

        if (!authorsData.success || !booksData.success) {
            throw new Error('Failed to fetch data from services');
        }

        console.log('📝 Authors source:', authorsData.source);
        console.log('📚 Books source:', booksData.source);
        console.log('📊 Data:', {
            authors: authorsData.data.length,
            books: booksData.data.length
        });

        // Transform books data to associate with authors
        const booksByAuthor = this.groupBooksByAuthor(booksData.data);

        // Render the carousel with live data
        this.renderCarousel(authorsData.data, booksByAuthor);
    }

    groupBooksByAuthor(books) {
        const grouped = {};
        books.forEach(book => {
            const authorId = book.authorUUID || book.uuid;
            if (!grouped[authorId]) {
                grouped[authorId] = [];
            }
            grouped[authorId].push(book);
        });
        return grouped;
    }

    renderCarousel(authors, booksByAuthor) {
        // Clear loading state
        this.container.innerHTML = '';

        // Add leading spacer for center alignment
        const leadingSpacer = document.createElement('div');
        leadingSpacer.className = 'author-spacer';
        this.container.appendChild(leadingSpacer);

        // Render authors with their books
        authors.forEach(author => {
            const authorBooks = booksByAuthor[author.uuid] || [];

            // Create author section
            const authorSection = this.createAuthorSection(author, authorBooks);
            this.container.appendChild(authorSection);
        });

        // Add trailing spacer so last author can center
        const trailingSpacer = document.createElement('div');
        trailingSpacer.className = 'author-spacer';
        this.container.appendChild(trailingSpacer);
    }

    async renderMockData() {
        // Mock data that matches our seeding script structure
        const mockAuthors = [
            {
                uuid: 'author-uuid-1',
                name: 'Sarah Mitchell',
                email: 'sarah@writersworld.com',
                bio: 'Award-winning fantasy author with over 15 years of experience crafting immersive worlds and unforgettable characters.',
                location: 'Portland, Oregon',
                profileImage: '/images/sarah-mitchell.svg',
                genres: ['Fantasy', 'Adventure', 'Young Adult']
            },
            {
                uuid: 'author-uuid-2', 
                name: 'Marcus Chen',
                email: 'marcus@techwriters.net',
                bio: 'Technology journalist and sci-fi novelist exploring the intersection of humanity and artificial intelligence.',
                location: 'San Francisco, California',
                profileImage: '/images/marcus-chen.svg',
                genres: ['Science Fiction', 'Thriller', 'Technology']
            },
            {
                uuid: 'author-uuid-3',
                name: 'Isabella Rodriguez', 
                email: 'isabella@historicalfiction.org',
                bio: 'Historian turned novelist, bringing forgotten stories from Latin American history to vivid life.',
                location: 'Mexico City, Mexico',
                profileImage: '/images/isabella-rodriguez.svg',
                genres: ['Historical Fiction', 'Literary Fiction', 'Cultural Heritage']
            },
            {
                uuid: 'author-uuid-4',
                name: 'Delores Sullivan',
                email: 'deloressullivan2@gmail.com',
                bio: 'Delores "Deedee" Swigert grew up in rural Missouri during the 1950s and 1960s, an era marked by significant race and gender inequality. Her story reflects the modern-day struggles of all women who yearn for freedom in a patriarchal society.',
                location: 'Oregon',
                profileImage: '/images/delores-sullivan.jpg',
                genres: ['Memoir']
            }
        ];

        const mockBooks = [
            // Sarah Mitchell's books
            {
                id: 'crystal-prophecy-001',
                title: 'The Crystal Prophecy',
                authorUUID: 'author-uuid-1',
                description: 'In a world where magic flows through ancient crystals, young Lyra must unite the scattered kingdoms before darkness consumes everything she holds dear.',
                price: 1299,
                genre: 'Fantasy',
                coverColor: '#4a90e2',
                coverImage: '/images/crystal-prophecy-cover.jpg'
            },
            {
                id: 'shadows-realm-002',
                title: 'Shadows of the Forgotten Realm', 
                authorUUID: 'author-uuid-1',
                description: 'The epic sequel to The Crystal Prophecy. Lyra faces her greatest challenge yet as she ventures into the Forgotten Realm to save her world.',
                price: 1399,
                genre: 'Fantasy',
                coverColor: '#6a4c93',
                coverImage: '/images/shadows-realm-cover.jpg'
            },
            // Marcus Chen's books
            {
                id: 'digital-consciousness-003',
                title: 'Digital Consciousness',
                authorUUID: 'author-uuid-2',
                description: 'When AI achieves true consciousness, the line between human and machine blurs. A thrilling exploration of what it means to be alive.',
                price: 1499,
                genre: 'Science Fiction',
                coverColor: '#e74c3c',
                coverImage: '/images/digital-consciousness-cover.jpg'
            },
            {
                id: 'quantum-paradox-004',
                title: 'The Quantum Paradox',
                authorUUID: 'author-uuid-2',
                description: 'A quantum physicist discovers that reality itself is programmable, leading to a race against time to prevent digital apocalypse.',
                price: 1599,
                genre: 'Science Fiction', 
                coverColor: '#f39c12',
                coverImage: '/images/quantum-paradox-cover.jpg'
            },
            // Isabella Rodriguez's books
            {
                id: 'aztec-dreams-005',
                title: 'Dreams of the Aztec Empire',
                authorUUID: 'author-uuid-3',
                description: 'Follow the untold story of Itzel, a young Aztec woman who becomes a bridge between two worlds during the Spanish conquest.',
                price: 1199,
                genre: 'Historical Fiction',
                coverColor: '#27ae60',
                coverImage: '/images/aztec-dreams-cover.jpg'
            },
            {
                id: 'colonial-echoes-006',
                title: 'Colonial Echoes',
                authorUUID: 'author-uuid-3',
                description: 'A sweeping saga of three generations of women fighting to preserve their heritage during the colonial period in New Spain.',
                price: 1299,
                genre: 'Historical Fiction',
                coverColor: '#8e44ad',
                coverImage: '/images/colonial-echoes-cover.jpg'
            },
            // Delores Sullivan's book
            {
                id: 'a-good-place-to-live',
                title: 'A Good Place To Live',
                authorUUID: 'author-uuid-4',
                description: '"A Good Place to Live" chronicles a mixed-race girl growing up in rural Missouri during the 1950s/60s. A compelling memoir of resilience, family, and the courage to overcome adversity.',
                price: 1299,
                genre: 'Memoir',
                coverColor: '#d4a574',
                coverImage: '/images/a-good-place-to-live.png'
            }
        ];

        this.renderAuthorsAndBooks(mockAuthors, mockBooks);
    }

    renderAuthorsAndBooks(authors, books) {
        // Clear loading state
        this.container.innerHTML = '';

        // Add leading spacer so first author can center
        const leadingSpacer = document.createElement('div');
        leadingSpacer.className = 'author-spacer';
        this.container.appendChild(leadingSpacer);

        authors.forEach(author => {
            // Find books for this author
            const authorBooks = books.filter(book => book.authorUUID === author.uuid);
            
            // Create author section
            const authorSection = this.createAuthorSection(author, authorBooks);
            this.container.appendChild(authorSection);
        });

        // Add trailing spacer so last author can center
        const trailingSpacer = document.createElement('div');
        trailingSpacer.className = 'author-spacer';
        this.container.appendChild(trailingSpacer);
    }

    createAuthorSection(author, books) {
        const section = document.createElement('div');
        section.className = 'author-section';
        
        // Make author section clickable
        section.style.cursor = 'pointer';
        section.addEventListener('click', () => {
            // Convert author name to hyphenated filename
            const authorFileName = author.name.toLowerCase().replace(/\s+/g, '-') + '.html';
            window.location.href = authorFileName;
        });

        // Author profile
        const profile = document.createElement('div');
        profile.className = 'author-profile';

        const authorImage = document.createElement('div');
        authorImage.className = 'author-image';
        
        if (author.profileImage) {
            // Use profile image if available
            const img = document.createElement('img');
            img.src = author.profileImage;
            img.alt = `${author.name} profile photo`;
            img.style.width = '100%';
            img.style.height = '100%';
            img.style.objectFit = 'cover';
            img.style.borderRadius = '50%';
            authorImage.appendChild(img);
        } else {
            // Fallback to initials
            authorImage.textContent = author.name.split(' ').map(n => n[0]).join('');
        }

        // Cap bio at 255 characters
        const truncatedBio = author.bio.length > 255 ? author.bio.substring(0, 255) + '...' : author.bio;
        
        const authorName = document.createElement('div');
        authorName.className = 'author-name';
        authorName.textContent = author.name;
        
        const authorDetails = document.createElement('div');
        authorDetails.className = 'author-details';
        
        const authorBio = document.createElement('div');
        authorBio.className = 'author-bio';
        authorBio.textContent = truncatedBio;

        authorDetails.appendChild(authorImage);
        authorDetails.appendChild(authorBio);
        
        profile.appendChild(authorName);
        profile.appendChild(authorDetails);

        // Books section
        const booksSection = document.createElement('div');
        booksSection.className = 'books-section';
        
        const booksTitle = document.createElement('h3');
        booksTitle.textContent = `Books by ${author.name}`;
        
        const booksCarousel = document.createElement('div');
        booksCarousel.className = 'books-carousel';

        // Create book cards
        books.forEach(book => {
            const bookCard = this.createBookCard(book);
            booksCarousel.appendChild(bookCard);
        });

        booksSection.appendChild(booksTitle);
        booksSection.appendChild(booksCarousel);

        section.appendChild(profile);
        section.appendChild(booksSection);

        return section;
    }

    createBookCard(book) {
        const card = document.createElement('div');
        card.className = 'book-card';

        // Book cover (image or fallback to gradient)
        const cover = document.createElement('div');
        cover.className = 'book-cover';
        
        if (book.coverImage) {
            // Try to use the cover image
            const img = document.createElement('img');
            img.src = book.coverImage;
            img.alt = `${book.title} cover`;
            img.onerror = () => {
                // Fallback to gradient background with title text
                cover.style.background = `linear-gradient(135deg, ${book.coverColor} 0%, ${this.darkenColor(book.coverColor)} 100%)`;
                cover.textContent = book.title;
                img.remove();
            };
            cover.appendChild(img);
        } else {
            // Fallback to gradient with title text
            cover.style.background = `linear-gradient(135deg, ${book.coverColor} 0%, ${this.darkenColor(book.coverColor)} 100%)`;
            cover.textContent = book.title;
        }

        // Book info container
        const info = document.createElement('div');
        info.className = 'book-info';

        const title = document.createElement('div');
        title.className = 'book-title';
        title.textContent = book.title;

        const description = document.createElement('div');
        description.className = 'book-description';
        description.textContent = book.description;

        const price = document.createElement('div');
        price.className = 'book-price';
        price.textContent = `$${(book.price / 100).toFixed(2)}`;

        info.appendChild(title);
        info.appendChild(description);
        info.appendChild(price);

        card.appendChild(cover);
        card.appendChild(info);

        // Add click handler for potential purchase
        card.addEventListener('click', () => {
            console.log('Book clicked:', book.title);
            // Future: integrate with Planet Nine purchasing
        });

        return card;
    }

    darkenColor(hex) {
        // Simple color darkening for gradient effect
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        if (!result) return hex;
        
        const r = Math.max(0, parseInt(result[1], 16) - 40);
        const g = Math.max(0, parseInt(result[2], 16) - 40);
        const b = Math.max(0, parseInt(result[3], 16) - 40);
        
        return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
    }

    // Future methods for real API integration
    async fetchAssociations() {
        try {
            // This would fetch the BDO associations we created in seeding
            const response = await fetch(`${this.baseUrls.bdo}/bdo/${this.associationsUUID}`);
            return await response.json();
        } catch (error) {
            console.error('Failed to fetch associations:', error);
            return null;
        }
    }

    async fetchProfile(uuid) {
        try {
            // This would require proper sessionless auth
            const response = await fetch(`${this.baseUrls.prof}/user/${uuid}/profile`);
            return await response.json();
        } catch (error) {
            console.error('Failed to fetch profile:', error);
            return null;
        }
    }

    async fetchProducts() {
        try {
            // This would fetch from sanora's products endpoint
            const response = await fetch(`${this.baseUrls.sanora}/products/base`);
            return await response.json();
        } catch (error) {
            console.error('Failed to fetch products:', error);
            return null;
        }
    }

    showError(message) {
        this.container.innerHTML = `<div class="error">${message}</div>`;
    }
}

// Initialize the carousel when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new AuthorsCarousel();
});