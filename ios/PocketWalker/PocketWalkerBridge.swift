import Foundation

// MARK: - C API Declarations

/// Opaque handle to the emulator instance
typealias PWEmulatorRef = OpaquePointer

/// Audio sample callback type
typealias PWAudioCallback = @convention(c) (Float, Bool, UnsafeMutableRawPointer?) -> Void

/// LCD dimensions
let PW_LCD_WIDTH: Int32 = 128
let PW_LCD_PAGES: Int32 = 22
let PW_LCD_HEIGHT: Int32 = PW_LCD_PAGES * 8
let PW_LCD_MEM_SIZE: Int32 = PW_LCD_WIDTH * 2 * PW_LCD_PAGES

/// EEPROM size
let PW_EEPROM_SIZE: Int32 = 0x10000

/// Button types
let PW_BUTTON_CENTER: Int32 = 1
let PW_BUTTON_LEFT: Int32 = 4
let PW_BUTTON_RIGHT: Int32 = 16

// MARK: - C API Functions

@_silgen_name("pw_create")
func c_pw_create(_ romData: UnsafePointer<UInt8>?, _ romSize: UInt32) -> PWEmulatorRef?

@_silgen_name("pw_destroy")
func c_pw_destroy(_ emu: PWEmulatorRef?)

@_silgen_name("pw_start")
func c_pw_start(_ emu: PWEmulatorRef?)

@_silgen_name("pw_stop")
func c_pw_stop(_ emu: PWEmulatorRef?)

@_silgen_name("pw_set_paused")
func c_pw_set_paused(_ emu: PWEmulatorRef?, _ paused: Bool)

@_silgen_name("pw_get_lcd")
func c_pw_get_lcd(_ emu: PWEmulatorRef?, _ buffer: UnsafeMutablePointer<UInt8>?)

@_silgen_name("pw_get_contrast")
func c_pw_get_contrast(_ emu: PWEmulatorRef?) -> UInt8

@_silgen_name("pw_get_power_save")
func c_pw_get_power_save(_ emu: PWEmulatorRef?) -> Bool

@_silgen_name("pw_get_eeprom")
func c_pw_get_eeprom(_ emu: PWEmulatorRef?, _ buffer: UnsafeMutablePointer<UInt8>?)

@_silgen_name("pw_set_eeprom")
func c_pw_set_eeprom(_ emu: PWEmulatorRef?, _ buffer: UnsafePointer<UInt8>?, _ size: UInt32)

@_silgen_name("pw_press_button")
func c_pw_press_button(_ emu: PWEmulatorRef?, _ button: Int32)

@_silgen_name("pw_release_button")
func c_pw_release_button(_ emu: PWEmulatorRef?, _ button: Int32)

@_silgen_name("pw_set_synthetic_steps")
func c_pw_set_synthetic_steps(_ emu: PWEmulatorRef?, _ enabled: Bool)

@_silgen_name("pw_set_session_steps")
func c_pw_set_session_steps(_ emu: PWEmulatorRef?, _ steps: UInt32)

@_silgen_name("pw_set_watts")
func c_pw_set_watts(_ emu: PWEmulatorRef?, _ watts: UInt16)

@_silgen_name("pw_set_fast_mode")
func c_pw_set_fast_mode(_ emu: PWEmulatorRef?, _ enabled: Bool)

@_silgen_name("pw_set_bypass_power_save")
func c_pw_set_bypass_power_save(_ emu: PWEmulatorRef?, _ enabled: Bool)

@_silgen_name("pw_set_audio_callback")
func c_pw_set_audio_callback(_ emu: PWEmulatorRef?, _ callback: PWAudioCallback?, _ userData: UnsafeMutableRawPointer?)

@_silgen_name("pw_read8")
func c_pw_read8(_ emu: PWEmulatorRef?, _ address: UInt16) -> UInt8

@_silgen_name("pw_read16")
func c_pw_read16(_ emu: PWEmulatorRef?, _ address: UInt16) -> UInt16

@_silgen_name("pw_read32")
func c_pw_read32(_ emu: PWEmulatorRef?, _ address: UInt16) -> UInt32

// MARK: - Swift Wrapper

