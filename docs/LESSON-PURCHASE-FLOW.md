# Lesson Purchase Flow

Complete end-to-end flow for purchasing lessons with nineum permissions, SODOTO contracts, and collection.

## Overview

Teacher creates lesson → Student purchases → SODOTO contract created → Progress through steps → Teacher grants nineum → Student collects lesson

## Services Used

- **Fount** (`:5117`) - User management, nineum permissions
- **BDO** (`:5114`) - CarrierBag storage (contracts, bookshelf)
- **Covenant** (`:5122`) - SODOTO contract creation and signing
- **Addie** (`:5115`) - Payment processing
- **castSpell.js** - Already available from Fount for spell casting

## Complete Flow

### 1. Teacher Creates Lesson (Ninefy)

Teacher creates lesson content with:
- Lesson BDO with SVG content
- Required nineum specification (galaxy, system, flavor)
- Price and metadata

```javascript
// Lesson data structure
{
  lessonId: 'lesson-blockchain-101',
  title: 'Introduction to Blockchain Development',
  bdoPubKey: '0x123...', // BDO containing lesson content
  teacherUUID: 'teacher-uuid',
  price: 2999, // cents
  requiredNineum: {
    galaxy: '01',
    system: 'blockchain',
    flavor: 'beginner'
  }
}
```

### 2. Student Purchases Lesson

**API Call:** POST to Addie
```javascript
await fetch('http://127.0.0.1:5115/payments', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    amount: 2999,
    currency: 'usd',
    productId: 'lesson-blockchain-101',
    creatorId: teacherUUID,
    buyerId: studentUUID,
    splits: { creator: 70, base: 20, site: 10 }
  })
});
```

### 3. Create SODOTO Contract

**API Call:** POST to Covenant
```javascript
await fetch('http://127.0.0.1:5122/contracts', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    title: 'Lesson: Introduction to Blockchain Development',
    creator: studentUUID,
    creatorPubKey: studentPubKey,
    participants: [
      { pubKey: teacherPubKey, role: 'teacher', uuid: teacherUUID },
      { pubKey: studentPubKey, role: 'student', uuid: studentUUID }
    ],
    steps: [
      {
        id: 'step_1_payment',
        title: 'Payment Completed',
        assignedTo: 'student',
        completed: true // Auto-complete on purchase
      },
      {
        id: 'step_2_access',
        title: 'Grant Lesson Access',
        assignedTo: 'teacher',
        completed: false
      },
      {
        id: 'step_3_completion',
        title: 'Complete Lesson',
        assignedTo: 'student',
        completed: false
      },
      {
        id: 'step_4_verification',
        title: 'Verify Completion',
        assignedTo: 'teacher',
        completed: false
      },
      {
        id: 'step_5_nineum',
        title: 'Grant Nineum Permission',
        assignedTo: 'teacher',
        completed: false,
        action: 'grantNineum',
        actionData: {
          recipientUUID: studentUUID,
          nineum: {
            galaxy: '01',
            system: 'blockchain',
            flavor: 'beginner'
          }
        }
      }
    ],
    metadata: {
      type: 'lesson_purchase',
      lessonId: 'lesson-blockchain-101',
      lessonBdoPubKey: '0x123...',
      requiredNineum: { ... },
      paymentId: 'payment-xyz'
    }
  })
});

// Response includes:
{
  contractUuid: '...',
  emojicode: '✨🎓📚🔥✨',
  bdoPubKey: '...',  // Contract is a BDO
  svgContent: '...'  // SVG visualization
}
```

### 4. Save Contract to Student's CarrierBag

**API Call:** PUT to BDO
```javascript
// Get current carrierBag
const carrierBag = await fetch(`http://127.0.0.1:5114/user/${studentUUID}/carrierbag`).then(r => r.json());

// Add to contracts collection
carrierBag.contracts.push({
  contractUuid: contract.contractUuid,
  emojicode: contract.emojicode,
  bdoPubKey: contract.bdoPubKey,
  title: contract.title,
  savedAt: Date.now()
});

// Save back
await fetch(`http://127.0.0.1:5114/user/${studentUUID}/carrierbag`, {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(carrierBag)
});
```

### 5. Progress Through Contract Steps

**Sign Contract Step** (via AdvanceKey or Swift extension):
```javascript
// Browser extension calls native Swift
await browser.runtime.sendNativeMessage('application.id', {
  type: 'signCovenantStep',
  contractUuid: contract.contractUuid,
  stepId: 'step_3_completion'
});

// Swift calls Covenant with signature
PUT http://127.0.0.1:5122/contracts/{contractUuid}/steps/{stepId}/sign
```

### 6. Teacher Grants Nineum

**API Call:** POST to Fount
```javascript
// Generate nineum ID: galaxy(2) + system(8) + flavor(12) + year(2) + ordinal(8)
const nineumId = '01blockchain' + 'beginner00000' + '25' + '00000001';

