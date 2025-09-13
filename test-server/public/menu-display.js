/**
 * Menu Display Components for The Advancement Test Server
 * 
 * Creates visual menu catalog cards and detailed menu displays
 */

const MenuDisplay = {
    /**
     * Create a menu catalog card
     * @param {Object} menuCatalog - Menu catalog data
     * @param {Object} config - Configuration options
     * @returns {HTMLElement} Menu catalog card element
     */
    createMenuCatalogCard(menuCatalog, config = {}) {
        const {
            onClick = null,
            showItemCount = true
        } = config;

        const card = document.createElement('div');
        card.className = 'menu-catalog-card product-card';
        card.dataset.menuId = menuCatalog.id;

        const itemCount = menuCatalog.metadata?.totalProducts || menuCatalog.products?.length || 0;
        const menuCount = menuCatalog.metadata?.menuCount || Object.keys(menuCatalog.menus || {}).length;

        card.innerHTML = `
            <div class="product-header">
                <div class="product-image menu-icon">
                    🍽️
                </div>
                <div class="product-info">
                    <h4 class="product-title">${this.escapeHtml(menuCatalog.title)}</h4>
                    <p class="product-creator">Restaurant Menu</p>
                    <div class="menu-stats">
                        ${itemCount} items • ${menuCount} categories
                    </div>
                </div>
            </div>
            <p class="product-description">${this.escapeHtml(menuCatalog.description || 'Complete restaurant menu')}</p>
            <div class="menu-catalog-badge">
                <span class="badge">MENU CATALOG</span>
            </div>
        `;

        // Add click handler
        if (onClick) {
            card.style.cursor = 'pointer';
            card.addEventListener('click', () => onClick(menuCatalog));
        }

        return card;
    },

    /**
     * Create a detailed menu structure display
     * @param {Object} menuCatalog - Menu catalog data
     * @param {Object} config - Configuration options
     * @returns {HTMLElement} Menu structure display element
     */
    createMenuStructureDisplay(menuCatalog, config = {}) {
        const {
            showPrices = true,
            onItemClick = null
        } = config;

        const container = document.createElement('div');
        container.className = 'menu-structure-display';

        let content = `
            <div class="menu-header">
                <h3>${this.escapeHtml(menuCatalog.title)}</h3>
                <p class="menu-description">${this.escapeHtml(menuCatalog.description || '')}</p>
            </div>
        `;

        // Render each menu section
        if (menuCatalog.menus) {
            Object.entries(menuCatalog.menus).forEach(([menuKey, menu]) => {
                content += `
                    <div class="menu-section">
                        <h4 class="menu-section-title">${this.escapeHtml(menu.title)}</h4>
                `;

                // Direct products in this menu
                if (menu.products && menu.products.length > 0) {
                    menu.products.forEach(productId => {
                        const product = menuCatalog.products?.find(p => p.id === productId);
                        if (product) {
                            content += this.createMenuItemHTML(product, showPrices, onItemClick);
                        }
                    });
                }

                // Submenus
                if (menu.submenus) {
                    Object.entries(menu.submenus).forEach(([submenuKey, submenu]) => {
                        content += `
                            <div class="menu-subsection">
                                <h5 class="menu-subsection-title">${this.escapeHtml(submenu.title)}</h5>
                        `;

                        if (submenu.products && submenu.products.length > 0) {
                            submenu.products.forEach(productId => {
                                const product = menuCatalog.products?.find(p => p.id === productId);
                                if (product) {
                                    content += this.createMenuItemHTML(product, showPrices, onItemClick);
                                }
                            });
                        }

                        content += '</div>';
                    });
                }

                content += '</div>';
            });
        }

        container.innerHTML = content;

        // Add click handlers for menu items
        if (onItemClick) {
            container.querySelectorAll('.menu-item').forEach(item => {
                const productId = item.dataset.productId;
                const product = menuCatalog.products?.find(p => p.id === productId);
                if (product) {
                    item.style.cursor = 'pointer';
                    item.addEventListener('click', () => onItemClick(product));
                }
            });
        }

        return container;
    },

    /**
     * Create HTML for a single menu item
     * @param {Object} product - Product data
     * @param {boolean} showPrice - Whether to show price
     * @param {Function} onItemClick - Click handler
     * @returns {string} HTML string for menu item
     */
    createMenuItemHTML(product, showPrice, onItemClick) {
        const price = showPrice && product.price ? `$${(product.price / 100).toFixed(2)}` : '';
        const clickable = onItemClick ? 'clickable' : '';

        return `
            <div class="menu-item ${clickable}" data-product-id="${product.id}">
                <div class="menu-item-info">
                    <span class="menu-item-name">${this.escapeHtml(product.name || product.title)}</span>
                    <span class="menu-item-description">${this.escapeHtml(product.description || '')}</span>
                </div>
                ${price ? `<span class="menu-item-price">${price}</span>` : ''}
            </div>
        `;
    },

    /**
     * Create a menu preview for the teleported feed
     * @param {Object} menuCatalog - Menu catalog data
     * @returns {HTMLElement} Menu preview element
     */
    createMenuPreview(menuCatalog) {
        const preview = document.createElement('div');
        preview.className = 'menu-preview';

        const itemCount = Math.min(3, menuCatalog.products?.length || 0);
        const sampleItems = (menuCatalog.products || []).slice(0, itemCount);

        let itemsHTML = '';
        sampleItems.forEach(item => {
            const price = item.price ? `$${(item.price / 100).toFixed(2)}` : '';
            itemsHTML += `
                <div class="preview-item">
                    <span class="preview-name">${this.escapeHtml(item.name || item.title)}</span>
                    ${price ? `<span class="preview-price">${price}</span>` : ''}
                </div>
            `;
        });

        const remainingCount = (menuCatalog.products?.length || 0) - itemCount;

        preview.innerHTML = `
            <div class="menu-preview-header">
                <span class="menu-icon">🍽️</span>
                <span class="menu-title">${this.escapeHtml(menuCatalog.title)}</span>
            </div>
            <div class="menu-preview-items">
                ${itemsHTML}
                ${remainingCount > 0 ? `<div class="preview-more">+${remainingCount} more items...</div>` : ''}
            </div>
        `;

        return preview;
    },

    /**
     * Escape HTML to prevent XSS
     * @param {string} text - Text to escape
     * @returns {string} Escaped text
     */
    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
};

// Export for global use
if (typeof window !== 'undefined') {
    window.MenuDisplay = MenuDisplay;
}

console.log('🍽️ Menu display components loaded for The Advancement test server');