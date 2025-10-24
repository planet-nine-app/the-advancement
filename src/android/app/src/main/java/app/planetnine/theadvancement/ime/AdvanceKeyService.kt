package app.planetnine.theadvancement.ime

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.FrameLayout
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.planetnine.theadvancement.ui.theme.AdvancementColors
import app.planetnine.theadvancement.ui.theme.TheAdvancementTheme

/**
 * AdvanceKey - Custom Android IME for Planet Nine
 *
 * Provides:
 * - BDO viewing and decoding
 * - Emojicode decoding (DEMOJI button)
 * - MAGIC spell casting
 * - Contract signing
 * - Standard keyboard functionality
 *
 * Android equivalent of iOS AdvanceKey keyboard extension
 */
class AdvanceKeyService : InputMethodService(), LifecycleOwner {

    private var viewModel: AdvanceKeyViewModel? = null
    private val lifecycleRegistry: LifecycleRegistry by lazy { LifecycleRegistry(this) }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override fun onCreate() {
        super.onCreate()
        android.util.Log.d("AdvanceKeyService", "onCreate - AdvanceKey IME created")

        // Initialize lifecycle
        lifecycleRegistry.currentState = Lifecycle.State.CREATED

        viewModel = AdvanceKeyViewModel(applicationContext)
    }

    override fun onCreateInputView(): View? {
        android.util.Log.d("AdvanceKeyService", "onCreateInputView - Creating WebView keyboard")
        return try {
            val webView = android.webkit.WebView(this).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    400 // Fixed height in pixels
                )

                // Enable JavaScript
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.allowFileAccess = true

                // Enable hardware acceleration
                setLayerType(android.view.View.LAYER_TYPE_HARDWARE, null)

                // Enable WebView debugging
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                    android.webkit.WebView.setWebContentsDebuggingEnabled(true)
                }

                // Console logging
                webChromeClient = object : android.webkit.WebChromeClient() {
                    override fun onConsoleMessage(consoleMessage: android.webkit.ConsoleMessage): Boolean {
                        android.util.Log.d("AdvanceKeyWebView",
                            "Console [${consoleMessage.messageLevel()}]: ${consoleMessage.message()} " +
                            "at ${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
                        return true
                    }
                }

                // JavaScript interface
                addJavascriptInterface(
                    KeyboardJSInterface(this@AdvanceKeyService, viewModel, this),
                    "Android"
                )

                // Load keyboard HTML
                loadUrl("file:///android_asset/keyboard.html")
            }

            android.util.Log.d("AdvanceKeyService", "onCreateInputView - WebView keyboard created successfully")
            webView
        } catch (e: Exception) {
            android.util.Log.e("AdvanceKeyService", "onCreateInputView - ERROR creating view", e)
            null
        }
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        android.util.Log.d("AdvanceKeyService", "onStartInputView - Input view started (restarting: $restarting)")

        // Move lifecycle to STARTED/RESUMED when keyboard is shown
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        android.util.Log.d("AdvanceKeyService", "onFinishInputView - Keyboard hidden")

        // Move lifecycle back to STARTED when keyboard is hidden
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
    }

    override fun onBindInput() {
        super.onBindInput()
        android.util.Log.d("AdvanceKeyService", "onBindInput - Keyboard bound to input")
    }

    override fun onUnbindInput() {
        super.onUnbindInput()
        android.util.Log.d("AdvanceKeyService", "onUnbindInput - Keyboard unbound from input")
    }

    override fun onDestroy() {
        super.onDestroy()
        android.util.Log.d("AdvanceKeyService", "onDestroy - Cleaning up AdvanceKey")

        // Clean up lifecycle
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
    }

    override fun onEvaluateFullscreenMode(): Boolean {
        // Never use fullscreen mode
        return false
    }

    override fun onEvaluateInputViewShown(): Boolean {
        // Always show the input view
        android.util.Log.d("AdvanceKeyService", "onEvaluateInputViewShown - returning true")
        return true
    }
}

/**
 * JavaScript interface for AdvanceKey keyboard
 */
