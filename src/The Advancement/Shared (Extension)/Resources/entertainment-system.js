class EntertainmentSystem {
    constructor() {
        this.gameConsole = null;
        this.isActive = false;
        this.isMonsterMode = false;
        this.gameElements = new Map();
        this.inputHandler = null;
        this.viewBox = { width: 2400, height: 1800 };
        this.isLandscape = true;
        this.ecs = null;
        this.lastTime = 0;
        this.animationFrame = null;
        
        this.init();
    }

    loadFonts() {
        // Load the custom fonts CSS for damage nodes
        if (!document.querySelector('link[href*="fonts.css"]')) {
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            
            // Safari extension - try browser.runtime first, fallback to relative paths
            if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.getURL) {
                link.href = browser.runtime.getURL('fonts.css');
            } else {
                // Fallback to relative path for Safari extension
                link.href = 'fonts.css';
            }
            
            if (link.href) {
                document.head.appendChild(link);
                console.log('[Entertainment System] Loaded FFVI damage font CSS from:', link.href);
                
                // Debug: Test direct font file access with multiple paths
                const testFontPaths = [
                    'fonts/FFVI-Damage-v3-LC-BW.otf',
                    'FFVI-Damage-v3-LC-BW.otf'
                ];
                
                testFontPaths.forEach((fontPath, index) => {
                    let testFontUrl;
                    if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.getURL) {
                        testFontUrl = browser.runtime.getURL(fontPath);
                    } else {
                        testFontUrl = fontPath;
                    }
                    
                    console.log(`[Entertainment System] 🔍 Testing font path ${index + 1}: ${testFontUrl}`);
                    
                    // Try to fetch the font file to see if it's accessible
                    fetch(testFontUrl)
                        .then(response => {
                            console.log(`[Entertainment System] Font path ${index + 1} fetch response:`, response.status, response.statusText);
                            if (response.ok) {
                                console.log(`[Entertainment System] ✅ Font path ${index + 1} is accessible`);
                                return response.blob();
                            } else {
                                console.error(`[Entertainment System] ❌ Font path ${index + 1} not accessible:`, response.status);
                            }
                        })
                        .then(blob => {
                            if (blob) {
                                console.log(`[Entertainment System] Font path ${index + 1} file size:`, blob.size, 'bytes');
                            }
                        })
                        .catch(error => {
                            console.error(`[Entertainment System] ❌ Font path ${index + 1} fetch failed:`, error);
                        });
                });
                
                // Debug: Check if font loads successfully
                link.onload = () => {
                    console.log('[Entertainment System] ✅ Fonts CSS loaded successfully');
                    this.checkFontAvailability();
                };
                link.onerror = () => {
                    console.error('[Entertainment System] ❌ Failed to load fonts CSS');
                };
            } else {
                console.error('[Entertainment System] ❌ Could not get font CSS URL');
            }
        }
    }
    
    async checkFontAvailability() {
        // Test if the FFVI font is actually loading and rendering properly
        console.log('[Entertainment System] 🔍 Checking font loading status...');
        
        // Try to load the font programmatically with multiple paths
        const fontPaths = [
            'fonts/FFVI-Damage-v3-LC-BW.otf',
            'FFVI-Damage-v3-LC-BW.otf'
        ];
        
        for (let i = 0; i < fontPaths.length; i++) {
            try {
                let fontUrl;
                if (typeof browser !== 'undefined' && browser.runtime && browser.runtime.getURL) {
                    fontUrl = browser.runtime.getURL(fontPaths[i]);
                } else {
                    fontUrl = fontPaths[i];
                }
                
                console.log(`[Entertainment System] 📖 Font URL attempt ${i + 1}:`, fontUrl);
                
                if (fontUrl) {
                    // Create FontFace object and load programmatically
                    const fontFace = new FontFace(`FFVI-Damage-v3-LC-BW-Direct-${i}`, `url(${fontUrl})`);
                    const loadedFont = await fontFace.load();
                    document.fonts.add(loadedFont);
                    console.log(`[Entertainment System] ✅ Font loaded programmatically (attempt ${i + 1}):`, loadedFont.family);
                    break; // Success, exit loop
                }
            } catch (error) {
                console.log(`[Entertainment System] ❌ Programmatic font loading failed (attempt ${i + 1}):`, error);
                if (i === fontPaths.length - 1) {
                    console.log('[Entertainment System] ⚠️ All font loading attempts failed');
                }
            }
        }
        
        // Test visual rendering differences
        const fonts = ['FFVI-Damage-Font', 'FFVI-Damage-v3-LC-BW', 'FFVI-Damage-v3-LC-BW-Alt', 'FFVI-Damage-v3-LC-BW-Direct'];
        
        fonts.forEach(fontName => {
            // Create test element with specific text that should look different in FFVI font
            const testElement = document.createElement('span');
            testElement.style.fontFamily = `${fontName}, monospace`;
            testElement.style.position = 'absolute';
            testElement.style.left = '-9999px';
            testElement.style.fontSize = '36px';
            testElement.textContent = '999'; // Numbers should look very different in FFVI font
            document.body.appendChild(testElement);
            
            const computedFont = window.getComputedStyle(testElement).fontFamily;
            const textWidth = testElement.offsetWidth;
            const textHeight = testElement.offsetHeight;
            
            console.log(`[Entertainment System] 🔍 ${fontName}:`);
            console.log(`  - Computed: ${computedFont}`);
            console.log(`  - Dimensions: ${textWidth}x${textHeight}px`);
            
            // Compare against known monospace dimensions to see if font is actually different
            const monoElement = document.createElement('span');
            monoElement.style.fontFamily = 'monospace';
            monoElement.style.position = 'absolute';
            monoElement.style.left = '-9999px';
            monoElement.style.fontSize = '36px';
            monoElement.textContent = '999';
            document.body.appendChild(monoElement);
            
            const monoWidth = monoElement.offsetWidth;
            const monoHeight = monoElement.offsetHeight;
            
            if (textWidth !== monoWidth || textHeight !== monoHeight) {
                console.log(`[Entertainment System] ✅ ${fontName} appears to be visually different from monospace (likely loaded)`);
            } else {
                console.log(`[Entertainment System] ❌ ${fontName} matches monospace dimensions (likely not loaded)`);
            }
            
            document.body.removeChild(testElement);
            document.body.removeChild(monoElement);
        });
        
        // List all loaded fonts
        console.log('[Entertainment System] 📚 All document fonts:');
        document.fonts.forEach(font => {
            console.log(`  - ${font.family}: ${font.status} (${font.style}, ${font.weight})`);
        });
        
        // Try to check if any FFVI fonts are available using check method
        const fontTests = ['FFVI-Damage-v3-LC-BW', 'FFVI-Damage-Font'];
        fontTests.forEach(fontName => {
            const isAvailable = document.fonts.check(`16px "${fontName}"`);
            console.log(`[Entertainment System] 🔍 Font check for "${fontName}": ${isAvailable}`);
        });
        
        // Check what CSS is actually loaded
        const styleSheets = Array.from(document.styleSheets);
        const fontStyleSheet = styleSheets.find(sheet => sheet.href && sheet.href.includes('fonts.css'));
        if (fontStyleSheet) {
            console.log('[Entertainment System] ✅ Found fonts.css stylesheet:', fontStyleSheet.href);
        } else {
            console.log('[Entertainment System] ❌ fonts.css stylesheet not found in document');
        }
    }

    init() {
        this.loadFonts();
        this.updateViewBox();
        this.createGameConsole();
        this.setupECS();
        this.setupInputHandling();
        this.setupEventForwarding();
        this.setupResizeHandler();
        this.addDemoElements();
        this.startGameLoop();
    }

    setupECS() {
        this.ecs = new EntityComponentSystem();
        this.ecs.addSystem(new PhysicsSystem());
        this.ecs.addSystem(new RenderSystem(this.gameConsole));
        this.ecs.addSystem(new LifetimeSystem());
    }

    startGameLoop() {
        const gameLoop = (currentTime) => {
            const deltaTime = (currentTime - this.lastTime) / 1000;
            this.lastTime = currentTime;
            
            if (this.ecs && deltaTime < 0.1) {
                this.ecs.update(deltaTime);
            }
            
            this.animationFrame = requestAnimationFrame(gameLoop);
        };
        
        this.animationFrame = requestAnimationFrame(gameLoop);
    }

    updateViewBox() {
        const windowWidth = window.innerWidth;
        const windowHeight = window.innerHeight;
        this.isLandscape = windowWidth > windowHeight;
        
        if (this.isLandscape) {
            this.viewBox = { width: 2400, height: 1800 };
        } else {
            this.viewBox = { width: 1800, height: 3200 };
        }
        
        if (this.gameConsole) {
            const coordinateSystem = this.gameConsole.querySelector('#nes-coordinate-system');
            if (coordinateSystem) {
                coordinateSystem.setAttribute('viewBox', `0 0 ${this.viewBox.width} ${this.viewBox.height}`);
            }
        }
        
        console.log(`[Entertainment System] ViewBox updated: ${this.viewBox.width}x${this.viewBox.height} (${this.isLandscape ? 'landscape' : 'portrait'})`);
    }

    setupResizeHandler() {
        window.addEventListener('resize', () => {
            this.updateViewBox();
        });
    }

    convertPosition(value, isXAxis = true) {
        if (typeof value === 'string') {
            return value;
        }
        
        if (typeof value === 'number') {
            const maxValue = isXAxis ? this.viewBox.width : this.viewBox.height;
            const percentage = (value / maxValue) * 100;
            return `${percentage}%`;
        }
        
        return '0%';
    }

    createGameConsole() {
        this.gameConsole = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        this.gameConsole.setAttribute('id', 'advancement-entertainment-system');
        this.gameConsole.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            z-index: 1000000;
            pointer-events: none;
            border: 6px solid #9932cc;
            box-sizing: border-box;
        `;

        this.gameConsole.innerHTML = `
            <defs>
                <style>
                    .nes-game-area {
                        pointer-events: auto;
                    }
                    .nes-passthrough {
                        pointer-events: none;
                    }
                    .nes-demo-rect {
                        fill-opacity: 0.7;
                        stroke: #000;
                        stroke-width: 2;
                    }
                </style>
            </defs>
            
            <!-- Inner SVG with proper coordinate system -->
            <svg id="nes-coordinate-system" x="0" y="0" width="100%" height="100%" 
                 viewBox="0 0 ${this.viewBox.width} ${this.viewBox.height}" 
                 preserveAspectRatio="none" class="nes-passthrough">
                
                <!-- Game area (initially empty) -->
                <g id="nes-game-layer" class="nes-passthrough">
                    <!-- Game elements will be added here -->
                </g>
            </svg>
        `;

        document.body.appendChild(this.gameConsole);
        console.log('[Entertainment System] NES-style game console initialized');
    }

    setupInputHandling() {
        this.inputHandler = (event) => {
            if (!this.isActive) return;
            
            if (!event.clientX || !event.clientY || !isFinite(event.clientX) || !isFinite(event.clientY)) {
                return;
            }
            
            const targetElement = document.elementFromPoint(event.clientX, event.clientY);
            
            if (targetElement && targetElement.closest('#advancement-entertainment-system')) {
                const rect = this.gameConsole.getBoundingClientRect();
                const x = event.clientX - rect.left;
                const y = event.clientY - rect.top;
                
                if (isFinite(x) && isFinite(y)) {
                    this.handleGameInput(event, x, y);
                }
                event.preventDefault();
                event.stopPropagation();
            }
        };

        document.addEventListener('keydown', this.inputHandler, true);
        document.addEventListener('keyup', this.inputHandler, true);
        
        document.addEventListener('keydown', (event) => this.handleGlobalKeydown(event), true);
    }

    setupEventForwarding() {
        // No longer needed - simplified approach
    }

    handleGameInput(event, x, y) {
        console.log(`[Entertainment System] Game input: ${event.type} at (${x}, ${y})`);
        
        switch (event.type) {
            case 'keydown':
                this.handleGameKeydown(event.key);
                break;
        }
    }

    handleGameKeydown(key) {
        console.log(`[Entertainment System] Game key: ${key}`);
        
        if (key === 'Escape') {
            this.toggleActive();
        }
    }

    handleGlobalKeydown(event) {
        console.log(`[Entertainment System] Global key: ${event.key}`);
        
        if (event.key === 'Escape') {
            this.toggleActive();
            event.preventDefault();
        }
    }

    addGameElement(elementConfig) {
        const gameLayer = this.gameConsole.querySelector('#nes-game-layer');
        if (!gameLayer) return null;

        const element = document.createElementNS('http://www.w3.org/2000/svg', elementConfig.type || 'circle');
        
        Object.entries(elementConfig.attributes || {}).forEach(([key, value]) => {
            if (key === 'x') {
                value = this.convertPosition(value, true);
            } else if (key === 'y') {
                value = this.convertPosition(value, false);
            }
            element.setAttribute(key, value);
        });

        if (elementConfig.className) {
            element.setAttribute('class', elementConfig.className);
        }

        gameLayer.appendChild(element);
        
        const elementId = elementConfig.id || `game-element-${Date.now()}`;
        this.gameElements.set(elementId, element);
        
        return element;
    }

    addDemoElements() {
        setTimeout(() => {
            this.addGameElement({
                type: 'rect',
                id: 'demo-number-rect',
                className: 'nes-demo-rect',
                attributes: {
                    x: 120,
                    y: 90,
                    width: 200,
                    height: 100,
                    fill: '#ff6b6b'
                }
            });

            this.addGameElement({
                type: 'rect', 
                id: 'demo-percentage-rect',
                className: 'nes-demo-rect',
                attributes: {
                    x: '7%',
                    y: '12%', 
                    width: 200,
                    height: 100,
                    fill: '#4ecdc4'
                }
            });

            console.log('[Entertainment System] Demo elements added:');
            console.log('  Red rect (120, 90) - number positioning');
            console.log('  Teal rect (7%, 12%) - percentage positioning');
        }, 1000);
    }

    removeGameElement(elementId) {
        const element = this.gameElements.get(elementId);
        if (element && element.parentNode) {
            element.parentNode.removeChild(element);
            this.gameElements.delete(elementId);
        }
    }

    toggleActive() {
        this.isActive = !this.isActive;
        const gameLayer = this.gameConsole.querySelector('#nes-game-layer');
        const coordinateSystem = this.gameConsole.querySelector('#nes-coordinate-system');
        
        console.log(`[Entertainment System] Toggle called - isActive: ${this.isActive}`);
        
        if (this.isActive) {
            if (gameLayer) gameLayer.setAttribute('class', 'nes-game-area');
            if (coordinateSystem) coordinateSystem.setAttribute('class', 'nes-game-area');
            this.gameConsole.style.pointerEvents = 'none';
            this.gameConsole.style.borderColor = '#00ff00';
            console.log('[Entertainment System] ✅ Game mode ACTIVATED - ESC to exit, click slimes to attack');
        } else {
            if (gameLayer) gameLayer.setAttribute('class', 'nes-passthrough');
            if (coordinateSystem) coordinateSystem.setAttribute('class', 'nes-passthrough');
            this.gameConsole.style.pointerEvents = 'none';
            this.gameConsole.style.borderColor = '#9932cc';
            console.log('[Entertainment System] ❌ Game mode DEACTIVATED');
        }
    }

    activateMonsterMode() {
        this.isMonsterMode = true;
        
        if (!this.isActive) {
            this.toggleActive();
        }
        
        console.log('[Entertainment System] Checking adversementSystem:', typeof window.adversementSystem);
        
        if (window.adversementSystem) {
            console.log('[Entertainment System] Setting monster mode and refreshing...');
            window.adversementSystem.setMonsterMode(true);
            window.adversementSystem.refreshOverlays();
        } else {
            console.log('[Entertainment System] ⚠️ adversementSystem not found');
        }
        
        console.log('[Entertainment System] 👹 Monster mode activated! Game mode enabled. Click slimes to attack!');
    }

    attackSlime(screenX, screenY) {
        console.log(`[Entertainment System] attackSlime called with coords (${screenX}, ${screenY})`);
        console.log(`[Entertainment System] ECS available:`, !!this.ecs);
        console.log(`[Entertainment System] Game console available:`, !!this.gameConsole);
        
        const damage = Math.floor(Math.random() * 41) + 30;
        console.log(`[Entertainment System] Generated damage: ${damage}`);
        
        const damageNodeId = this.createDamageNode(damage, screenX, screenY);
        console.log(`[Entertainment System] Created damage node with ID: ${damageNodeId}`);
        console.log(`[Entertainment System] Slime attacked for ${damage} damage!`);
    }

    createDamageNode(damage, screenX, screenY) {
        console.log(`[Entertainment System] createDamageNode called: damage=${damage}, coords=(${screenX}, ${screenY})`);
        
        const angle = (Math.random() * 60 - 30) * Math.PI / 180;
        const speed = 200 + Math.random() * 100;
        
        const velocityX = Math.sin(angle) * speed;
        const velocityY = -Math.abs(Math.cos(angle)) * speed;
        
        console.log(`[Entertainment System] Physics: angle=${angle.toFixed(2)}, velocity=(${velocityX.toFixed(1)}, ${velocityY.toFixed(1)})`);

        const damageNode = document.createElement('div');
        damageNode.style.cssText = `
            position: fixed;
            left: ${screenX}px;
            top: ${screenY}px;
            color: #FFD700;
            font-size: 36px;
            font-weight: normal;
            text-shadow: 3px 3px 6px rgba(0,0,0,0.9), -1px -1px 3px rgba(0,0,0,0.7);
            pointer-events: none;
            z-index: 999999;
            font-family: 'FFVI-Damage-v3-LC-BW-Direct-1', 'FFVI-Damage-v3-LC-BW-Direct-0', 'FFVI-Damage-Font', 'FFVI-Damage-v3-LC-BW', 'FFVI-Damage', 'Courier New', Monaco, monospace;
            user-select: none;
            transform: translate(-50%, -50%);
            letter-spacing: 1px;
        `;
        damageNode.textContent = `-${damage}`;
        
        console.log(`[Entertainment System] Created damage node element:`, damageNode);
        
        document.body.appendChild(damageNode);
        console.log(`[Entertainment System] Added damage node to document body`);

        const entityId = this.ecs.createEntity();
        console.log(`[Entertainment System] Created ECS entity: ${entityId}`);
        
        this.ecs.addComponent(entityId, 'position', { x: screenX, y: screenY });
        this.ecs.addComponent(entityId, 'velocity', { x: velocityX, y: velocityY });
        this.ecs.addComponent(entityId, 'render', { element: damageNode });
        this.ecs.addComponent(entityId, 'lifetime', { remaining: 2.0 });
        
        console.log(`[Entertainment System] Added all ECS components for entity ${entityId}`);
        console.log(`[Entertainment System] ECS entity count:`, this.ecs.entities.size);
        
        return entityId;
    }

    destroy() {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
        }
        
        if (this.gameConsole && this.gameConsole.parentNode) {
            this.gameConsole.parentNode.removeChild(this.gameConsole);
        }
        
        if (this.inputHandler) {
            document.removeEventListener('keydown', this.inputHandler, true);
            document.removeEventListener('keyup', this.inputHandler, true);
        }
        
        this.gameElements.clear();
        console.log('[Entertainment System] Console destroyed');
    }
}

if (typeof window !== 'undefined') {
    console.log('[Entertainment System] Creating global instance...');
    const entertainmentSystem = new EntertainmentSystem();
    
    const script = document.createElement('script');
    script.textContent = `
        console.log('[Entertainment System] Injecting into page context...');
        window.entertainmentSystem = {
            toggleActive: function() {
                console.log('[Entertainment System] Page toggleActive called');
                document.dispatchEvent(new CustomEvent('entertainment-toggle-active'));
            },
            activateMonsterMode: function() {
                console.log('[Entertainment System] Page activateMonsterMode called');
                document.dispatchEvent(new CustomEvent('entertainment-activate-monster'));
            },
            attackSlime: function(x, y) {
                console.log('[Entertainment System] Page attackSlime called at', x, y);
                document.dispatchEvent(new CustomEvent('entertainment-attack-slime', { 
                    detail: { x: x, y: y } 
                }));
            },
            isActive: false,
            isMonsterMode: false
        };
        
        document.addEventListener('entertainment-toggle-active', () => {
            window.entertainmentSystem.isActive = !window.entertainmentSystem.isActive;
            console.log('[Entertainment System] Page state updated - isActive:', window.entertainmentSystem.isActive);
        });
        
        document.addEventListener('entertainment-activate-monster', () => {
            window.entertainmentSystem.isMonsterMode = true;
            console.log('[Entertainment System] Page state updated - isMonsterMode:', window.entertainmentSystem.isMonsterMode);
        });
        
        console.log('[Entertainment System] ✅ Available in page console as window.entertainmentSystem');
    `;
    document.documentElement.appendChild(script);
    document.documentElement.removeChild(script);
    
    document.addEventListener('entertainment-toggle-active', () => {
        console.log('[Entertainment System] Custom event received - toggling');
        entertainmentSystem.toggleActive();
    });
    
    document.addEventListener('entertainment-activate-monster', () => {
        console.log('[Entertainment System] Custom event received - monster mode');
        entertainmentSystem.activateMonsterMode();
    });
    
    document.addEventListener('entertainment-attack-slime', (event) => {
        console.log('[Entertainment System] Attack slime event received:', event.detail);
        entertainmentSystem.attackSlime(event.detail.x, event.detail.y);
    });
    
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && event.ctrlKey) {
            console.log('[Entertainment System] Ctrl+ESC detected - toggling game mode');
            entertainmentSystem.toggleActive();
            event.preventDefault();
        }
    }, true);
    
    window.entertainmentSystemContentScript = entertainmentSystem;
    
    console.log('[Entertainment System] Ready! Try: window.entertainmentSystem.toggleActive() or Ctrl+ESC');
}
