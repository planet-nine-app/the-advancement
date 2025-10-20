package app.planetnine.theadvancement.ui.onboarding

import android.annotation.SuppressLint
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView

/**
 * WebView-based onboarding screen
 * Loads shared HTML from assets
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun OnboardingWebViewScreen(viewModel: OnboardingViewModel) {
    val context = LocalContext.current
    val loadingMessage by viewModel.loadingMessage.collectAsState()

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

            // Set WebView background to black (matches SVG background)
            setBackgroundColor(android.graphics.Color.BLACK)

            // Add console message handler for better debugging
            webChromeClient = object : android.webkit.WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: android.webkit.ConsoleMessage): Boolean {
                    Log.d("OnboardingWebView",
                        "Console [${consoleMessage.messageLevel()}]: ${consoleMessage.message()} " +
                        "at ${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
                    return true
                }
            }

            // Enable WebView debugging in debug builds
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                WebView.setWebContentsDebuggingEnabled(true)
            }

            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    Log.d("OnboardingWebView", "Page started loading: $url")
                }

                override fun onLoadResource(view: WebView?, url: String?) {
                    super.onLoadResource(view, url)
                    Log.d("OnboardingWebView", "Loading resource: $url")
                }
                override fun shouldOverrideUrlLoading(
                    view: WebView?,
                    request: WebResourceRequest?
                ): Boolean {
                    return false
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.d("OnboardingWebView", "Page loaded: $url")
                }
            }

            // JavaScript interface for Android
            addJavascriptInterface(
                OnboardingJSInterface(viewModel),
                "Android"
            )

            // Load HTML from assets
            loadUrl("file:///android_asset/onboarding.html")
        }
    }

    // Update loading text when it changes
    LaunchedEffect(loadingMessage) {
        if (loadingMessage.isNotEmpty()) {
            webView.evaluateJavascript(
                "updateLoadingText('$loadingMessage')",
                null
            )
        }
    }

    // Check if onboarding is complete
    LaunchedEffect(Unit) {
        if (viewModel.isOnboardingComplete()) {
            // Will trigger navigation in MainActivity
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            webView.destroy()
        }
    }

    AndroidView(
        factory = { webView },
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black),
        update = { view ->
            // Log dimensions for debugging
            view.post {
                Log.d("OnboardingWebView", "WebView size: ${view.width}x${view.height}")
            }
        }
    )
}

/**
 * JavaScript interface for onboarding
 */
class OnboardingJSInterface(private val viewModel: OnboardingViewModel) {
    @JavascriptInterface
    fun log(message: String) {
        Log.d("OnboardingWebView", message)
    }

    @JavascriptInterface
    fun logError(message: String) {
        Log.e("OnboardingWebView", message)
    }

    @JavascriptInterface
    fun logWarn(message: String) {
        Log.w("OnboardingWebView", message)
    }

    @JavascriptInterface
    fun joinAdvancement() {
        Log.d("OnboardingJSInterface", "User joining The Advancement")
        viewModel.joinAdvancement()
    }
}
