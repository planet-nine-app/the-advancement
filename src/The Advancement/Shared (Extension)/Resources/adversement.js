class AdversementSystem {
    constructor() {
        this.adStrings = ['ads_', 'ad-', 'ads-', 'googlesyndication', 'pagead2', 'fixed-ad'];
        this.coveredAds = new Set();
        this.observer = null;
        this.ficusImageUrl = null;
        this.isMonsterMode = false;
        
        this.init();
    }

    init() {
        this.loadFicusImage();
        this.scanExistingAds();
        this.startObserver();
    }

    loadFicusImage() {
        this.ficusImageUrl = chrome.runtime.getURL('ficus.jpg');
    }

    testStringForAdStrings(str) {
        if (!str) return false;
        return this.adStrings.filter(adString => str.indexOf(adString) > -1).length > 0;
    }

    attributeStringForNode(node) {
        if (!node.attributes) return '';
        
        let attributeString = '';
        for (let attr of node.attributes) {
            attributeString += `${attr.name}=${attr.value} `;
        }
        return attributeString.trim();
    }

    stringsContainAd(strings) {
        return strings.some(str => this.testStringForAdStrings(str));
    }

    isAdElement(element) {
        if (!element || element.nodeType !== Node.ELEMENT_NODE) return false;
        
        const testStrings = [
            element.id,
            this.attributeStringForNode(element),
            Array.from(element.classList).join(' ')
        ];

        return this.stringsContainAd(testStrings);
    }

    createAdOverlay(adElement) {
        const rect = adElement.getBoundingClientRect();
        
        if (rect.width < 50 || rect.height < 50) {
            return null;
        }

        const isMonsterMode = this.isMonsterMode;
        const imageUrl = isMonsterMode ? chrome.runtime.getURL('slime.png') : this.ficusImageUrl;
        const overlayClass = isMonsterMode ? 'advancement-slime-overlay' : 'advancement-ficus-overlay';
        
        const overlay = document.createElement('div');
        overlay.className = overlayClass;
        overlay.style.cssText = `
            position: absolute;
            top: ${rect.top + window.scrollY}px;
            left: ${rect.left + window.scrollX}px;
            width: ${rect.width}px;
            height: ${rect.height}px;
            z-index: 999999;
            background: url('${imageUrl}') center/cover no-repeat;
            background-color: ${isMonsterMode ? '#1a1a2e' : '#f0f8f0'};
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            cursor: pointer;
            transition: opacity 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        `;

        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', '100%');
        svg.setAttribute('height', '100%');
        svg.setAttribute('viewBox', '0 0 100 100');
        svg.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            pointer-events: none;
        `;

        const image = document.createElementNS('http://www.w3.org/2000/svg', 'image');
        image.setAttributeNS('http://www.w3.org/1999/xlink', 'href', imageUrl);
        image.setAttribute('x', '0');
        image.setAttribute('y', '0');
        image.setAttribute('width', '100');
        image.setAttribute('height', '100');
        image.setAttribute('preserveAspectRatio', 'xMidYMid slice');

        const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', '50');
        text.setAttribute('y', '15');
        text.setAttribute('text-anchor', 'middle');
        text.setAttribute('fill', isMonsterMode ? '#ff4444' : '#2d5016');
        text.setAttribute('font-size', '3');
        text.setAttribute('font-weight', 'bold');
        text.textContent = isMonsterMode ? '👹 Attack the Slime!' : '🌿 Peaceful Plants';

        svg.appendChild(image);
        svg.appendChild(text);
        overlay.appendChild(svg);

        overlay.addEventListener('click', () => {
            console.log(`[Adversement] ${isMonsterMode ? 'Slime' : 'Ficus'} clicked! Monster mode: ${isMonsterMode}`);
            
            if (isMonsterMode) {
                const centerX = rect.left + rect.width/2;
                const centerY = rect.top + rect.height/2;
                console.log(`[Adversement] Slime rect:`, rect);
                console.log(`[Adversement] Scroll offset: (${window.scrollX}, ${window.scrollY})`);
                console.log(`[Adversement] Dispatching attack event at viewport coords (${centerX}, ${centerY})`);
                
                document.dispatchEvent(new CustomEvent('entertainment-attack-slime', { 
                    detail: { x: centerX, y: centerY } 
                }));
            }
        });

        return overlay;
    }

    coverAd(adElement) {
        if (this.coveredAds.has(adElement)) return;

        const overlay = this.createAdOverlay(adElement);
        if (!overlay) return;

        document.body.appendChild(overlay);
        this.coveredAds.add(adElement);
        
        adElement.style.visibility = 'hidden';
    }

    scanExistingAds() {
        const allDivs = Array.from(document.getElementsByTagName('div'));
        const allIframes = Array.from(document.getElementsByTagName('iframe'));
        const allElements = [...allDivs, ...allIframes];
        
        allElements.forEach(element => {
            if (this.isAdElement(element)) {
                this.coverAd(element);
            }
        });
    }

    startObserver() {
        this.observer = new MutationObserver((mutations) => {
            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        if (this.isAdElement(node)) {
                            this.coverAd(node);
                        }
                        
                        const childAds = node.querySelectorAll ? 
                            Array.from(node.querySelectorAll('div, iframe')).filter(el => this.isAdElement(el)) : 
                            [];
                        
                        childAds.forEach(ad => this.coverAd(ad));
                    }
                });
            });
        });

        this.observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    setMonsterMode(enabled) {
        this.isMonsterMode = enabled;
        console.log(`[Adversement] Monster mode set to: ${enabled}`);
    }

    refreshOverlays() {
        console.log('[Adversement] Refreshing overlays for mode change...');
        
        document.querySelectorAll('.advancement-ficus-overlay, .advancement-slime-overlay').forEach(overlay => {
            overlay.remove();
        });
        
        const adsToRecover = Array.from(this.coveredAds);
        this.coveredAds.clear();
        
        adsToRecover.forEach(ad => {
            ad.style.visibility = '';
            this.coverAd(ad);
        });
        
        console.log(`[Adversement] Refreshed ${adsToRecover.length} ad overlays (monster mode: ${this.isMonsterMode})`);
    }

    destroy() {
        if (this.observer) {
            this.observer.disconnect();
        }
        
        this.coveredAds.forEach(ad => {
            ad.style.visibility = '';
        });
        
        document.querySelectorAll('.advancement-ficus-overlay, .advancement-slime-overlay').forEach(overlay => {
            overlay.remove();
        });
        
        this.coveredAds.clear();
    }
}

if (typeof window !== 'undefined') {
    window.adversementSystem = new AdversementSystem();
}