import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            EmulatorView()
                .tabItem {
                    Label("Emulator", systemImage: "gamecontroller")
                }
                .tag(0)
            
            SaveManagementView()
                .tabItem {
                    Label("Saves", systemImage: "externaldrive")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}

// MARK: - Emulator View

struct EmulatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPressingButton = false
    @State private var currentButton: Int32 = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if appState.romLoaded {
                // LCD Display
                LCDView(emulator: appState.emulator)
                    .aspectRatio(CGFloat(128) / CGFloat(96), contentMode: .fit)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Button controls
                HStack(spacing: 40) {
                    // Left button
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isPressingButton {
                                    isPressingButton = true
                                    currentButton = PW_BUTTON_LEFT
                                    appState.emulator?.pressButton(PW_BUTTON_LEFT)
                                }
                            }
                            .onEnded { _ in
                                isPressingButton = false
                                appState.emulator?.releaseButton(currentButton)
                            }
                    )
                    
                    // Center button
                    Button(action: {}) {
                        Image(systemName: "circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isPressingButton {
                                    isPressingButton = true
                                    currentButton = PW_BUTTON_CENTER
                                    appState.emulator?.pressButton(PW_BUTTON_CENTER)
                                }
                            }
                            .onEnded { _ in
                                isPressingButton = false
                                appState.emulator?.releaseButton(currentButton)
                            }
                    )
                    
                    // Right button
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isPressingButton {
                                    isPressingButton = true
                                    currentButton = PW_BUTTON_RIGHT
                                    appState.emulator?.pressButton(PW_BUTTON_RIGHT)
                                }
                            }
                            .onEnded { _ in
                                isPressingButton = false
                                appState.emulator?.releaseButton(currentButton)
                            }
                    )
                }
                .padding(.vertical)
                
                // Control bar
                HStack(spacing: 20) {
                    Button(action: {
                        if appState.isEmulatorRunning {
                            appState.stopEmulator()
                        } else {
                            appState.startEmulator()
                        }
                    }) {
                        Image(systemName: appState.isEmulatorRunning ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    
                    Button(action: {
                        appState.saveEEPROM()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                    }
                    
                    Button(action: {
                        appState.fastMode.toggle()
                        appState.emulator?.setFastMode(appState.fastMode)
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(appState.fastMode ? .blue : .primary)
                    }
                }
                .padding()
            } else {
                // No ROM loaded
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No ROM Loaded")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Place pweep.rom in the app's Documents folder\nor use the Files tab to load one.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

// MARK: - LCD View (Renders the emulator display)

struct LCDView: View {
    let emulator: PocketWalkerCore?
    @State private var displayImage: UIImage?
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if let image = displayImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
            } else {
                Rectangle()
                    .fill(Color.green.opacity(0.1))
            }
        }
        .onAppear {
            startDisplayUpdates()
        }
        .onDisappear {
            stopDisplayUpdates()
        }
    }
    
    private func startDisplayUpdates() {
        // Update display at ~15fps to save battery
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/15.0, repeats: true) { _ in
            updateDisplay()
        }
    }
    
    private func stopDisplayUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateDisplay() {
        guard let emu = emulator, let lcdData = emu.getLCD() else { return }
        
        // Convert emulator LCD data to UIImage
        let width = 128
        let height = 96  // 22 pages * 8 pixels, but we use 96 for the visible area
        let contrast = emu.getContrast()
        let powerSave = emu.getPowerSave()
        
        // Create grayscale image from VRAM
        let bytesPerPixel = 1
        let bytesPerRow = width * bytesPerPixel
        var pixelData = Data(count: width * height * bytesPerPixel)
        
        lcdData.withUnsafeBytes { lcdPtr in
            pixelData.withUnsafeMutableBytes { pixPtr in
                guard let lcdBase = lcdPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                      let pixBase = pixPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                
                if powerSave {
                    // Power save mode - blank screen
                    for i in 0..<(width * height) {
                        pixBase[i] = 255  // white
                    }
                    return
                }
                
                // Convert VRAM to pixels
                // VRAM is organized as pages (8 rows each), each page has 128 columns * 2 bytes
                let contrastFactor = CGFloat(max(1, contrast)) / 255.0
                
                for page in 0..<22 {
                    for col in 0..<128 {
                        let vramOffset = page * 256 + col * 2
                        let byte1 = lcdBase[vramOffset]
                        let byte2 = lcdBase[vramOffset + 1]
                        
                        for bit in 0..<8 {
                            let y = page * 8 + bit
                            if y >= height { continue }
                            
                            let pixelIndex = y * width + col
                            let isBlack = ((byte1 >> (7 - bit)) & 1) != 0 || ((byte2 >> (7 - bit)) & 1) != 0
                            
                            // Invert: PokéWalker LCD has 0=black, 1=white
                            let value: UInt8 = isBlack ? 0 : 255
                            pixBase[pixelIndex] = value
                        }
                    }
                }
            }
        }
        
        // Create image
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        if let provider = CGDataProvider(data: pixelData as CFData),
           let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
           ) {
            displayImage = UIImage(cgImage: cgImage)
        }
    }
}

