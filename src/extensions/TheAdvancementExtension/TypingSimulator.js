class TypingSimulator {
    constructor(options = {}) {
      this.minDelay = options.minDelay || 50; // Minimum delay between keystrokes
      this.maxDelay = options.maxDelay || 150; // Maximum delay between keystrokes
      this.naturalMode = options.naturalMode !== false; // Add small variations in timing
    }
  
    async typeIntoElement(element, text) {
      // Focus the element first
      element.focus();
  
      // Clear existing value if needed
      if (element.value) {
        element.value = '';
        this.triggerEvent(element, 'input');
      }
  
      // Type each character
      for (let i = 0; i < text.length; i++) {
        const char = text[i];
  
        // Get keyboard event details for this character
        const keyDetails = this.getKeyDetails(char);
  
        // Simulate keydown
        this.triggerKeyEvent(element, 'keydown', keyDetails);
  
        // Simulate keypress
        this.triggerKeyEvent(element, 'keypress', keyDetails);
  
        // Update input value to include the new character
        element.value = text.substring(0, i + 1);
  
        // Simulate input event
        this.triggerEvent(element, 'input');
  
        // Simulate keyup
        this.triggerKeyEvent(element, 'keyup', keyDetails);
  
        // Wait for a random delay before next character
        await this.delay();
      }
  
      // Trigger final change event
      this.triggerEvent(element, 'change');
  
      // Blur the element
      element.blur();
      this.triggerEvent(element, 'blur');
    }
  
    getKeyDetails(char) {
      return {
        key: char,
        code: `Key${char.toUpperCase()}`,
        keyCode: char.charCodeAt(0),
        which: char.charCodeAt(0),
        shiftKey: /[A-Z]/.test(char),
        bubbles: true,
        cancelable: true,
      };
    }
  
    triggerKeyEvent(element, eventType, keyDetails) {
      const event = new KeyboardEvent(eventType, {
        ...keyDetails,
        view: window,
        composed: true,
      });
  
      // Handle special key properties that can't be set through the constructor
      Object.defineProperties(event, {
        keyCode: { value: keyDetails.keyCode },
        which: { value: keyDetails.which },
        key: { value: keyDetails.key },
      });
  
      element.dispatchEvent(event);
    }
  
    triggerEvent(element, eventType) {
      const event = new Event(eventType, {
        bubbles: true,
        cancelable: true,
        composed: true,
      });
      element.dispatchEvent(event);
    }
  
    delay() {
      let delay = Math.random() * (this.maxDelay - this.minDelay) + this.minDelay;
  
      if (this.naturalMode) {
        // Add occasional longer pauses
        if (Math.random() < 0.1) {
          delay *= 2;
        }
  
        // Add slight variations
        delay += (Math.random() - 0.5) * 25;
      }
  
      return new Promise((resolve) => setTimeout(resolve, delay));
    }
  }