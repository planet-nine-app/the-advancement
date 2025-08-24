'use strict';

var sessionless = require('sessionless-node');

const get = async (url) => {
  return await fetch(url);
};

const post = async (url, payload) => {
  return await fetch(url, {
    method: 'post',
    body: JSON.stringify(payload),
    headers: {'Content-Type': 'application/json'}
  });
};

const put = async (url, payload) => {
  return await fetch(url, {
    method: 'put',
    body: JSON.stringify(payload),
    headers: {'Content-Type': 'application/json'}
  });
};

const _delete = async (url, payload) => {
  return await fetch(url, {
    method: 'delete',
    body: JSON.stringify(payload),
    headers: {'Content-Type': 'application/json'}
  });
};

const fount = {
  baseURL: 'https://dev.fount.allyabase.com/',

  createUser: async (saveKeys, getKeys) => {
    const keys = (await getKeys()) || (await sessionless.generateKeys(saveKeys, getKeys));
    sessionless.getKeys = getKeys;

    const payload = {
      timestamp: new Date().getTime() + '',
      pubKey: keys.pubKey
    };

    payload.signature = await sessionless.sign(payload.timestamp + payload.pubKey);

    const res = await put(`${fount.baseURL}user/create`, payload);
    const user = await res.json();

    return user;
  },

  getUserByUUID: async (uuid) => {
    const timestamp = new Date().getTime() + '';
    
    const message = timestamp + uuid;
    
    const signature = await sessionless.sign(message);

    const res = await get(`${fount.baseURL}user/${uuid}?signature=${signature}&timestamp=${timestamp}`);
    const user = res.json();

    return user;
  },

  getUserByPublicKey: async (pubKey) => {
    const timestamp = new Date().getTime() + '';
    
    const message = timestamp + pubKey;
    
    const signature = await sessionless.sign(message);

    const res = await get(`${fount.baseURL}user/pubKey/${pubKey}?signature=${signature}&timestamp=${timestamp}`);
    const user = res.json();

    return user;
  },

  resolve: async (spell) => {
    const res = await post(`${fount.baseURL}resolve/${spell.spell}`, spell);
    const response = await res.json();
    return response;
  },

  grant: async (uuid, destinationUUID, amount, description) => {
    const payload = {
      timestamp: new Date().getTime(),
      destinationUUID,
      amount,
      description
    };

    const message = payload.timestamp + uuid + payload.destinationUUID + payload.amount + payload.description;

    payload.signature = await sessionless.sign(message);

    const res = await post(`${fount.baseURL}user/${uuid}/grant`, payload);
console.log(res);
    const user = await res.json();
    return user;
  },

  grantNineum: async (uuid, destinationUUID, flavor) => {
    const payload = {
      timestamp: new Date().getTime() + '',
      toUserUUID: destinationUUID,
      charge: flavor.slice(0, 2),
      direction: flavor.slice(2, 4),
      rarity: flavor.slice(4, 6),
      size: flavor.slice(6, 8),
      texture: flavor.slice(8, 10),
      shape: flavor.slice(10, 12),
      quantity: 1
    };

//    const flavor = payload.charge + payload.direction + payload.rarity + payload.size + payload.texture + payload.shape;

    const message = payload.timestamp + uuid + payload.toUserUUID + flavor + payload.quantity;

    payload.signature = await sessionless.sign(message);

    const res = await put(`${fount.baseURL}user/${uuid}/nineum`, payload);
console.log(res);
    const user = await res.json();
    return user;
  },

  grantAdminNineum: async (uuid, destinationUUID) => {
    const payload = {
      timestamp: new Date().getTime() + '',
      toUserUUID: destinationUUID
    };

    const message = payload.timestamp + uuid;
   
    payload.signature = await sessionless.sign(message);

    const res = await put(`${fount.baseURL}user/${uuid}/nineum/admin`, payload);
console.log(res);
    const user = await res.json();
    return user;
  },

  grantGalacticNineum: async (uuid, galaxy) => {
console.log('got galaxy', galaxy);
    const payload = {
      timestamp: new Date().getTime() + '',
      galaxy
    };
console.log('payload to send is', payload);
    const message = payload.timestamp + uuid + galaxy;
console.log('message for galactic is', message);
   
    payload.signature = await sessionless.sign(message);

    const res = await put(`${fount.baseURL}user/${uuid}/nineum/galactic`, payload);
console.log(res);
    const user = await res.json();
    return user;
  },

  getNineum: async (uuid) => {
    const timestamp = new Date().getTime() + '';

    const message = timestamp + uuid;

    const signature = await sessionless.sign(message);

    const res = await get(`${fount.baseURL}user/${uuid}/nineum?timestamp=${timestamp}&signature=${signature}`);
    const nineum = (await res.json()).nineum;
    return nineum;
  },

  transferNineum: async (uuid, destinationUUID, nineumUniqueIds, price, currency) => {
    const payload = {
      timestamp: new Date().getTime() + '',
      destinationUUID,
      nineumUniqueIds,
      price: 0,
      currency: 'usd'
    };

    const message = payload.timestamp + uuid + destinationUUID + payload.nineumUniqueIds.join('') + payload.price + payload.currency;

    payload.signature = await sessionless.sign(message);

    const res = await post(`${fount.baseURL}user/${uuid}/transfer`, payload);
    const user = await res.json();
    return user;
  },

  deleteUser: async (uuid) => {
    const timestamp = new Date().getTime() + '';

    const signature = await sessionless.sign(timestamp + uuid);
    const payload = {timestamp, uuid, signature};


    const res = await _delete(`${fount.baseURL}user/${uuid}`, payload);
    return res.status === 200;
  }
};

module.exports = fount;
