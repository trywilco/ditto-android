import SwiftUI

struct PlanetEditorView: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var orderFromSun: Double = 1.0
    @State private var hasRings = false
    @State private var atmosphere = ""
    @State private var maxTemp: Double?
    @State private var meanTemp: Double = 0
    @State private var minTemp: Double?
    
    // Add property to store existing planet for editing
    let existingPlanet: Planet?
    
    init(isPresented: Binding<Bool>, planet: Planet? = nil) {
        self._isPresented = isPresented
        self.existingPlanet = planet
        
        // Initialize state with existing planet data if editing
        if let planet = planet {
            self._name = State(initialValue: planet.name)
            self._orderFromSun = State(initialValue: planet.orderFromSun)
            self._hasRings = State(initialValue: planet.hasRings)
            self._atmosphere = State(initialValue: planet.mainAtmosphere.joined(separator: ", "))
            self._maxTemp = State(initialValue: planet.surfaceTemperatureC.max)
            self._meanTemp = State(initialValue: planet.surfaceTemperatureC.mean)
            self._minTemp = State(initialValue: planet.surfaceTemperatureC.min)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    
                    HStack {
                        Text("Order from Sun")
                        Spacer()
                        TextField("Order", value: $orderFromSun, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Toggle("Has Rings", isOn: $hasRings)
                }
                
                Section("Atmosphere") {
                    TextField(
                        "Enter atmospheres (comma separated)",
                        text: $atmosphere
                    )
                    .autocapitalization(.none)
                }
                
                Section("Surface Temperature (°C)") {
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("Max", value: $maxTemp, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Mean")
                        Spacer()
                        TextField("Mean", value: $meanTemp, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("Min", value: $minTemp, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle(existingPlanet == nil ? "Add Planet" : "Edit Planet")
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
                            await savePlanet()
                            isPresented = false
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func savePlanetNew() async {
        let atmosphereComponents = atmosphere.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        do {
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
                try await DittoService.shared.updatePlanet(updatedPlanet)
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
                try await DittoService.shared.addPlanet(newPlanet)
            }
        } catch {
            print("Error saving planet: \(error)")
            // TODO: Show error to user
        }
    }
    
    private func savePlanet() async {
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

#Preview {
    PlanetEditorView(isPresented: .constant(true))
} 
