# You are not a number

I started college in 2000.
There were a few mobile phones in the US back then (they were much more prevalent across the Pacific at that time), mostly in cars. 
I still remember the giant magnetized antenna that we plopped on top of our car just in case my parents needed to make a call on the side of the road.

I didn't have a car though, nor did I have a phone. 
I received calls like most of the rest of my dorm on a single handset hung from the wall, and dispatched to from the school's switchboard.
The phone would ring, someone would pick it up, and then shout out through the halls for whomever was supposed to answer. 

Nothing weird there at all.

This set up in 2000 just so happened to overlap with the advent of loyalty programs in retailers. 
To this day, I reckon you could probably take the main phone number of every college and university in the US, and use it to invoke any loyalty program at a retailer that was around back in 2000. 
I still use my school's number from time to time, and it always works. 

When I did get my first cell phone, I picked up a number in the 312 area of downtown Chicago because it was, and is cool. 
I will hold on to that number for all time.
I do not want to share it with Krogers and Piggly-Wigglies, and I don't need to be texted thirty times a day [because Facebook didn't want to pay some poor guy $10k for pestering him][fbvduguid].

What I want instead is to use my alma mater's number for everything, and leave my cool number for my cool friends.
But all those darn 'puters need me to be "me" so they send me a text for verification, and that can't go to that handset on the wall, and I don't live there anymore anyways so it doesn't work.

## You are not a handle

When I was maybe twelve or thirteen I "invented" a mythology. 
I guess to go back even further, when I was in grammar school, I exhausted the school library's entries on mythology. 
Pantheons, and the stories they create have been one of my many obsessions. 

My mythology was the pantheon of the Ephesians, a group I only knew existed from random bible passages since Wikipedia had not been invented yet. 
It included maybe twelve gods and goddesses, which fit into the sophisticated mind of a boy in the midst of puberty. 

I only remember a few, like Betedoun, the Ephesian god of war. 
He was responsible for sending a meteor to kill the dinosaurs, because he didn't think they were cool enough iirc. 

The leader of this divine group was Ramdatookisodom, Ephesian god of sexual tendencies. 
Before you ask, yes this name purposefully contains two not-so-veiled references to anal sex. 
To twelve year old Catholic me, some pagan deity tappin' everything around him was about as iconclastic as I could get. And since the Greeks' Zeus had already filled the role of banging everything that moves for procreation, I had to get a little creative.

It was right around this time that my Dad got us a Compuserve account, and I started going online. 
Stranger Danger being a thing even before the internet, I somehow had enough sense not to use my real name online, so when I had to identify myself, I used the name of one of my creations: Ramdatooki.
How's that for dodging the vulgarity filters :tap-forehead:.

A few years later when it became time to start getting in touch with colleges, I made the grown up decision to retire Ramdatooki as my handle, and update to something more sophisticated: zkpunk @ hotmail.com. 

Then gmail burst on the scene, and they nailed the false demand created by artificial constraint by keeping their service invite-only for years.
Through some connections to the more 31337 parts of the internet (4chan) I was able to score an invite, and secured the coveted firstnamelastname @ gmail.com.
Afaict there is only one other Zach Babb, and him and I seem to be around the same age, and we compete for signing up first for things. 
It's a friendly competition for me.
I hope he feels the same.

Then the socials came, where it mattered who you were to some (Facebook), and to others you could be pseudonymous (Twitter and Reddit).
Handles proliferated so much that services created just to link to your online personas were created and actually monetizable (according to [this][linktree] there are at least sixteen of these services around).

So who am I?

Ramdatooki, Zweibel (the german word for onion, but before I knew that I named myself after [T. Herman Zweibel][onion]), zkpunk, zachbabb at gmail/me/mac/icloud, zach at planetine/zkbabb, CurvatureTensor, planetnineisaspaceship...

Who are you?

## Interoperability

For historical reasons, phone numbers and email have a very useful property: interoperability.

Interoperability is an idea in electronic systems, which has largely been forgotten in our modern technical world, which is dominated by gigantic corporations looking to extract every nickel from your every digital move. 
The story of how we got there is worthy of a read, but I'll try and give the quick hits here.

Alexander Graham Bell invents the telephone in the late nineteenth century, and in true American fashion immediately establishes one of the most ruthless monopolistic corporations to ever exist: American Telephone and Telegraph Company (AT&T). 

In 1913, AT&T bought the other telecommunications monopoly Western Union, who had consolidated the telegraph system as the telephone took market share.
This was a little too close in time to Teddy Roosevelt's trust bustin' movement, and brought about the ire of the US government.

Faced with commupance from the federal government, AT&T negotiated an out of court settlement called the [Kingsbury Commission].
The Kingsbury Commission forced AT&T to divest itself from Western Union, and, important to our phone number story, forced them to allow smaller networks to connect to their long-distance infrastructure. 
This required AT&T and the other networks to start down the path on standardizing some sort of protocol for keeping their identifiers unique, and interoperable.

In the sixties, Thomas Carter invented the Carterfone, a device which was essentially a walkey-talkey connected to a phone receiver so folks could talk via radio to other folks on a phone.
AT&T magnanimously told Carter to pound sand when he tried to use their network.
This led the FCC to tell AT&T that not only did they have to allow Carter, but they had to allow anyone to connect to their network so long as it didn't harm the network. 

