// Authors and Books Carousel Implementation using Post Widget
// Integrates with Planet Nine services: Prof (profiles), Sanora (products), BDO (associations)

class AuthorsPostWidgetCarousel {
    constructor() {
        this.baseUrls = {
            prof: 'http://localhost:5123',
            sanora: 'http://localhost:5121', 
            bdo: 'http://localhost:5114'
        };
        this.container = null;
        this.postWidget = null;
        this.associationsUUID = null;
        // Don't initialize immediately, wait for DOM
    }

    ensureContainer() {
        if (!this.container) {
            this.container = document.getElementById('authorsContainer');
            if (!this.container) {
                console.error('DOM state:', document.readyState);
                console.error('Body children:', document.body ? document.body.children.length : 'no body');
                throw new Error('Container element "authorsContainer" not found in DOM');
            }
            console.log('Container element found:', this.container.id);
        }
        return this.container;
    }

    async init() {
        try {
            console.log('AuthorsPostWidgetCarousel: Starting initialization...');
            
            // Ensure container exists
            this.ensureContainer();
            console.log('AuthorsPostWidgetCarousel: Container found successfully');
            
            // Check if PostWidget is available (but don't initialize yet)
            if (window.PostWidget) {
                console.log('PostWidget class is available');
                this.hasPostWidget = true;
            } else {
                console.log('PostWidget not available - loading fallback');
                this.hasPostWidget = false;
                // Fallback to mock data if PostWidget not available
                await this.renderMockData();
                return;
            }

            // For now, let's use mock data until we get the seeding working
            console.log('Rendering mock data with PostWidget...');
            await this.renderMockDataWithPostWidget();
            console.log('AuthorsPostWidgetCarousel: Initialization complete');
        } catch (error) {
            console.error('AuthorsPostWidgetCarousel error:', error);
            this.showError('Failed to load authors and books: ' + error.message);
        }
    }

    async renderMockDataWithPostWidget() {
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

        this.renderAuthorsAndBooksWithPostWidget(mockAuthors, mockBooks);
    }

    renderAuthorsAndBooksWithPostWidget(authors, books) {
        // Ensure container exists and clear loading state
        const container = this.ensureContainer();
        container.innerHTML = '';

        authors.forEach(author => {
            // Find books for this author
            const authorBooks = books.filter(book => book.authorUUID === author.uuid);
            
            // Create author section using PostWidget
            const authorSection = this.createAuthorSectionWithPostWidget(author, authorBooks);
            container.appendChild(authorSection);
        });
    }

    createAuthorSectionWithPostWidget(author, books) {
        const section = document.createElement('div');
        section.className = 'author-section';

        // Create author profile post using PostWidget
        const authorPost = this.createAuthorPost(author);
        section.appendChild(authorPost);

        // Create books section
        const booksSection = document.createElement('div');
        booksSection.className = 'books-section';
        
        const booksTitle = document.createElement('h3');
        booksTitle.textContent = `Books by ${author.name}`;
        
        const booksCarousel = document.createElement('div');
        booksCarousel.className = 'books-carousel';

        // Create book posts using PostWidget
        books.forEach(book => {
            const bookContainer = document.createElement('div');
            bookContainer.className = 'book-widget-container';
            
            const bookPost = this.createBookPost(book);
            bookContainer.appendChild(bookPost);
            booksCarousel.appendChild(bookContainer);
        });

        booksSection.appendChild(booksTitle);
        booksSection.appendChild(booksCarousel);
        section.appendChild(booksSection);

        return section;
    }

    createAuthorPost(author) {
        // Create a container for this post
        const postContainer = document.createElement('div');
        postContainer.className = 'author-post-container';

        // Use PostWidget if available
        if (this.hasPostWidget && window.PostWidget) {
            try {
                // Create a PostWidget instance for this specific post
                const postWidget = new window.PostWidget(postContainer, { debug: false });
                
                // Add author profile image if available
                if (author.profileImage) {
                    postWidget.addElement('image', author.profileImage, { alt: `${author.name} profile photo` });
                }
                
                // Customize the PostWidget with author data
                postWidget.addElement('name', author.name);
                postWidget.addElement('description', author.bio, { inTopSection: false });
                
                // Add author metadata 
                const metaElement = postWidget.createElement('div', 'author-meta');
                metaElement.innerHTML = `
                    <div class="author-location">📍 ${author.location}</div>
                    <div class="author-genres">🏷️ ${author.genres.join(', ')}</div>
                `;
                postWidget.elements.postContent.appendChild(metaElement);
                
                console.log('Created PostWidget for author:', author.name);
                return postContainer;
            } catch (error) {
                console.error('PostWidget creation failed for author:', error);
                // Fall back to manual creation
                return this.createAuthorPostFallback(author);
            }
        } else {
            // Fallback to manual creation if PostWidget not available
            return this.createAuthorPostFallback(author);
        }
    }

