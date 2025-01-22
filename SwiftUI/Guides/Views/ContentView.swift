import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject private var appState: DittoApp
    @State private var viewModel: ContentView.ViewModel = ViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Planets...")
                        .progressViewStyle(.circular)
                } else if viewModel.planets.isEmpty {
                    ContentUnavailableView(
                        "No Planets",
                        systemImage: "globe",
                        description: Text("There are no planets to display")
                    )
                } else {
                    List(viewModel.planets, id: \.planetId) { planet in
                        PlanetRow(planet: planet)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.showPlanetEditor(planet)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .cancel) {
                                    viewModel.archivePlanet(planetId: planet.planetId, appState: appState)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Planets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showPlanetEditor(nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresented) {
                PlanetEditorView(
                    isPresented: $viewModel.isPresented,
                    planet: viewModel.planetToEdit
                )
                .environmentObject(appState)
            }
        }
        .task(id: ObjectIdentifier(appState)) {
            await viewModel.loadPlanets(appState: appState)
        }
    }
}

struct PlanetRow: View {
    let planet: Planet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(planet.name)
                .font(.headline)
            
            if !planet.mainAtmosphere.isEmpty {
                Text("Atmosphere: \(planet.mainAtmosphere.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let max = planet.surfaceTemperatureC.max {
                    Text("Max: \(Int(max))°C")
                        .foregroundStyle(.red)
                }
                Text("Mean: \(Int(planet.surfaceTemperatureC.mean))°C")
                    .foregroundStyle(.orange)
                if let min = planet.surfaceTemperatureC.min {
                    Text("Min: \(Int(min))°C")
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            DittoApp(
                configuration: AppConfig(
                    endpointUrl: "", appId: "", authToken: "")))
}

extension ContentView {
    @Observable
    @MainActor
    class ViewModel {
        @ObservationIgnored private var cancellables = Set<AnyCancellable>()
        
        var planets: [Planet] = []
        var isLoading = false
        
        //used for editor
        var isPresented = false
        var planetToEdit: Planet?
        
        init() {
            // Observe changes to DittoService's planets
            Task { @MainActor in
                DittoService.shared.$planets
                    .receive(on: RunLoop.main)
                    .sink { [weak self] updatedPlanets in
                        self?.planets = updatedPlanets
                    }
                    .store(in: &cancellables)
            }
        }
        
        func loadPlanets(appState: DittoApp) async {
            isLoading = true
            do {
                try await DittoService.shared
                    .initializeStore(dittoApp: appState)
                planets = DittoService.shared.planets
            } catch {
                appState.setError(error)
            }
            isLoading = false
        }
        
        func archivePlanet(planetId: String, appState: DittoApp) {
            Task { @MainActor in
                do {
                    try await DittoService.shared.archivePlanet(planetId)
                } catch {
                    appState.setError(error)
                }
            }
        }
        
        func showPlanetEditor(_ planet: Planet?) {
            planetToEdit = planet
            isPresented = true
        }
    }
}
