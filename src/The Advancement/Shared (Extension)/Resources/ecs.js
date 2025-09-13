class EntityComponentSystem {
    constructor() {
        this.entities = new Map();
        this.components = new Map();
        this.systems = [];
        this.nextEntityId = 0;
    }

    createEntity() {
        const id = this.nextEntityId++;
        this.entities.set(id, new Set());
        return id;
    }

    addComponent(entityId, componentName, data) {
        if (!this.entities.has(entityId)) return;
        
        if (!this.components.has(componentName)) {
            this.components.set(componentName, new Map());
        }
        
        this.components.get(componentName).set(entityId, data);
        this.entities.get(entityId).add(componentName);
    }

    getComponent(entityId, componentName) {
        if (!this.components.has(componentName)) return null;
        return this.components.get(componentName).get(entityId);
    }

    hasComponent(entityId, componentName) {
        return this.entities.has(entityId) && this.entities.get(entityId).has(componentName);
    }

    removeEntity(entityId) {
        if (!this.entities.has(entityId)) return;
        
        for (const [componentName, componentMap] of this.components) {
            componentMap.delete(entityId);
        }
        
        this.entities.delete(entityId);
    }

    getEntitiesWithComponents(componentNames) {
        const result = [];
        
        for (const [entityId, entityComponents] of this.entities) {
            if (componentNames.every(name => entityComponents.has(name))) {
                result.push(entityId);
            }
        }
        
        return result;
    }

    addSystem(system) {
        this.systems.push(system);
    }

    update(deltaTime) {
        this.systems.forEach(system => system.update(this, deltaTime));
    }
}

class PhysicsSystem {
    update(ecs, deltaTime) {
        const entities = ecs.getEntitiesWithComponents(['position', 'velocity']);
        
        entities.forEach(entityId => {
            const pos = ecs.getComponent(entityId, 'position');
            const vel = ecs.getComponent(entityId, 'velocity');
            
            pos.x += vel.x * deltaTime;
            pos.y += vel.y * deltaTime;
            
            vel.y += 980 * deltaTime;
        });
    }
}

class RenderSystem {
    constructor(gameConsole) {
        this.gameConsole = gameConsole;
    }

    update(ecs, deltaTime) {
        const entities = ecs.getEntitiesWithComponents(['position', 'render']);
        
        entities.forEach(entityId => {
            const pos = ecs.getComponent(entityId, 'position');
            const render = ecs.getComponent(entityId, 'render');
            
            if (render.element) {
                if (render.element.tagName === 'DIV') {
                    // DOM element - update style
                    render.element.style.left = `${pos.x}px`;
                    render.element.style.top = `${pos.y}px`;
                } else {
                    // SVG element - update attributes
                    render.element.setAttribute('x', pos.x);
                    render.element.setAttribute('y', pos.y);
                }
            }
        });
    }
}

class LifetimeSystem {
    update(ecs, deltaTime) {
        const entities = ecs.getEntitiesWithComponents(['lifetime']);
        
        entities.forEach(entityId => {
            const lifetime = ecs.getComponent(entityId, 'lifetime');
            lifetime.remaining -= deltaTime;
            
            if (lifetime.remaining <= 0) {
                const render = ecs.getComponent(entityId, 'render');
                if (render && render.element && render.element.parentNode) {
                    render.element.parentNode.removeChild(render.element);
                }
                ecs.removeEntity(entityId);
            }
        });
    }
}