By the time Carter's case reached the FCC, the agency had started to recognize the need for computers to connect to each other.
They used the carterfone case as an opportunity to revisit AT&T's ability to block devices from connecting to their network.
AT&T was faced with a similar reality. 
Carter's device was little more than a nuisance, but the rapid rise of computers, and the fact that their modems were largely supplied by AT&T's Bell Labs, meant allowing firms to connect to their network could be more lucrative than maintaining their monopoly. 

I had to track down a picture of Thomas Carter to see what this legend looked like.
I was not disappointed.

![Thomas Carter looks like a character out of Dynasty with a ten gallon hat, bolo tie, mutton chops, and amber aviators](./tom-carter.jpg)

It doesn't get much more American than some guy jury-rigging a way for those in the oil fields of Texas to phone home to let their people know they haven't blown up yet that day taking on the largest company in the country, and winning so that it can ultimately make more money.

### Multi-user

These newfangled computers that were using AT&T's network to talk to each other had a problem though. 
Unlike humans that have distinct voices, the machines all talked the same. 
So to have any reasonable notion of who was behind the machine, we had to introduce _auth_.

Nowadays there are a lot of auth protocols, but back in those days it was good ol' username and password.
You need both because passwords can't be unique, and usernames don't need to be secret.

And thus as Narsil was sundered as it severed the ring from Sauron's hand, the interoperability of this original network was broken. 

## America goes online

There's an interesting problem in statistics called the [birthday problem][birthday].
It shows that you only need 23 people chosen at random to have a greater than 50% chance of two of them having the same birthday. 
The reason for this comes down to some simple math. 

Probabilities are usually represented as fractions less than one.
In this case, if we had only two people the probability that they would _not_ have the same birthday is 364/365 since there are 364 days the second person could be born on that would be different than the first person's birthday. 
The third person would then have a probability of 363/365 instead because now there are two different days that people have birthdays on. 
You continue ticking down the numerator for each person added to the test.

To find the total probability of this series of probabilities, you just multiply them all together, and when you do that for 23 people you get the probability that two people will have the same birthday just over 50%. 

What does this have to do with the price of beans in Boston?

Well that whole username and password thing was working just fine for computers connecting to things, but as the number of people grew, people started birthday probleming their desired usernames. 
There are somewhere around 20,000 common six-letter words in English.
You know how many people need to be selecting words before there's a 50% chance of two people selecting the same one?

167.

Those of you who are known as ponies724 know what I'm talking about.

This wasn't so bad when there was just one thing to sign into, but as places with usernames proliferated you had to deal with someone snaking you on ponies724.
Then you'd have to _remember_ not only your password, but which incarnation of your username to use.
Zweibel is German of onion, but it's also two-bell.
So when it's taken I use Dreibel (three-bell).
There's even one place where I'm Vierbel (four-bell).
I don't remember where that place is, but I remember it's out there somewhere. 

So the online folks went searching for a "username" that was unique to the user so they could carry them around with them. 
Something cheap, and easy to give to anyone. 
Maybe something where ponies724 could just be ponies alongside other ponies. 
Something like email.

### You've got mail

Listen, I was there.
Hearing the digitized low-fi voice of [Elwood Edwards][elwood] [^2] was awesome, and the first few emails you got were so novel and cool.
But soon there would be such a deluge of emails that had to be forwarded to ten friends to avert disaster, that it was impossible to keep up. 
Obviously those were all spam since nothing bad has happened since the mid 90s...

Email was then, and mostly still is now, the simplest open and interoperable thing that exists in cyberspace.

![Walter from the Big Lebowsky saying "I can get you a toe by 3pm," but toe is crossed out and says "email server" instead](./walter.jpg)

All you need is a domain and a computer, and you can set up an email server.
Now if you lookup how to do this you'll find a lot of things telling you not to, and the reason for that is that nowadays there're a ton of hoops to jump through to make it so that your emails actually go through.
But I can't really tell if that's to keep the spam out, or to keep the people beholden to the email giants who are gatekeeping this in the first place.
I mean, how do you feel they're doing at keeping out spam?

Once the internet got going in full swing, AOL started to lose its shine, and people started looking to alternatives for email. 
Hotmail, and Yahoo were the major players of the late nineties, and a lot of people jumped over.
There were other factors of course, but the incredible flood of users claiming free emails is partly what fueled the dotcom bubble that saw Yahoo with a market valuation of $125 billion, and made Microsoft the highest market valued company in the world (do you see a trend here?).

Then in 2000 the bubble would pop, and as so often happens the human phoenix of innovation would rise from the ashes.
And as so doubly often happens, that phoenix would exploit the masses for profit.

## Ahoy matey

While the business world of the dotcom boom was preparing to burst, consumers were starting to learn that while waiting for an image to load on the internet was still slow, once it was on your machine, things were fast. 
Users started branching out into other media like music, and certainly not pornographic videos. 
The likes of Napster, Limewire, Kazaa, and people just torrenting things left and right, was a One Piece-level deployment of piracy unseen before on Earth.

And suddenly firstname.lastname@companywhohasmycreditcard.com wasn't such a great identifier.

### Don't be evil

It's so hard some times to remember that the world may have once been any way other than it is now.
In the early aughts the internet wasn't the ad-infested garbage pile it is now.[^3]

Back in the mid-nineties if you wanted to share a website with someone, you wrote down its url on a piece of paper, and handed it to them in class. 
I remember vividly reading and copying the urlencoded equivalent of antidisestablishmentarianism into netscape's url bar, and hoping it didn't land me somewhere weird. 
To ammeliorate this pain for web denizens, various solutions arrived.
One of these, was the humble search engine, and the best ones around were Yahoo, Google, AltaVista, and Ask Jeeves. 

