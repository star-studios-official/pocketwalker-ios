#include "include/pocketwalker_capi.h"
#include "core/pokewalker/pocketwalker.h"

#include <memory>
#include <thread>
#include <atomic>

struct PWEmulator {
    std::unique_ptr<PocketWalker> walker;
    std::unique_ptr<std::thread> thread;
    std::atomic<bool> running{false};
    PWAudioCallback audio_callback{nullptr};
    void* audio_user_data{nullptr};
};

extern "C" {

PWEmulator* pw_create(const uint8_t* rom_data, uint32_t rom_size) {
    if (!rom_data || rom_size < 0xC000) return nullptr;

    auto emu = new PWEmulator();
    RomBuffer rom = {};
    std::memcpy(rom.data(), rom_data, 0xC000);

    emu->walker = std::make_unique<PocketWalker>(rom);
    return emu;
}

void pw_destroy(PWEmulator* emu) {
    if (!emu) return;
    pw_stop(emu);
    delete emu;
}

void pw_start(PWEmulator* emu) {
    if (!emu || emu->running) return;

    // Set up audio callback forwarding
    if (emu->audio_callback) {
        PWAudioCallback cb = emu->audio_callback;
        void* ud = emu->audio_user_data;
        emu->walker->OnSamplePushed([cb, ud](BuzzerInformation info) {
            cb(info.frequency, info.is_full_volume, ud);
        });
    }

    emu->running = true;
    emu->thread = std::make_unique<std::thread>([emu]() {
        emu->walker->Start();
    });
}

void pw_stop(PWEmulator* emu) {
    if (!emu) return;
    emu->walker->Stop();
    if (emu->thread && emu->thread->joinable()) {
        emu->thread->join();
    }
    emu->running = false;
}

void pw_set_paused(PWEmulator* emu, bool paused) {
    if (!emu) return;
    emu->walker->SetPause(paused);
}

void pw_get_lcd(PWEmulator* emu, uint8_t* buffer) {
    if (!emu || !buffer) return;
    auto* info = emu->walker->GetDrawInfo();
    void* src = info->vram.Ptr(0);
    std::memcpy(buffer, src, PW_LCD_MEM_SIZE);
}

uint8_t pw_get_contrast(PWEmulator* emu) {
    if (!emu) return 0;
    return emu->walker->GetDrawInfo()->contrast;
}

bool pw_get_power_save(PWEmulator* emu) {
    if (!emu) return false;
    return emu->walker->GetDrawInfo()->power_save_mode;
}

void pw_get_eeprom(PWEmulator* emu, uint8_t* buffer) {
    if (!emu || !buffer) return;
    auto eeprom = emu->walker->GetEepromBuffer();
    std::memcpy(buffer, eeprom.data(), PW_EEPROM_SIZE);
}

void pw_set_eeprom(PWEmulator* emu, const uint8_t* buffer, uint32_t size) {
    if (!emu || !buffer) return;
    EepromBuffer eeprom = {};
    uint32_t copy_size = (size < PW_EEPROM_SIZE) ? size : PW_EEPROM_SIZE;
    std::memcpy(eeprom.data(), buffer, copy_size);
    emu->walker->SetEepromBuffer(eeprom);
}

void pw_press_button(PWEmulator* emu, int button) {
    if (!emu) return;
    emu->walker->PressButton(static_cast<ButtonType>(button));
}

void pw_release_button(PWEmulator* emu, int button) {
    if (!emu) return;
    emu->walker->ReleaseButton(static_cast<ButtonType>(button));
}

void pw_set_synthetic_steps(PWEmulator* emu, bool enabled) {
    if (!emu) return;
    emu->walker->UseSyntheticSteps(enabled);
}

void pw_set_session_steps(PWEmulator* emu, uint32_t steps) {
    if (!emu) return;
    emu->walker->SetSessionSteps(steps);
}

void pw_set_watts(PWEmulator* emu, uint16_t watts) {
    if (!emu) return;
    emu->walker->SetWatts(watts);
}

void pw_set_fast_mode(PWEmulator* emu, bool enabled) {
    if (!emu) return;
    emu->walker->UseFastMode(enabled);
}

void pw_set_bypass_power_save(PWEmulator* emu, bool enabled) {
    if (!emu) return;
    emu->walker->SetBypassPowerSave(enabled);
}

void pw_set_audio_callback(PWEmulator* emu, PWAudioCallback callback, void* user_data) {
    if (!emu) return;
    emu->audio_callback = callback;
    emu->audio_user_data = user_data;
}

uint8_t pw_read8(PWEmulator* emu, uint16_t address) {
    if (!emu) return 0;
    return emu->walker->ReadRam(address);
}

uint16_t pw_read16(PWEmulator* emu, uint16_t address) {
    uint8_t lo = pw_read8(emu, address);
    uint8_t hi = pw_read8(emu, address + 1);
    return (uint16_t)(lo | (hi << 8));
}

uint32_t pw_read32(PWEmulator* emu, uint16_t address) {
    uint16_t lo = pw_read16(emu, address);
    uint16_t hi = pw_read16(emu, address + 2);
    return (uint32_t)(lo | (hi << 16));
}

} // extern "C"
