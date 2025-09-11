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
            // For now, let's use mock data until we get the seeding working
            await this.renderMockData();
        } catch (error) {
            this.showError('Failed to load authors and books: ' + error.message);
        }
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
                genres: ['Fantasy', 'Adventure', 'Young Adult']
            },
            {
                uuid: 'author-uuid-2', 
                name: 'Marcus Chen',
                email: 'marcus@techwriters.net',
                bio: 'Technology journalist and sci-fi novelist exploring the intersection of humanity and artificial intelligence.',
                location: 'San Francisco, California',
                genres: ['Science Fiction', 'Thriller', 'Technology']
            },
            {
                uuid: 'author-uuid-3',
                name: 'Isabella Rodriguez', 
                email: 'isabella@historicalfiction.org',
                bio: 'Historian turned novelist, bringing forgotten stories from Latin American history to vivid life.',
                location: 'Mexico City, Mexico',
                genres: ['Historical Fiction', 'Literary Fiction', 'Cultural Heritage']
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
                coverColor: '#4a90e2'
            },
            {
                id: 'shadows-realm-002',
                title: 'Shadows of the Forgotten Realm', 
                authorUUID: 'author-uuid-1',
                description: 'The epic sequel to The Crystal Prophecy. Lyra faces her greatest challenge yet as she ventures into the Forgotten Realm to save her world.',
                price: 1399,
                genre: 'Fantasy',
                coverColor: '#6a4c93'
            },
            // Marcus Chen's books
            {
                id: 'digital-consciousness-003',
                title: 'Digital Consciousness',
                authorUUID: 'author-uuid-2',
                description: 'When AI achieves true consciousness, the line between human and machine blurs. A thrilling exploration of what it means to be alive.',
                price: 1499,
                genre: 'Science Fiction',
                coverColor: '#e74c3c'
            },
            {
                id: 'quantum-paradox-004',
                title: 'The Quantum Paradox',
                authorUUID: 'author-uuid-2',
                description: 'A quantum physicist discovers that reality itself is programmable, leading to a race against time to prevent digital apocalypse.',
                price: 1599,
                genre: 'Science Fiction', 
                coverColor: '#f39c12'
            },
            // Isabella Rodriguez's books
            {
                id: 'aztec-dreams-005',
                title: 'Dreams of the Aztec Empire',
                authorUUID: 'author-uuid-3',
                description: 'Follow the untold story of Itzel, a young Aztec woman who becomes a bridge between two worlds during the Spanish conquest.',
                price: 1199,
                genre: 'Historical Fiction',
                coverColor: '#27ae60'
            },
            {
                id: 'colonial-echoes-006',
                title: 'Colonial Echoes',
                authorUUID: 'author-uuid-3',
                description: 'A sweeping saga of three generations of women fighting to preserve their heritage during the colonial period in New Spain.',
                price: 1299,
                genre: 'Historical Fiction',
                coverColor: '#8e44ad'
            }
        ];

        this.renderAuthorsAndBooks(mockAuthors, mockBooks);
    }

    renderAuthorsAndBooks(authors, books) {
        // Clear loading state
        this.container.innerHTML = '';

        authors.forEach(author => {
            // Find books for this author
            const authorBooks = books.filter(book => book.authorUUID === author.uuid);
            
            // Create author section
            const authorSection = this.createAuthorSection(author, authorBooks);
            this.container.appendChild(authorSection);
        });
    }

    createAuthorSection(author, books) {
        const section = document.createElement('div');
        section.className = 'author-section';

        // Author profile
        const profile = document.createElement('div');
        profile.className = 'author-profile';

        const authorImage = document.createElement('div');
        authorImage.className = 'author-image';
        authorImage.textContent = author.name.split(' ').map(n => n[0]).join('');

        const authorInfo = document.createElement('div');
        authorInfo.className = 'author-info';
        authorInfo.innerHTML = `
            <h2>${author.name}</h2>
            <p>${author.bio}</p>
        `;

        profile.appendChild(authorImage);
        profile.appendChild(authorInfo);

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

        const cover = document.createElement('div');
        cover.className = 'book-cover';
        cover.style.background = `linear-gradient(135deg, ${book.coverColor} 0%, ${this.darkenColor(book.coverColor)} 100%)`;
        cover.textContent = book.title;

        const title = document.createElement('div');
        title.className = 'book-title';
        title.textContent = book.title;

        const description = document.createElement('div');
        description.className = 'book-description';
        description.textContent = book.description;

        const price = document.createElement('div');
        price.className = 'book-price';
        price.textContent = `$${(book.price / 100).toFixed(2)}`;

        card.appendChild(cover);
        card.appendChild(title);
        card.appendChild(description);
        card.appendChild(price);

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