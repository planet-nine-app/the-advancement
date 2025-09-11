// Post Widget JavaScript with Spacer functionality
// This extends the existing post-widget functionality

class PostWidget {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            debug: false,
            maxSpacers: 1,
            ...options
        };
        this.elements = {};
        this.spacerCount = 0;
        this.init();
    }

    init() {
        this.createPostStructure();
        this.bindEvents();
        this.validateLayout();
    }

    createPostStructure() {
        // Create main post card
        this.elements.postCard = this.createElement('div', 'post-card');
        this.elements.postContent = this.createElement('div', 'post-content');
        
        // Create top section for image and description horizontal scrolling
        this.elements.postTopSection = this.createElement('div', 'post-top-section');
        
        this.elements.postCard.appendChild(this.elements.postContent);
        this.elements.postContent.appendChild(this.elements.postTopSection);
        this.container.appendChild(this.elements.postCard);
    }

    // NEW: Add spacer functionality
    addSpacer(config = {}) {
        // Validate: Only allow one spacer per post
        if (this.spacerCount >= this.options.maxSpacers) {
            console.warn('PostWidget: Only one spacer allowed per post. Skipping additional spacer.');
            return null;
        }

        const spacerConfig = {
            minHeight: '0px',
            maxHeight: 'none',
            background: 'transparent',
            visibility: 'visible',
            debug: this.options.debug,
            ...config
        };

        const spacer = this.createElement('div', 'post-spacer');
        
        // Apply configuration
        spacer.style.setProperty('--spacer-min-height', spacerConfig.minHeight);
        spacer.style.setProperty('--spacer-max-height', spacerConfig.maxHeight);
        spacer.style.setProperty('--spacer-bg', spacerConfig.background);
        spacer.style.setProperty('--spacer-visibility', spacerConfig.visibility);

        // Add debug class if enabled
        if (spacerConfig.debug) {
            spacer.classList.add('debug');
        }

        // Track spacer count
        this.spacerCount++;
        spacer.dataset.spacerId = this.spacerCount;

        return spacer;
    }

    // NEW: Insert spacer at specific position
    insertSpacer(targetElement, position = 'after', config = {}) {
        const spacer = this.addSpacer(config);
        if (!spacer) return null;

        if (position === 'after') {
            targetElement.parentNode.insertBefore(spacer, targetElement.nextSibling);
        } else if (position === 'before') {
            targetElement.parentNode.insertBefore(spacer, targetElement);
        } else {
            console.warn('PostWidget: Invalid position. Use "before" or "after".');
            return null;
        }

        return spacer;
    }

    // NEW: Add spacer to push content to bottom
    addBottomSpacer(config = {}) {
        const spacer = this.addSpacer(config);
        if (!spacer) return null;

        // Find the last element that should be pushed to bottom
        const lastElement = this.elements.postContent.lastElementChild;
        if (lastElement) {
            this.elements.postContent.insertBefore(spacer, lastElement);
        } else {
            this.elements.postContent.appendChild(spacer);
        }

        return spacer;
    }

    // NEW: Remove spacer
    removeSpacer(spacer) {
        if (spacer && spacer.classList.contains('post-spacer')) {
            spacer.remove();
            this.spacerCount = Math.max(0, this.spacerCount - 1);
            return true;
        }
        return false;
    }

    // NEW: Get all spacers in the post
    getSpacers() {
        return this.elements.postContent.querySelectorAll('.post-spacer');
    }

    // NEW: Clear all spacers
    clearSpacers() {
        const spacers = this.getSpacers();
        spacers.forEach(spacer => spacer.remove());
        this.spacerCount = 0;
    }

    // Utility: Create element with class
    createElement(tag, className) {
        const element = document.createElement(tag);
        if (className) element.className = className;
        return element;
    }

    // Add content elements to post
    addElement(type, content, config = {}) {
        let element;

        switch (type) {
            case 'name':
                element = this.createElement('div', 'post-name');
                element.textContent = content;
                break;

            case 'image':
                // Handle image in top section
                const layout = config.layout || 'mixed'; // 'mixed', 'image-only', 'full'
                
                if (layout === 'image-only') {
                    this.elements.postTopSection.classList.add('image-only');
                    element = this.createElement('div', 'post-image-full');
                } else {
                    element = this.createElement('div', 'post-image');
                }
                
                if (content) {
                    const img = document.createElement('img');
                    img.src = content;
                    img.alt = config.alt || 'Event Image';
                    img.onerror = () => {
                        element.innerHTML = '<div class="image-error">Failed to load image</div>';
                    };
                    img.onload = () => {
                        element.innerHTML = '';
                        element.appendChild(img);
                    };
                    element.innerHTML = '<div class="image-loading">Loading...</div>';
                    element.appendChild(img);
                } else {
                    element.innerHTML = '<div class="placeholder">No image</div>';
                }
                
                // Add to top section
                this.elements.postTopSection.appendChild(element);
                return element;

            case 'description':
                // Check if this should go in top section or as standalone
                const inTopSection = config.inTopSection !== false; // default true
                
                if (inTopSection && this.elements.postTopSection) {
                    // Create description container for top section
                    element = this.createElement('div', 'post-description-container');
                    const description = this.createElement('div', 'post-description');
                    description.textContent = content;
                    element.appendChild(description);
                    
                    // Add to top section
                    this.elements.postTopSection.appendChild(element);
                } else {
                    // Standalone description
                    element = this.createElement('div', 'post-description');
                    element.textContent = content;
                }
                break;

            case 'datetime':
                element = this.createElement('div', 'post-datetime-container');
                const datetimeScroll = this.createElement('div', 'post-datetime-scroll');
                
                // Handle single datetime or array of datetimes
                const datetimes = Array.isArray(content) ? content : [content];
                
                datetimes.forEach(dt => {
                    const datetime = this.createElement('div', 'post-datetime');
                    
                    // Parse datetime object or create from string
                    let dayDate, timeRange;
                    
                    if (typeof dt === 'object' && dt.day && dt.date && dt.time) {
                        dayDate = `${dt.day}, ${dt.date}`;
                        timeRange = dt.time;
                    } else if (typeof dt === 'string') {
                        // For backward compatibility, try to parse string
                        dayDate = dt;
                        timeRange = config.time || '';
                    } else {
                        dayDate = dt.toString();
                        timeRange = '';
                    }
                    
                    datetime.innerHTML = `
                        <div class="post-datetime-day-date">${dayDate}</div>
                        ${timeRange ? `<div class="post-datetime-time">${timeRange}</div>` : ''}
                    `;
                    
                    datetimeScroll.appendChild(datetime);
                });
                
                element.appendChild(datetimeScroll);
                break;

            case 'address':
                element = this.createElement('div', 'post-address-container');
                const addressText = this.createElement('div', 'post-address-text');
                const address = this.createElement('div', 'post-address');
                
                // Handle address object or string
                let line1, line2;
                
                if (typeof content === 'object' && (content.address1 || content.address2 || content.city)) {
                    // Build address lines from object
                    const addr1Parts = [content.address1, content.address2].filter(Boolean);
                    line1 = addr1Parts.join(', ');
                    
                    const addr2Parts = [content.city, content.state, content.zip].filter(Boolean);
                    line2 = addr2Parts.join(', ');
                } else if (typeof content === 'string') {
                    // Try to split string address into two lines
                    const parts = content.split(',').map(p => p.trim());
                    if (parts.length >= 3) {
                        // Assume first part(s) are address, last 2-3 are city, state, zip
                        const cityStateZipCount = parts.length >= 4 ? 3 : 2;
                        line1 = parts.slice(0, -cityStateZipCount).join(', ');
                        line2 = parts.slice(-cityStateZipCount).join(', ');
                    } else {
                        line1 = content;
                        line2 = '';
                    }
                } else {
                    line1 = content.toString();
                    line2 = '';
                }
                
                address.innerHTML = `
                    ${line1 ? `<div class="post-address-line1">${line1}</div>` : ''}
                    ${line2 ? `<div class="post-address-line2">${line2}</div>` : ''}
                `;
                
                addressText.appendChild(address);
                element.appendChild(addressText);
                break;

            case 'button':
                element = this.createElement('div', 'post-buttons-container');
                const button = this.createElement('button', `post-button post-button-single`);
                button.textContent = content;
                element.appendChild(button);
                break;

            case 'spacer':
                element = this.addSpacer(config);
                break;

            default:
                console.warn(`PostWidget: Unknown element type "${type}"`);
                return null;
        }

        if (element && type !== 'image' && (type !== 'description' || config.inTopSection === false)) {
            this.elements.postContent.appendChild(element);
        }

        return element;
    }

    // Validate layout and provide warnings
    validateLayout() {
        const spacers = this.getSpacers();
        
        if (spacers.length > 1) {
            console.warn('PostWidget: Multiple spacers detected. Only one spacer should be used per post for optimal layout.');
        }

        // Check if spacer is being used effectively
        spacers.forEach((spacer, index) => {
            const nextElement = spacer.nextElementSibling;
            const prevElement = spacer.previousElementSibling;

            if (!nextElement) {
                console.warn(`PostWidget: Spacer ${index + 1} is at the end of the content. Consider moving it before the last element to anchor content to bottom.`);
            }

            if (!prevElement) {
                console.warn(`PostWidget: Spacer ${index + 1} is at the beginning of the content. This may not provide the expected spacing behavior.`);
            }
        });
    }

    // Bind events
    bindEvents() {
        // Add click handler for post card
        this.elements.postCard.addEventListener('click', (e) => {
            if (!e.target.closest('button, .post-share-button')) {
                this.handlePostClick(e);
            }
        });
    }

    handlePostClick(e) {
        // Override this method for custom post click behavior
        console.log('Post clicked', e);
    }

    // Enable/disable debug mode
    setDebugMode(enabled) {
        this.options.debug = enabled;
        const spacers = this.getSpacers();
        
        spacers.forEach(spacer => {
            if (enabled) {
                spacer.classList.add('debug');
            } else {
                spacer.classList.remove('debug');
            }
        });
    }

    // Get layout information
    getLayoutInfo() {
        return {
            totalHeight: this.elements.postCard.offsetHeight,
            contentHeight: this.elements.postContent.offsetHeight,
            spacerCount: this.spacerCount,
            spacers: Array.from(this.getSpacers()).map((spacer, index) => ({
                id: index + 1,
                height: spacer.offsetHeight,
                position: Array.from(this.elements.postContent.children).indexOf(spacer)
            }))
        };
    }
}

