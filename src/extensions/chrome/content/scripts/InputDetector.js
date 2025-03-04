class InputDetector {
  constructor() {
      this.loginKeywords = ['user', 'username', 'login', 'account', 'email'];
  }

  searchNode(node) {
      const inputs = [];
      const shadowRoot = node.shadowRoot;
      
      if (shadowRoot) {
          // Search within shadow DOM
          shadowRoot.querySelectorAll('input').forEach((input) => inputs.push(input));
          
          // Continue searching child shadow DOMs
          shadowRoot.querySelectorAll('*').forEach(child => {
              inputs.push(...this.searchNode(child));
          });
      }

      // Search regular children
      node.querySelectorAll('*').forEach((child) => {
          if (child.shadowRoot) {
              inputs.push(...this.searchNode(child));
          }
      });

      return inputs;
  }

  findInputsInShadowDOM(root) {
      return this.searchNode(root);
  }

  findInputsInIframes() {
      const inputs = [];
      const iframes = document.getElementsByTagName('iframe');

      for (const iframe of iframes) {
          try {
              const iframeInputs = iframe.contentDocument.getElementsByTagName('input');
              inputs.push(...iframeInputs);
          } catch (e) {
              console.log('Cannot access iframe content (likely cross-origin):', e);
          }
      }

      return inputs;
  }

  isLoginField(input) {
      const fieldIdentifiers = [
          input.id.toLowerCase(),
          input.name.toLowerCase(),
          input.placeholder.toLowerCase(),
          input.getAttribute('aria-label')?.toLowerCase() || '',
      ];

      return this.loginKeywords.some((keyword) =>
          fieldIdentifiers.some((identifier) => identifier.includes(keyword))
      );
  }

  markField(input, className) {
      input.classList.add(className);
      const iconContainer = document.createElement('div');
      iconContainer.className = 'disguise-self';
      input.parentNode.insertBefore(iconContainer, input.nextSibling);

      iconContainer.addEventListener('click', () => {
          console.log(`Clicked disguise self icon for ${className}`);
      });
  }

  detectFields() {
      // Find all input fields on the page
      const inputs = document.getElementsByTagName('input');
      console.log('got ' + inputs.length + ' inputs');

      const inputsByQuerySelector = document.querySelectorAll('input');
      console.log('Method 2 - querySelectorAll:', inputsByQuerySelector.length);

      const shadowInputs = this.findInputsInShadowDOM(document.body);
      console.log('Method 3 - Shadow DOM inputs:', shadowInputs.length);

      // Process regular inputs
      for (const input of inputs) {
          if (
              input.type === 'email' ||
              input.id.toLowerCase().includes('email') ||
              input.name.toLowerCase().includes('email')
          ) {
              this.markField(input, 'email-field');
              continue;
          }
          if (this.isLoginField(input)) {
              this.markField(input, 'login-field');
          }
      }

      // Process shadow DOM inputs
      for (const input of shadowInputs) {
          console.log('Processing shadow input:', input);
          if (
              input.type === 'email' ||
              input.id.toLowerCase().includes('email') ||
              input.name.toLowerCase().includes('email')
          ) {
              this.markField(input, 'email-field');
              continue;
          }
          if (this.isLoginField(input)) {
              console.log('found a login field');
              this.markField(input, 'login-field');
          }
      }
  }
}
