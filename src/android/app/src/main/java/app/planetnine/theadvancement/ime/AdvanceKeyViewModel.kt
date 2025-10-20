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
    }

    private val _clipboardText = MutableStateFlow("")
    val clipboardText: StateFlow<String> = _clipboardText.asStateFlow()

    private val _decodedBDO = MutableStateFlow<Map<String, Any>?>(null)
    val decodedBDO: StateFlow<Map<String, Any>?> = _decodedBDO.asStateFlow()

    private val _postedBDOs = MutableStateFlow<List<PostedBDO>>(emptyList())
    val postedBDOs: StateFlow<List<PostedBDO>> = _postedBDOs.asStateFlow()

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
     * Monitor clipboard for emojicode patterns
     */
    private fun monitorClipboard() {
        try {
            val clipboardManager = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            clipboardManager?.addPrimaryClipChangedListener {
                val clipData = clipboardManager.primaryClip
                if (clipData != null && clipData.itemCount > 0) {
                    val text = clipData.getItemAt(0).text?.toString() ?: ""

                    // Check if it looks like an emojicode (8 emoji characters)
                    if (isEmojicode(text)) {
                        _clipboardText.value = text
                        Log.d(TAG, "Detected emojicode in clipboard: $text")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to monitor clipboard", e)
        }
    }

    /**
     * Check if text looks like an emojicode (8 emoji characters)
     */
    private fun isEmojicode(text: String): Boolean {
        // Rough check: emojicodes are typically 8-32 characters (8 emojis in UTF-16)
        val trimmed = text.trim()
        return trimmed.length in 8..32 && trimmed.any { it.code > 0x1F000 }
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

                Log.d(TAG, "✅ BDO decoded successfully")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to decode emojicode", e)
            }
        }
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

                val result = resolveSpell(spellName, fountUUID, keys.publicKey, timestamp, signature)

                Log.d(TAG, "✅ Spell cast successfully: $result")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to cast spell", e)
            }
        }
    }

    /**
     * Resolve spell through Fount
     */
    private suspend fun resolveSpell(
        spellName: String,
        userUUID: String,
        pubKey: String,
        timestamp: String,
        signature: String
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        val url = Configuration.Fount.resolve(spellName)

        val body = mapOf(
            "userUUID" to userUUID,
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "signature" to signature
        )

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
}
