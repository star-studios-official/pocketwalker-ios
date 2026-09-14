import Foundation

/// Manages ROM and EEPROM files in the app's Documents directory
class EmulatorFileManager {
    private let fileManager = FileManager.default
    
    /// Path to the app's Documents directory
    var documentsPath: String? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path
    }
    
    private var documentsURL: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // MARK: - ROM File
    
    /// ROM file name
    private let romFileName = "pweep.rom"
    
    /// Full path to ROM file
    var romPath: URL? {
        documentsURL?.appendingPathComponent(romFileName)
    }
    
    /// Check if ROM file exists
    func romExists() -> Bool {
        guard let path = romPath else { return false }
        return fileManager.fileExists(atPath: path.path)
    }
    
    /// Load ROM data
    func loadROM() -> Data? {
        guard let path = romPath else { return nil }
        return try? Data(contentsOf: path)
    }
    
    /// Save ROM data
    func saveROM(_ data: Data) {
        guard let path = romPath else { return }
        try? data.write(to: path)
    }
    
    // MARK: - EEPROM / Save File
    
    /// EEPROM file name
    private let eepromFileName = "eeprom.bin"
    
    /// Full path to EEPROM file
    var eepromPath: URL? {
        documentsURL?.appendingPathComponent(eepromFileName)
    }
    
    /// Check if EEPROM file exists
    func eepromExists() -> Bool {
        guard let path = eepromPath else { return false }
        return fileManager.fileExists(atPath: path.path)
    }
    
    /// Load EEPROM data
    func loadEEPROM() -> Data? {
        guard let path = eepromPath else { return nil }
        return try? Data(contentsOf: path)
    }
    
    /// Save EEPROM data
    func saveEEPROM(_ data: Data) {
        guard let path = eepromPath else { return }
        try? data.write(to: path)
    }
    
    // MARK: - pwflash.rom (optional, for firmware-based emulation)
    
    /// pwflash.rom file name (optional, for firmware-based emulation)
    private let pwflashFileName = "pwflash.rom"
    
    /// Full path to pwflash.rom file
    var pwflashPath: URL? {
        documentsURL?.appendingPathComponent(pwflashFileName)
    }
    
    /// Check if pwflash.rom exists
    func pwflashExists() -> Bool {
        guard let path = pwflashPath else { return false }
        return fileManager.fileExists(atPath: path.path)
    }
    
    /// Load pwflash.rom data
    func loadPwflash() -> Data? {
        guard let path = pwflashPath else { return nil }
        return try? Data(contentsOf: path)
    }
    
    /// Save pwflash.rom data
    func savePwflash(_ data: Data) {
        guard let path = pwflashPath else { return }
        try? data.write(to: path)
    }
    
    // MARK: - List all files in Documents
    
    /// List all files in the Documents directory
    func listFiles() -> [URL] {
        guard let url = documentsURL else { return [] }
        return (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
    }
    
    /// Delete a file
    func deleteFile(at url: URL) -> Bool {
        return (try? fileManager.removeItem(at: url)) != nil
    }
    
    /// Get file size
    func fileSize(at url: URL) -> Int64? {
        let attrs = try? fileManager.attributesOfItem(atPath: url.path)
        return attrs?[.size] as? Int64
    }
}
