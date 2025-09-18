/**
 * Form Widget - Extracted from idothis form-widget.js
 * Simplified SVG-based form components for author platform
 */

class FormWidget {
    constructor(container, config = {}) {
        this.container = container;
        this.config = {
            width: 600,
            height: 400,
            colors: {
                primary: '#4CAF50',
                background: '#ffffff',
                text: '#333333',
                border: '#e0e0e0'
            },
            ...config
        };
        this.fields = {};
        this.svg = null;
        this.onSubmitCallback = null;
    }

    create() {
        this.svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        this.svg.setAttribute('width', '100%');
        this.svg.setAttribute('height', this.config.height);
        this.svg.setAttribute('viewBox', `0 0 ${this.config.width} ${this.config.height}`);
        this.svg.style.background = this.config.colors.background;
        this.svg.style.borderRadius = '12px';
        this.svg.style.border = `2px solid ${this.config.colors.border}`;

        this.container.appendChild(this.svg);
        return this;
    }

    addField(id, config) {
        const fieldConfig = {
            type: 'text',
            label: '',
            placeholder: '',
            required: false,
            y: Object.keys(this.fields).length * 80 + 40,
            ...config
        };

        this.fields[id] = fieldConfig;
        this.renderField(id, fieldConfig);
        return this;
    }

    renderField(id, config) {
        const group = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        group.setAttribute('id', `field-${id}`);

        // Label
        if (config.label) {
            const label = document.createElementNS('http://www.w3.org/2000/svg', 'text');
            label.setAttribute('x', '30');
            label.setAttribute('y', config.y);
            label.setAttribute('fill', this.config.colors.text);
            label.setAttribute('font-size', '16');
            label.setAttribute('font-weight', '500');
            label.textContent = config.label + (config.required ? ' *' : '');
            group.appendChild(label);
        }

        // Input field (using foreignObject)
        const foreign = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject');
        foreign.setAttribute('x', '30');
        foreign.setAttribute('y', config.y + 20);
        foreign.setAttribute('width', this.config.width - 60);
        foreign.setAttribute('height', config.type === 'textarea' ? '80' : '40');

        const input = config.type === 'textarea'
            ? document.createElement('textarea')
            : document.createElement('input');

        if (config.type !== 'textarea') {
            input.setAttribute('type', config.type);
        }

        input.setAttribute('id', `form-${id}`);
        input.setAttribute('name', id);
        input.setAttribute('placeholder', config.placeholder);
        input.required = config.required;

        input.style.width = '100%';
        input.style.height = '100%';
        input.style.border = `2px solid ${this.config.colors.border}`;
        input.style.borderRadius = '8px';
        input.style.padding = '12px';
        input.style.fontSize = '16px';
        input.style.fontFamily = 'Arial, sans-serif';
        input.style.background = '#fff';
        input.style.color = this.config.colors.text;
        input.style.outline = 'none';
        input.style.resize = config.type === 'textarea' ? 'vertical' : 'none';

        // Focus styles
        input.addEventListener('focus', () => {
            input.style.borderColor = this.config.colors.primary;
        });
        input.addEventListener('blur', () => {
            input.style.borderColor = this.config.colors.border;
        });

        foreign.appendChild(input);
        group.appendChild(foreign);
        this.svg.appendChild(group);
    }

    addSubmitButton(text = 'Submit', config = {}) {
        const buttonConfig = {
            y: Object.keys(this.fields).length * 80 + 60,
            width: 120,
            height: 40,
            ...config
        };

        const button = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        button.setAttribute('class', 'submit-button');
        button.style.cursor = 'pointer';

        // Button background
        const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
        rect.setAttribute('x', '30');
        rect.setAttribute('y', buttonConfig.y);
        rect.setAttribute('width', buttonConfig.width);
        rect.setAttribute('height', buttonConfig.height);
        rect.setAttribute('rx', '8');
        rect.setAttribute('fill', this.config.colors.primary);

        // Button text
        const buttonText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        buttonText.setAttribute('x', 30 + buttonConfig.width / 2);
        buttonText.setAttribute('y', buttonConfig.y + buttonConfig.height / 2 + 5);
        buttonText.setAttribute('text-anchor', 'middle');
        buttonText.setAttribute('fill', '#ffffff');
        buttonText.setAttribute('font-size', '16');
        buttonText.setAttribute('font-weight', '600');
        buttonText.textContent = text;

        button.appendChild(rect);
        button.appendChild(buttonText);

        // Click handler
        button.addEventListener('click', () => {
            this.handleSubmit();
        });

        // Hover effects
        button.addEventListener('mouseenter', () => {
            rect.setAttribute('fill', '#45a049');
        });
        button.addEventListener('mouseleave', () => {
            rect.setAttribute('fill', this.config.colors.primary);
        });

        this.svg.appendChild(button);

        // Update SVG height
        this.svg.setAttribute('height', buttonConfig.y + buttonConfig.height + 30);

        return this;
    }

    onSubmit(callback) {
        this.onSubmitCallback = callback;
        return this;
    }

    handleSubmit() {
        const formData = this.getData();

        // Basic validation
        for (const [id, config] of Object.entries(this.fields)) {
            if (config.required && !formData[id]) {
                alert(`Please fill in the required field: ${config.label}`);
                return;
            }
        }

        if (this.onSubmitCallback) {
            this.onSubmitCallback(formData);
        }
    }

    getData() {
        const data = {};
        for (const id of Object.keys(this.fields)) {
            const input = document.getElementById(`form-${id}`);
            if (input) {
                data[id] = input.value;
            }
        }
        return data;
    }

    setData(data) {
        for (const [id, value] of Object.entries(data)) {
            const input = document.getElementById(`form-${id}`);
            if (input) {
                input.value = value;
            }
        }
        return this;
    }

    clear() {
        for (const id of Object.keys(this.fields)) {
            const input = document.getElementById(`form-${id}`);
            if (input) {
                input.value = '';
            }
        }
        return this;
    }
}

// Export for global use
window.FormWidget = FormWidget;