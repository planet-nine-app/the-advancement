package app.planetnine.theadvancement.ime

import android.content.ClipboardManager
import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.planetnine.theadvancement.config.Configuration
import app.planetnine.theadvancement.crypto.Sessionless
import app.planetnine.theadvancement.ui.main.PostedBDO
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

/**
 * ViewModel for AdvanceKey IME
 *
 * Handles:
 * - Emojicode decoding
 * - BDO fetching and display
 * - MAGIC spell casting
 * - Contract signing
 */
class AdvanceKeyViewModel(private val context: Context) : ViewModel() {

    companion object {
        private const val TAG = "AdvanceKeyViewModel"
        private const val PREFS_NAME = "the_advancement"
        private const val KEY_FOUNT_UUID = "fount_uuid"
        private const val KEY_USER_PUBKEY = "user_pubkey"
        private const val KEY_CARRIER_BAG = "carrier_bag"
    }

    private val _clipboardText = MutableStateFlow("")
    val clipboardText: StateFlow<String> = _clipboardText.asStateFlow()

    private val _decodedBDO = MutableStateFlow<Map<String, Any>?>(null)
    val decodedBDO: StateFlow<Map<String, Any>?> = _decodedBDO.asStateFlow()

    private val _postedBDOs = MutableStateFlow<List<PostedBDO>>(emptyList())
    val postedBDOs: StateFlow<List<PostedBDO>> = _postedBDOs.asStateFlow()

    private val _errorMessage = MutableStateFlow<ErrorMessage?>(null)
    val errorMessage: StateFlow<ErrorMessage?> = _errorMessage.asStateFlow()

    private val sessionless = Sessionless(context)
    private val gson = Gson()
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    init {
        // Monitor clipboard for emojicodes
        monitorClipboard()
        // Load posted BDOs
        loadPostedBDOs()
    }