class KeyboardJSInterface(
    private val service: AdvanceKeyService,
    private val viewModel: AdvanceKeyViewModel?,
    private val webView: android.webkit.WebView
) {
    @android.webkit.JavascriptInterface
    fun insertText(text: String) {
        android.util.Log.d("KeyboardJSInterface", "Insert text: $text")
        service.currentInputConnection?.commitText(text, 1)
    }

    @android.webkit.JavascriptInterface
    fun deleteText() {
        android.util.Log.d("KeyboardJSInterface", "Delete text")
        service.currentInputConnection?.deleteSurroundingText(1, 0)
    }

    @android.webkit.JavascriptInterface
    fun decodeEmojicode(emojicode: String) {
        android.util.Log.d("KeyboardJSInterface", "Decode emojicode: $emojicode")
        viewModel?.decodeEmojicode(emojicode)
    }

    @android.webkit.JavascriptInterface
    fun castSpell(spellName: String) {
        android.util.Log.d("KeyboardJSInterface", "Cast spell: $spellName")
        viewModel?.castSpell(spellName)
    }

    @android.webkit.JavascriptInterface
    fun getPostedBDOs(): String {
        android.util.Log.d("KeyboardJSInterface", "Get posted BDOs")
        val bdos = viewModel?.postedBDOs?.value ?: emptyList()
        return com.google.gson.Gson().toJson(bdos)
    }

    @android.webkit.JavascriptInterface
    fun getClipboardText(): String {
        android.util.Log.d("KeyboardJSInterface", "Get clipboard text")
        return viewModel?.clipboardText?.value ?: ""
    }

    @android.webkit.JavascriptInterface
    fun saveToCarrierBag(emojicode: String) {
        android.util.Log.d("KeyboardJSInterface", "Save to carrier bag: $emojicode")
        viewModel?.saveToCarrierBag(emojicode)
    }
}

/**
 * Main keyboard UI
 */
@Composable
fun AdvanceKeyboard(
    viewModel: AdvanceKeyViewModel,
    onTextInput: (String) -> Unit,
    onDeleteText: () -> Unit,
    onClose: () -> Unit
) {
    var currentMode by remember { mutableStateOf(KeyboardMode.Standard) }
    val clipboardText by viewModel.clipboardText.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.Black)
            .padding(8.dp)
    ) {
        // Mode selector row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            ModeButton(
                text = "ABC",
                selected = currentMode == KeyboardMode.Standard,
                onClick = { currentMode = KeyboardMode.Standard }
            )
            ModeButton(
                text = "DEMOJI",
                selected = currentMode == KeyboardMode.Demoji,
                onClick = { currentMode = KeyboardMode.Demoji }
            )
            ModeButton(
                text = "MAGIC",
                selected = currentMode == KeyboardMode.Magic,
                onClick = { currentMode = KeyboardMode.Magic }
            )
            ModeButton(
                text = "BDO",
                selected = currentMode == KeyboardMode.BDO,
                onClick = { currentMode = KeyboardMode.BDO }
            )
        }

        // Content area based on mode
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .border(
                    width = 1.dp,
                    color = AdvancementColors.purple,
                    shape = RoundedCornerShape(4.dp)
                )
                .background(
                    color = Color.Black,
                    shape = RoundedCornerShape(4.dp)
                )
                .padding(8.dp)
        ) {
            when (currentMode) {
                KeyboardMode.Standard -> StandardKeyboard(
                    onTextInput = onTextInput,
                    onDeleteText = onDeleteText
                )
                KeyboardMode.Demoji -> DemojiPanel(
                    clipboardText = clipboardText,
                    viewModel = viewModel,
                    onTextInput = onTextInput
                )
                KeyboardMode.Magic -> MagicPanel(
                    viewModel = viewModel,
                    onTextInput = onTextInput
                )
                KeyboardMode.BDO -> BDOPanel(
                    viewModel = viewModel,
                    onTextInput = onTextInput
                )
            }
        }

        // Bottom row with close button
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.End
        ) {
            Button(
                onClick = onClose,
                colors = ButtonDefaults.buttonColors(
                    containerColor = AdvancementColors.pink.copy(alpha = 0.3f),
                    contentColor = AdvancementColors.pink
                )
            ) {
                Text("Close Keyboard")
            }
        }
    }
}

@Composable
fun ModeButton(
    text: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .width(80.dp)
            .height(40.dp)
            .border(
                width = 1.dp,
                color = if (selected) AdvancementColors.green else AdvancementColors.purple.copy(
                    alpha = 0.5f
                ),
                shape = RoundedCornerShape(4.dp)
            )
            .background(
                color = if (selected) AdvancementColors.green.copy(alpha = 0.2f)
                else Color.Transparent,
                shape = RoundedCornerShape(4.dp)
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (selected) AdvancementColors.green else AdvancementColors.purple
        )
    }
}

@Composable
fun StandardKeyboard(
    onTextInput: (String) -> Unit,
    onDeleteText: () -> Unit
) {
    // Simplified standard keyboard
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.SpaceEvenly
    ) {
        val rows = listOf(
            listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"),
            listOf("A", "S", "D", "F", "G", "H", "J", "K", "L"),
            listOf("Z", "X", "C", "V", "B", "N", "M")
        )

        rows.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                row.forEach { letter ->
                    KeyButton(text = letter, onClick = { onTextInput(letter) })
                }
            }
        }

        // Space and delete row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            KeyButton(text = "Space", onClick = { onTextInput(" ") }, modifier = Modifier.weight(2f))
            KeyButton(text = "←", onClick = onDeleteText)
        }
    }
}