// Usage examples and utility functions
class PostWidgetBuilder {
    constructor(container, options = {}) {
        this.widget = new PostWidget(container, options);
        return this;
    }

    // Chainable methods for building posts
    name(text) {
        this.widget.addElement('name', text);
        return this;
    }

    // Add image to top section
    image(imageUrl, config = {}) {
        this.widget.addElement('image', imageUrl, config);
        return this;
    }

    // Description - can go in top section (default) or standalone
    description(text, config = {}) {
        this.widget.addElement('description', text, config);
        return this;
    }

    // Standalone description (not in top section)
    standaloneDescription(text) {
        return this.description(text, { inTopSection: false });
    }

    // Updated datetime method to handle new format
    datetime(datetimes) {
        this.widget.addElement('datetime', datetimes);
        return this;
    }

    // Convenience method for single datetime
    singleDatetime(day, date, time) {
        return this.datetime({ day, date, time });
    }

    // Convenience method for multiple datetimes
    multipleDatetimes(datetimeArray) {
        return this.datetime(datetimeArray);
    }

    // NEW: Add spacer with chainable interface
    spacer(config = {}) {
        this.widget.addElement('spacer', null, config);
        return this;
    }

    // Updated address method to handle new format
    address(addressData) {
        this.widget.addElement('address', addressData);
        return this;
    }

