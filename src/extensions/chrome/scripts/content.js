// browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
//   if (message.action === 'decorateAds') {
//     const script = document.createElement('script');
//     const src = `https://dev.savage.allyabase.com/game-scene.js?decoration=${message.decoration}`;
//     console.log(src);
//     script.src = src;
//     console.log(script.src);
//     document.body.appendChild(script);

//     console.log(message.decoration);
//     console.log('foo');
//   }
// });

function searchNode(node) {
  // Check if node has shadow root
  const shadowRoot = node.shadowRoot;
  if (shadowRoot) {
    // Search within shadow DOM
    shadowRoot.querySelectorAll('input').forEach((input) => inputs.push(input));

    // Continue searching child shadow DOMs
    shadowRoot.querySelectorAll('*').forEach(searchNode);
  }

  // Search regular children
  node.querySelectorAll('*').forEach((child) => {
    if (child.shadowRoot) {
      searchNode(child);
    }
  });
}

function findInputsInShadowDOM(root) {
  const inputs = [];
  // Function to recursively search shadow DOMs
  searchNode(root);
  return inputs;
}

// Method 4: Check iframes (note: only works for same-origin iframes)
function findInputsInIframes() {
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

// content.js
function detectFields() {
  // Find all input fields on the page
  const inputs = document.getElementsByTagName('input');
  console.log('got ' + inputs.length + ' inputs');

  const inputsByQuerySelector = document.querySelectorAll('input');
  console.log('Method 2 - querySelectorAll:', inputsByQuerySelector.length);

  const shadowInputs = findInputsInShadowDOM(document.body);
  console.log('Method 3 - Shadow DOM inputs:', shadowInputs.length);

  //const iframeInputs = findInputsInIframes();
  //console.log('Method 4 - Iframe inputs:', iframeInputs.length);

  for (const input of inputs) {
    // Check if it's a password field
    if (input.type === 'password') {
      markField(input, 'password-field');
      continue;
    }
    // Check if it's an email field
    if (
      input.type === 'email' ||
      input.id.toLowerCase().includes('email') ||
      input.name.toLowerCase().includes('email')
    ) {
      markField(input, 'email-field');
      continue;
    }
    // Check for username/login fields
    if (isLoginField(input)) {
      markField(input, 'login-field');
    }
  }

  for (const input of shadowInputs) {
    console.log(input);
    // Check if it's a password field
    if (input.type === 'password') {
      console.log('found a password field');
      markField(input, 'password-field');
      continue;
    }

    // Check if it's an email field
    if (
      input.type === 'email' ||
      input.id.toLowerCase().includes('email') ||
      input.name.toLowerCase().includes('email')
    ) {
      markField(input, 'email-field');
      continue;
    }

    // Check for username/login fields
    if (isLoginField(input)) {
      console.log('found a log in field');
      markField(input, 'login-field');
    }
  }
}

function isLoginField(input) {
  const loginKeywords = ['user', 'username', 'login', 'account'];
  const fieldIdentifiers = [
    input.id.toLowerCase(),
    input.name.toLowerCase(),
    input.placeholder.toLowerCase(),
    input.getAttribute('aria-label')?.toLowerCase() || '',
  ];

  // Check if any of the field identifiers contain login keywords
  return loginKeywords.some((keyword) =>
    fieldIdentifiers.some((identifier) => identifier.includes(keyword))
  );
}

function markField(input, className) {
  // Add class for styling
  input.classList.add(className);

  // Add an icon container next to the input
  const iconContainer = document.createElement('div');
  iconContainer.className = 'password-manager-icon';
  input.parentNode.insertBefore(iconContainer, input.nextSibling);

  // Handle click on icon
  iconContainer.addEventListener('click', () => {
    // This is where you'd typically trigger your password manager
    console.log(`Clicked password manager icon for ${className}`);
  });
}

let histeresis = false;
// Also run detection when dynamic content is added
const observer = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    if (!histeresis && mutation.addedNodes.length) {
      histeresis = true;
      setTimeout(() => {
        histeresis = false;
        console.log('histeresis changed to ', histeresis);
      }, 1500);
      detectFields();
    }
  }
});

observer.observe(document.body, {
  childList: true,
  subtree: true,
});

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

// Usage Example:
const simulator = new TypingSimulator({
  minDelay: 50,
  maxDelay: 150,
  naturalMode: true,
});

(() => {
  setTimeout(() => {
    //         console.log('adding script');
    //         const script = document.createElement('script');
    ////         script.src = `http://127.0.0.1:5117/game-scene.js`;
    //         script.src = `https://dev.savage.allyabase.com/game-scene.js`;
    //         document.body.appendChild(script);
    // Run detection when page loads
    console.log('running detect fields');
    detectFields();

    document.addEventListener('click', async (event) => {
      // Get clicked element info
      const element = event.target;
      console.log(element);
      if (element.type === 'email') {
        element.focus();
        //element.value = "letstest@planetnineapp.com";
        const email = 'letstest@planetnineapp.com';
        await simulator.typeIntoElement(element, email);
        event.preventDefault();
      }
      if (element.type === 'password') {
        element.focus();
        //element.value = "Password1!";
        const password = 'Password1!';
        await simulator.typeIntoElement(element, password);
        event.preventDefault();
      }
    });
  }, 3000);
})();
