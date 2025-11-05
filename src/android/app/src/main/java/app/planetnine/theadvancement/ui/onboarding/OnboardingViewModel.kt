package app.planetnine.theadvancement.ui.onboarding

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
import java.util.concurrent.TimeUnit

/**
 * ViewModel for onboarding flow
 *
 * Handles Planet Nine user creation across services:
 * - Fount (experience/leveling)
 * - BDO (data storage)
 * - Addie (payments)
 * - CarrierBag creation
 */
class OnboardingViewModel(private val context: Context) : ViewModel() {

    companion object {
        private const val TAG = "OnboardingViewModel"
        private const val PREFS_NAME = "the_advancement"
        private const val KEY_FOUNT_UUID = "fount_uuid"
        private const val KEY_BDO_UUID = "bdo_uuid"
        private const val KEY_ADDIE_UUID = "addie_uuid"
        private const val KEY_USER_PUBKEY = "user_pubkey"
    }

    private val _loadingState = MutableStateFlow(LoadingState.Idle)
    val loadingState: StateFlow<LoadingState> = _loadingState.asStateFlow()

    private val _loadingMessage = MutableStateFlow("")
    val loadingMessage: StateFlow<String> = _loadingMessage.asStateFlow()

    private val _errorMessage = MutableStateFlow("")
    val errorMessage: StateFlow<String> = _errorMessage.asStateFlow()

    private val sessionless = Sessionless(context)
    private val gson = Gson()
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Start the onboarding process
     */
    fun joinAdvancement() {
        viewModelScope.launch {
            try {
                _loadingState.value = LoadingState.Loading
                _loadingMessage.value = "Generating cryptographic keys..."

                createPlanetNineUsers()

                _loadingMessage.value = "Welcome to The Advancement!"
                Log.d(TAG, "✅ Onboarding complete!")

                // Small delay to show success message
                kotlinx.coroutines.delay(1000)

                _loadingState.value = LoadingState.Idle

            } catch (e: Exception) {
                Log.e(TAG, "❌ Onboarding failed: ${e.message}", e)
                e.printStackTrace()
                _loadingState.value = LoadingState.Error
                _errorMessage.value = e.message ?: "Unknown error"

                // Auto-reset error state after 3 seconds
                kotlinx.coroutines.delay(3000)
                _loadingState.value = LoadingState.Idle
                _errorMessage.value = ""
            }
        }
    }

    private suspend fun createPlanetNineUsers() = withContext(Dispatchers.IO) {
        Log.d(TAG, "🚀 Creating Planet Nine users...")

        // Generate or get existing keys
        val keys = sessionless.getKeys() ?: sessionless.generateKeys()
        val userPubKey = keys.publicKey

        // Save pubKey
        prefs.edit().putString(KEY_USER_PUBKEY, userPubKey).apply()

        Log.d(TAG, "🔑 User pubKey: $userPubKey")

        val timestamp = System.currentTimeMillis().toString()

        // Create signature for user creation
        val message = timestamp + userPubKey
        val signature = sessionless.sign(message)
            ?: throw Exception("Failed to sign message")

        // Create Fount user
        withContext(Dispatchers.Main) {
            _loadingMessage.value = "Creating Fount user..."
        }
        val fountUUID = createFountUser(userPubKey, timestamp, signature)

        // Create BDO user
        withContext(Dispatchers.Main) {
            _loadingMessage.value = "Creating BDO user..."
        }
        val bdoUUID = createBDOUser(userPubKey)

        // Create carrierBag
        withContext(Dispatchers.Main) {
            _loadingMessage.value = "Creating carrierBag..."
        }
        createCarrierBag(bdoUUID, userPubKey)

        // Create Addie user
        withContext(Dispatchers.Main) {
            _loadingMessage.value = "Creating payment user..."
        }
        createAddieUser(userPubKey)

        Log.d(TAG, "✅ Planet Nine users created successfully!")
        Log.d(TAG, "✅ Fount UUID: $fountUUID")
        Log.d(TAG, "✅ BDO UUID: $bdoUUID")
    }

