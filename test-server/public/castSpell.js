/**
 * castSpell.js - Unified MAGIC Protocol Operations
 *
 * Handles:
 * - Spell casting with MAGIC protocol
 * - BDO creation and saving to carrierBag
 * - Contract creation and signing (SODOTO)
 * - Payment processing through Addie
 * - Nineum permission checks and grants
 * - Lesson purchases and collection
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

const SERVICES = {
  FOUNT: 'http://127.0.0.1:5117',
  BDO: 'http://127.0.0.1:5114',
  COVENANT: 'http://127.0.0.1:5122',
  ADDIE: 'http://127.0.0.1:5115'
};

// ============================================================================
// CORE SPELL CASTING
// ============================================================================

/**
 * Cast a spell through the MAGIC protocol
 * @param {Object} options - Spell casting options
 * @param {string} options.spellName - Name of the spell to cast
 * @param {Object} options.spellData - Additional spell-specific data
 * @param {Array} options.destinations - Gateway destinations for the spell
 * @returns {Promise<Object>} - Spell casting result
 */
async function castSpell({ spellName, spellData = {}, destinations = [] }) {
  console.log(`🪄 Casting spell: ${spellName}`);

  // 1. Get fount user (creates if doesn't exist)
  const fountUser = await getOrCreateFountUser();
  console.log(`👤 Fount user: ${fountUser.uuid}`);

  // 2. Build MAGIC payload
  const magicPayload = {
    spell: spellName,
    timestamp: Date.now().toString(),
    casterUUID: fountUser.uuid,
    ordinal: fountUser.ordinal,
    mp: 0, // Will be set by specific spell functions
    totalCost: 0, // Will be set by specific spell functions
    ...spellData
  };

  // 3. Request Swift to sign and send the spell
  const result = await browser.runtime.sendNativeMessage('application.id', {
    type: 'castSpell',
    spellName,
    magicPayload,
    destinations
  });

  console.log(`✅ Spell cast result:`, result);
  return result;
}

// ============================================================================
// BDO OPERATIONS
// ============================================================================

/**
 * Save a BDO to the user's carrierBag
 * @param {string} collectionName - Name of the collection (e.g., 'cookbook', 'contracts')
 * @param {Object} bdoData - BDO data to save
 * @returns {Promise<Object>} - Save result
 */
async function saveToBDO(collectionName, bdoData) {
  console.log(`💾 Saving to BDO collection: ${collectionName}`);

  const fountUser = await getOrCreateFountUser();

  // Get current carrierBag
  const carrierBag = await fetchCarrierBag(fountUser.uuid);

  // Update the specific collection
  if (!carrierBag[collectionName]) {
    carrierBag[collectionName] = [];
  }
  carrierBag[collectionName].push(bdoData);

  // Save back to BDO
  const result = await updateCarrierBag(fountUser.uuid, carrierBag);
  console.log(`✅ Saved to ${collectionName}`);

  return result;
}

/**
 * Fetch user's carrierBag from BDO
 */
async function fetchCarrierBag(userUUID) {
  const response = await fetch(`${SERVICES.BDO}/user/${userUUID}/carrierbag`);

  if (!response.ok) {
    console.log(`📦 No carrierBag found, creating new one`);
    return {
      cookbook: [],
      apothecary: [],
      gallery: [],
      bookshelf: [],
      familiarPen: [],
      machinery: [],
      metallics: [],
      music: [],
      oracular: [],
      greenHouse: [],
      closet: [],
      games: [],
      events: [],
      contracts: []
    };
  }

  return await response.json();
}

/**
 * Update user's carrierBag in BDO
 */