Thing is, Google was still private at the time, while the others were all public. 
So when the dotcom bubble burst and imploded the other three's valuations, Google was comparitively unscathed.

Now Google was still private for the same the bubble burst: lots of users, but no way to monetize them.
All those companies that had just evaporated from the bubble bursting had the silly notion that people would "pay" for the services they provided. 
Google wasn't the first of course, but they were certainly the ones who went HAM on the idea of monetizing user behavior through advertising.

They started by putting ads on their search results page, but in 2003 they released the real money maker. 
Google's ad sense platform would let content creators drop some small snippets of code on their sites that would serve ads to users based on what the users search history. 
Serving _relevant_ ads to users improved engagement, which was more profitable for Google, the company advertising, and the content creator...well at least at first.

Once the money faucet was turned on, Google's thirst for information became insatiable. 
Their motto, "Don't be evil" let everyone know just how innocuous their data collection was.
Their plan was to release free services for the benefit of humanity, and for their troubles they'd just collect some data here and there.

In 2004, less than twelve months after releasing ad sense, they released the ultimate money making service: gmail.

By 2004, Yahoo, and Hotmail emails were decidedly uncool. 
And forget about it if you were still using aol.
In fact most tech was pretty uncool since it put a bunch of people out of work just a few years before.

There was one cool thing though.
In 2001 the soon to be largest company in the world had figured out a device for people to put all that pirated music on, and somehow convinced the world that if your headphones weren't white, you weren't even really listening to music. 

Now the iPod was cool in large part because it was exclusive, and it was exclusive the old-fashioned way--Apple made it prohibitively expensive.
Exclusivity in tech was a novel concept from the dotcom days of everyone and their brother being able to sign up for everything. 
So when Google launched gmail as a "beta" that people had to be invited to, it created exclusivity, and suddenly the decades old tech of email, long rendered useless by spam and garbage, was somehow cool enough again for everyone to switch.

Today about a quarter of all humans have a gmail account. 
I'll leave it to you how they're living up to their motto.[^4]

So great, Google corners the market on one of the universally held identifiers out there. 
The other, of course, is your phone number. 
Seems fitting your next move would be to acquire a phone company right?

In 2005 Google acquired Android to do just that.

## Humans are social animals right?

Somewhere in the early aughts, my friend bought the domain mauledbytigers.com and set up a message board. 
The only significant world event I can remember circulating on the board was the Mr. Hands video, an event that if you do not know about I highly suggest you do not look up.[^5]
That event happened in 2005, so that gives you the year.

I was known as Lazer back in those days, and part of the Chicago music scene. 
It was a big scene, and my contribution largely insignificant, but I did meet a lot of people, and there are more than a few who know me as Lazer to this day.
The problem, of course, was how to keep up with all of these friends. 

Luckily tech had the answer again!

In 2002, an enterprising Canadian named Jonathan Abrams started work on a new social network.
In early 2003 he launched Friendster. 
Friendster introduced a new problem to internet--hyper scaling. 
AOL had topped off around three million users.
A decade later, Friendster would hit 100 million users, and making things work for those many people was a bit of a challenge.

### A thumb on the scale

Friendster was the first, but the two that came next, at least in the states, were the real players to define the social networking era. 
One lives on in my mind as a symbol of freedom and awesomeness, and the other is possibly the most damaging entity on the planet.
Let's start with the former.

![The legendary picture of Tom from MySpace](./tom.jpg)

If you're over a certain age, this image needs no introduction.
When you signed up for MySpace, this was your first friend: Tom from MySpace.
As I write this, tech billionaires are capitulating to right-wing hostility, and endeavoring to make life as hard as possible for everyone other than themselves.
So the fact that Tom sold MySpace for $500 million+, and then just kind of disappeared, is really refreshing.

After Friendster, and MySpace, the Winklevoss Twins had the genius idea of ripping off those websites, but making it exclusive to Harvard students so as to separate themselves from the dirty plebes around them.
They turned to the obviously talented programmer of the website they used to drunkenly rate coeds on campus, and together that braintrust created Facebook.[^6]

A lot has been written on these first hyperscaled social networks, and why Facebook won when the others didn't.
Like with anything else with pontificating pundits, most of it is reductive, and kind of lame.
Let me give you the inside scoop.

MySpace had this amazing feature where you could grab snippets of web code, and paste it onto your home page. 
If you wanted your page to be bubblegum pink with sparkles around the text, and rainbows raining down, all you had to do was paste in some text.
And that's how it should be, because, after all, _it was your fucking space._

From a performance standpoint, this made everything load slow as molasses, and for anyone who hadn't been online ten years ago, made the site pretty unusable. 
Us twenty-somethings were the target demographic, and we loved it, but it left the younger folk kind of uninterested (not that big of a deal).
For the older folk though it left Facebook with the perfect opportunity.

Somebody at Facebook had the critical insight that for most people, and definitely anyone who has left the devil may care time of their lives, their friends just weren't all that interesting.
Instead, using their friends to target shared interests in a timeline feed kept people more engaged. 
And the timeline feed loaded fast, and always had good stuff.

In the world of digital monetization there's a big difference between people in their mid-twenties, and people over thirty-five because the latter has money, and the former doesn't. 

For a brief moment in time, everyone was touching code just a bit to make things fun on the internet. 
It was beautiful, and important, and that shard of collective creativity was shattered by the most boring gray with blue accents bs like the time thieves in Momo. 

Of course, now we know who came out on top--a company who has single-handedly advanced disinformation and destructive rabbit holes in the name of ad-based profit moreso than any entity in history. 

