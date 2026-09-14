import SwiftUI

@main
struct PocketWalkerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

/// Global app state managing the emulator, health, and file operations
@MainActor
class AppState: ObservableObject {
    @Published var emulator: PocketWalkerCore?
    @Published var isEmulatorRunning = false
    @Published var romLoaded = false
    @Published var selectedTab = 0
    
    // File management
    let fileManager = EmulatorFileManager()
    
    // Health integration
    var healthManager = HealthManager()
    
    // Audio
    let audioManager = AudioManager()
    
    // Settings
    @AppStorage("useSyntheticSteps") var useSyntheticSteps = false
    @AppStorage("bypassPowerSave") var bypassPowerSave = true
    @AppStorage("fastMode") var fastMode = false
    
    init() {
        // Set up file logging
        setupFileLogging()
        
        // Auto-load ROM if available
        if let romData = fileManager.loadROM() {
            loadEmulator(romData: romData)
            
            // Auto-load save if available
            if let saveData = fileManager.loadEEPROM(), let emu = emulator {
                emu.setEeprom(saveData)
            }
        }
    }
    
    private func setupFileLogging() {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logURL = docsURL.appendingPathComponent("pocketwalker.log")
        
        // Open log file and redirect stderr to it
        let path = logURL.path
        path.withCString { cPath in
            if let file = fopen(cPath, "w") {
                dup2(fileno(file), fileno(stderr))
                fclose(file)
            }
        }
        
        print("[PocketWalker] Log file: \(logURL.path)")
        print("[PocketWalker] Started at \(Date())")
    }
    
    func loadEmulator(romData: Data) {
        // Stop existing emulator
        if let existing = emulator {
            existing.stop()
        }
        
        guard let emu = PocketWalkerCore(romData: romData) else {
            print("Failed to create emulator")
            return
        }
        
        // Set up audio
        emu.setAudioCallback { [weak self] frequency, fullVolume in
            Task { @MainActor in
                self?.audioManager.playTone(frequency: frequency, fullVolume: fullVolume)
            }
        }
        
        emulator = emu
        romLoaded = true
        
        // Apply settings
        emu.setSyntheticSteps(useSyntheticSteps)
        emu.setBypassPowerSave(bypassPowerSave)
        emu.setFastMode(fastMode)
        
        // Start emulation
        emu.start()
        isEmulatorRunning = true
    }
    
    func startEmulator() {
        emulator?.start()
        isEmulatorRunning = true
    }
    
    func stopEmulator() {
        emulator?.stop()
        isEmulatorRunning = false
    }
    
    func saveEEPROM() {
        guard let emu = emulator, let data = emu.getEeprom() else { return }
        fileManager.saveEEPROM(data)
    }
    
    func loadEEPROM() {
        guard let emu = emulator, let data = fileManager.loadEEPROM() else { return }
        emu.setEeprom(data)
    }
    
    func loadROMFromFile(_ url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        fileManager.saveROM(data)
        loadEmulator(romData: data)
    }
}