    button(text) {
        this.widget.addElement('button', text);
        return this;
    }

    build() {
        this.widget.validateLayout();
        return this.widget;
    }
}

// Example usage:
/*
// Basic usage with image and description in top section (horizontal scroll)
const container = document.getElementById('post-container');
const post = new PostWidgetBuilder(container, { debug: true })
    .image('https://example.com/event-image.jpg')
    .description('Event description goes here in the top section...')
    .name('Event Title')
    .datetime([
        { day: 'Monday', date: '12/25', time: '7:00pm-11:00pm' },
        { day: 'Tuesday', date: '12/26', time: '6:00pm-10:00pm' }
    ])
    .spacer() // This will push everything below to the bottom
    .address({
        address1: '123 Main Street',
        address2: 'Suite 200',
        city: 'Portland',
        state: 'OR',
        zip: '97205'
    })
    .button('Register Now')
    .build();

// Image-only layout (full width image)
const imageOnlyPost = new PostWidgetBuilder(container)
    .image('https://example.com/banner.jpg', { layout: 'image-only' })
    .name('Full Width Image Event')
    .standaloneDescription('Description below the image')
    .singleDatetime('Friday', '01/15', '8:00pm-11:30pm')
    .spacer()
    .address('456 Oak Ave, Portland, OR 97201')
    .button('Buy Tickets')
    .build();

// Mixed layout with image and description side by side
const mixedPost = new PostWidgetBuilder(container)
    .image('https://example.com/event.jpg', { layout: 'mixed' })
    .description('This description will appear next to the image in a scrollable container')
    .name('Mixed Layout Event')
    .multipleDatetimes([
        { day: 'Monday', date: '03/01', time: '9:00am-5:00pm' },
        { day: 'Tuesday', date: '03/02', time: '9:00am-5:00pm' },
        { day: 'Wednesday', date: '03/03', time: '9:00am-3:00pm' },
        { day: 'Thursday', date: '03/04', time: '10:00am-4:00pm' }
    ])
    .spacer()
    .address({
        address1: '789 Convention Center Dr',
        city: 'Salem',
        state: 'OR',
        zip: '97301'
    })
    .button('Register')
    .build();

// No image, just description in top section
const noImagePost = new PostWidgetBuilder(container)
    .description('Just description in the top section without an image')
    .name('Text-Only Event')
    .datetime({ day: 'Saturday', date: '02/14', time: '7:00pm-12:00am' })
    .spacer()
    .address('321 Event Plaza, Eugene, OR 97401')
    .button('Join Event')
    .build();

// Programmatic approach with multiple images/descriptions
const widget = new PostWidget(container);

// Add image and description to top section
widget.addElement('image', 'https://example.com/image1.jpg');
widget.addElement('description', 'First description in top section');

// Add main content
widget.addElement('name', 'Multi-Section Event');

// Add standalone description (not in top section)
widget.addElement('description', 'This is a standalone description below', { inTopSection: false });

// Add multiple datetimes
widget.addElement('datetime', [
    { day: 'Saturday', date: '02/14', time: '7:00pm-12:00am' },
    { day: 'Sunday', date: '02/15', time: '2:00pm-8:00pm' }
]);

// Add spacer to push remaining content to bottom
const spacer = widget.addBottomSpacer({ debug: true });

// Add structured address
widget.addElement('address', {
    address1: '321 Event Plaza',
    address2: 'Building A',
    city: 'Eugene',
    state: 'OR',
    zip: '97401'
});

widget.addElement('button', 'Action Button');
*/

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { PostWidget, PostWidgetBuilder };
}

// Global access
if (typeof window !== 'undefined') {
    window.PostWidget = PostWidget;
    window.PostWidgetBuilder = PostWidgetBuilder;
}