Tom, I wish you the best, but I wish you'd never left.

## OAuth, and Web 2.0

In 2006 a relatively minor player in this narrative joined the party. 
Twitter quickly made waves because it was, by the standards of the time, open. 
If you were cool, people with twitter could tweet right from your site.

Eventually Twitter's openness ran into the problem that every open thing does, which is that bandits show up to shut down the party.
In this case, the trouble was that people entering their Twitter password into random websites wasn't the best security practice. 

To save the people from themselves, some very smart got together and came up with a protocol called OAuth.
It's successor OAuth2.0 would become as close to singularly dominant as software gets, being the method used by Google, Meta, Microsoft, and thus anything that uses them for authentication. 
The original [OAuth rfc][oauth] is a pithy 38 pages, and well worth the read if you want to know more about auth.

So what is oauth? 
Well basically it says that you cannot be trusted to sign into things, so instead you'll just sign in to things you trust like Google and/or Meta, and they'll handle, out of the goodness of their hearts, the hard part of keeping you safe from the internet bandits. 
For their troubles, they'll get an ongoing list of every service you use from now until the end of time. 

Sounds like an even trade right?

### The smart phone

In January of 2007, Steve Jobs stepped onto the Apple stage in his trademark black turtleneck, and told the world that Apple had put an iPod in a phone with the internet. 
Missing the opportunity to call it the phoneputer, the iPhone would launch that summer starting the smart phone on the trajectory towards arguably the most important product category on Earth. 
The first android devices would launch the next year. 

In 2005, only about 10-15% on humans owned computers, and none of those who did could take them _everywhere_ and use them _all the gosh darn time._
Fifteen years later, half of all humans owned computers, with almost all of that half owning a tiny computer that was coming with them everywhere they go. 
And pretty much all of them were signed in to Google and Facebook. 

### The cloud

2007 was an auspicious year for humanity's story with computers.
A plucky book selling company named Amazon had grown to a large enough size that they were having trouble keeping everyone's carts up to date. 
To address this, they built a system called Dynamo (now branded as DynamoDB), and presented it to the world in [a paper][dynamo] at an ACM conference in the fall. 

It was a watershed moment in distributed systems design because it allowed for the system to run on a large number of (relatively) cheap machines, as opposed to the hugely expensive enterprise systems available at the time. 
People started wondering if they could lease time on these servers, and AWS was born. 

The second iPhone, and the nascent android phones came with app stores. 
This significantly lowered the barrier of entry for developers to reach users, while also providing a rapidly growing userbase eager to use their crispy new devices.
Speed was the name of the game, and if app creators could offload the boring backend stuff to someone as prestegious as Amazon, what was a few bucks a month?

This setup for backend stuff was collectively called the Cloud, and if you were around in 06 and 07 you heard it ad nauseum, but no one could explain what the heck the Cloud was.
So allow me.

The Cloud meant that instead of buying and owning the computer(s) your software ran on, you could rent computers from someone else. 
Whether that was good or bad at the time I think could be discussed, but it certainly doesn't seem great now that two of the three largest cloud platforms are run by the world's largest advertiser, and the eCommerce shop that sells you all the garbage you get advertised to about.

This was nearly twenty years ago. 
Moore's Law suggests that machines are 1,000 times more powerful today. 
Wright's Law suggests that that should correlate to a 90% decrease in price. 

Do you feel like things in the cloud are 90% cheaper?

## Hey where'd my money go?

In 2008, no...let's go back a bit.

Banks hold your money, and rather than charging you for the privelage of holding it, they re-invest it and make money off of that.
Now if they invest in something nice and safe like a mortgage that someone can afford, your money's safe, and the bank makes its income.
But if the bank goes and lays your money on red, and it spins black, you're money's gone.
That might not be a huge deal if the bank can make that money back before you ask for it, but if it doesn't that's a problem.

In the 1920s, the bankers invested heavily in a stock market that could seemingly do no wrong.
Then in 1929 it all came crashing down, and plunged the country into the Great Depression.

For their role in causing the trouble, the banks were "broken up" with an act of congress known as Glass-Steagall. 
Glass-Steagall said, "you can take people's money, or you can invest in risky bullshit, but you can't do both."

Things went pretty well with respect to banks not causing global financial collapse for the rest of the twentieth century, but all good things come to an end. 
In 1999 pretty much everyone in DC was ready to let the banks go back to the roulette table, and Glass-Steagall was repealed.

Now the thing about money is that a sudden increase in its supply doesn't make more things to purchase appear out of thin air. 
Instead the increased demand causes the price of the existing assets to rise.
If they rise fast enough, this is called a bubble. 

Like the dotcom bubble that happened in, _checks notes_, 2001.

Luckily everyone learned their lesson from that bubble burst, and decided to invest in the much safer realm of real estate mortgages. 
The same increased demand that caused the dotcom bubble, had a different effect in real estate where the price of the investment vehicles was much less volatile.
In order to meet the increased demand, lenders had to create more investment vehicles.
Part of this was done by creating convoluted derivatives of derivatives of investments, and part of this was done just by giving people more mortgages.

When you combine these two things you end up with assets that are both risky, and impossible to assess the risk of. 
In September of 2008, a large investment bank, Lehman Brothers, filed for bankruptcy. 
When they did it "broke the buck," a term used when a money market fund's net asset value falls below $1 per share.[^8]

All hell broke loose, and if you were around back then, it felt like the sky was falling.

### Like a p5x we rise