    /**
     * Monitor clipboard for emojicode patterns and URLs
     */
    private fun monitorClipboard() {
        try {
            val clipboardManager = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            clipboardManager?.addPrimaryClipChangedListener {
                val clipData = clipboardManager.primaryClip
                if (clipData != null && clipData.itemCount > 0) {
                    val text = clipData.getItemAt(0).text?.toString() ?: ""

                    // Check if it looks like an emojicode (9 emoji characters)
                    if (isEmojicode(text)) {
                        _clipboardText.value = text
                        Log.d(TAG, "Detected emojicode in clipboard: $text")
                    }
                    // Check if it's a URL
                    else if (isURL(text)) {
                        Log.d(TAG, "🔗 Detected URL in clipboard: $text")
                        saveURLToLinks(text)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to monitor clipboard", e)
        }
    }

    /**
     * Check if text looks like an emojicode (9 emoji characters)
     */
    private fun isEmojicode(text: String): Boolean {
        // Rough check: emojicodes are typically 9-36 characters (9 emojis in UTF-16)
        val trimmed = text.trim()
        return trimmed.length in 9..36 && trimmed.any { it.code > 0x1F000 }
    }

    /**
     * Check if text is a valid URL
     */
    private fun isURL(text: String): Boolean {
        val trimmed = text.trim()
        return (trimmed.startsWith("http://") || trimmed.startsWith("https://")) &&
                trimmed.contains(".")
    }

    /**
     * Save URL to links collection with cool SVG
     */
    private fun saveURLToLinks(url: String) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "🔗 Saving URL to links: $url")

                // Extract domain for title
                val title = extractDomain(url)

                // Generate SVG
                val svgContent = generateLinkSVG(title, url)

                // Create link data
                val linkData = mapOf(
                    "title" to title,
                    "url" to url,
                    "type" to "link",
                    "svgContent" to svgContent,
                    "savedAt" to System.currentTimeMillis()
                )

                // Load carrier bag
                val carrierBagJson = prefs.getString(KEY_CARRIER_BAG, null)
                val carrierBag = if (carrierBagJson != null) {
                    @Suppress("UNCHECKED_CAST")
                    gson.fromJson(carrierBagJson, Map::class.java).toMutableMap() as MutableMap<String, Any>
                } else {
                    createEmptyCarrierBag().toMutableMap()
                }

                // Get links collection
                @Suppress("UNCHECKED_CAST")
                val linksItems = (carrierBag["links"] as? List<Map<String, Any>>)?.toMutableList()
                    ?: mutableListOf()

                // Add link to beginning
                linksItems.add(0, linkData)

                // Update carrier bag
                carrierBag["links"] = linksItems

                // Save to SharedPreferences
                val updatedJson = gson.toJson(carrierBag)
                prefs.edit().putString(KEY_CARRIER_BAG, updatedJson).apply()

                Log.d(TAG, "✅ Saved URL to links collection (${linksItems.size} items)")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to save URL to links", e)
            }
        }
    }

    /**
     * Extract domain from URL
     */
    private fun extractDomain(urlString: String): String {
        return try {
            val url = java.net.URL(urlString)
            url.host.replace("^www\\.".toRegex(), "")
        } catch (e: Exception) {
            urlString
        }
    }

    /**
     * Generate colorful SVG for link
     */
    private fun generateLinkSVG(title: String, url: String): String {
        // Escape special characters
        val escapedTitle = title
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        val escapedURL = url.replace("\"", "&quot;")

        // Truncate title if too long
        val displayTitle = if (escapedTitle.length > 25) {
            escapedTitle.substring(0, 25) + "..."
        } else {
            escapedTitle
        }

        // Random gradient color scheme
        val gradients = listOf(
            listOf("#10b981", "#059669"),  // Green
            listOf("#3b82f6", "#2563eb"),  // Blue
            listOf("#8b5cf6", "#7c3aed"),  // Purple
            listOf("#ec4899", "#db2777"),  // Pink
            listOf("#f59e0b", "#d97706"),  // Orange
            listOf("#ef4444", "#dc2626")   // Red
        )
        val gradient = gradients.random()

        return """
<svg width="320" height="100" viewBox="0 0 320 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="linkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${gradient[0]};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${gradient[1]};stop-opacity:1" />
    </linearGradient>
  </defs>

  <rect fill="url(#linkGrad)" width="320" height="100" rx="12"/>

  <!-- Link icon -->
  <text x="30" y="60" fill="white" font-size="36">🔗</text>

  <!-- Title -->
  <text x="75" y="50" fill="white" font-size="16" font-weight="bold">
    $displayTitle
  </text>

  <!-- Tap to open text -->
  <text x="75" y="70" fill="rgba(255,255,255,0.8)" font-size="12">
    Tap to open link
  </text>

  <!-- Clickable area -->
  <a href="$escapedURL" target="_blank">
    <rect x="0" y="0" width="320" height="100" fill="transparent" cursor="pointer">
      <title>Open $escapedTitle</title>
    </rect>
  </a>
</svg>
        """.trimIndent()
    }

    /**
     * Decode emojicode and fetch BDO
     */
    fun decodeEmojicode(emojicode: String) {
        if (emojicode.isEmpty()) return

        viewModelScope.launch {
            try {
                Log.d(TAG, "Decoding emojicode: $emojicode")

                val bdo = fetchBDOByEmojicode(emojicode)
                _decodedBDO.value = bdo
                _errorMessage.value = null // Clear any previous errors

                Log.d(TAG, "✅ BDO decoded successfully")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to decode emojicode", e)

                // Show user-friendly error based on environment
                val errorMsg = createUserFriendlyError(
                    exception = e,
                    baseUrl = "${Configuration.bdoBaseURL}/emoji/$emojicode"
                )
                _errorMessage.value = errorMsg
            }
        }
    }

    /**
     * Create user-friendly error message based on environment
     */
    private fun createUserFriendlyError(exception: Exception, baseUrl: String? = null): ErrorMessage {
        val isProduction = Configuration.isProduction

        if (isProduction) {
            // User-friendly messages for production
            val errorMessage = exception.message ?: ""

            return when {
                errorMessage.contains("Failed to fetch") ||
                errorMessage.contains("Unable to resolve host") ||
                errorMessage.contains("timeout") -> {
                    ErrorMessage(
                        title = "Connection Issue",
                        message = """
                            ⚠️ Unable to fetch content

                            This keyboard needs network access permission to connect to Planet Nine services.

                            Please check:
                            • You have an internet connection
                            • The keyboard has network permission enabled
                            • You've allowed full access for AdvanceKey

                            ${baseUrl?.let { "🌐 You can also check this content in a browser:\n$it" } ?: ""}
                        """.trimIndent()
                    )
                }
                errorMessage.contains("Empty response") ||
                errorMessage.contains("Invalid") ||
                errorMessage.contains("parse") -> {
                    ErrorMessage(
                        title = "Invalid Emojicode",
                        message = """
                            🎯 The emojicode format seems incorrect

                            Valid formats:
                            • 9 consecutive emojis (e.g., 🌍🔑💎🌟💎🎨🐉📌🎯)
                            • Emojis wrapped in sparkles (e.g., ✨🏰👑✨)

                            Tips:
                            • Make sure you've copied the entire emojicode
                            • Check that it hasn't been modified
                            • Try copying the emojicode again
                        """.trimIndent()
                    )
                }
                else -> {
                    ErrorMessage(
                        title = "Something Went Wrong",
                        message = """
                            ⚠️ Unable to decode emojicode

                            Please make sure:
                            • You have an internet connection
                            • The emojicode is valid
                            • The keyboard has network permission

                            ${baseUrl?.let { "🌐 Try opening this in a browser:\n$it" } ?: ""}
                        """.trimIndent()
                    )
                }
            }
        } else {
            // Debug mode - show all details
            return ErrorMessage(
                title = "Error",
                message = """
                    ${exception.javaClass.simpleName}: ${exception.message}

                    ${baseUrl?.let { "URL: $it\n" } ?: ""}

                    Stack trace:
                    ${exception.stackTraceToString().take(500)}
                """.trimIndent()
            )
        }
    }

    /**
     * Clear error message
     */
    fun clearError() {
        _errorMessage.value = null
    }

    /**
     * Fetch BDO by emojicode
     */
    private suspend fun fetchBDOByEmojicode(emojicode: String): Map<String, Any> =
        withContext(Dispatchers.IO) {
            // Use BDO service /emoji endpoint
            val url = "${Configuration.bdoBaseURL}/emoji/$emojicode"

            val request = Request.Builder()
                .url(url)
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw Exception("Failed to fetch BDO: ${response.body?.string()}")
                }

                val responseBody = response.body?.string()
                    ?: throw Exception("Empty response")

                gson.fromJson(responseBody, Map::class.java) as Map<String, Any>
            }
        }

    /**
     * Cast MAGIC spell
     */
    fun castSpell(spellName: String) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "Casting spell: $spellName")

                val fountUUID = prefs.getString(KEY_FOUNT_UUID, null)
                    ?: throw Exception("Fount UUID not found")

                val keys = sessionless.getKeys()
                    ?: throw Exception("User keys not found")

                val timestamp = System.currentTimeMillis().toString()
                val message = timestamp + fountUUID
                val signature = sessionless.sign(message)
                    ?: throw Exception("Failed to sign spell")

                // Get primary shipping address if available
                val components = mutableMapOf<String, Any>()
                getPrimaryShippingAddress()?.let { address ->
                    Log.d(TAG, "📮 Including shipping address: ${address["name"]}")
                    components["shippingAddress"] = address
                }

                val result = resolveSpell(spellName, fountUUID, keys.publicKey, timestamp, signature, components)

                Log.d(TAG, "✅ Spell cast successfully: $result")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to cast spell", e)
            }
        }
    }

    /**
     * Get primary shipping address from carrier bag
     */
    private fun getPrimaryShippingAddress(): Map<String, Any>? {
        val carrierBagJson = prefs.getString(KEY_CARRIER_BAG, null) ?: return null

        @Suppress("UNCHECKED_CAST")
        val carrierBag = gson.fromJson(carrierBagJson, Map::class.java) as? Map<String, Any>
            ?: return null

        @Suppress("UNCHECKED_CAST")
        val addresses = carrierBag["addresses"] as? List<Map<String, Any>> ?: return null

        // Find primary address
        val primaryAddress = addresses.firstOrNull { it["isPrimary"] as? Boolean == true }
        if (primaryAddress != null) {
            Log.d(TAG, "📮 Found primary address: ${primaryAddress["name"]}")
            return primaryAddress
        }

        // If no primary, use first address
        val firstAddress = addresses.firstOrNull()
        if (firstAddress != null) {
            Log.d(TAG, "📮 Using first address (no primary set): ${firstAddress["name"]}")
            return firstAddress
        }

        Log.d(TAG, "📮 No addresses available")
        return null
    }

    /**
     * Resolve spell through Fount
     */
    private suspend fun resolveSpell(
        spellName: String,
        userUUID: String,
        pubKey: String,
        timestamp: String,
        signature: String,
        components: Map<String, Any> = emptyMap()
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        val url = Configuration.Fount.resolve(spellName)

        val body = mutableMapOf<String, Any>(
            "userUUID" to userUUID,
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "signature" to signature
        )

        if (components.isNotEmpty()) {
            body["components"] = components
        }

        val request = Request.Builder()
            .url(url)
            .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Spell failed: ${response.body?.string()}")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response")

            gson.fromJson(responseBody, Map::class.java) as Map<String, Any>
        }
    }

    /**
     * Fetch BDO by public key
     */
    fun fetchBDOByPubKey(pubKey: String) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "Fetching BDO: $pubKey")

                val bdo = getBDO(pubKey)
                _decodedBDO.value = bdo

                Log.d(TAG, "✅ BDO fetched successfully")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to fetch BDO", e)
            }
        }
    }

    /**
     * Get BDO from Fount service
     */
    private suspend fun getBDO(bdoPubKey: String): Map<String, Any> =
        withContext(Dispatchers.IO) {
            val url = Configuration.Fount.getBDO(bdoPubKey)

            val request = Request.Builder()
                .url(url)
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw Exception("Failed to fetch BDO: ${response.body?.string()}")
                }

                val responseBody = response.body?.string()
                    ?: throw Exception("Empty response")

                gson.fromJson(responseBody, Map::class.java) as Map<String, Any>
            }
        }

    /**
     * Load posted BDOs from SharedPreferences
     */
    private fun loadPostedBDOs() {
        try {
            val bdosJson = prefs.getString("posted_bdos", null)
            if (bdosJson != null) {
                val bdos = gson.fromJson(bdosJson, Array<PostedBDO>::class.java).toList()
                _postedBDOs.value = bdos
                Log.d(TAG, "📦 AdvanceKey loaded ${bdos.size} posted BDOs")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load posted BDOs", e)
        }
    }

    /**
     * Reload posted BDOs (call when returning to keyboard)
     */
    fun refreshPostedBDOs() {
        loadPostedBDOs()
    }

    /**
     * Save BDO to carrier bag
     */
    fun saveToCarrierBag(emojicode: String) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "💾 Saving to carrier bag: $emojicode")

                // Fetch BDO by emojicode
                val bdoResponse = fetchBDOByEmojicode(emojicode)
                val bdo = bdoResponse["bdo"] as? Map<String, Any>
                    ?: throw Exception("No BDO data in response")

                val bdoPubKey = bdoResponse["pubKey"] as? String
                    ?: throw Exception("No pubKey in response")

                // Determine collection from BDO type
                val collection = determineCollection(bdo)

                Log.d(TAG, "💾 Determined collection: $collection")

                // Load current carrier bag
                val carrierBagJson = prefs.getString(KEY_CARRIER_BAG, null)
                val carrierBag = if (carrierBagJson != null) {
                    @Suppress("UNCHECKED_CAST")
                    gson.fromJson(carrierBagJson, Map::class.java).toMutableMap() as MutableMap<String, Any>
                } else {
                    createEmptyCarrierBag().toMutableMap()
                }

                // Get collection array
                @Suppress("UNCHECKED_CAST")
                val collectionItems = (carrierBag[collection] as? List<Map<String, Any>>)?.toMutableList()
                    ?: mutableListOf()

                // Create item to save
                val item = mapOf(
                    "title" to (bdo["name"] as? String ?: bdo["title"] as? String ?: "Untitled"),
                    "type" to (bdo["type"] as? String ?: "unknown"),
                    "emojicode" to emojicode,
                    "bdoPubKey" to bdoPubKey,
                    "bdoData" to bdo,
                    "metadata" to (bdo["metadata"] ?: emptyMap<String, Any>()),
                    "savedAt" to System.currentTimeMillis()
                )

                // Add to collection (avoid duplicates by checking emojicode)
                val existingIndex = collectionItems.indexOfFirst {
                    it["emojicode"] == emojicode
                }

                if (existingIndex >= 0) {
                    Log.d(TAG, "💾 Item already in $collection, updating...")
                    collectionItems[existingIndex] = item
                } else {
                    Log.d(TAG, "💾 Adding new item to $collection")
                    collectionItems.add(0, item) // Add to beginning
                }

                // Update carrier bag
                carrierBag[collection] = collectionItems

                // Save to SharedPreferences
                val updatedJson = gson.toJson(carrierBag)
                prefs.edit().putString(KEY_CARRIER_BAG, updatedJson).apply()

                Log.d(TAG, "✅ Saved to carrier bag: $collection (${collectionItems.size} items)")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to save to carrier bag", e)
            }
        }
    }

    /**
     * Create affiliate BDO with user as 10% commission payee
     */
    fun createAffiliateBDO(bdoJson: String, onSuccess: (String) -> Unit) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "🔗 Creating affiliate BDO")

                // Parse original BDO
                @Suppress("UNCHECKED_CAST")
                val originalBDO = gson.fromJson(bdoJson, Map::class.java) as Map<String, Any>

                // Get user keys
                val keys = sessionless.getKeys()
                    ?: throw Exception("User keys not found")

                // Get original BDO data
                @Suppress("UNCHECKED_CAST")
                val bdo = originalBDO["bdo"] as? Map<String, Any>
                    ?: throw Exception("No BDO data in response")

                val originalPubKey = originalBDO["pubKey"] as? String
                    ?: throw Exception("No pubKey in response")

                // Get original payees
                @Suppress("UNCHECKED_CAST")
                val originalPayees = (bdo["payees"] as? List<Map<String, Any>>) ?: emptyList()

                // Get home base URL for Addie
                val homeBase = prefs.getString("home_base_url", null)
                    ?: Configuration.addieBaseURL

                // Calculate affiliate payee (10% commission)
                val affiliatePercent = 10
                val affiliatePubKey = keys.publicKey
                val affiliateAddieURL = homeBase

                // Create signature for affiliate payee quad
                val affiliateMessage = affiliatePubKey + affiliateAddieURL + affiliatePercent
                val affiliateSignature = sessionless.sign(affiliateMessage)
                    ?: throw Exception("Failed to sign affiliate payee")

                val affiliatePayee = mapOf(
                    "pubKey" to affiliatePubKey,
                    "addieURL" to affiliateAddieURL,
                    "percent" to affiliatePercent,
                    "signature" to affiliateSignature
                )

                // Adjust original payees to 90% total
                val adjustedPayees = originalPayees.map { payee ->
                    @Suppress("UNCHECKED_CAST")
                    val originalPercent = (payee["percent"] as? Number)?.toInt() ?: 100
                    val adjustedPercent = (originalPercent * 0.9).toInt()

                    payee.toMutableMap().apply {
                        put("percent", adjustedPercent)
                    }
                }

                // New payees array: [affiliate (10%), ...adjusted originals (90% total)]
                val newPayees = listOf(affiliatePayee) + adjustedPayees

                // Create new BDO with updated payees
                val newBDOData = bdo.toMutableMap().apply {
                    put("payees", newPayees)
                }

                // Generate new keys for the affiliate BDO (create separate Sessionless instance)
                val tempSessionless = Sessionless(context)
                val affiliateBDOKeys = tempSessionless.generateKeys()

                // Hash for BDO authentication
                val hash = "The Advancement"

                // Create BDO using BDO service
                val createResult = createBDO(affiliateBDOKeys, hash, newBDOData, tempSessionless)

                val newBDOUUID = createResult["uuid"] as? String
                    ?: throw Exception("No UUID in create response")

                // Make BDO public to get emojicode
                val publicResult = updateBDOPublic(newBDOUUID, affiliateBDOKeys, hash, newBDOData, tempSessionless)

                val emojicode = publicResult["emojiShortcode"] as? String
                    ?: throw Exception("No emojicode generated")

                Log.d(TAG, "✅ Affiliate BDO created with emojicode: $emojicode")

                // Save to carrierBag "store" collection
                saveToCarrierBagStore(newBDOData, emojicode, bdo["title"] as? String ?: bdo["name"] as? String ?: "Untitled")

                // Call success callback with emojicode
                withContext(Dispatchers.Main) {
                    onSuccess(emojicode)
                }

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to create affiliate BDO", e)
            }
        }
    }

    /**
     * Save shared BDO to carrierBag "store" collection
     */
    private suspend fun saveToCarrierBagStore(bdoData: Map<String, Any>, emojicode: String, title: String) {
        Log.d(TAG, "💼 Saving shared BDO to carrierBag store collection")

        // Load current carrier bag
        val carrierBagJson = prefs.getString(KEY_CARRIER_BAG, null)
        val carrierBag = if (carrierBagJson != null) {
            @Suppress("UNCHECKED_CAST")
            gson.fromJson(carrierBagJson, Map::class.java).toMutableMap() as MutableMap<String, Any>
        } else {
            createEmptyCarrierBag().toMutableMap()
        }

        // Get store collection
        @Suppress("UNCHECKED_CAST")
        val storeItems = (carrierBag["store"] as? List<Map<String, Any>>)?.toMutableList()
            ?: mutableListOf()

        // Create item to save with emojicode
        val item = mapOf(
            "title" to title,
            "type" to "shared-link",
            "emojicode" to emojicode,
            "bdoData" to bdoData,
            "sharedAt" to System.currentTimeMillis()
        )

        // Add to beginning of store collection
        storeItems.add(0, item)

        // Update carrier bag
        carrierBag["store"] = storeItems

        // Save to SharedPreferences
        val updatedJson = gson.toJson(carrierBag)
        prefs.edit().putString(KEY_CARRIER_BAG, updatedJson).apply()

        Log.d(TAG, "✅ Saved shared BDO to store collection (${storeItems.size} items)")
    }

    /**
     * Create BDO using BDO service
     */
    private suspend fun createBDO(
        keys: Sessionless.Keys,
        hash: String,
        bdoData: Map<String, Any>,
        sessionlessInstance: Sessionless
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        val url = "${Configuration.bdoBaseURL}/user/create"

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey + hash
        val signature = sessionlessInstance.sign(message)
            ?: throw Exception("Failed to sign create request")

        val body = mapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "hash" to hash,
            "signature" to signature,
            "bdo" to bdoData
        )

        val request = Request.Builder()
            .url(url)
            .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Failed to create BDO: ${response.body?.string()}")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response")

            gson.fromJson(responseBody, Map::class.java) as Map<String, Any>
        }
    }

    /**
     * Update BDO to public status
     */
    private suspend fun updateBDOPublic(
        uuid: String,
        keys: Sessionless.Keys,
        hash: String,
        bdoData: Map<String, Any>,
        sessionlessInstance: Sessionless
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        val url = "${Configuration.bdoBaseURL}/user/$uuid/bdo"

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + uuid + hash
        val signature = sessionlessInstance.sign(message)
            ?: throw Exception("Failed to sign update request")

        val body = mapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "hash" to hash,
            "signature" to signature,
            "bdo" to bdoData,
            "public" to true
        )

        val request = Request.Builder()
            .url(url)
            .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Failed to update BDO: ${response.body?.string()}")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response")

            gson.fromJson(responseBody, Map::class.java) as Map<String, Any>
        }
    }

    /**
     * Determine collection from BDO type
     */
    private fun determineCollection(bdo: Map<String, Any>): String {
        val type = bdo["type"] as? String ?: ""

        return when {
            type == "recipe" || type == "food" -> "cookbook"
            type == "potion" || type == "remedy" -> "apothecary"
            type == "artwork" || type == "image" -> "gallery"
            type == "book" || type == "literature" -> "bookshelf"
            type == "pet" || type == "familiar" -> "familiarPen"
            type == "tool" || type == "machine" -> "machinery"
            type == "gem" || type == "metal" -> "metallics"
            type == "music" || type == "song" || type == "canimus-feed" -> "music"
            type == "prophecy" || type == "divination" -> "oracular"
            type == "plant" || type == "botanical" -> "greenHouse"
            type == "clothing" || type == "garment" -> "closet"
            type == "game" || type == "entertainment" -> "games"
            type == "event" || type == "popup" -> "events"
            type == "contract" || type == "covenant" -> "contracts"
            type == "room" || type == "space" -> "stacks"
            else -> "stacks" // default
        }
    }

    /**
     * Create empty carrier bag with all collections
     */
    private fun createEmptyCarrierBag(): Map<String, Any> {
        return mapOf(
            "cookbook" to emptyList<Any>(),
            "apothecary" to emptyList<Any>(),
            "gallery" to emptyList<Any>(),
            "bookshelf" to emptyList<Any>(),
            "familiarPen" to emptyList<Any>(),
            "machinery" to emptyList<Any>(),
            "metallics" to emptyList<Any>(),
            "music" to emptyList<Any>(),
            "oracular" to emptyList<Any>(),
            "greenHouse" to emptyList<Any>(),
            "closet" to emptyList<Any>(),
            "games" to emptyList<Any>(),
            "events" to emptyList<Any>(),
            "contracts" to emptyList<Any>(),
            "stacks" to emptyList<Any>(),
            "store" to emptyList<Any>(),  // Shared affiliate links
            "links" to emptyList<Any>(),  // Personal links (like linktree)
            "addresses" to emptyList<Any>()  // Shipping addresses for purchases
        )
    }
}

/**
 * Error message data class
 */
data class ErrorMessage(
    val title: String,
    val message: String
)
