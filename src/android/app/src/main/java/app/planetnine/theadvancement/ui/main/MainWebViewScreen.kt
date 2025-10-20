package app.planetnine.theadvancement.ui.main

import android.annotation.SuppressLint
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import com.google.gson.Gson

/**
 * WebView-based main screen
 * Loads shared HTML from assets
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun MainWebViewScreen(viewModel: MainViewModel) {
    val context = LocalContext.current
    val postedBDOs by viewModel.postedBDOs.collectAsState()

    val webView = remember {
        WebView(context).apply {
            // Enable JavaScript and storage
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = true

            // Enhanced settings for SVG and graphics rendering
            settings.loadWithOverviewMode = true
            settings.useWideViewPort = true
            settings.setSupportZoom(false)
            settings.builtInZoomControls = false
            settings.displayZoomControls = false

            // Enable hardware acceleration for this WebView
            setLayerType(android.view.View.LAYER_TYPE_HARDWARE, null)

            // Enable WebView debugging in debug builds
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                WebView.setWebContentsDebuggingEnabled(true)
            }

            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    view: WebView?,
                    request: WebResourceRequest?
                ): Boolean {
                    return false
                }

                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    Log.d("MainWebView", "Page started loading: $url")
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.d("MainWebView", "Page loaded: $url")

                    // Log SVG dimensions after page load
                    view?.evaluateJavascript(
                        """
                        (function() {
                            const svg = document.getElementById('mainSVG');
                            const rect = svg.getBoundingClientRect();
                            return JSON.stringify({
                                width: rect.width,
                                height: rect.height,
                                viewBox: svg.getAttribute('viewBox')
                            });
                        })();
                        """.trimIndent()
                    ) { result ->
                        Log.d("MainWebView", "SVG dimensions: $result")
                    }
                }
            }

            // Enable console logging
            webChromeClient = object : android.webkit.WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: android.webkit.ConsoleMessage): Boolean {
                    Log.d("MainWebView",
                        "Console [${consoleMessage.messageLevel()}]: ${consoleMessage.message()} " +
                        "at ${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
                    return true
                }
            }

            // JavaScript interface for Android
            addJavascriptInterface(
                MainJSInterface(viewModel, this),
                "Android"
            )

            // Load HTML from assets
            loadUrl("file:///android_asset/main.html")
        }
    }

    // When new BDO is posted, add it to display
    LaunchedEffect(postedBDOs.size) {
        if (postedBDOs.isNotEmpty()) {
            val latestBDO = postedBDOs.first()
            val gson = Gson()
            val bdoJson = gson.toJson(
                mapOf(
                    "text" to latestBDO.text,
                    "emojicode" to latestBDO.emojicode
                )
            )

            webView.evaluateJavascript(
                """
                (function() {
                    try {
                        const bdoData = $bdoJson;
                        console.log('📥 Received BDO data:', bdoData);
                        addPostedBDO(bdoData);
                    } catch(e) {
                        console.error('❌ Error adding BDO:', e.message);
                    }
                })();
                """.trimIndent(),
                null
            )
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            webView.destroy()
        }
    }

    AndroidView(
        factory = { webView },
        modifier = Modifier.fillMaxSize()
    )
}

/**
 * JavaScript interface for main screen
 */
class MainJSInterface(
    private val viewModel: MainViewModel,
    private val webView: WebView
) {
    @JavascriptInterface
    fun log(message: String) {
        Log.d("MainWebView", message)
    }

    @JavascriptInterface
    fun logError(message: String) {
        Log.e("MainWebView", message)
    }

    @JavascriptInterface
    fun logWarn(message: String) {
        Log.w("MainWebView", message)
    }

    @JavascriptInterface
    fun postBDO(text: String) {
        Log.d("MainJSInterface", "Posting BDO: $text")
        viewModel.postBDO(text)
    }

    @JavascriptInterface
    fun showKeyboard() {
        Log.d("MainJSInterface", "Requesting soft keyboard")
        webView.post {
            webView.requestFocus()
            val imm = webView.context.getSystemService(android.content.Context.INPUT_METHOD_SERVICE)
                as android.view.inputmethod.InputMethodManager
            imm.showSoftInput(webView, android.view.inputmethod.InputMethodManager.SHOW_IMPLICIT)
        }
    }

    @JavascriptInterface
    fun showKeyboardPicker() {
        Log.d("MainJSInterface", "Opening keyboard picker")
        webView.post {
            val imm = webView.context.getSystemService(android.content.Context.INPUT_METHOD_SERVICE)
                as android.view.inputmethod.InputMethodManager
            imm.showInputMethodPicker()
        }
    }
}
