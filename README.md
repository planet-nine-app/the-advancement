# The Advancement

The Advancement is a repo with a mission to help a movement to improve the world.

## Overview

*The Advancement* is the *free* consumer-facing application of the [Planet Nine](www.planetnineapp.com) stack, built on top of [Sessionless], [MAGIC], and [teleportation].
It is a set of browser extensions paired with companion apps that allow users to navigate cyberspace without a shared credential like email, and without the need for passwords. 
Since it allows for a lot of behaviors, there's a bit of a smorgasbord (I suspect this word won't translate well, but many of its synonyms in English are idomatic. 
Maybe conglomeration?)
to choose from. 

Perhaps a bit of lore might help.

### Planet Nine is a spaceship

Benevolent aliens have been watching us from afar at their home on Planet Nine.
Unable to make physical contact, they waited patiently for humanity to create an online ecosystem where they could interact in small quantities with us via the pseudonymity of the internet.
These aliens belong to a galactic federation called the Advancement. 

There are four criteria to join the Advancement, and humanity is close, but not quite there so interaction is limited.
But there are other aliens out there with less than positive intentions. 
They have infiltrated our cyberspace, and polluted it nigh onto the unusability. 

They call themselves *the Advertisement* (we have been assured that any similarity to actual human words this name may have are purely coincidental quirks of galactic linguistics).

## How to battle the Advertisement

The first order of business in defending against the Advertisement is identifying them in the first place.
The Advancement provides browser extensions for doing just that. 
Most browsers are supported, if your browser of choice isn't on the list below, let us know.

#### Supported browsers

TODO

The extensions are geared towards a gaming experience, and a non-gaming experience, which users can opt into in the app.
Not everyone has fun the same way, so we wanted to keep it flexible.

#### The technical reason for these extensions

These extensions are ad ~blockers~ cover-uppers. 
With [Google's adoption of manifest v3][manifest-v3], ad blockers are losing their ability to rely on huge filter sets for blocking ad domains.
In that link you can read about one ad blockers attempt to continue without the filter rules, but we wanted to go an alternative route.

You see there's nothing stopping us in manifest v3 from just covering up ads with this harmless ficus.

![a picture of a pleasant ficus][ficus]

That might not seem like much, but it makes it so that if you tap *anywhere* on the ad, it just goes away.
Unless you're playing the game version, in which case you have to kill the ad.

Oh, and unlike ad blockers, doing it this way makes sure the content creator still gets paid. 

## But how will I know where to buy socks?

Well first of all, in addition to battling ads, the browser extension gives you the ability to use any MAGICal interaction built anywhere on the web.
That can be one click shopping, or just liking a blog post.

The second thing the Advancement provides is an entry point to a (the?) teleportal network.
The Advancement apps aren't meant to be true shopping experiences, though teleportation can enable that, but rather an aggregater for finding teleportals that might interest a user.
Check out the [teleportation][teleportation] repo for more on this.

## Contributing

For more on how this all works and how to get started, check out these companion docs.

| Dev          | UX          | Product     |
|--------------|-------------|-------------|
| [README-DEV] | [README-UX] | coming soon |

[README-DEV]: ./README-DEV.md
[README-UX]: ./README-UX.md

[Sessionless]: https://www.github.com/planet-nine-app/sessionless
[MAGIC]: https://www.github.com/planet-nine-app/MAGIC
[teleportation]: https://www.github.com/planet-nine-app/teleportation
[manifest-v3]: https://adguard.com/en/blog/chrome-manifest-v3-where-we-stand.html
[ficus]: https://github.com/planet-nine-app/the-advancement/blob/main/resources/ficus.jpg?raw=true

