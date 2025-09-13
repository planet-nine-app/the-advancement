# Fount

This is the JavaScript client SDK for the Fount miniservice. 

### Usage

```javascript
import fount from 'fount-js';

const saveKeys = (keys) => { /* handle persisting keys here */ };
const getKeys = () => { /* return keys here. Can be async */ };

const spell = // See [MAGIC](https://www.github.com/planet-nine-app/MAGIC) for how to build a spell
const anotherUserUUID = 'some other uuid';
const arbitraryGrantAmount = 200;
const description = 'This might show up in other clients';

const uuid = await fount.createUser(saveKeys, getKeys);

const user = await fount.getUserByUUID(uuid);

const pubKey = getKeys().pubKey;

const userAgain = await fount.getUserByPublicKey(pubKey);

const resolution = await fount.resolve(spell); // see [MAGIC](https://www.github.com/planet-nine-app/MAGIC) for how spells resolve.

const userAfterGrant = await fount.grant(uuid, anotherUserUUID, arbitraryGrantAmount, description); 

const nineum = await fount.getNineum(uuid);

const transferNineum = await fount.transferNineum(uuid, anotherUserUUID, nineum, 0, 'usd'); // priced transfers not supported yet

const deleted = await fount.deleteUser(uuid, newHash); // returns true on success
```