await fetch(`http://127.0.0.1:5117/users/${studentUUID}/nineum`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ nineumId })
});

// Also sign the contract step
await signCovenantStep(contractUuid, 'step_5_nineum');
```

### 7. Student Collects Lesson

**Check Nineum Permission** (automatic via Fount magic.js):

When student tries to collect lesson, the MAGIC protocol resolver checks:

```javascript
// fount/src/server/node/src/routes/magic.js
// Checks if user has required nineum automatically

const hasPermission = await checkNineumPermission(caster, {
  galaxy: '01',
  system: 'blockchain',
  flavor: 'beginner'
});

// Returns 900 error if missing permission
```

**Collect Lesson:**
```javascript
// Fetch lesson BDO
const lessonBDO = await fetch(`http://127.0.0.1:5114/public/bdo?pubKey=${lessonBdoPubKey}`).then(r => r.json());

// Save to bookshelf collection
const carrierBag = await fetch(`http://127.0.0.1:5114/user/${studentUUID}/carrierbag`).then(r => r.json());

carrierBag.bookshelf.push({
  bdoPubKey: lessonBdoPubKey,
  title: lessonBDO.title,
  svgContent: lessonBDO.svgContent,
  collectedAt: Date.now()
});

await fetch(`http://127.0.0.1:5114/user/${studentUUID}/carrierbag`, {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(carrierBag)
});
```

## CarrierBag Structure

The BDO service provides persistent user-owned storage with 14 collections:

```javascript
{
  cookbook: [],      // Recipes
  apothecary: [],    // Potions/items
  gallery: [],       // Art/images
  bookshelf: [],     // Lessons/content ← Lessons stored here
  familiarPen: [],   // Pets/companions
  machinery: [],     // Tools
  metallics: [],     // Materials
  music: [],         // Audio
  oracular: [],      // Predictions
  greenHouse: [],    // Plants
  closet: [],        // Wearables
  games: [],         // Game data
  events: [],        // Calendar
  contracts: []      // SODOTO contracts ← Contracts stored here
}
```

## Nineum Permission System

Nineum is structured as a 32-character identifier:
- **Galaxy** (2 chars): Broad category
- **System** (8 chars): Specific domain
- **Flavor** (12 chars): Permission level
- **Year** (2 chars): Grant year
- **Ordinal** (8 chars): Unique sequence

Example: `01blockchain` + `beginner00000` + `25` + `00000001`

### Permission Checking

Fount's magic.js automatically checks nineum permissions for spells with `requiredNineum`:

```javascript
// In spellbook
{
  collectLesson: {
    requiredNineum: {
      galaxy: '01',
      system: 'blockchain',
      flavor: 'beginner'
    },
    // ...
  }
}

// Fount checks user's nineum array for matching galaxy+system+flavor
```

## Integration with Existing Code

### AdvanceKey (iOS Keyboard)

Already has Covenant integration:
- `KeyboardViewController.swift` - displays contract SVGs
- Contract signing via Sessionless
- CarrierBag saving

### SafariWebExtensionHandler

Already has spell casting:
- `handleCastSpell` - sends spells through MAGIC protocol
- `signMagicPayload` - Sessionless signing
- `handleSignCovenantStep` - contract step signing

### Test Environment

```bash
# Start services (already configured)
docker-compose up  # Fount :5117, BDO :5114, Covenant :5122, Addie :5115

# Test page
open http://localhost:3456/lesson-purchase-test.html
```

## Example: Complete Flow in Action

```javascript
// 1. Student purchases
const payment = await purchaseLesson(lessonId, studentUUID);

// 2. Contract auto-created
const contract = await createContractForLesson(lessonId, payment);

// 3. Saved to carrierBag
await saveToCarrierBag(studentUUID, 'contracts', contract);

// 4. Teacher and student sign steps
await signStep(contract.uuid, 'step_2_access'); // Teacher
await signStep(contract.uuid, 'step_3_completion'); // Student
await signStep(contract.uuid, 'step_4_verification'); // Teacher

// 5. Teacher grants nineum
await grantNineum(studentUUID, nineumId);
await signStep(contract.uuid, 'step_5_nineum'); // Teacher

// 6. Student collects (nineum checked automatically)
await collectLesson(lessonBdoPubKey, studentUUID);
```

## API Summary

| Service | Port | Purpose |
|---------|------|---------|
| Fount | 5117 | Users, nineum, MAGIC protocol |
| BDO | 5114 | CarrierBag storage |
| Covenant | 5122 | Contract creation/signing |
| Addie | 5115 | Payment processing |

## Next Steps

1. ✅ All services already running and integrated
2. ✅ AdvanceKey can sign contracts
3. ✅ BDO stores contracts in carrierBags
4. ✅ Fount checks nineum permissions
5. ✅ castSpell.js available from Fount

**Ready to use!** Just call the services directly with fetch() and the existing Swift integrations.