// MARK: - Save Management View

struct SaveManagementView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDocumentPicker = false
    @State private var documentPickerType: DocumentPickerType = .rom
    
    enum DocumentPickerType {
        case rom, eeprom
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("ROM File") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("pweep.rom")
                                .font(.headline)
                            Text(appState.fileManager.romExists() ? "Loaded" : "Not found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if appState.fileManager.romExists() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button("Import ROM...") {
                        documentPickerType = .rom
                        showingDocumentPicker = true
                    }
                }
                
                Section("Save File") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("eeprom.bin")
                                .font(.headline)
                            Text(appState.fileManager.eepromExists() ? "Available" : "Not found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if appState.fileManager.eepromExists() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button("Import Save...") {
                        documentPickerType = .eeprom
                        showingDocumentPicker = true
                    }
                    
                    Button("Export Save...") {
                        if let data = appState.emulator?.getEeprom() {
                            shareEEPROM(data)
                        }
                    }
                    .disabled(appState.emulator == nil)
                }
                
                Section("Documents Folder") {
                    Text("Files in the app's Documents folder are accessible via the iOS Files app. You can edit or transfer your saves there.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let docsPath = appState.fileManager.documentsPath {
                        Text(docsPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }
                
                Section("Actions") {
                    Button("Save Current State") {
                        appState.saveEEPROM()
                    }
                    .disabled(appState.emulator == nil)
                    
                    Button("Load Save") {
                        appState.loadEEPROM()
                    }
                    .disabled(appState.emulator == nil)
                }
            }
            .navigationTitle("Files")
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard let urls = try? result.get(), let url = urls.first else { return }
        
        // Start accessing the security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let data = try? Data(contentsOf: url) else { return }
        
        switch documentPickerType {
        case .rom:
            appState.loadROMFromFile(url)
        case .eeprom:
            appState.fileManager.saveEEPROM(data)
            appState.loadEEPROM()
        }
    }
    
    private func shareEEPROM(_ data: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("eeprom.bin")
        try? data.write(to: tempURL)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section("Emulation") {
                    Toggle("Fast Mode", isOn: $appState.fastMode)
                        .onChange(of: appState.fastMode) { newValue in
                            appState.emulator?.setFastMode(newValue)
                        }
                    
                    Toggle("Bypass Power Save", isOn: $appState.bypassPowerSave)
                        .onChange(of: appState.bypassPowerSave) { newValue in
                            appState.emulator?.setBypassPowerSave(newValue)
                        }
                    
                    Toggle("Synthetic Steps", isOn: $appState.useSyntheticSteps)
                        .onChange(of: appState.useSyntheticSteps) { newValue in
                            appState.emulator?.setSyntheticSteps(newValue)
                        }
                }
                
                Section("HealthKit") {
                    Toggle("Enable Step Counting", isOn: $appState.healthManager.isEnabled)
                    
                    if appState.healthManager.isEnabled {
                        Button("Request Permission") {
                            appState.healthManager.requestAuthorization()
                        }
                        
                        Button("Sync Steps to Emulator") {
                            appState.healthManager.fetchTodaySteps { steps in
                                appState.emulator?.setSessionSteps(UInt32(steps))
                            }
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("PocketWalker Emulator", destination: URL(string: "https://github.com/h4lfheart/pocketwalker")!)
                    
                    Link("PokéWalker Firmware Decompilation", destination: URL(string: "https://github.com/h4lfheart/pw_firm")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Document Importer Extension

extension View {
    func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], allowsMultipleSelection: Bool, completion: @escaping (Result<[URL], Error>) -> Void) -> some View {
        self.fileImporter(
            isPresented: isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection
        ) { result in
            completion(result)
        }
    }
}