    private fun createFountUser(pubKey: String, timestamp: String, signature: String): String {
        val url = Configuration.Fount.createUser()
        Log.d(TAG, "Creating Fount user at: $url")

        val body = mapOf(
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "signature" to signature
        )

        val bodyJson = gson.toJson(body)
        Log.d(TAG, "Request body: $bodyJson")
        Log.d(TAG, "Signature length: ${signature.length}")
        Log.d(TAG, "Message to verify: $timestamp$pubKey")

        val request = Request.Builder()
            .url(url)
            .put(bodyJson.toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            Log.d(TAG, "Fount response code: ${response.code}, body: $responseBody")

            if (!response.isSuccessful) {
                throw Exception("Fount error (${response.code}): $responseBody")
            }

            val responseMap = gson.fromJson(responseBody, Map::class.java)
            val userUUID = responseMap["uuid"] as? String
                ?: throw Exception("Failed to parse Fount user response")

            // Save UUID
            prefs.edit().putString(KEY_FOUNT_UUID, userUUID).apply()

            Log.d(TAG, "✅ Fount user created: $userUUID")
            return userUUID
        }
    }

    private fun createBDOUser(pubKey: String): String {
        val url = Configuration.BDO.createUser()

        val timestamp = System.currentTimeMillis().toString()
        val hash = "the-advancement"
        val message = timestamp + pubKey + hash
        val signature = sessionless.sign(message)
            ?: throw Exception("Failed to sign BDO user creation")

        val body = mapOf(
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "hash" to hash,
            "signature" to signature
        )

        val request = Request.Builder()
            .url(url)
            .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("BDO error: ${response.body?.string()}")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response from BDO")

            val responseMap = gson.fromJson(responseBody, Map::class.java)
            val userUUID = responseMap["uuid"] as? String
                ?: throw Exception("Failed to parse BDO user response")

            // Save UUID
            prefs.edit().putString(KEY_BDO_UUID, userUUID).apply()

            Log.d(TAG, "✅ BDO user created: $userUUID")
            return userUUID
        }
    }

    private fun createCarrierBag(userUUID: String, pubKey: String) {
        val url = Configuration.BDO.putBDO(userUUID)

        // Create empty carrierBag with all collections
        val carrierBagData = mapOf(
            "type" to "carrierBag",
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
            "stacks" to emptyList<Any>()
        )

        val timestamp = System.currentTimeMillis().toString()
        val hash = ""
        val message = timestamp + hash + pubKey
        val signature = sessionless.sign(message)
            ?: throw Exception("Failed to sign carrierBag creation")

        val body = mapOf(
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "hash" to hash,
            "signature" to signature,
            "bdo" to carrierBagData
        )

        val request = Request.Builder()
            .url(url)
            .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful && response.code != 201) {
                throw Exception("CarrierBag creation failed: ${response.body?.string()}")
            }

            Log.d(TAG, "✅ CarrierBag created successfully")
        }
    }

    private fun createAddieUser(pubKey: String) {
        val url = Configuration.Addie.createUser()

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + pubKey
        val signature = sessionless.sign(message)
            ?: throw Exception("Failed to sign Addie user creation")

        val body = mapOf(
            "pubKey" to pubKey,
            "timestamp" to timestamp,
            "signature" to signature
        )

        val request = Request.Builder()
            .url(url)
            .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Addie error: ${response.body?.string()}")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response from Addie")

            val responseMap = gson.fromJson(responseBody, Map::class.java)
            val userUUID = responseMap["uuid"] as? String
                ?: throw Exception("Failed to parse Addie user response")

            // Save UUID
            prefs.edit().putString(KEY_ADDIE_UUID, userUUID).apply()

            Log.d(TAG, "✅ Addie user created: $userUUID")
        }
    }

    /**
     * Check if user has already completed onboarding
     */
    fun isOnboardingComplete(): Boolean {
        val fountUUID = prefs.getString(KEY_FOUNT_UUID, null)
        val bdoUUID = prefs.getString(KEY_BDO_UUID, null)
        return fountUUID != null && bdoUUID != null
    }
}
