package app.planetnine.theadvancement.ui.carrierbag

import android.content.Intent
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
import app.planetnine.theadvancement.ui.music.MusicPlayerActivity
import app.planetnine.theadvancement.ui.theme.TheAdvancementTheme
import com.google.gson.Gson
import kotlinx.coroutines.delay

/**
 * Carrier Bag Activity
 *
 * Displays the user's carrier bag with all saved collections
 * Uses WebView to display CarrierBag.html
 */
class CarrierBagActivity : ComponentActivity() {

    companion object {
        const val EXTRA_CARRIER_BAG_JSON = "carrier_bag_json"
        private const val TAG = "CarrierBagActivity"
    }

    private lateinit var webView: WebView
    private val gson = Gson()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val carrierBagJson = intent.getStringExtra(EXTRA_CARRIER_BAG_JSON) ?: "{}"

        Log.d(TAG, "🎒 CarrierBagActivity loaded")
        Log.d(TAG, "🎒 Carrier bag data: $carrierBagJson")

        enableEdgeToEdge()

        setContent {
            TheAdvancementTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color(0xFF1A0033) // Dark purple background
                ) {
                    CarrierBagWebView(
                        carrierBagJson = carrierBagJson,
                        onWebViewCreated = { wv ->
                            webView = wv
                        }
                    )
                }
            }
        }
    }

    @Composable
    fun CarrierBagWebView(
        carrierBagJson: String,
        onWebViewCreated: (WebView) -> Unit
    ) {
        var webViewInitialized by remember { mutableStateOf(false) }

        AndroidView(
            factory = { context ->
                WebView(context).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    settings.allowFileAccess = true

                    // Add JavaScript interface for item selection
                    addJavascriptInterface(
                        CarrierBagJSInterface(this@CarrierBagActivity),
                        "Android"
                    )

                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView?, url: String?) {
                            Log.d(TAG, "✅ CarrierBag.html loaded")
                            webViewInitialized = true
                        }
                    }

                    loadUrl("file:///android_asset/CarrierBag.html")
                    onWebViewCreated(this)
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // Update carrier bag data after WebView loads
        LaunchedEffect(webViewInitialized) {
            if (webViewInitialized) {
                delay(300) // Wait for JavaScript to be ready
                updateCarrierBagData(carrierBagJson)
            }
        }
    }

    /**
     * Update carrier bag data in WebView
     */
    private fun updateCarrierBagData(carrierBagJson: String) {
        if (!::webView.isInitialized) {
            Log.w(TAG, "⚠️ WebView not initialized yet")
            return
        }

        val javascript = "window.updateCarrierBag($carrierBagJson);"

        runOnUiThread {
            webView.evaluateJavascript(javascript) { result ->
                if (result != null) {
                    Log.d(TAG, "✅ Carrier bag updated in WebView")
                } else {
                    Log.e(TAG, "❌ Failed to update carrier bag")
                }
            }
        }
    }

    /**
     * Handle item selection from JavaScript
     */
    fun onItemSelected(collectionName: String, index: Int, itemJson: String) {
        Log.d(TAG, "📖 Item selected from $collectionName at index $index")
        Log.d(TAG, "📖 Item data: $itemJson")

        try {
            val item = gson.fromJson(itemJson, Map::class.java)

            // Special handling for music items - open audio player
            if (collectionName == "music") {
                openMusicPlayer(item)
                return
            }

            // For other items, show details (could add a dialog here)
            Log.d(TAG, "📖 Item title: ${item["title"]}")
            Log.d(TAG, "📖 Item emojicode: ${item["emojicode"]}")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to parse item data", e)
        }
    }

    /**
     * Open music player with feed URL
     */
    private fun openMusicPlayer(item: Map<*, *>) {
        Log.d(TAG, "🎵 Opening music player")

        // Try to get feedUrl from various possible locations
        val feedUrl: String? = when {
            item["feedUrl"] is String -> {
                Log.d(TAG, "🎵 Found feedUrl at top level")
                item["feedUrl"] as String
            }
            item["metadata"] is Map<*, *> -> {
                val metadata = item["metadata"] as Map<*, *>
                if (metadata["feedUrl"] is String) {
                    Log.d(TAG, "🎵 Found feedUrl in metadata")
                    metadata["feedUrl"] as String
                } else null
            }
            item["bdoData"] is Map<*, *> -> {
                val bdoData = item["bdoData"] as Map<*, *>
                val metadata = bdoData["metadata"] as? Map<*, *>
                if (metadata?["feedUrl"] is String) {
                    Log.d(TAG, "🎵 Found feedUrl in bdoData.metadata")
                    metadata["feedUrl"] as String
                } else null
            }
            else -> {
                Log.w(TAG, "🎵 No feedUrl found!")
                null
            }
        }

        if (feedUrl != null) {
            val title = item["title"] as? String ?: "Music"
            Log.d(TAG, "🎵 Opening player with URL: $feedUrl")

            val intent = Intent(this, MusicPlayerActivity::class.java).apply {
                putExtra(MusicPlayerActivity.EXTRA_FEED_URL, feedUrl)
                putExtra(MusicPlayerActivity.EXTRA_FEED_TITLE, title)
            }
            startActivity(intent)
        } else {
            Log.w(TAG, "⚠️ Music item has no feedUrl")
        }
    }

    /**
     * JavaScript interface for CarrierBag.html
     */
    class CarrierBagJSInterface(private val activity: CarrierBagActivity) {
        @JavascriptInterface
        fun onItemSelected(collectionName: String, index: Int, itemJson: String) {
            activity.onItemSelected(collectionName, index, itemJson)
        }

        @JavascriptInterface
        fun log(message: String) {
            Log.d(TAG, "WebView: $message")
        }
    }
}
