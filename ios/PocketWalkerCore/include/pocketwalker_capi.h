#ifndef POCKETWALKER_CAPI_H
#define POCKETWALKER_CAPI_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque handle to the emulator instance */
typedef struct PWEmulator PWEmulator;

/* LCD dimensions */
#define PW_LCD_WIDTH  128
#define PW_LCD_PAGES  22
#define PW_LCD_HEIGHT (PW_LCD_PAGES * 8)  /* 176 pixels, but only 96x64 visible */
#define PW_LCD_MEM_SIZE (PW_LCD_WIDTH * 2 * PW_LCD_PAGES)

/* EEPROM size */
#define PW_EEPROM_SIZE 0x10000

/* Button types */
#define PW_BUTTON_CENTER 1
#define PW_BUTTON_LEFT   4
#define PW_BUTTON_RIGHT  16

/* Create a new emulator instance with the given ROM data.
 * rom_data must be at least 0xC000 bytes (48KB).
 * Returns NULL on failure. */
PWEmulator* pw_create(const uint8_t* rom_data, uint32_t rom_size);

/* Destroy the emulator instance and free resources. */
void pw_destroy(PWEmulator* emu);

/* Start the emulation loop on a background thread. */
void pw_start(PWEmulator* emu);

/* Stop the emulation loop. */
void pw_stop(PWEmulator* emu);

/* Pause/unpause the emulation. */
void pw_set_paused(PWEmulator* emu, bool paused);

/* Get a snapshot of the LCD VRAM (64KB for 128x176 monochrome).
 * Caller must provide a buffer of at least PW_LCD_MEM_SIZE bytes. */
void pw_get_lcd(PWEmulator* emu, uint8_t* buffer);

/* Get the LCD contrast value (0-255). */
uint8_t pw_get_contrast(PWEmulator* emu);

/* Check if LCD is in power save mode. */
bool pw_get_power_save(PWEmulator* emu);

/* Get the current EEPROM state (64KB).
 * Caller must provide a buffer of at least PW_EEPROM_SIZE bytes. */
void pw_get_eeprom(PWEmulator* emu, uint8_t* buffer);

/* Set the EEPROM state (e.g., load a save file). */
void pw_set_eeprom(PWEmulator* emu, const uint8_t* buffer, uint32_t size);

/* Press a button (bitmask of PW_BUTTON_*). */
void pw_press_button(PWEmulator* emu, int button);

/* Release a button. */
void pw_release_button(PWEmulator* emu, int button);

/* Enable/disable synthetic step generation. */
void pw_set_synthetic_steps(PWEmulator* emu, bool enabled);

/* Inject steps directly into the emulator's memory. */
void pw_set_session_steps(PWEmulator* emu, uint32_t steps);

/* Inject watts into the emulator's memory. */
void pw_set_watts(PWEmulator* emu, uint16_t watts);

/* Enable/disable fast mode (no frame limiting). */
void pw_set_fast_mode(PWEmulator* emu, bool enabled);

/* Enable/disable bypass power save (keeps LCD active). */
void pw_set_bypass_power_save(PWEmulator* emu, bool enabled);

/* Audio sample callback type.
 * Called from the emulator thread with frequency and volume info. */
typedef void (*PWAudioCallback)(float frequency, bool full_volume, void* user_data);

/* Set the audio callback. */
void pw_set_audio_callback(PWEmulator* emu, PWAudioCallback callback, void* user_data);

/* Read a specific memory address (for reading RAM globals). */
uint8_t pw_read8(PWEmulator* emu, uint16_t address);
uint16_t pw_read16(PWEmulator* emu, uint16_t address);
uint32_t pw_read32(PWEmulator* emu, uint16_t address);

#ifdef __cplusplus
}
#endif

#endif /* POCKETWALKER_CAPI_H */
