import Foundation

class DittoApp: ObservableObject {
    @Published var appConfig: AppConfig
    @Published var error: Error? = nil
    
    init(configuration: AppConfig) {
        appConfig = configuration
    }
    
    func setError(_ error: Error?) {
        DispatchQueue.main.sync {
            self.error = error
        }
    }
}