Now the nice thing about the whole housing crisis thing is that it only really hurt the folks who shouldn't have been getting mortgages in the first place, the hard working people dependent on those people, the communities those people lived in, and was in no way bias along racial lines (this is of course not nice at all, but not being snarky makes it too depressing).
The people and banks with plenty of money were largely fine. 

This is because when you give someone a mortgage you actually own the property the mortgage is for.
So when they can't pay, you foreclose on them, and now you own the house.
Sure you take a little hit on the house's value, but you're a bank so you know that value's going to come back up.
After all, there're a bunch of people who need housing now.

But now everyone needed a new thing to invest in. 
Enter Andreessen Horowitz aka a16z, and the VCs.

I asked ClaudeAI what the difference between the VCs, and the dotcom investors are, and it gave me some nonsense about how companies are more proven these days, and blah blah blah. 
It's the same song and dance: too much money chasing too little value. 

Sometimes in life you've just got to hang in there.
Friendster and MySpace went home too early, leaving Facebook hanging around the DJ Booth when the after hours crowd poured in.
The phoneputers became the perfect device for all those folks without houses, and since people get bored they were hungry for something to do on the machines. 
All the doom scrollers needed to scale was piles of money, and since nothing else was appetizing at the time, the VC-era took off.

## What if we just got rid of money?

Little more than a month after Lehman Brothers broke the buck, Satoshi Nakamoto, who may or may not exist, published a whitepaper entitled ["Bitcoin: A Peer-to-Peer Electronic Cash System."][bitcoin]
In it he described a system that used asymmetric cryptography, and a new kind of datastore called a blockchain to allow for a transaction system.
In the system, transaction values would be represented by a fungible token called a bitcoin. 

Chances are you've heard of this system.

Bitcoin, and the crypto category it spawned will weave in and out of this story, but this isn't a blog about crypto. 
I introduce it here because Satoshi introduced a third identifier for people: the public key. 

## More bubble?

Now you may be wondering what, if anything, happened to make it so that the bubbles of 2001 and 2008 didn't continue to happen throughout the 2010's.
Well, it turns out there was a crucial asset class that had long gone ignored in the hyper-capitalist United States. 

In 2010, the US Supreme Court passed the Citizens United decision, which decided that the first amendment considered money to be speech, and that there could be no limit on political contributions from institutions.
And you know... politics have been totally cool in the US ever since.

Wherever you stand politically, I hope you can at least recognize the disparity between the US, and other countries' approaches to online protections. 
The EU's General Data Protection Regulation (GDPR) is the most notable. 
It's what's responsible for those giant cookie banners that show up everywhere on the web.

Without the GDPR, everyone would get to track you without you being none the wiser--just like the gigantocorps would like.
But the GDPR's reach across the pond is limited, and with politics being the cash-hungry beast it is, the gigantocorps coffers wield non-negligible influence around here, and would regardless of who's in charge.
We'll have to wait about a decade for where this really reers its head, but if you're already feeling uneasy, I wouldn't blame you.

## Two-factorin'

So it's the late aughts, you're Google, you have a near monopoly on where people are logging in because they're all using your email, and now, thanks to the benevolence of your Android operating system, you know everyone's phone numbers, and can even construct a social graph similar to Facebook's via access to people's contacts.
There's just one rub: that darn iPhone's around, and Apple doesn't want to share.

So the braintrust came up with the genius idea of making you're already secure accounts _even more secure_ by adding two-factor authentication via sms.
Google released this 2FA in 2011 because the world was clearly unable to function without it up until that point.

The rise of two-factor authentication via sms provides an important lesson on how additional complexity often leads to _less_ security, and not more. 
Whenever you deal with consumers who might be miffed if you lose all their data, you need to provide a way for them to recover accounts. 
Most of the time you do that via email. 
But what do you do if the account they care about is email?

Google, and others with 2FA, said, "no problem, we'll just use your phone number."
But then the question became what if you had your phone stolen, or you lost it.
Well then the security of 2FA would be dependent on the carriers' ability to protect your interests.

Now I've worked retail, and I have the utmost respect for people who do, and their capabilities.
I do not have much faith in the corporations who pay these good people a pittance to be on their frontline.
A company who does that, probably isn't going to put much thought into making sure you're you when you go to replace your phone.

The vulnerability here wasn't exposed for a while because, despite how you might feel, the Harry Potter fanfic in your google drive isn't all that valuable.
But when crypto became valuable enough for bandits to want to steal, they started stealing people's phone numbers by just going into stores and requesting sim cards as that person in what's called a [SIM swap attack][sim]. 

### Where you at?

Now you might be wondering what's the big deal with phone numbers in the first place. 
If you're old like me you might remember a time when we just published all our phone numbers in a book, with our name and addresses, and then gave everyone that book for free.
If you're not old like me I'd be curious what your thoughts are on that practice.

Have you ever wondered what the cell in cellular refers to? 
I hadn't until I started researching this whole rigamarole. 

Our phones communicate wirelessly, and since they're small, the distance that they can communicate at is fairly limited.
So to accommodate them, cell towers are setup every so often around the Earth for them to connect to.
These towers define a cell, and as you travel the Earth your phone switches from tower to tower as you move from cell to cell.

Now the telecomms companies aren't supposed to provide this data to anyone, but [of course they do][investigation], because when they got caught the FCC fined them a whole $200 million, a little under one dollar for everyone whose location they were selling.
But even if the telecomms didn't sell this data, your phone would report it back anyways through background networking tasks, or just plain old checking your phone at a red light.