/// Swift wrapper around the PocketWalker emulator
class PocketWalkerCore {
    private var emu: PWEmulatorRef?
    private var audioCallback: PWAudioCallback?
    
    var isRunning = false
    
    /// Create emulator from ROM data
    init?(romData: Data) {
        guard romData.count >= 0xC000 else { return nil }
        
        self.emu = romData.withUnsafeBytes { ptr in
            c_pw_create(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), UInt32(romData.count))
        }
        
        guard self.emu != nil else { return nil }
    }
    
    deinit {
        stop()
        if let emu = emu {
            c_pw_destroy(emu)
        }
    }
    
    func start() {
        guard let emu = emu, !isRunning else { return }
        c_pw_start(emu)
        isRunning = true
    }
    
    func stop() {
        guard let emu = emu, isRunning else { return }
        c_pw_stop(emu)
        isRunning = false
    }
    
    func setPaused(_ paused: Bool) {
        c_pw_set_paused(emu, paused)
    }
    
    /// Get LCD framebuffer as Data
    func getLCD() -> Data? {
        guard let emu = emu else { return nil }
        var data = Data(count: Int(PW_LCD_MEM_SIZE))
        data.withUnsafeMutableBytes { ptr in
            c_pw_get_lcd(emu, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self))
        }
        return data
    }
    
    /// Get LCD contrast
    func getContrast() -> UInt8 {
        return c_pw_get_contrast(emu)
    }
    
    /// Check if LCD is in power save mode
    func getPowerSave() -> Bool {
        return c_pw_get_power_save(emu)
    }
    
    /// Get EEPROM data
    func getEeprom() -> Data? {
        guard let emu = emu else { return nil }
        var data = Data(count: Int(PW_EEPROM_SIZE))
        data.withUnsafeMutableBytes { ptr in
            c_pw_get_eeprom(emu, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self))
        }
        return data
    }
    
    /// Set EEPROM data
    func setEeprom(_ data: Data) {
        guard let emu = emu else { return }
        data.withUnsafeBytes { ptr in
            c_pw_set_eeprom(emu, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), UInt32(data.count))
        }
    }
    
    func pressButton(_ button: Int32) {
        c_pw_press_button(emu, button)
    }
    
    func releaseButton(_ button: Int32) {
        c_pw_release_button(emu, button)
    }
    
    func setSyntheticSteps(_ enabled: Bool) {
        c_pw_set_synthetic_steps(emu, enabled)
    }
    
    func setSessionSteps(_ steps: UInt32) {
        c_pw_set_session_steps(emu, steps)
    }
    
    func setWatts(_ watts: UInt16) {
        c_pw_set_watts(emu, watts)
    }
    
    func setFastMode(_ enabled: Bool) {
        c_pw_set_fast_mode(emu, enabled)
    }
    
    func setBypassPowerSave(_ enabled: Bool) {
        c_pw_set_bypass_power_save(emu, enabled)
    }
    
    /// Set audio callback (called from emulator thread)
    func setAudioCallback(_ callback: @escaping (Float, Bool) -> Void) {
        let wrapper = AudioCallbackWrapper(callback)
        audioCallback = { frequency, fullVolume, userData in
            guard let userData = userData else { return }
            let wrapper = Unmanaged<AudioCallbackWrapper>.fromOpaque(userData).takeUnretainedValue()
            wrapper.callback(frequency, fullVolume)
        }
        audioCallbackPointer = wrapper
        c_pw_set_audio_callback(emu, audioCallback, Unmanaged.passUnretained(wrapper).toOpaque())
    }
    
    /// Read RAM byte
    func readRam(_ address: UInt16) -> UInt8 {
        return c_pw_read8(emu, address)
    }
    
    /// Read RAM word (little-endian)
    func readRam16(_ address: UInt16) -> UInt16 {
        return c_pw_read16(emu, address)
    }
    
    /// Read RAM dword (little-endian)
    func readRam32(_ address: UInt16) -> UInt32 {
        return c_pw_read32(emu, address)
    }
}

/// Helper class to bridge Swift closure to C callback
private class AudioCallbackWrapper {
    let callback: (Float, Bool) -> Void
    init(_ callback: @escaping (Float, Bool) -> Void) {
        self.callback = callback
    }
}

private var audioCallbackPointer: AudioCallbackWrapper?
