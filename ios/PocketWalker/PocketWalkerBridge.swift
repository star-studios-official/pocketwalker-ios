import Foundation

// MARK: - Constants (macros from C header aren't available in Swift)

private let PW_LCD_WIDTH: Int = 128
private let PW_LCD_PAGES: Int = 22
private let PW_LCD_MEM_SIZE: Int = PW_LCD_WIDTH * 2 * PW_LCD_PAGES
private let PW_EEPROM_SIZE: Int = 0x10000

// MARK: - Swift Wrapper

/// Swift wrapper around the PocketWalker emulator
class PocketWalkerCore {
    private var emu: OpaquePointer?
    private var audioCallback: PWAudioCallback?

    var isRunning = false

    /// Create emulator from ROM data
    init?(romData: Data) {
        guard romData.count >= 0xC000 else { return nil }

        self.emu = romData.withUnsafeBytes { ptr in
            pw_create(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), UInt32(romData.count))
        }

        guard self.emu != nil else { return nil }
    }

    deinit {
        stop()
        if let emu = emu {
            pw_destroy(emu)
        }
    }

    func start() {
        guard let emu = emu, !isRunning else { return }
        pw_start(emu)
        isRunning = true
    }

    func stop() {
        guard let emu = emu, isRunning else { return }
        pw_stop(emu)
        isRunning = false
    }

    func setPaused(_ paused: Bool) {
        pw_set_paused(emu, paused)
    }

    /// Get LCD framebuffer as Data
    func getLCD() -> Data? {
        guard let emu = emu else { return nil }
        var data = Data(count: PW_LCD_MEM_SIZE)
        data.withUnsafeMutableBytes { ptr in
            pw_get_lcd(emu, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self))
        }
        return data
    }

    /// Get LCD contrast
    func getContrast() -> UInt8 {
        return pw_get_contrast(emu)
    }

    /// Check if LCD is in power save mode
    func getPowerSave() -> Bool {
        return pw_get_power_save(emu)
    }

    /// Get EEPROM data
    func getEeprom() -> Data? {
        guard let emu = emu else { return nil }
        var data = Data(count: PW_EEPROM_SIZE)
        data.withUnsafeMutableBytes { ptr in
            pw_get_eeprom(emu, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self))
        }
        return data
    }

    /// Set EEPROM data
    func setEeprom(_ data: Data) {
        guard let emu = emu else { return }
        data.withUnsafeBytes { ptr in
            pw_set_eeprom(emu, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), UInt32(data.count))
        }
    }

    func pressButton(_ button: Int32) {
        pw_press_button(emu, button)
    }

    func releaseButton(_ button: Int32) {
        pw_release_button(emu, button)
    }

    func setSyntheticSteps(_ enabled: Bool) {
        pw_set_synthetic_steps(emu, enabled)
    }

    func setSessionSteps(_ steps: UInt32) {
        pw_set_session_steps(emu, steps)
    }

    func setWatts(_ watts: UInt16) {
        pw_set_watts(emu, watts)
    }

    func setFastMode(_ enabled: Bool) {
        pw_set_fast_mode(emu, enabled)
    }

    func setBypassPowerSave(_ enabled: Bool) {
        pw_set_bypass_power_save(emu, enabled)
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
        pw_set_audio_callback(emu, audioCallback, Unmanaged.passUnretained(wrapper).toOpaque())
    }

    /// Read RAM byte
    func readRam(_ address: UInt16) -> UInt8 {
        return pw_read8(emu, address)
    }

    /// Read RAM word (little-endian)
    func readRam16(_ address: UInt16) -> UInt16 {
        return pw_read16(emu, address)
    }

    /// Read RAM dword (little-endian)
    func readRam32(_ address: UInt16) -> UInt32 {
        return pw_read32(emu, address)
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
