/**
 * Shared Menu Utilities for The Advancement Test Server
 * 
 * Basic menu detection and reconstruction utilities
 * (Simplified version of the Nullary shared menu utilities)
 */

const MenuUtils = {
    /**
     * Detect menu products from a list of products
     * @param {Array} products - Array of products
     * @returns {Object} Detection results
     */
    detectMenuProducts(products) {
        if (!products || !Array.isArray(products)) {
            return { hasMenus: false, menuProducts: [], regularProducts: products || [], menuCatalogs: new Map() };
        }

        const menuProducts = [];
        const regularProducts = [];
        const menuCatalogs = new Map();

        products.forEach(product => {
            const catalogId = product.metadata?.menuCatalogId;
            
            if (catalogId) {
                menuProducts.push(product);
                
                if (!menuCatalogs.has(catalogId)) {
                    menuCatalogs.set(catalogId, {
                        structure: null,
                        catalog: null,
                        items: []
                    });
                }
                
                const catalogData = menuCatalogs.get(catalogId);
                
                if (product.metadata?.isMenuStructure) {
                    catalogData.structure = product.metadata.menuData;
                    catalogData.catalog = product;
                } else if (product.type === 'menu_item') {
                    catalogData.items.push(product);
                }
            } else {
                regularProducts.push(product);
            }
        });

        return {
            hasMenus: menuProducts.length > 0,
            menuProducts,
            regularProducts,
            menuCatalogs
        };
    },

    /**
     * Reconstruct a menu from items and structure
     * @param {Array} menuItems - Array of menu item products
     * @param {Object} structure - Menu structure data
     * @returns {Object} Reconstructed menu catalog
     */
    reconstructMenu(menuItems, structure) {
        if (!structure || !menuItems) {
            return null;
        }

        const products = menuItems.map(item => ({
            id: item.id,
            name: item.title,
            description: item.description,
            price: item.price,
            currency: item.currency,
            category: item.metadata?.category
        }));

        return {
            title: structure.title,
            description: structure.description,
            menus: structure.menus || {},
            products: products,
            metadata: {
                totalProducts: products.length,
                menuCount: Object.keys(structure.menus || {}).length
            }
        };
    }
};

// Export for global use
if (typeof window !== 'undefined') {
    window.MenuUtils = MenuUtils;
}

console.log('🍽️ Menu utilities loaded for The Advancement test server');