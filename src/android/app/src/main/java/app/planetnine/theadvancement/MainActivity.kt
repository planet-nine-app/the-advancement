package app.planetnine.theadvancement

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import app.planetnine.theadvancement.ui.onboarding.OnboardingViewModel
import app.planetnine.theadvancement.ui.onboarding.OnboardingWebViewScreen
import app.planetnine.theadvancement.ui.main.MainViewModel
import app.planetnine.theadvancement.ui.main.MainWebViewScreen
import app.planetnine.theadvancement.ui.theme.TheAdvancementTheme

/**
 * Main activity for The Advancement
 *
 * Shows onboarding flow for new users, then transitions to main app
 */
class MainActivity : ComponentActivity() {

    private lateinit var onboardingViewModel: OnboardingViewModel
    private lateinit var mainViewModel: MainViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        onboardingViewModel = OnboardingViewModel(applicationContext)
        mainViewModel = MainViewModel(applicationContext)

        enableEdgeToEdge()

        Log.d("MainActivity", "onCreate - starting The Advancement")

        setContent {
            TheAdvancementTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.Black
                ) {
                    TheAdvancementApp(
                        onboardingViewModel = onboardingViewModel,
                        mainViewModel = mainViewModel
                    )
                }
            }
        }
    }
}

@Composable
fun TheAdvancementApp(
    onboardingViewModel: OnboardingViewModel,
    mainViewModel: MainViewModel
) {
    var showOnboarding by remember {
        mutableStateOf(!onboardingViewModel.isOnboardingComplete())
    }

    Log.d("MainActivity", "TheAdvancementApp - showOnboarding: $showOnboarding")

    // Check periodically if onboarding is complete
    LaunchedEffect(Unit) {
        while (showOnboarding) {
            kotlinx.coroutines.delay(500)
            if (onboardingViewModel.isOnboardingComplete()) {
                Log.d("MainActivity", "Onboarding complete, switching to main screen")
                showOnboarding = false
            }
        }
    }

    if (showOnboarding) {
        // WebView-based onboarding screen
        Log.d("MainActivity", "Showing onboarding screen")
        OnboardingWebViewScreen(viewModel = onboardingViewModel)
    } else {
        // WebView-based main screen
        Log.d("MainActivity", "Showing main screen")
        MainWebViewScreen(viewModel = mainViewModel)
    }
}