Now location wouldn't be that big of an idea I guess if you didn't have at your disposal the largest database of location-based info on Earth. 
But of course the company doing all of this _was_ the company with the largest database of location-based info on Earth. Almost as if this whole getcha phone to getcha location was planned or something.

And what do you do with all this info?
Well you know that creepy thing that happens sometimes where you were talking about a thing with a friend and then you start getting ads for it? 
Well I have no doubt that sometimes you're being listened to, but most of the time what's happening is that one of you googles that thing, and then because google (and the rest of the gigantocorps for that matter) know that you were with that person, the ad netwroks serve you an ad about that thing too. 

## The boob tube

The television was invented in the 1920s.
Its history is long, and interesting, but out of scope for this doc. 
Except for one part. 

In 1941, before a sunny baseball game between the Brooklyn Dodgers, and the Philadelphia Phillies, a brief ad, the first television ad in the US aired. 
It cost $9 (close to $200 today) and aired to about 4,000 people. 
I have no doubt that this would have opened the flood gates regardless of what was going on in the world, but as it would happen 1941 was a rather auspicious year.

On December 7th of 1941, the Japanese attacked Pearl Harbor launching the United States into a full participant in World War II. 
To produce the kind of war-time provisions needed to fight that war, the government rationed a bunch of things.
Pretty much any large manufacturer was rationed, or flat out bought up, by the government.

For their troubles, the government set up the War Advertising Council.
The council's mandate was to provide free or cheap advertising for these harmed businesses while also supporting the war effort. 
[You can see some of the sweet ads here][oh-the-forties-were-a-looong-time-ago].

The WAC, an auspicious acronym given their mandate, was essentially the propaganda engine for the war effort, but because it was American, it made sure to sell tires alongside white picket fences, and obedient dames for when you got home.

When the war ended, the US stood as pretty much the only industrial power not bombed significantly, and a bunch of twenty-somethings came home with cash in their pockets.
The WAC disbanded, companies started producing again, and all they had to do was replace uniforms with suits, and they had their advertising ready to go. 
Print, film, and radio were all known mediums, but one of the things all those soldiers were buying were tvs--the perfect new medium for companies looking to reach an audience. 

It didn't take long before one of the largest marketing firms in the country ACNielsen realized that advertisers would benefit from, and thus pay them for information about who was watching what.
To do this they went to a couple of towns in America, and had the good people there write down what shows they were watching. 
And this is how tv ratings worked for almost four decades, until cable joined the party.

With cable, Nielsen was able to make a box.
You could attach this box in between your cable and your tv, and it would record what you were watching for Nielsen.
For your troubles, Nielsen would pay you a couple bucks, and sell your demographic data and viewing habits for a bit more than those couple of bucks.

### The searchlights

I was maybe twelve years old when the family was driving home from some dinner at some American suburban culinary stalwart, when we saw the hollywood spotlights scanning the skies near our house. 
Intrigued, we ventured over to the grand opening of the hottest chain sweeping the nation in in the first half of the nineties: Blockbuster Video. 
We of course had a perfectly fine video rental shop we already frequented, but Blockbuster was new and shiny, and closer to home, so we were hooked.

Blockbuster had a novel instrument for us--the Blockbuster card. 
At our local rental shop, you'd just leave your name, and they'd put you into their ancient phosphorescent green machine, and you'd be on your way.
Blockbuster had UPCs and scanners, and a laminated wallet-stuffer you could use to show people you were cool.

Prior to Blockbuster, there were some retailers which collected customer data into a nationwide database, but nothing that came close to Blockbuster's reach. 
At its peak, Blockbuster had close to a fifth of the US as members, all just givin' away when they rented War of the Roses four weekends in a row to get through a breakup.

Of course Blockbuster would blunder the world's transition from physicial to digital media, and Netflix would pick up the ball. 
What Blockbuster was doing with your rental habits seems lost to the ages, but Netflix has partnered with Nielsen to provide that information at the very least. 

And there you go, your tv too, just spying on you for advertisers to sell you more stuff.

## 1984 was a typo

By 2014, the tech giant advertisers had the apparatus in place to effectively spy on everyone everywhere that they did anything digitally more or less anywhere on Earth.
And out of their benevolence they used this information to create, and rapidly deliver, an unprecedented decade of creativity and techno-social progress never before seen.

That's what happened right?[^9]

Well if these assholes weren't making things that people wanted, what the heck were they doing?

## The algorithm

Do you remember those math class games in grade school where'd you pick a number, and then do some math, and it'd always come out to the same number regardless of what you pickerd?
Claude tells me this is a classic one:

* Pick any number (1-99)

* Add 7

* Multiply by 2

* Subtract 4

* Divide by 2

* Subtract your original number

This will always come out to five. 

When you get to college and take some computer science courses, eventually you come across algorithms. 
Like many computer science terms, there isn't a singular exact definition of what an algorithm is, but it's more or less this math game.
There is some number of steps that take some input, and always produces the same output. 

It has long been known that content displayed to users on social media platforms can change based on the user's behavior and likes and dislikes. 
In the past few years people have been talking about The Algorithm, as in the underlying process by which these platforms choose to display you content. 
Whether it's a singular algorithm, or an amalgamation is immaterial.
But what it's trying to do isn't.
Let's see if we can figure that out.

* Learn about a user

* Show them content they like

* They return to your platform because its nice

Seems reasonable. 
How about this?

* Learn about a user

* Show them content they like

* They return to your platform because its nice

* Encourage them to invite their friends

* Show their friends content that they all like

* Everyone's just hanging with their friends having a good time

Ok cool, everything seems good here, but of course eventually you're going to have to pay the servers hosting all of this content. 
So you monetize:

