package app.planetnine.theadvancement.ui.payment

import android.content.Context
import android.os.Bundle
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.viewinterop.AndroidView
import app.planetnine.theadvancement.crypto.Sessionless
import app.planetnine.theadvancement.ui.theme.TheAdvancementTheme
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

/**
 * Payment Method Activity
 *
 * Displays payment methods and card issuance interface
 * Uses WebView to display PaymentMethod.html
 */
class PaymentMethodActivity : ComponentActivity() {

    companion object {
        private const val TAG = "PaymentMethodActivity"
        private const val DEFAULT_HOME_BASE = "http://10.0.2.2:7243" // Android emulator localhost
    }

    private lateinit var webView: WebView
    private lateinit var sessionless: Sessionless
    private val gson = Gson()
    private val httpClient = OkHttpClient()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sessionless = Sessionless(applicationContext)

        Log.d(TAG, "💳 PaymentMethodActivity loaded")

        enableEdgeToEdge()

        setContent {
            TheAdvancementTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color(0xFF1A0033) // Dark purple background
                ) {
                    PaymentMethodWebView(
                        onWebViewCreated = { wv ->
                            webView = wv
                        }
                    )
                }
            }
        }
    }

    @Composable
    fun PaymentMethodWebView(
        onWebViewCreated: (WebView) -> Unit
    ) {
        var webViewInitialized by remember { mutableStateOf(false) }

        AndroidView(
            factory = { context ->
                WebView(context).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    settings.allowFileAccess = true

                    // Add JavaScript interface
                    addJavascriptInterface(
                        PaymentMethodJSInterface(this@PaymentMethodActivity),
                        "Android"
                    )

                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView?, url: String?) {
                            Log.d(TAG, "✅ PaymentMethod.html loaded")
                            webViewInitialized = true
                        }
                    }

                    loadUrl("file:///android_asset/PaymentMethod.html")
                    onWebViewCreated(this)
                }
            },
            modifier = Modifier.fillMaxSize()
        )
    }

    /**
     * Get home base URL from SharedPreferences
     */
    private fun getHomeBaseURL(): String {
        val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
        return prefs.getString("home_base_url", DEFAULT_HOME_BASE) ?: DEFAULT_HOME_BASE
    }

    /**
     * Make authenticated HTTP request to Addie
     */
    private suspend fun makeAuthenticatedRequest(
        endpoint: String,
        method: String,
        body: Map<String, Any>? = null
    ): Map<String, Any> = withContext(Dispatchers.IO) {
        try {
            val keys = sessionless.getKeys()
            if (keys == null) {
                Log.e(TAG, "❌ No keys found")
                return@withContext mapOf("error" to "Authentication required")
            }

            val homeBase = getHomeBaseURL()
            val url = "$homeBase$endpoint"

            Log.d(TAG, "🌐 Making request to: $url")

            val request = when (method.uppercase()) {
                "GET" -> {
                    Request.Builder()
                        .url(url)
                        .get()
                        .build()
                }
                "POST", "PATCH" -> {
                    val jsonBody = gson.toJson(body ?: emptyMap<String, Any>())
                    val mediaType = "application/json; charset=utf-8".toMediaType()

                    Request.Builder()
                        .url(url)
                        .method(method.uppercase(), jsonBody.toRequestBody(mediaType))
                        .build()
                }
                "DELETE" -> {
                    Request.Builder()
                        .url(url)
                        .delete()
                        .build()
                }
                else -> throw IllegalArgumentException("Unsupported HTTP method: $method")
            }

            val response = httpClient.newCall(request).execute()
            val responseBody = response.body?.string() ?: "{}"

            Log.d(TAG, "📥 Response (${response.code}): $responseBody")

            if (!response.isSuccessful) {
                Log.e(TAG, "❌ Request failed with code: ${response.code}")
                return@withContext mapOf("error" to "Request failed: ${response.code}")
            }

            @Suppress("UNCHECKED_CAST")
            gson.fromJson(responseBody, Map::class.java) as Map<String, Any>

        } catch (e: IOException) {
            Log.e(TAG, "❌ Network error", e)
            mapOf("error" to "Network error: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Request error", e)
            mapOf("error" to "Error: ${e.message}")
        }
    }

    /**
     * Sign a message with Sessionless
     */
    private fun signMessage(message: String): String? {
        return sessionless.sign(message)
    }

    /**
     * Create SetupIntent for saving cards
     */
    suspend fun createSetupIntent(): String {
        Log.d(TAG, "🔧 Creating SetupIntent...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val body = mutableMapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "signature" to signature
        )

        val result = makeAuthenticatedRequest("/processor/stripe/setup-intent", "POST", body)
        return gson.toJson(result)
    }

    /**
     * Handle successful setup intent
     */
    suspend fun setupIntentSucceeded(paramsJson: String): String {
        Log.d(TAG, "✅ SetupIntent succeeded")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val setupIntentId = params["setupIntentId"] as? String
        val paymentMethodId = params["paymentMethodId"] as? String

        Log.d(TAG, "SetupIntent ID: $setupIntentId")
        Log.d(TAG, "Payment Method ID: $paymentMethodId")

        // For now, just return success - in production, we'd save this to user's account
        return gson.toJson(mapOf("success" to true))
    }

    /**
     * Get saved cards
     */
    suspend fun getSavedCards(): String {
        Log.d(TAG, "📋 Getting saved cards...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("cards" to emptyList<Any>()))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("cards" to emptyList<Any>()))
        }

        val endpoint = "/saved-payment-methods?timestamp=$timestamp&processor=stripe&pubKey=${keys.publicKey}&signature=$signature"
        val result = makeAuthenticatedRequest(endpoint, "GET")

        // Transform Stripe payment methods to card format
        val paymentMethods = result["paymentMethods"] as? List<Map<String, Any>> ?: emptyList()
        val cards = paymentMethods.mapNotNull { pm ->
            val card = pm["card"] as? Map<String, Any> ?: return@mapNotNull null
            mapOf(
                "id" to (pm["id"] ?: ""),
                "brand" to (card["brand"] ?: ""),
                "last4" to (card["last4"] ?: ""),
                "exp_month" to (card["exp_month"] ?: ""),
                "exp_year" to (card["exp_year"] ?: "")
            )
        }

        return gson.toJson(mapOf("cards" to cards))
    }

    /**
     * Delete payment method
     */
    suspend fun deletePaymentMethod(paramsJson: String): String {
        Log.d(TAG, "🗑️ Deleting payment method...")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val paymentMethodId = params["paymentMethodId"] as? String
            ?: return gson.toJson(mapOf("error" to "Missing paymentMethodId"))

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val endpoint = "/saved-payment-methods/$paymentMethodId?timestamp=$timestamp&processor=stripe&pubKey=${keys.publicKey}&signature=$signature"
        val result = makeAuthenticatedRequest(endpoint, "DELETE")

        return gson.toJson(result)
    }

    /**
     * Create cardholder account
     */
    suspend fun createCardholder(paramsJson: String): String {
        Log.d(TAG, "👤 Creating cardholder...")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val individualInfo = params["individualInfo"] as? Map<String, Any>
            ?: return gson.toJson(mapOf("error" to "Missing individual info"))

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val body = mapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "signature" to signature,
            "individualInfo" to individualInfo
        )

        val result = makeAuthenticatedRequest("/issuing/cardholder", "POST", body)
        return gson.toJson(result)
    }

    /**
     * Get cardholder status
     */
    suspend fun getCardholderStatus(): String {
        Log.d(TAG, "🔍 Checking cardholder status...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("hasCardholder" to false))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("hasCardholder" to false))
        }

        val endpoint = "/issuing/cardholder/status?timestamp=$timestamp&pubKey=${keys.publicKey}&signature=$signature"
        val result = makeAuthenticatedRequest(endpoint, "GET")

        return gson.toJson(result)
    }

    /**
     * Issue virtual card
     */
    suspend fun issueVirtualCard(paramsJson: String): String {
        Log.d(TAG, "🌐 Issuing virtual card...")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val spendingLimit = params["spendingLimit"] as? Double ?: 100000.0

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val body = mapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "signature" to signature,
            "currency" to "usd",
            "spendingLimit" to spendingLimit.toInt()
        )

        val result = makeAuthenticatedRequest("/issuing/card/virtual", "POST", body)
        return gson.toJson(result)
    }

    /**
     * Get issued cards
     */
    suspend fun getIssuedCards(): String {
        Log.d(TAG, "📋 Getting issued cards...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("cards" to emptyList<Any>()))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("cards" to emptyList<Any>()))
        }

        val endpoint = "/issuing/cards?timestamp=$timestamp&pubKey=${keys.publicKey}&signature=$signature"
        val result = makeAuthenticatedRequest(endpoint, "GET")

        return gson.toJson(result)
    }

    /**
     * Get card details (full number, CVC)
     */
    suspend fun getCardDetails(paramsJson: String): String {
        Log.d(TAG, "🔍 Getting card details...")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val cardId = params["cardId"] as? String
            ?: return gson.toJson(mapOf("error" to "Missing cardId"))

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey + cardId
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val endpoint = "/issuing/card/$cardId/details?timestamp=$timestamp&pubKey=${keys.publicKey}&signature=$signature"
        val result = makeAuthenticatedRequest(endpoint, "GET")

        return gson.toJson(result)
    }

    /**
     * Update card status (freeze/unfreeze/cancel)
     */
    suspend fun updateCardStatus(paramsJson: String): String {
        Log.d(TAG, "🔄 Updating card status...")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val cardId = params["cardId"] as? String
            ?: return gson.toJson(mapOf("error" to "Missing cardId"))
        val status = params["status"] as? String
            ?: return gson.toJson(mapOf("error" to "Missing status"))

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey + cardId + status
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val body = mapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "signature" to signature,
            "status" to status
        )

        val result = makeAuthenticatedRequest("/issuing/card/$cardId/status", "PATCH", body)
        return gson.toJson(result)
    }

    /**
     * Get transactions
     */
    suspend fun getTransactions(): String {
        Log.d(TAG, "📊 Getting transactions...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("transactions" to emptyList<Any>()))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("transactions" to emptyList<Any>()))
        }

        val endpoint = "/issuing/transactions?timestamp=$timestamp&pubKey=${keys.publicKey}&signature=$signature&limit=10"
        val result = makeAuthenticatedRequest(endpoint, "GET")

        return gson.toJson(result)
    }

    /**
     * Save Payout Card for receiving affiliate payouts
     */
    suspend fun savePayoutCard(paramsJson: String): String {
        Log.d(TAG, "💳 Saving payout card...")

        val params = gson.fromJson(paramsJson, Map::class.java)
        val paymentMethodId = params["paymentMethodId"] as? String
            ?: return gson.toJson(mapOf("error" to "Missing paymentMethodId"))

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "Authentication required"))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey + paymentMethodId
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("error" to "Failed to sign request"))
        }

        val body = mapOf(
            "timestamp" to timestamp,
            "pubKey" to keys.publicKey,
            "signature" to signature,
            "paymentMethodId" to paymentMethodId
        )

        val result = makeAuthenticatedRequest("/payout-card/save", "POST", body)

        // Store payout card ID if returned
        if (result["payoutCardId"] != null) {
            val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
            prefs.edit().putString("stripe_payout_card_id", result["payoutCardId"] as String).apply()
            Log.d(TAG, "💳 Saved payout card ID")
        }

        return gson.toJson(result)
    }

    /**
     * Get Payout Card status
     */
    suspend fun getPayoutCardStatus(): String {
        Log.d(TAG, "🔍 Checking payout card status...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("hasPayoutCard" to false))
        }

        val timestamp = System.currentTimeMillis().toString()
        val message = timestamp + keys.publicKey
        val signature = signMessage(message)

        if (signature == null) {
            return gson.toJson(mapOf("hasPayoutCard" to false))
        }

        val endpoint = "/payout-card/status?timestamp=$timestamp&pubKey=${keys.publicKey}&signature=$signature"
        val result = makeAuthenticatedRequest(endpoint, "GET")

        return gson.toJson(result)
    }

    /**
     * Get Service Info for base admin sharing
     */
    suspend fun getServiceInfo(): String {
        Log.d(TAG, "🔑 Getting service info...")

        val keys = sessionless.getKeys()
        if (keys == null) {
            return gson.toJson(mapOf("error" to "No authentication keys found"))
        }

        val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)

        // Get UUIDs from SharedPreferences
        val fountUUID = prefs.getString("fount_user_uuid", null) ?: "Not available"
        val covenantUUID = prefs.getString("covenant_user_uuid", null) ?: "Not available"
        val addieUUID = prefs.getString("addie_user_uuid", null) ?: "Not available"

        val result = mapOf(
            "fountUUID" to fountUUID,
            "covenantUUID" to covenantUUID,
            "addieUUID" to addieUUID,
            "pubKey" to keys.publicKey
        )

        return gson.toJson(result)
    }

    /**
     * JavaScript interface for PaymentMethod.html
     */
    class PaymentMethodJSInterface(private val activity: PaymentMethodActivity) {

        @JavascriptInterface
        fun createSetupIntent(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.createSetupIntent()
            }
            return result
        }

        @JavascriptInterface
        fun setupIntentSucceeded(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.setupIntentSucceeded(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun getSavedCards(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getSavedCards()
            }
            return result
        }

        @JavascriptInterface
        fun deletePaymentMethod(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.deletePaymentMethod(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun createCardholder(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.createCardholder(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun getCardholderStatus(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getCardholderStatus()
            }
            return result
        }

        @JavascriptInterface
        fun issueVirtualCard(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.issueVirtualCard(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun getIssuedCards(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getIssuedCards()
            }
            return result
        }

        @JavascriptInterface
        fun getCardDetails(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getCardDetails(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun updateCardStatus(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.updateCardStatus(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun getTransactions(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getTransactions()
            }
            return result
        }

        @JavascriptInterface
        fun savePayoutCard(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.savePayoutCard(paramsJson)
            }
            return result
        }

        @JavascriptInterface
        fun getPayoutCardStatus(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getPayoutCardStatus()
            }
            return result
        }

        @JavascriptInterface
        fun getServiceInfo(paramsJson: String): String {
            var result = ""
            kotlinx.coroutines.runBlocking {
                result = activity.getServiceInfo()
            }
            return result
        }

        @JavascriptInterface
        fun log(message: String) {
            Log.d(TAG, "WebView: $message")
        }
    }
}
