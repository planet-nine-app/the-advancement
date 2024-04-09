# Extensions

## Overview

These browser extensions cover up ads with images and animations based on a user's preference.
The cover up removes the ad from sight, but it also gives the user the ability to dismiss the ad through broader interaction, and not just small x's hidden in corners.
The flow of the extensions is fairly simple.

## Extension listening loop

The goal of the extension is to build the following pipeline:

* `findAds()`: returns an array of DOM elements that the extension has identified as ads.
* `replaceAds()`: covers up the ads with interactable elements
* `waitForInteraction()`: not so much a function as a set of listeners for interaction
* `onInteractionDo____()`: For the game interface this can be battling monsters, for other interfaces this can be something else inline with the experience, or just removing the ad directly.

In addition to the above, we'll want to setup a `MutationObserver` that watches for added DOM elements (16 nineum to whomever can turn a popup ad into a monster first!), and replaces them if they are ads.


