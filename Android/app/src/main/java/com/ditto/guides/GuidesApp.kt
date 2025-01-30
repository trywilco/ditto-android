package com.ditto.guides
import android.app.Application
import com.ditto.guides.models.AppConfig
import com.ditto.guides.services.DittoService
import com.ditto.guides.services.DittoServiceImp
import com.ditto.guides.services.ErrorService
import com.ditto.guides.viewModels.PlanetEditorViewModel
import com.ditto.guides.viewModels.PlanetsListViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.context.GlobalContext
import org.koin.core.module.Module
import org.koin.core.module.dsl.viewModel
import org.koin.dsl.module

class GuidesApp : Application() {

    override fun onCreate() {
        super.onCreate()

        //
        // Start Koin dependency injection
        // https://insert-koin.io/docs/reference/koin-android/start
        //
        GlobalContext.startKoin {
            androidLogger()
            androidContext(this@GuidesApp)
            modules(registerDependencies())
        }

    }

    private fun registerDependencies() : Module {
        return module {
            // Create AppConfig as a single instance
            single { 
                AppConfig(
                    getString(R.string.endpointUrl),
                    getString(R.string.appId),
                    getString(R.string.authToken)
                )
            }
            // Create DittoServiceImp with injected dependencies
            single<DittoService> { 
                DittoServiceImp(
                    appConfig = get(),  // Koin will provide the AppConfig instance
                    context = get(),   // Koin will provide the Application context
                    errorService = get()
                )
            }

            // Create PlanetsListViewModel with injected DittoService
            viewModel { PlanetsListViewModel(get(),get()) }

            // Create PlanetEditorViewModel with injected DittoService
            viewModel { PlanetEditorViewModel(get(), get()) }

            // add in the ErrorService which is used to display errors in the app
            single { ErrorService() }
        }
    }
}