* Learn about a user

* Show them content they like

* Throw in some ads, but not too many

* They return to your platform because its nice

* Encourage them to invite their friends

* Show their friends content that they all like

* Throw in some ads, but not too many

* Everyone's just hanging with their friends having a good time

But of course, usage growth stalls, competition moves in, but shareholders need that growth. So you start messing with The Algorithm to get the results you want.
Eventually, the ads are the purpose of the algorithm:

* Learn about a user
 
* Show them content they like

* Throw in lots of ads

* They return to your platform because its nice

* Encourage them to invite their friends

* Show their friends content that they all like

* Throw in lots of ads

* Everyone's just hanging with their friends having a good time

* Keep people watching AAAADDDDDSSSSS!!!!

Nothing to see here, just some good ol' fashioned capitalism right? 
But then they hire an intern who goes ahead and makes just one tiny tweak to The Algorithm, see if you can catch it:

* Learn about a user

* Show them content they like

* Throw in lots of ads

* They return to your platform because its nice

* Encourage them to invite their friends

* Show their friends content that they all like

* Throw in lots of ads

* Everyone's just hanging with their friends having a good time

* Keep people watching political AAAADDDDDSSSSS!!!!

Did you catch it? 
Some folks didn't. 
How about a few months later when that intern goes ahead and sprinkles their flavoring a bit more:

* Learn about a user

* Show them political content they like

* Throw in lots of ads

* They return to your platform because its nice

* Encourage them to invite their friends

* Show their friends political content that they all like

* Throw in lots of ads

* Everyone's just hanging with their friends having a good time

* Keep people watching political AAAADDDDDSSSSS!!!!

Now the problem with this algorithm is that it comes down to whether you agree with the intern or not. 
And that's what makes undoing this shit so hard, because the whole algorithm is designed to make you feel good when you are aligned with it. 
So when someone who you perceive as being different from you comes for your darlings saying they're poisoned, it causes defensiveness, and fear.
The sides become entrenched, and the surveilance apparatus grows in power.

And that's why we're not going to try to do it that way.
Instead, I hope that regardless of political affiliation, and the necessity of surveilance in the rule of law, we can agree that with respect to corporations, people should always have the option to opt out. 
Opting out's just such a gnarly mess, that we have to get creative. 

## Getting creative

A surprising amount of the way I interpret the world comes from playing the original Final Fantasy when I was like six or seven lol.
When you start that game, you select four characters, and you give them a name. 
Your entry point into this world is this ontological decision about who you are, and who is coming along with you. 

Voice acting ruined this subtle yet powerful notion. 
_I_ was no longer the protagonist in my game, and my party was no longer my friends. 
I was just a passenger on a ride packaged up for me in design studios around the world--still fun to be sure, but missing just that little something.

I talked much earlier about handles, and how I've had different ones over the years. 
In games like these I could have the same handle, and be different things. 
Zach the fighter, Zach the paladin, and Zach the, ahem, treasure hunter, each had different incredible adventures. 

The whole of the digital realm I could be whomever or whatever I wanted.
Companies could give me structure to fit myself into, or some lack of structure to explore.
The notion that you had to be yourself was so anathema that you would never even dream of sharing personal information in some random chat room. 

You'd drop into a chat room, get bombarded with "asl," and only fools would actually drop the correct answers to those questions. 
And in this way the creepy old men would self-select by "being" totally legal teen women who would go off together and have criminally unsatisfying lesbian cybersex. 

And the rest of us who weren't there because nudey pics still downloaded too slowly were the most interesting group of philosophers, scientists, inventors, artists, and writers ever assembled--it didn't matter that in real life we were whatever we were, and we didn't have to share our phone numbers to get there.
That's what the internet's for goshdarnit!

I want this back.

### The frontlines

In 2018, the EU passed the first real protections against the incredible spying apparatus the internet had become.
Probably the most noticable thing it did from a day-to-day perspective is that it makes websites which use cookies to track you have to disclose that they do so, and make them opt-in.
How many of y'all know how that works, and what you should opt-in to?
How many of you care to learn?

I'll give you two guesses as to who the biggest provider of cookie-based tracking is.

And here's how that tracking works. 
Google and Meta each give you a number.
Every time you log in to anything anywhere, you're given another number.

Then Google and Meta spend billions and billions of dollars making sure that they can tie the second number to the first. 
Then that first number is given some set of lifetime-values: the amount of money you're likely to spend based on your demographics, and your personality, all of which they know because they've been spying on you since the first time your mouse clicked login.

And somewhere, deep in the bowels of a network you're not invited to, they've added those two numbers together, and probably handed it off to all the governments that they regularly break the regulations of with impunity. 
I don't know what this number looks like, but in computers we have these things called universal unique identifiers (UUIDs), and they look like this: C6B20666-6AF4-4DF6-AB57-8F47A429D415. 

And that's what you and I are: C6B20666-6AF4-4DF6-AB57-8F47A429D415, just a hexadecimal number, followed around the internet by the largest corporations the Earth has ever known. 

Against this there are browsers blocking trackers like Firefox and even Safari, browser extensions fighting back like Privacy Badger and ClearURLs, platforms like signal and matrix for messaging, ad blockers like UBlock, DuckDuckGo for search, Protonmail for email, OpenStreetMap for maps, self-hosted cloud apps you can run in your house. 

These are the projects on the frontlines of this battle. 
Please check them out and give them your support.

### Fuckin' nazis

