import SwiftUI

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
                                    viewModel.deletePlanet(planetId: planet.planetId)
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
    class ViewModel {
        //used for list loading
        var planets: [Planet] = []
        var isLoading = false
        
        //used for editor
        var isPresented = false
        var planetToEdit: Planet?
        
        func loadPlanets(appState: DittoApp) async {
            isLoading = true
            do {
                try await DittoService.shared
                    .initializeStore(dittoApp: appState)
                planets = await DittoService.shared.planets
            } catch {
                appState.setError(error)
            }
            isLoading = false
        }
        
        func deletePlanet(planetId: String) {
            print("Delete planet with ID: \(planetId)")
        }
        
        func showPlanetEditor(_ planet: Planet?) {
            planetToEdit = planet
            isPresented = true
        }
    }
}
