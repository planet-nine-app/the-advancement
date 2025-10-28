package app.planetnine.theadvancement.ui.carrierbag

import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.util.Log
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
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
import java.text.SimpleDateFormat
import java.util.*

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

            // Special handling for addresses
            if (collectionName == "addresses") {
                showAddressDetails(item as Map<String, Any>, index)
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
     * Show address details with edit/delete options
     */
    private fun showAddressDetails(address: Map<String, Any>, index: Int) {
        Log.d(TAG, "📮 Showing address details at index $index")

        val name = address["name"] as? String ?: "Address"
        val recipientName = address["recipientName"] as? String ?: ""
        val street = address["street"] as? String ?: ""
        val street2 = address["street2"] as? String ?: ""
        val city = address["city"] as? String ?: ""
        val state = address["state"] as? String ?: ""
        val zip = address["zip"] as? String ?: ""
        val country = address["country"] as? String ?: "US"
        val phone = address["phone"] as? String ?: ""
        val isPrimary = address["isPrimary"] as? Boolean ?: false

        val message = buildString {
            append(recipientName)
            append("\n")
            append(street)
            append("\n")
            if (street2.isNotEmpty()) {
                append(street2)
                append("\n")
            }
            append("$city, $state $zip")
            append("\n")
            append(country)
            if (phone.isNotEmpty()) {
                append("\n\nPhone: $phone")
            }
            if (isPrimary) {
                append("\n\n⭐️ Primary Address")
            }
        }

        runOnUiThread {
            AlertDialog.Builder(this)
                .setTitle(name)
                .setMessage(message)
                .setPositiveButton("Edit") { _, _ ->
                    showAddressForm(address, index)
                }
                .setNeutralButton(if (isPrimary) "Primary" else "Set as Primary") { _, _ ->
                    if (!isPrimary) {
                        setAddressAsPrimary(index)
                    }
                }
                .setNegativeButton("Delete") { _, _ ->
                    removeAddress(index)
                }
                .show()
        }
    }

    /**
     * Handle add new address request
     */
    fun onAddAddress() {
        Log.d(TAG, "📮 Add new address requested")
        runOnUiThread {
            showAddressForm(null, null)
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
     * Show address form dialog
     */
    private fun showAddressForm(existingAddress: Map<String, Any>?, index: Int?) {
        Log.d(TAG, "📮 Showing address form (editing: ${existingAddress != null})")

        val scrollView = ScrollView(this)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val padding = (16 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }

        // Create fields
        val nameField = createTextField(this, "Address Name (e.g., Home, Work)", existingAddress?.get("name") as? String ?: "")
        val recipientNameField = createTextField(this, "Recipient Name", existingAddress?.get("recipientName") as? String ?: "")
        val streetField = createTextField(this, "Street Address", existingAddress?.get("street") as? String ?: "")
        val street2Field = createTextField(this, "Apt / Suite (Optional)", existingAddress?.get("street2") as? String ?: "")
        val cityField = createTextField(this, "City", existingAddress?.get("city") as? String ?: "")
        val stateField = createTextField(this, "State / Province", existingAddress?.get("state") as? String ?: "")
        val zipField = createTextField(this, "ZIP / Postal Code", existingAddress?.get("zip") as? String ?: "")
        val countryField = createTextField(this, "Country", existingAddress?.get("country") as? String ?: "US")
        val phoneField = createTextField(this, "Phone (Optional)", existingAddress?.get("phone") as? String ?: "").apply {
            inputType = InputType.TYPE_CLASS_PHONE
        }

        // Primary switch
        val primaryLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            val padding = (8 * resources.displayMetrics.density).toInt()
            setPadding(0, padding, 0, padding)
        }
        val primaryLabel = TextView(this).apply {
            text = "Set as Primary Address"
            layoutParams = LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1f
            )
        }
        val primarySwitch = Switch(this).apply {
            isChecked = existingAddress?.get("isPrimary") as? Boolean ?: false
        }
        primaryLayout.addView(primaryLabel)
        primaryLayout.addView(primarySwitch)

        // Add all fields to layout
        layout.addView(nameField)
        layout.addView(recipientNameField)
        layout.addView(streetField)
        layout.addView(street2Field)
        layout.addView(cityField)
        layout.addView(stateField)
        layout.addView(zipField)
        layout.addView(countryField)
        layout.addView(phoneField)
        layout.addView(primaryLayout)

        scrollView.addView(layout)

        runOnUiThread {
            AlertDialog.Builder(this)
                .setTitle(if (existingAddress != null) "Edit Address" else "Add Address")
                .setView(scrollView)
                .setPositiveButton("Save") { _, _ ->
                    // Validate required fields
                    val name = nameField.text.toString()
                    val recipientName = recipientNameField.text.toString()
                    val street = streetField.text.toString()
                    val city = cityField.text.toString()
                    val state = stateField.text.toString()
                    val zip = zipField.text.toString()

                    if (name.isEmpty() || recipientName.isEmpty() || street.isEmpty() ||
                        city.isEmpty() || state.isEmpty() || zip.isEmpty()) {
                        AlertDialog.Builder(this)
                            .setTitle("Missing Information")
                            .setMessage("Please fill in all required fields")
                            .setPositiveButton("OK", null)
                            .show()
                        return@setPositiveButton
                    }

                    val address = mutableMapOf<String, Any>(
                        "name" to name,
                        "recipientName" to recipientName,
                        "street" to street,
                        "street2" to street2Field.text.toString(),
                        "city" to city,
                        "state" to state,
                        "zip" to zip,
                        "country" to countryField.text.toString(),
                        "phone" to phoneField.text.toString(),
                        "isPrimary" to primarySwitch.isChecked
                    )

                    // Preserve existing ID and createdAt
                    existingAddress?.get("id")?.let { address["id"] = it }
                    existingAddress?.get("createdAt")?.let { address["createdAt"] = it }

                    saveAddress(address, index)
                }
                .setNegativeButton("Cancel", null)
                .show()
        }
    }

    /**
     * Create a text field with label
     */
    private fun createTextField(context: Context, hint: String, value: String): EditText {
        return EditText(context).apply {
            this.hint = hint
            setText(value)
            val padding = (8 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }
    }

    /**
     * Save address to carrier bag
     */
    private fun saveAddress(address: MutableMap<String, Any>, index: Int?) {
        Log.d(TAG, "📮 Saving address (index: $index)")

        val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
        val carrierBagJson = prefs.getString("carrier_bag", null)

        val carrierBag = if (carrierBagJson != null) {
            gson.fromJson(carrierBagJson, Map::class.java).toMutableMap()
        } else {
            createEmptyCarrierBag().toMutableMap()
        }

        @Suppress("UNCHECKED_CAST")
        val addresses = (carrierBag["addresses"] as? List<Map<String, Any>>)?.toMutableList() ?: mutableListOf()

        // Ensure ID and createdAt
        if (!address.containsKey("id")) {
            address["id"] = UUID.randomUUID().toString()
        }
        if (!address.containsKey("createdAt")) {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            dateFormat.timeZone = TimeZone.getTimeZone("UTC")
            address["createdAt"] = dateFormat.format(Date())
        }

        if (index != null && index >= 0 && index < addresses.size) {
            // Update existing
            addresses[index] = address
            Log.d(TAG, "✅ Updated address at index $index")
        } else {
            // Add new - if first address, make it primary
            if (addresses.isEmpty()) {
                address["isPrimary"] = true
            }
            addresses.add(address)
            Log.d(TAG, "✅ Added new address")
        }

        carrierBag["addresses"] = addresses

        // Save to SharedPreferences
        val updatedJson = gson.toJson(carrierBag)
        prefs.edit().putString("carrier_bag", updatedJson).apply()

        // Reload WebView
        updateCarrierBagData(updatedJson)
    }

    /**
     * Set address as primary
     */
    private fun setAddressAsPrimary(index: Int) {
        Log.d(TAG, "📮 Setting address at index $index as primary")

        val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
        val carrierBagJson = prefs.getString("carrier_bag", null) ?: return

        val carrierBag = gson.fromJson(carrierBagJson, Map::class.java).toMutableMap()

        @Suppress("UNCHECKED_CAST")
        val addresses = (carrierBag["addresses"] as? List<Map<String, Any>>)?.toMutableList() ?: return

        // Remove primary from all addresses
        for (i in addresses.indices) {
            val addr = addresses[i].toMutableMap()
            addr["isPrimary"] = (i == index)
            addresses[i] = addr
        }

        carrierBag["addresses"] = addresses

        // Save
        val updatedJson = gson.toJson(carrierBag)
        prefs.edit().putString("carrier_bag", updatedJson).apply()

        // Reload
        updateCarrierBagData(updatedJson)

        Log.d(TAG, "✅ Address set as primary")
    }

    /**
     * Remove address
     */
    private fun removeAddress(index: Int) {
        Log.d(TAG, "🗑️ Removing address at index $index")

        val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
        val carrierBagJson = prefs.getString("carrier_bag", null) ?: return

        val carrierBag = gson.fromJson(carrierBagJson, Map::class.java).toMutableMap()

        @Suppress("UNCHECKED_CAST")
        val addresses = (carrierBag["addresses"] as? List<Map<String, Any>>)?.toMutableList() ?: return

        if (index < 0 || index >= addresses.size) {
            Log.e(TAG, "❌ Invalid index")
            return
        }

        val wasPrimary = addresses[index]["isPrimary"] as? Boolean ?: false
        addresses.removeAt(index)

        // If we removed the primary address, make the first one primary
        if (wasPrimary && addresses.isNotEmpty()) {
            val firstAddr = addresses[0].toMutableMap()
            firstAddr["isPrimary"] = true
            addresses[0] = firstAddr
        }

        carrierBag["addresses"] = addresses

        // Save
        val updatedJson = gson.toJson(carrierBag)
        prefs.edit().putString("carrier_bag", updatedJson).apply()

        // Reload
        updateCarrierBagData(updatedJson)

        Log.d(TAG, "✅ Address removed")
    }

    /**
     * Create empty carrier bag
     */
    private fun createEmptyCarrierBag(): Map<String, Any> {
        return mapOf(
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
            "stacks" to emptyList<Any>(),
            "addresses" to emptyList<Any>()
        )
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
        fun onAddAddress() {
            activity.onAddAddress()
        }

        @JavascriptInterface
        fun log(message: String) {
            Log.d(TAG, "WebView: $message")
        }
    }
}