My dad's favorite movie is Patton. 
The movie begins with the incomporable George C. Scott's rendition of the titular general's speech to the third army in advance of the allied invasion of France. 
It's a good speech.

I remember watching it as a kid, one of those memories that's not really continuous with anything else, just some moment you remember for some reason or another.
There's a part where Scott's Patton says, "we're going to hold them by the nose, and kick them in the ass!" and my dad turned to me and said, "that's really what he did. His army would hold the front, and then attack the rear."

And so when the richest man on Earth threw a nazi salute up at the inauguration of the president that my dad tried to overthrow the government for it hit a bit personally.
My dad may have forgotten about the war that his dad fought in, but hearing about it left an impression on me.

So I figured what worked for Patton, might just work for me, and I got to work on the kick them in the ass part.

The specifics of the work are far too much to go into here, but the gist of it is this: build a system that

a) allows for monetization that isn't ad-based
b) allow users to proliferate their digital identities
c) mess with existing notions of identity

For now, I'll just ask that you take my word on a). 
It's obviously quite important, but again too big for here.

For b) we already know the model, but we have a lot more computing horsepower to go along with it.
You just bring back the handle--Ramdatooki, zweibel, and zkpunk can all live again. 
And why don't we throw in anonymity alongside pseudonymity. 

Of course websites aren't just going to switch to handles overnight, and remembering which ones you used where is impossible, so what if we treated it like a password manager?
And what if we setup a mail server that gave everyone random site-by-site emails that did nothing other than confirm themselves when users signed up for and in to things?
And then, what if we just signed up a few extra users every time you went somewhere, and poked around at some things?

And thinking about that, what if we took all the accounts on social media that people are abandoning because of the nazi thing, and start handing them to people who turn them into zombie bots, and all of a sudden uuids like C6B20666-6AF4-4DF6-AB57-8F47A429D415 started being into different things? 
What happens to the advertising platforms when all of the spying that they rely on suddenly becomes junk, _not_ because we undid 30 years and trillions of dollars worth of spying infrastructure, but because the number that they think we are just isn't us anymore?

## You are not a number

In the sixties Patrick McGoohan wrote, directed, and starred in an incredible 17 episode show called The Prisoner.
In it McGoohan plays a spy who attempts to retire, and for doing so is sent to a mysterious island as a prisoner. 
The opening of the show always features a shadowy character named Number 2 who tells McGoohan that they need information, and that McGoohan is Number Six.
To this, McGoohan responds:

"I am not a number, I am a free man!"

Turning human beings into numbers is a dehumanizing act akin to calling them animals or statistics. 
It makes it easier to convince yourself that you're doing the right thing, because there's no way all those poeple are going to figure it out. 
After all, they were dumb enough to become numbers.



 








[fbvduguid]: https://en.wikipedia.org/wiki/Facebook,_Inc._v._Duguid
[linktree]: https://www.adamenfroy.com/linktree-alternatives
[onion]: https://theonion.com/t-herman-zweibel-in-memoriam-1819583647/
[birthday]: https://en.wikipedia.org/wiki/Birthday_problem
[elwood]: https://en.wikipedia.org/wiki/Elwood_Edwards
[oauth]: https://www.rfc-editor.org/rfc/rfc5849
[dynamo]: https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf
[bitcoin]: https://bitcoin.org/bitcoin.pdf
[sim]: https://en.wikipedia.org/wiki/SIM_swap_scam
[investigation]: https://www.vice.com/en/article/fcc-propose-fines-verizon-att-sprint-tmobile-selling-location-data/
[oh-the-forties-were-a-looong-time-ago]: https://www.nationalgeographic.com/history/article/141207-world-war-advertising-consumption-anniversary-people-photography-culture

[^1]: "auth is short for authentication (authn) and authorization (authz). The former establishes who you are, and the latter establishes that you are able to do what you're trying to do. I like writing about auth, which is why I'm going to leave this as a footnote, and not add fifty paragraphs to this post."

[^2]: "Elwood was paid not one, but two cool Benjamins for his recording of perhaps the most well-known voice acting of the 90s."

[^3]: "If you make your money from ads, I've got no beef with you. The ad-dispensing companies have made it their mission to encroach on your creative space as much as possible to extract value from your hard work. I'm here to help carve out a path to you making more money in addition to how you use the ad networks."

[^4]: "When Google created a parent company Alphabet, Alphabet dropped the don't be evil. The don't be evil line moved to Google's code of conduct. I wanted to avoid inferring anything from this, but when you change something like don't be evil to anything else, it's worth a questioning glance."

[^5]: "I told you not to look it up"

[^6]: "This story is a little different than what I've represented here, and this is mostly based on my recollection of the film the Social Network, which was itself inaccurate, but I don't much care. Facebook is the largest deseminator of disinformation on the planet, and I'm not too worried about them getting a turn."

[^7]: "Yes there are plenty of bank fees, and some accounts do have monthly fees, but those are largely just because banks are dicks"

[^8]: "So banks don't hold a lot of cash, because cash is better used in investments. So to handle their day-to-day operation they borrow money for really short terms (like for a day) from money market funds. They pay this back with a small amount of interest, and that gets paid to the investors in the money market. When Lehman Brothers collapsed, the debt it owed to the money market represented money that was effectively gone."

[^9]: "These jamokes reneged on so many dumb promises this time, but the one that I think just really sums it all up is Haven, the healthcare venture that Warren Buffet and Jeff Bezos started to fix healthcare. It shudown unceremoniously in 2021, after doing nothing. The second richest man on Earth just gives up after a couple of years, because something's too hard, what a ballsack."
