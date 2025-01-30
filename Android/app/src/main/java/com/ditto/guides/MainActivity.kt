package com.ditto.guides

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.ditto.guides.services.DittoService
import com.ditto.guides.services.ErrorService
import com.ditto.guides.ui.PlanetsListView
import com.ditto.guides.ui.theme.GuidesTheme
import live.ditto.transports.DittoSyncPermissions
import org.koin.android.ext.android.inject

//
// requires ExperimentalMaterial3Api in order to do the global snackbar to show errors
// https://developer.android.com/reference/kotlin/androidx/compose/material3/SnackbarHostState
//
@OptIn(ExperimentalMaterial3Api::class)
class MainActivity() : ComponentActivity() {

    private val dittoService: DittoService by inject()
    private val errorService: ErrorService by inject()

    /** 
    * Setup Permissions for Bluetooth and Wifi 
    * see docs: https://docs.ditto.live/sdk/latest/install-guides/kotlin
    */
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { 
        dittoService.ditto?.refreshPermissions() 
    }

    /**
     * Initializes the activity and sets up the UI components.
     * 
     * This method:
     * 1. Installs the splash screen before the activity is created
     * 2. Requests necessary permissions for Ditto sync functionality
     * 3. Enables edge-to-edge display for better UI experience
     * 4. Sets up the Compose UI with the main PlanetsListView
     *
     * @param savedInstanceState Bundle? containing the activity's previously saved state
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before calling super.onCreate()
        // https://developer.android.com/reference/kotlin/androidx/core/splashscreen/SplashScreen
        // https://developer.android.com/develop/ui/views/launch/splash-screen
        installSplashScreen()

        super.onCreate(savedInstanceState)

        //
        // Setup Permissions for Bluetooth and Wifi - see docs: https://docs.ditto.live/sdk/latest/install-guides/kotlin
        //
        requestPermissions()

        enableEdgeToEdge()
        setContent {
            GuidesTheme {
                val errorMessage by errorService.errorMessage.collectAsState()
                val snackbarHostState = remember { SnackbarHostState() }
                
                Scaffold(
                    modifier = Modifier.fillMaxSize(),
                    snackbarHost = {
                        SnackbarHost(hostState = snackbarHostState) { data ->
                            Snackbar(
                                snackbarData = data,
                                containerColor = MaterialTheme.colorScheme.errorContainer,
                                contentColor = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                ) { innerPadding ->
                    Box(modifier = Modifier.fillMaxSize()) {
                        PlanetsListView(
                            modifier = Modifier.padding(innerPadding)
                        )

                        //
                        // show any exception that might have been thrown
                        //
                        errorMessage?.let { message ->
                            LaunchedEffect(message) {
                                snackbarHostState.showSnackbar(
                                    message = message,
                                    duration = SnackbarDuration.Short
                                )
                                errorService.errorShown()
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Requests necessary permissions for Ditto functionality.
     * 
     * This method:
     * 1. Checks for missing permissions required by Ditto
     * 2. Requests any missing permissions from the user
     *
     * Required permissions include:
     * - Bluetooth permissions for peer-to-peer sync
     * - Location permissions for BLE scanning
     * - WiFi permissions for network sync
     *
     * See: https://docs.ditto.live/sdk/latest/install-guides/kotlin#using-the-helper
     */
    private fun requestPermissions() {
        val missing = DittoSyncPermissions(this).missingPermissions()
        if (missing.isNotEmpty()) {
            this.requestPermissions(missing, 0)
        }
    }
}
