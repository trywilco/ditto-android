import SwiftUI

struct PlanetEditorView: View {
    @Binding var isPresented: Bool
    @State private var viewModel: ViewModel
    
    init(isPresented: Binding<Bool>, planet: Planet? = nil) {
        self._isPresented = isPresented
        self._viewModel = State(initialValue: ViewModel(planet: planet))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $viewModel.name)
                    
                    HStack {
                        Text("Order from Sun")
                        Spacer()
                        TextField("Order", value: $viewModel.orderFromSun, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Toggle("Has Rings", isOn: $viewModel.hasRings)
                }
                
                Section("Atmosphere") {
                    TextField(
                        "Enter atmospheres (comma separated)",
                        text: $viewModel.atmosphere
                    )
                    .autocapitalization(.none)
                }
                
                Section("Surface Temperature (°C)") {
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("Max", value: $viewModel.maxTemp, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Mean")
                        Spacer()
                        TextField("Mean", value: $viewModel.meanTemp, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("Min", value: $viewModel.minTemp, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle(viewModel.existingPlanet == nil ? "Add Planet" : "Edit Planet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.savePlanet()
                            isPresented = false
                        }
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PlanetEditorView(isPresented: .constant(true))
}

extension PlanetEditorView {
    @Observable
    class ViewModel {
        var name = ""
        var orderFromSun: Double = 1.0
        var hasRings = false
        var atmosphere = ""
        var maxTemp: Double?
        var meanTemp: Double = 0
        var minTemp: Double?
        let existingPlanet: Planet?
        
        init(planet: Planet? = nil) {
            self.existingPlanet = planet
            
            if let planet = planet {
                self.name = planet.name
                self.orderFromSun = planet.orderFromSun
                self.hasRings = planet.hasRings
                self.atmosphere = planet.mainAtmosphere.joined(separator: ", ")
                self.maxTemp = planet.surfaceTemperatureC.max
                self.meanTemp = planet.surfaceTemperatureC.mean
                self.minTemp = planet.surfaceTemperatureC.min
            }
        }
        
        func savePlanet() async {
            let atmosphereComponents = atmosphere.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if let existingPlanet = existingPlanet {
                // Update existing planet
                let updatedPlanet = Planet(
                    _id: existingPlanet._id,
                    _mdb: existingPlanet._mdb,
                    hasRings: hasRings,
                    isArchived: false,
                    mainAtmosphere: atmosphereComponents,
                    name: name,
                    orderFromSun: orderFromSun,
                    planetId: existingPlanet.planetId,
                    surfaceTemperatureC: .init(
                        max: maxTemp,
                        mean: meanTemp,
                        min: minTemp
                    )
                )
                // TODO: Call DittoService update method
                print("Updating planet: \(updatedPlanet)")
            } else {
                // Create new planet
                let newPlanet = Planet(
                    _id: UUID().uuidString,
                    _mdb: .init(
                        _id: UUID().uuidString,
                        ct: [Int(Date().timeIntervalSince1970), 1],
                        tm: .init(_id: 7)
                    ),
                    hasRings: hasRings,
                    isArchived: false,
                    mainAtmosphere: atmosphereComponents,
                    name: name,
                    orderFromSun: orderFromSun,
                    planetId: UUID().uuidString,
                    surfaceTemperatureC: .init(
                        max: maxTemp,
                        mean: meanTemp,
                        min: minTemp
                    )
                )
                // TODO: Call DittoService add method
                print("Saving new planet: \(newPlanet)")
            }
        }
    }
}
