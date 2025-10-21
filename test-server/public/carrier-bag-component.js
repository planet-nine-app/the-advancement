/**
 * Carrier Bag Component for The Advancement
 *
 * Usage:
 * 1. Include carrier-bag-styles.css in your page
 * 2. Include this script: <script src="/carrier-bag-component.js"></script>
 * 3. Call CarrierBag.init() to inject the component
 * 4. Optionally call CarrierBag.loadFromFount(uuid) to load real data
 */

const CarrierBag = {
    // Collection definitions
    collections: [
        { name: 'cookbook', icon: '🍳', description: 'Recipes and culinary delights' },
        { name: 'apothecary', icon: '🧪', description: 'Potions and remedies' },
        { name: 'gallery', icon: '🖼️', description: 'Art and visual treasures' },
        { name: 'bookshelf', icon: '📚', description: 'Books and literature' },
        { name: 'familiarPen', icon: '🐾', description: 'Companions and creatures' },
        { name: 'machinery', icon: '⚙️', description: 'Tools and mechanisms' },
        { name: 'metallics', icon: '💎', description: 'Precious metals and gems' },
        { name: 'music', icon: '🎵', description: 'Songs and melodies' },
        { name: 'oracular', icon: '🔮', description: 'Divination and prophecy' },
        { name: 'greenHouse', icon: '🌿', description: 'Plants and botanicals' },
        { name: 'closet', icon: '👔', description: 'Garments and accessories' },
        { name: 'games', icon: '🎮', description: 'Entertainment and play' },
        { name: 'events', icon: '🎫', description: 'Gatherings and occasions' },
        { name: 'contracts', icon: '📜', description: 'Agreements and covenants' }
    ],

    // Current carrier bag data
    data: {},

    // Initialize the component
    init() {
        this.injectHTML();
        this.attachEventListeners();
        this.loadMockData();
        console.log('🎒 Carrier Bag component initialized');
    },

    // Inject the HTML structure into the page
    injectHTML() {
        const html = `
            <!-- Carrier Bag Toggle (semi-circle) -->
            <div class="carrier-bag-toggle" id="bag-toggle">
                <span>BAG</span>
            </div>

            <!-- Carrier Bag Full View -->
            <div class="carrier-bag-full" id="bag-full">
                <button class="bag-close" id="bag-close">✕</button>

                <div class="bag-header">
                    <div class="bag-title">🎒 Carrier Bag</div>
                    <div class="bag-subtitle">Your personal collection of discoveries</div>
                </div>

                <div class="collections-grid" id="collections-grid">
                    <!-- Collections will be loaded here -->
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', html);
    },

    // Attach event listeners
    attachEventListeners() {
        const toggle = document.getElementById('bag-toggle');
        const close = document.getElementById('bag-close');
        const full = document.getElementById('bag-full');

        if (toggle) {
            toggle.addEventListener('click', () => this.open());
        }

        if (close) {
            close.addEventListener('click', () => this.close());
        }

        // Close on escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && full && full.classList.contains('active')) {
                this.close();
            }
        });
    },

    // Open the carrier bag
    open() {
        const full = document.getElementById('bag-full');
        if (full) {
            full.classList.add('active');
            this.render();
        }
    },

    // Close the carrier bag
    close() {
        const full = document.getElementById('bag-full');
        if (full) {
            full.classList.remove('active');
        }
    },

    // Load mock data for testing
    loadMockData() {
        this.data = {
            cookbook: [
                { title: "Grandma's Chocolate Chip Cookies", emojicode: "🌍🔑💎🌟💎🎨🐉📌", bdoPubKey: "02abc..." }
            ],
            bookshelf: [
                { title: "The Digital Garden", emojicode: "🌍🔑💎🎯🔥✨💫🎪", bdoPubKey: "02def..." },
                { title: "If I Write Another Word", emojicode: "🌍🔑💎🌈🎨🔮🌙✨", bdoPubKey: "02ghi..." }
            ],
            events: [
                { title: "Coffee & Code Meetup", emojicode: "🌍🔑💎☕💻🎯🌟✨", bdoPubKey: "02jkl..." }
            ],
            contracts: [],
            apothecary: [],
            gallery: [],
            familiarPen: [],
            machinery: [],
            metallics: [],
            music: [],
            oracular: [],
            greenHouse: [],
            closet: [],
            games: []
        };
    },

    // Load carrier bag from Fount
    async loadFromFount(uuid) {
        try {
            console.log('🎒 Loading carrier bag from Fount for user:', uuid);

            // Get service URL helper
            const fountUrl = typeof getServiceUrl === 'function'
                ? getServiceUrl('fount')
                : 'http://localhost:3006';

            // Fetch carrier bag
            const response = await fetch(`${fountUrl}/user/${uuid}/carrierBag`);

            if (!response.ok) {
                throw new Error(`Failed to load carrier bag: ${response.status}`);
            }

            const carrierBag = await response.json();

            // Process carrier bag data
            this.data = {};
            this.collections.forEach(collection => {
                this.data[collection.name] = carrierBag[collection.name] || [];
            });

            console.log('✅ Carrier bag loaded successfully');
            this.render();

        } catch (error) {
            console.error('❌ Failed to load carrier bag:', error);
            // Fall back to mock data
            this.loadMockData();
        }
    },

    // Render the collections
    render() {
        const grid = document.getElementById('collections-grid');
        if (!grid) return;

        grid.innerHTML = '';

        this.collections.forEach(collection => {
            const items = this.data[collection.name] || [];
            const card = document.createElement('div');
            card.className = 'collection-card';

            let itemsHTML = '';
            if (items.length > 0) {
                itemsHTML = `
                    <div class="collection-items">
                        ${items.map(item => `
                            <div class="collection-item" data-emojicode="${item.emojicode}" data-pubkey="${item.bdoPubKey || ''}">
                                <div class="item-title">${item.title}</div>
                                <div class="item-emojicode">${item.emojicode}</div>
                            </div>
                        `).join('')}
                    </div>
                `;
            }

            card.innerHTML = `
                <div class="collection-icon">${collection.icon}</div>
                <div class="collection-name">${collection.name}</div>
                <div class="collection-count">${items.length} ${items.length === 1 ? 'item' : 'items'}</div>
                ${itemsHTML}
            `;

            // Attach click handlers to items
            card.querySelectorAll('.collection-item').forEach(itemEl => {
                itemEl.addEventListener('click', () => {
                    const emojicode = itemEl.dataset.emojicode;
                    const pubkey = itemEl.dataset.pubkey;
                    this.openItem(emojicode, pubkey);
                });
            });

            grid.appendChild(card);
        });
    },

    // Open an item from the carrier bag
    openItem(emojicode, bdoPubKey) {
        console.log('📖 Opening item:', { emojicode, bdoPubKey });

        // Dispatch custom event that other parts of the app can listen to
        const event = new CustomEvent('carrierBagItemOpened', {
            detail: { emojicode, bdoPubKey }
        });
        document.dispatchEvent(event);

        // If there's a magistack display on the page, use it
        if (typeof loadBDOIntoMagistack === 'function' && bdoPubKey) {
            this.close();
            loadBDOIntoMagistack(bdoPubKey);
        } else {
            // Fallback: show info
            alert(`Opening item: ${emojicode}\n\nBDO PubKey: ${bdoPubKey || 'N/A'}\n\n(Implement BDO display here)`);
        }
    },

    // Add item to carrier bag (for use when saving items)
    addItem(collectionName, item) {
        if (!this.data[collectionName]) {
            this.data[collectionName] = [];
        }

        // Check if item already exists
        const exists = this.data[collectionName].some(
            existing => existing.emojicode === item.emojicode
        );

        if (!exists) {
            this.data[collectionName].push(item);
            console.log(`✅ Added to ${collectionName}:`, item.title);

            // Show toast notification if available
            if (typeof showToast === 'function') {
                showToast('success', `Added to ${collectionName}!`);
            }
        } else {
            console.log(`ℹ️ Item already in ${collectionName}:`, item.title);
        }
    },

    // Get count of items in a collection
    getCollectionCount(collectionName) {
        return (this.data[collectionName] || []).length;
    },

    // Get total item count
    getTotalCount() {
        return Object.values(this.data).reduce((total, items) => total + items.length, 0);
    }
};

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => CarrierBag.init());
} else {
    CarrierBag.init();
}

// Export for use in other scripts
window.CarrierBag = CarrierBag;
