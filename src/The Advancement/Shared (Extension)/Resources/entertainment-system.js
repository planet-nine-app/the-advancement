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

    init() {
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
            color: #ff4444;
            font-size: 32px;
            font-weight: 900;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.8), -1px -1px 2px rgba(255,255,255,0.8);
            pointer-events: none;
            z-index: 999999;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            user-select: none;
            transform: translate(-50%, -50%);
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