    createBookPost(book) {
        // Create a container for this post
        const postContainer = document.createElement('div');
        postContainer.className = 'book-post-container';

        // Use PostWidget if available
        if (this.hasPostWidget && window.PostWidget) {
            try {
                // Create a PostWidget instance for this specific post
                const postWidget = new window.PostWidget(postContainer, { debug: false });
                
                // Customize the PostWidget with book data
                postWidget.addElement('name', book.title);
                postWidget.addElement('description', book.description, { inTopSection: false });
                
                // Add book cover visual representation
                const coverElement = postWidget.createElement('div', 'book-cover');
                coverElement.style.background = `linear-gradient(135deg, ${book.coverColor} 0%, ${this.darkenColor(book.coverColor)} 100%)`;
                coverElement.style.height = '200px';
                coverElement.style.borderRadius = '10px';
                coverElement.style.marginBottom = '15px';
                coverElement.style.display = 'flex';
                coverElement.style.alignItems = 'center';
                coverElement.style.justifyContent = 'center';
                coverElement.style.color = 'white';
                coverElement.style.fontSize = '0.9rem';
                coverElement.style.textAlign = 'center';
                coverElement.style.padding = '10px';
                coverElement.textContent = book.title;
                postWidget.elements.postTopSection.appendChild(coverElement);
                
                // Add book metadata (price, genre)
                const metaElement = postWidget.createElement('div', 'book-meta');
                metaElement.innerHTML = `
                    <div class="book-price">💰 $${(book.price / 100).toFixed(2)}</div>
                    <div class="book-genre">📚 ${book.genre}</div>
                `;
                postWidget.elements.postContent.appendChild(metaElement);
                
                // Add click handler for potential purchase
                postContainer.addEventListener('click', () => {
                    console.log('Book clicked:', book.title);
                    // Future: integrate with Planet Nine purchasing
                });
                
                console.log('Created PostWidget for book:', book.title);
                return postContainer;
            } catch (error) {
                console.error('PostWidget creation failed for book:', error);
                // Fall back to manual creation
                return this.createBookPostFallback(book);
            }
        } else {
            // Fallback to manual creation if PostWidget not available
            return this.createBookPostFallback(book);
        }
    }

    createAuthorPostFallback(author) {
        // Fallback author post creation
        const post = document.createElement('div');
        post.className = 'post-card author-post';
        
        post.innerHTML = `
            <div class="author-profile">
                <div class="author-image">${author.name.split(' ').map(n => n[0]).join('')}</div>
                <div class="author-info">
                    <h2>${author.name}</h2>
                    <p>${author.bio}</p>
                    <div class="author-meta">
                        <span class="location">${author.location}</span>
                        <span class="genres">${author.genres.join(', ')}</span>
                    </div>
                </div>
            </div>
        `;

        return post;
    }

    createBookPostFallback(book) {
        // Fallback book post creation
        const post = document.createElement('div');
        post.className = 'post-card book-post';
        
        post.innerHTML = `
            <div class="book-cover" style="background: linear-gradient(135deg, ${book.coverColor} 0%, ${this.darkenColor(book.coverColor)} 100%)">
                ${book.title}
            </div>
            <div class="book-content">
                <h3 class="book-title">${book.title}</h3>
                <p class="post-description">${book.description}</p>
                <div class="book-price">${book.price ? `$${(book.price / 100).toFixed(2)}` : 'Free'}</div>
            </div>
        `;

        // Add click handler for potential purchase
        post.addEventListener('click', () => {
            console.log('Book clicked:', book.title);
            // Future: integrate with Planet Nine purchasing
        });

        return post;
    }

    // Fallback method for when PostWidget isn't available
    async renderMockData() {
        console.log('Using fallback mock data rendering');
        // This would use the original implementation from authors.js
        // For now, just show a message
        const container = this.ensureContainer();
        container.innerHTML = `
            <div class="error">
                <h2>PostWidget Integration</h2>
                <p>PostWidget is not available. Please ensure post-widget.js is loaded from dolores.</p>
                <p>This page demonstrates integration with the Planet Nine post widget system.</p>
            </div>
        `;
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
        try {
            const container = this.ensureContainer();
            container.innerHTML = `<div class="error">${message}</div>`;
        } catch (containerError) {
            console.error('Failed to show error message:', message);
            console.error('Container error:', containerError.message);
        }
    }
}

// Initialize the carousel when the page loads
document.addEventListener('DOMContentLoaded', () => {
    // Wait a bit for post-widget.js to load
    setTimeout(() => {
        const carousel = new AuthorsPostWidgetCarousel();
        carousel.init();
    }, 100);
});