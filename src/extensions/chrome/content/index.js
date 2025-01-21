// TODO: FICUS!
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


console.log('index loading')

const detector = new InputDetector();
const simulator = new TypingSimulator({
  minDelay: 50,
  maxDelay: 150,
  naturalMode: true,
});

let histeresis = false;
// TODO: PageObserver class
// Also run detection when dynamic content is added
const observer = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    if (!histeresis && mutation.addedNodes.length) {
      histeresis = true;
      setTimeout(() => {
        histeresis = false;
        console.log('histeresis changed to ', histeresis);
      }, 1500);
      detector.detectFields();
    }
  }
});

observer.observe(document.body, {
  childList: true,
  subtree: true,
});

(() => {
  setTimeout(() => {
    // TODO:
    // console.log('adding script');
    // const script = document.createElement('script');
    // script.src = `http://127.0.0.1:5117/game-scene.js`;
    // script.src = `https://dev.savage.allyabase.com/game-scene.js`;
    // document.body.appendChild(script);

    // Run detection when page loads
    console.log('running detect fields');
    detector.detectFields();

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