async function updateCarrierBag(userUUID, carrierBag) {
  const response = await fetch(`${SERVICES.BDO}/user/${userUUID}/carrierbag`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(carrierBag)
  });

  if (!response.ok) {
    throw new Error(`Failed to update carrierBag: ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Fetch a BDO by public key
 */
async function fetchBDO(bdoPubKey) {
  console.log(`🔍 Fetching BDO: ${bdoPubKey}`);

  // Try Swift-side fetch first (handles authentication)
  try {
    const result = await browser.runtime.sendNativeMessage('application.id', {
      type: 'fetchBDO',
      bdoPubKey
    });
    return result;
  } catch (error) {
    console.warn(`⚠️ Swift fetch failed, trying direct:`, error);

    // Fallback to direct fetch
    const response = await fetch(`${SERVICES.BDO}/public/bdo?pubKey=${bdoPubKey}`);
    if (!response.ok) {
      throw new Error(`Failed to fetch BDO: ${response.statusText}`);
    }
    return await response.json();
  }
}

// ============================================================================
// CONTRACT OPERATIONS (SODOTO via Covenant)
// ============================================================================

/**
 * Create a SODOTO contract
 * @param {Object} contractData - Contract parameters
 * @returns {Promise<Object>} - Created contract with emojicode
 */
async function createContract({
  title,
  participants, // Array of { pubKey, role }
  steps, // Array of contract steps
  metadata = {}
}) {
  console.log(`📜 Creating contract: ${title}`);

  const fountUser = await getOrCreateFountUser();

  const contractPayload = {
    title,
    creator: fountUser.uuid,
    creatorPubKey: fountUser.pubKey,
    participants,
    steps,
    metadata,
    timestamp: Date.now().toString()
  };

  const response = await fetch(`${SERVICES.COVENANT}/contracts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(contractPayload)
  });

  if (!response.ok) {
    throw new Error(`Failed to create contract: ${response.statusText}`);
  }

  const contract = await response.json();
  console.log(`✅ Contract created: ${contract.contractUuid}`);
  console.log(`✨ Emojicode: ${contract.emojicode}`);

  return contract;
}

/**
 * Sign a contract step
 * @param {string} contractUuid - Contract UUID
 * @param {string} stepId - Step ID to sign
 * @returns {Promise<Object>} - Signing result
 */
async function signContractStep(contractUuid, stepId) {
  console.log(`✍️ Signing contract step: ${contractUuid} / ${stepId}`);

  // Request Swift to sign via Sessionless
  const result = await browser.runtime.sendNativeMessage('application.id', {
    type: 'signCovenantStep',
    contractUuid,
    stepId
  });

  console.log(`✅ Step signed:`, result);
  return result;
}

/**
 * Fetch contract by UUID or emojicode
 */
async function fetchContract(identifier) {
  console.log(`📜 Fetching contract: ${identifier}`);

  const isEmojicode = identifier.startsWith('✨');
  const endpoint = isEmojicode
    ? `${SERVICES.COVENANT}/contracts/by-emojicode`
    : `${SERVICES.COVENANT}/contracts/${identifier}`;

  const response = await fetch(endpoint, {
    method: isEmojicode ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json' },
    body: isEmojicode ? JSON.stringify({ emojicode: identifier }) : undefined
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch contract: ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Save contract to carrierBag
 */
async function saveContract(contract) {
  return await saveToBDO('contracts', {
    contractUuid: contract.contractUuid,
    emojicode: contract.emojicode,
    bdoPubKey: contract.bdoPubKey,
    title: contract.title,
    savedAt: Date.now()
  });
}

// ============================================================================
// PAYMENT OPERATIONS (via Addie)
// ============================================================================

/**
 * Process payment through Addie
 * @param {Object} paymentData - Payment details
 * @returns {Promise<Object>} - Payment result
 */
async function processPayment({
  amount,
  currency = 'usd',
  productId,
  creatorId,
  splits = {} // { creator: 70, base: 20, site: 10 }
}) {
  console.log(`💳 Processing payment: ${amount} ${currency}`);

  const fountUser = await getOrCreateFountUser();

  const paymentPayload = {
    amount,
    currency,
    productId,
    creatorId,
    buyerId: fountUser.uuid,
    splits: {
      creator: splits.creator || 70,
      base: splits.base || 20,
      site: splits.site || 10
    },
    timestamp: Date.now().toString()
  };

  const response = await fetch(`${SERVICES.ADDIE}/payments`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(paymentPayload)
  });

  if (!response.ok) {
    throw new Error(`Payment failed: ${response.statusText}`);
  }

  const result = await response.json();
  console.log(`✅ Payment processed:`, result);

  return result;
}

// ============================================================================
// NINEUM OPERATIONS
// ============================================================================

/**
 * Grant nineum to a user (typically teacher -> student)
 * @param {string} recipientUUID - Recipient's fount UUID
 * @param {Object} nineumData - Nineum identifier (galaxy, system, flavor)
 * @returns {Promise<Object>} - Grant result
 */
async function grantNineum(recipientUUID, nineumData) {
  console.log(`💎 Granting nineum to ${recipientUUID}:`, nineumData);

  const { galaxy, system, flavor } = nineumData;

  // Generate full nineum ID: galaxy(2) + system(8) + flavor(12) + year(2) + ordinal(8)
  const year = new Date().getFullYear().toString().slice(-2);
  const ordinal = Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
  const nineumId = `${galaxy}${system}${flavor}${year}${ordinal}`;

  const response = await fetch(`${SERVICES.FOUNT}/users/${recipientUUID}/nineum`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ nineumId })
  });

  if (!response.ok) {
    throw new Error(`Failed to grant nineum: ${response.statusText}`);
  }

  const result = await response.json();
  console.log(`✅ Nineum granted:`, nineumId);

  return result;
}

