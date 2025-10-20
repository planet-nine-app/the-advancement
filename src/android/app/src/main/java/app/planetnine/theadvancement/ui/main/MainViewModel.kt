package app.planetnine.theadvancement.ui.main

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.planetnine.theadvancement.config.Configuration
import app.planetnine.theadvancement.crypto.Sessionless
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
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * ViewModel for main screen
 *
 * Handles BDO posting with sessionless authentication
 */
class MainViewModel(private val context: Context) : ViewModel() {

    companion object {
        private const val TAG = "MainViewModel"
        private const val PREFS_NAME = "the_advancement"
        private const val KEY_BDO_UUID = "bdo_uuid"
        private const val KEY_USER_PUBKEY = "user_pubkey"
    }

    private val _postedBDOs = MutableStateFlow<List<PostedBDO>>(emptyList())
    val postedBDOs: StateFlow<List<PostedBDO>> = _postedBDOs.asStateFlow()

    private val _isPosting = MutableStateFlow(false)
    val isPosting: StateFlow<Boolean> = _isPosting.asStateFlow()

    private val sessionless = Sessionless(context)
    private val gson = Gson()
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Post a text BDO to the Planet Nine network
     */
    fun postBDO(text: String) {
        if (text.isEmpty()) return

        viewModelScope.launch {
            try {
                _isPosting.value = true

                val result = postTextBDO(text)

                // Add to list of posted BDOs
                val currentList = _postedBDOs.value.toMutableList()
                currentList.add(0, result) // Add to beginning
                _postedBDOs.value = currentList

                // Save to SharedPreferences for AdvanceKey access
                savePostedBDOs(currentList)

                Log.d(TAG, "✅ BDO posted successfully!")
                Log.d(TAG, "✅ Emojicode: ${result.emojicode}")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to post BDO", e)
            } finally {
                _isPosting.value = false
            }
        }
    }

    init {
        // Load previously posted BDOs
        loadPostedBDOs()
    }

    private suspend fun postTextBDO(text: String): PostedBDO = withContext(Dispatchers.IO) {
        // Get user info
        val bdoUUID = prefs.getString(KEY_BDO_UUID, null)
            ?: throw Exception("BDO UUID not found")

        val keys = sessionless.getKeys()
            ?: throw Exception("User keys not found")

        val pubKey = keys.publicKey

        // Create timestamp
        val timestamp = System.currentTimeMillis().toString()

        // Generate SVG for this BDO (simplified version matching iOS)
        val svg = generateBDOSVG(text)

        // Create BDO data
        val bdoData = mapOf(
            "type" to "text-post",
            "text" to text,
            "svgContent" to svg,
            "created" to timestamp
        )

        // Use static hash (matching iOS implementation)
        val hash = "the-advancement"

        // Sign message: timestamp + uuid + hash
        val message = timestamp + bdoUUID + hash
        val signature = sessionless.sign(message)
            ?: throw Exception("Failed to sign BDO")

        Log.d(TAG, "📝 Posting BDO...")
        Log.d(TAG, "   Text: $text")
        Log.d(TAG, "   Hash: $hash")
        Log.d(TAG, "   Signature: ${signature.take(20)}...")

        // Post to BDO service
        val url = Configuration.BDO.putBDO(bdoUUID)

        val body = mapOf(
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "hash" to hash,
            "signature" to signature,
            "bdo" to bdoData
        )

        val request = Request.Builder()
            .url(url)
            .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful && response.code != 201) {
                val errorBody = response.body?.string() ?: "Unknown error"
                throw Exception("BDO posting failed: $errorBody")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response from BDO service")

            Log.d(TAG, "📥 Response: $responseBody")

            // Parse response for emojicode
            val responseMap = gson.fromJson(responseBody, Map::class.java)
            val emojicode = responseMap["emojiShortcode"] as? String ?: ""

            // Format timestamp for display
            val dateFormat = SimpleDateFormat("MMM dd, yyyy 'at' HH:mm", Locale.getDefault())
            val formattedTime = dateFormat.format(Date())

            PostedBDO(
                text = text,
                emojicode = emojicode,
                timestamp = formattedTime
            )
        }
    }

    /**
     * Generate SVG for BDO (simplified version matching iOS)
     */
    private fun generateBDOSVG(text: String): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 30" preserveAspectRatio="xMidYMid meet">
                <defs>
                    <filter id="glow">
                        <feGaussianBlur stdDeviation="0.5" result="coloredBlur"/>
                        <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
                    </filter>
                    <radialGradient id="bgGradient" cx="50%" cy="50%" r="70%">
                        <stop offset="0%" style="stop-color:#1a0033; stop-opacity:1" />
                        <stop offset="100%" style="stop-color:#000000; stop-opacity:1" />
                    </radialGradient>
                </defs>

                <rect width="100" height="30" fill="url(#bgGradient)"/>

                <rect x="2" y="2" width="96" height="26" rx="2" fill="rgba(139, 92, 246, 0.15)"
                      stroke="#8b5cf6" stroke-width="0.25" filter="url(#glow)" opacity="0.9"/>

                <text x="50" y="18" text-anchor="middle"
                      style="font-family: -apple-system; font-size: 4px; font-weight: 500;"
                      fill="#ffffff" filter="url(#glow)">
                    ${escapeXml(text.take(50))}
                </text>
            </svg>
        """.trimIndent()
    }

    /**
     * Calculate SHA-256 hash of BDO data
     */
    private fun calculateHash(data: Map<String, Any>): String {
        val json = gson.toJson(data)
        val bytes = MessageDigest.getInstance("SHA-256").digest(json.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }

    /**
     * Escape XML special characters
     */
    private fun escapeXml(text: String): String {
        return text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }

    /**
     * Save posted BDOs to SharedPreferences for AdvanceKey access
     */
    private fun savePostedBDOs(bdos: List<PostedBDO>) {
        try {
            val bdosJson = gson.toJson(bdos)
            prefs.edit().putString("posted_bdos", bdosJson).apply()
            Log.d(TAG, "📦 Saved ${bdos.size} posted BDOs")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save posted BDOs", e)
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
                Log.d(TAG, "📦 Loaded ${bdos.size} posted BDOs")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load posted BDOs", e)
        }
    }
}