@Composable
fun KeyButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .padding(2.dp)
            .height(35.dp)
            .background(
                color = AdvancementColors.purple.copy(alpha = 0.3f),
                shape = RoundedCornerShape(4.dp)
            )
            .clickable(onClick = onClick)
            .then(if (modifier == Modifier) Modifier.width(30.dp) else Modifier),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White
        )
    }
}

@Composable
fun DemojiPanel(
    clipboardText: String,
    viewModel: AdvanceKeyViewModel,
    onTextInput: (String) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.SpaceEvenly
    ) {
        Text(
            text = "DEMOJI - Decode Emojicode",
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = AdvancementColors.green
        )

        Text(
            text = if (clipboardText.isNotEmpty()) "Clipboard: $clipboardText" else "No emojicode in clipboard",
            fontSize = 12.sp,
            color = AdvancementColors.purple.copy(alpha = 0.8f)
        )

        Button(
            onClick = {
                viewModel.decodeEmojicode(clipboardText)
            },
            enabled = clipboardText.isNotEmpty(),
            colors = ButtonDefaults.buttonColors(
                containerColor = AdvancementColors.green.copy(alpha = 0.3f),
                contentColor = AdvancementColors.green
            )
        ) {
            Text("Decode & Insert")
        }
    }
}

@Composable
fun MagicPanel(
    viewModel: AdvanceKeyViewModel,
    onTextInput: (String) -> Unit
) {
    val spells = listOf(
        "arethaUserPurchase" to "Purchase with nineum",
        "teleport" to "Teleport to location",
        "grant" to "Grant experience"
    )

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            Text(
                text = "MAGIC - Cast Spells",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = AdvancementColors.pink
            )
        }

        items(spells) { (spellName, description) ->
            SpellButton(
                spellName = spellName,
                description = description,
                onClick = {
                    viewModel.castSpell(spellName)
                }
            )
        }
    }
}

@Composable
fun SpellButton(
    spellName: String,
    description: String,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                color = AdvancementColors.pink,
                shape = RoundedCornerShape(4.dp)
            )
            .background(
                color = AdvancementColors.pink.copy(alpha = 0.1f),
                shape = RoundedCornerShape(4.dp)
            )
            .clickable(onClick = onClick)
            .padding(12.dp)
    ) {
        Column {
            Text(
                text = spellName,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = AdvancementColors.pink
            )
            Text(
                text = description,
                fontSize = 12.sp,
                color = AdvancementColors.purple.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
fun BDOPanel(
    viewModel: AdvanceKeyViewModel,
    onTextInput: (String) -> Unit
) {
    val postedBDOs by viewModel.postedBDOs.collectAsState()

    LaunchedEffect(Unit) {
        // Refresh when panel opens
        viewModel.refreshPostedBDOs()
    }

    if (postedBDOs.isEmpty()) {
        // Empty state
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "No BDOs Posted Yet",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = AdvancementColors.yellow
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Post a BDO from the main screen to see it here",
                fontSize = 12.sp,
                color = AdvancementColors.purple.copy(alpha = 0.8f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    } else {
        // Show list of posted BDOs
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Text(
                    text = "Your Posted BDOs",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = AdvancementColors.yellow
                )
            }

            items(postedBDOs) { bdo ->
                BDOCard(
                    bdo = bdo,
                    onEmojicodeClick = {
                        // Insert emojicode into text field
                        onTextInput(bdo.emojicode)
                    }
                )
            }
        }
    }
}

@Composable
fun BDOCard(
    bdo: app.planetnine.theadvancement.ui.main.PostedBDO,
    onEmojicodeClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                color = AdvancementColors.pink,
                shape = RoundedCornerShape(4.dp)
            )
            .background(
                color = AdvancementColors.pink.copy(alpha = 0.1f),
                shape = RoundedCornerShape(4.dp)
            )
            .padding(12.dp)
    ) {
        Column {
            // Text content
            Text(
                text = bdo.text,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Emojicode (clickable)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        color = AdvancementColors.yellow.copy(alpha = 0.2f),
                        shape = RoundedCornerShape(4.dp)
                    )
                    .clickable(onClick = onEmojicodeClick)
                    .padding(8.dp)
            ) {
                Text(
                    text = bdo.emojicode,
                    fontSize = 20.sp,
                    color = AdvancementColors.yellow,
                    letterSpacing = 0.1.sp
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Timestamp
            Text(
                text = bdo.timestamp,
                fontSize = 10.sp,
                color = AdvancementColors.purple.copy(alpha = 0.6f)
            )
        }
    }
}

/**
 * Keyboard modes
 */
enum class KeyboardMode {
    Standard,   // Regular typing
    Demoji,     // Emojicode decoding
    Magic,      // Spell casting
    BDO         // BDO viewing
}
