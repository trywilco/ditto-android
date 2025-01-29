package com.ditto.guides

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.ditto.guides.ui.PlanetsListView
import com.ditto.guides.ui.theme.GuidesTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before calling super.onCreate()
        // https://developer.android.com/reference/kotlin/androidx/core/splashscreen/SplashScreen
        // https://developer.android.com/develop/ui/views/launch/splash-screen
        installSplashScreen()

        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            GuidesTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    PlanetsListView(
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}
