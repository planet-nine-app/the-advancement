package app.planetnine.theadvancement.ui.music

import android.os.Bundle
import android.util.Log
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.viewinterop.AndroidView
import app.planetnine.theadvancement.config.Configuration
import app.planetnine.theadvancement.ui.theme.TheAdvancementTheme

/**
 * Music Player Activity
 *
 * Displays the Dolores audio player in a WebView
 * Launched with EXTRA_FEED_URL intent parameter
 */
class MusicPlayerActivity : ComponentActivity() {

    companion object {
        const val EXTRA_FEED_URL = "feed_url"
        const val EXTRA_FEED_TITLE = "feed_title"
        private const val TAG = "MusicPlayerActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val feedUrl = intent.getStringExtra(EXTRA_FEED_URL)
        val feedTitle = intent.getStringExtra(EXTRA_FEED_TITLE) ?: "Music Player"

        if (feedUrl == null) {
            Log.e(TAG, "No feed URL provided")
            finish()
            return
        }

        Log.d(TAG, "🎵 Opening music player for: $feedTitle")
        Log.d(TAG, "🎵 Feed URL: $feedUrl")

        enableEdgeToEdge()

        setContent {
            TheAdvancementTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color(0xFF1A0033) // Dark purple background
                ) {
                    MusicPlayerWebView(feedUrl = feedUrl)
                }
            }
        }
    }
}

@Composable
fun MusicPlayerWebView(feedUrl: String) {
    val doloresUrl = Configuration.Dolores.audioPlayer(feedUrl)

    Log.d("MusicPlayerActivity", "🎵 Loading Dolores audio player: $doloresUrl")

    AndroidView(
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.mediaPlaybackRequiresUserGesture = false
                settings.allowFileAccess = true
                settings.allowContentAccess = true

                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        Log.d("MusicPlayerActivity", "✅ Audio player loaded successfully")
                    }

                    override fun onReceivedError(
                        view: WebView?,
                        errorCode: Int,
                        description: String?,
                        failingUrl: String?
                    ) {
                        Log.e("MusicPlayerActivity", "❌ Failed to load audio player: $description")
                    }
                }

                loadUrl(doloresUrl)
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}
