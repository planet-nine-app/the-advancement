import sessionless from 'sessionless-node';

import b from './base512.js';

let mismatches = 0;
let problems = 0;

for(var i = 0; i < 1; i++) {
  try {
    const uuid = sessionless.generateUUID() + sessionless.generateUUID() + sessionless.generateUUID() + sessionless.generateUUID();
    const uuidWithoutDashes = uuid.replace(/-/g, '');
console.log(uuidWithoutDashes);
console.log(b.encode(uuidWithoutDashes));

    const after = b.decode(b.encode(uuidWithoutDashes));

    if(uuidWithoutDashes !== after) {
      mismatches++;
    }
  } catch(err) {
console.warn(err);
    problems++;
  }
}

console.log('There were ', mismatches, 'mismatches, and ', problems, ' problems');