/**
 * Check if user has required nineum permission
 * @param {Object} requiredNineum - Required nineum (galaxy, system, flavor)
 * @returns {Promise<boolean>} - True if user has permission
 */
async function checkNineumPermission(requiredNineum) {
  console.log(`🔍 Checking nineum permission:`, requiredNineum);

  const fountUser = await getOrCreateFountUser();

  // Fetch user's current nineum collection
  const response = await fetch(`${SERVICES.FOUNT}/users/${fountUser.uuid}`);
  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.statusText}`);
  }

  const user = await response.json();
  const userNineum = user.nineum || [];

  const { galaxy, system, flavor } = requiredNineum;

  // Check if any nineum matches
  const hasPermission = userNineum.some(nineumId => {
    if (nineumId.length !== 32) return false;

    const nineumGalaxy = nineumId.substring(0, 2);
    const nineumSystem = nineumId.substring(2, 10);
    const nineumFlavor = nineumId.substring(10, 22);

    return nineumGalaxy === galaxy &&
           nineumSystem === system &&
           nineumFlavor === flavor;
  });

  console.log(`${hasPermission ? '✅' : '❌'} Nineum permission: ${hasPermission}`);
  return hasPermission;
}

// ============================================================================
// LESSON PURCHASE FLOW
// ============================================================================

/**
 * Complete lesson purchase flow:
 * 1. Student purchases lesson from teacher
 * 2. Creates SODOTO contract
 * 3. Teacher and student progress through contract
 * 4. Teacher grants nineum on completion
 * 5. Student can collect lesson with nineum permission
 *
 * @param {Object} lessonData - Lesson details
 * @returns {Promise<Object>} - Purchase flow result
 */
async function purchaseLesson({
  lessonId,
  lessonTitle,
  lessonBdoPubKey,
  teacherUUID,
  teacherPubKey,
  price,
  currency = 'usd',
  requiredNineum // { galaxy, system, flavor }
}) {
  console.log(`📚 Starting lesson purchase flow: ${lessonTitle}`);

  const fountUser = await getOrCreateFountUser();
  const results = {
    payment: null,
    contract: null,
    error: null
  };

  try {
    // Step 1: Process payment
    console.log(`💳 Step 1: Processing payment...`);
    results.payment = await processPayment({
      amount: price,
      currency,
      productId: lessonId,
      creatorId: teacherUUID,
      splits: { creator: 70, base: 20, site: 10 }
    });

    // Step 2: Create SODOTO contract
    console.log(`📜 Step 2: Creating SODOTO contract...`);
    const contract = await createContract({
      title: `Lesson: ${lessonTitle}`,
      participants: [
        { pubKey: teacherPubKey, role: 'teacher', uuid: teacherUUID },
        { pubKey: fountUser.pubKey, role: 'student', uuid: fountUser.uuid }
      ],
      steps: [
        {
          id: 'step_1_payment',
          title: 'Payment Completed',
          assignedTo: 'student',
          completed: true, // Auto-complete since payment succeeded
          completedAt: Date.now(),
          completedBy: fountUser.uuid
        },
        {
          id: 'step_2_access',
          title: 'Grant Lesson Access',
          assignedTo: 'teacher',
          completed: false,
          description: 'Teacher provides lesson materials and access'
        },
        {
          id: 'step_3_completion',
          title: 'Complete Lesson',
          assignedTo: 'student',
          completed: false,
          description: 'Student completes the lesson requirements'
        },
        {
          id: 'step_4_verification',
          title: 'Verify Completion',
          assignedTo: 'teacher',
          completed: false,
          description: 'Teacher verifies lesson completion'
        },
        {
          id: 'step_5_nineum',
          title: 'Grant Nineum Permission',
          assignedTo: 'teacher',
          completed: false,
          description: 'Teacher grants nineum for lesson collection',
          action: 'grantNineum',
          actionData: {
            recipientUUID: fountUser.uuid,
            nineum: requiredNineum
          }
        }
      ],
      metadata: {
        type: 'lesson_purchase',
        lessonId,
        lessonBdoPubKey,
        requiredNineum,
        paymentId: results.payment.paymentId,
        purchaseDate: Date.now()
      }
    });

    results.contract = contract;

    // Step 3: Save contract to student's carrierBag
    console.log(`💾 Step 3: Saving contract to carrierBag...`);
    await saveContract(contract);

    console.log(`✅ Lesson purchase complete!`);
    console.log(`📜 Contract: ${contract.contractUuid}`);
    console.log(`✨ Share code: ${contract.emojicode}`);

    return results;

  } catch (error) {
    console.error(`❌ Lesson purchase failed:`, error);
    results.error = error.message;
    throw error;
  }
}

/**
 * Teacher grants nineum after contract completion
 */
async function completeContractAndGrantNineum(contractUuid) {
  console.log(`🎓 Completing contract and granting nineum: ${contractUuid}`);

  // Fetch contract
  const contract = await fetchContract(contractUuid);

  // Find the nineum grant step
  const nineumStep = contract.steps.find(s => s.action === 'grantNineum');
  if (!nineumStep) {
    throw new Error('Contract does not have nineum grant step');
  }

  // Grant nineum
  const { recipientUUID, nineum } = nineumStep.actionData;
  await grantNineum(recipientUUID, nineum);

  // Sign the contract step
  await signContractStep(contractUuid, nineumStep.id);

  console.log(`✅ Nineum granted and step signed`);
}

/**
 * Student collects lesson (requires nineum permission)
 */
async function collectLesson(lessonBdoPubKey, requiredNineum) {
  console.log(`📚 Collecting lesson: ${lessonBdoPubKey}`);

  // Check nineum permission
  const hasPermission = await checkNineumPermission(requiredNineum);

  if (!hasPermission) {
    throw new Error('Missing required nineum permission to collect this lesson');
  }

  // Fetch lesson BDO
  const lessonBDO = await fetchBDO(lessonBdoPubKey);

  // Save to bookshelf collection
  await saveToBDO('bookshelf', {
    bdoPubKey: lessonBdoPubKey,
    title: lessonBDO.title || 'Untitled Lesson',
    collectedAt: Date.now()
  });

  console.log(`✅ Lesson collected and saved to bookshelf`);
  return lessonBDO;
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Get or create Fount user via Swift
 */
async function getOrCreateFountUser() {
  const result = await browser.runtime.sendNativeMessage('application.id', {
    type: 'createFountUser'
  });

  if (!result.success) {
    throw new Error('Failed to get/create Fount user');
  }

  return result.data || result;
}

// ============================================================================
// EXPORTS
// ============================================================================

// Make available globally for browser extension context
if (typeof window !== 'undefined') {
  window.CastSpell = {
    // Core
    castSpell,

    // BDO
    saveToBDO,
    fetchBDO,
    fetchCarrierBag,
    updateCarrierBag,

    // Contracts
    createContract,
    signContractStep,
    fetchContract,
    saveContract,

    // Payments
    processPayment,

    // Nineum
    grantNineum,
    checkNineumPermission,

    // Lesson Flow
    purchaseLesson,
    completeContractAndGrantNineum,
    collectLesson
  };
}

// For Node.js/module context
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    castSpell,
    saveToBDO,
    fetchBDO,
    fetchCarrierBag,
    updateCarrierBag,
    createContract,
    signContractStep,
    fetchContract,
    saveContract,
    processPayment,
    grantNineum,
    checkNineumPermission,
    purchaseLesson,
    completeContractAndGrantNineum,
    collectLesson
  };
}
