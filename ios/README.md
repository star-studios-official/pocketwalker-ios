# PocketWalker iOS

An iOS port of the [PocketWalker](https://github.com/h4lfheart/pocketwalker) H8/38606F emulator, built for the PokéWalker.

## Features

### Emulation
- Full H8/300H CPU emulation (ported from the desktop Qt version)
- LCD display rendering (SSD1854 96×64 grayscale)
- Button controls (Left, Center, Right)
- Buzzer audio (square wave synthesis via AVAudioEngine)
- EEPROM save/load (M95512)

### iOS Integration
- **HealthKit Step Counting**: Sync your real-world steps from the Health app into the emulator
- **Document Access**: ROM and save files are stored in the app's Documents folder, accessible via the iOS Files app
- **Audio Engine**: Real-time buzzer sound synthesis matching the emulator's output
- **File Sharing**: Import/export ROM and save files via the Files app or share sheet

### PokéWalker Features
- Walk sessions with step counting
- Battle system (from the decompiled firmware)
- Dowsing minigame
- PokéRadar minigame
- IR communications (via TCP with melonDS-IR)
- Trainer card and stats
- Sound effects and music

## File Management

The app stores files in its Documents directory, which is accessible via the iOS Files app:

| File | Description |
|------|-------------|
| `pweep.rom` | PokéWalker ROM file (required) |
| `eeprom.bin` | Save file (64KB EEPROM dump) |
| `pwflash.rom` | Optional firmware file |

### Loading Files
1. Connect your device to a Mac/PC and use Finder/iTunes File Sharing
2. Use the Files app on iOS to copy files to/from the PocketWalker folder
3. Use the app's built-in file picker to import files

### Editing Saves
The `eeprom.bin` file can be edited using:
- [PokéWalker EEPROM Editor](https://github.com/h4lfheart/pokewalker-eeprom-editor) (web-based)
- Any hex editor that supports 64KB binary files
- Copy the file to your computer, edit it, and copy it back

## Building

### Prerequisites
- Xcode 15.0+ (for manual builds)
- iOS 16.0+ deployment target
- CMake 3.20+

### GitHub Actions (No Mac Required)

The project includes a GitHub Actions workflow that builds the iOS app:

1. Push your changes to GitHub
2. Go to Actions → ios-build
3. Click "Run workflow"
4. Download the unsigned IPA artifact when the build completes

To sign the IPA for device installation:
1. Set `IOS_CERT_P12_BASE64` and `IOS_MOBILEPROVISION_BASE64` repo secrets
2. Trigger the `sign-ipa` workflow manually

### Manual Build (Local)

```bash
# Clone the repository
git clone --recursive https://github.com/h4lfheart/pocketwalker
cd pocketwalker

# Configure CMake with Xcode generator
cd ios
cmake -S . -B build-ios -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64

# Build (produces PocketWalker.app in build-ios/)
cmake --build build-ios --config Release

# Or open in Xcode
open build-ios/PocketWalker.xcodeproj
```

## Architecture

```
ios/
├── CMakeLists.txt                    # CMake build for core library
├── PocketWalkerCore/
│   ├── include/
│   │   └── pocketwalker_capi.h      # C API wrapper header
│   └── pocketwalker_capi.cpp        # C++ → C bridge
├── PocketWalker/
│   ├── App.swift                     # Main app entry point
│   ├── ContentView.swift             # Main UI with tabs
│   ├── PocketWalkerBridge.swift      # Swift → C bridge
│   ├── EmulatorFileManager.swift     # File management
│   ├── HealthManager.swift           # HealthKit integration
│   ├── AudioManager.swift            # Audio engine
│   ├── Info.plist                    # App configuration
│   ├── PocketWalker.entitlements     # HealthKit entitlements
│   └── Assets.xcassets/              # App icons
├── build-ios/                        # CMake build output
└── README.md
```

### Core Library (C++)

The emulator core is written in C++17 and provides:
- H8/300H CPU emulation
- H8/38606F SoC (memory bus, timers, interrupts)
- PokéWalker peripherals (LCD, EEPROM, accelerometer, buzzer, IR)

### C API Wrapper

A C API wrapper (`pocketwalker_capi.h/cpp`) bridges the C++ core to Swift:
- Opaque handle for the emulator instance
- LCD framebuffer access
- EEPROM read/write
- Button input
- Audio callback
- RAM access

### Swift Layer

The Swift layer provides:
- SwiftUI-based UI (emulator view, file management, settings)
- HealthKit integration for step counting
- AVAudioEngine for buzzer sounds
- FileManager integration for document access

## PokéWalker Hardware Reference

| Component | Details |
|-----------|---------|
| MCU | Renesas H8/38606R — H8/300H core, 3.6 MHz |
| RAM | 2 KiB |
| ROM | 48 KiB |
| Display | 96×64 4-shade grayscale LCD (SSD1854) |
| Input | 3 buttons |
| Sensors | Accelerometer (BMA150), IrDA transceiver |
| Storage | 64 KiB EEPROM (M95512) |
| Audio | Piezo buzzer |

## EEPROM Layout

The 64KB EEPROM contains:
- 0x0000-0x007F: Boot/system block
- 0x0080-0x0155: Trainer record (primary + backup)
- 0x0156-0x017F: Session save block
- 0x0278-0x2A00: Graphics/sprite data
- 0x8F00-0x9000: Active trainer profile
- 0xB800-0xBEC8: Step history flags
- 0xBD40-0xBEC8: Wild Pokémon encounter data
- 0xC6FC-0xCE7F: Sound/asset region
- 0xCE80-0xDE23: Peer/interaction log
- 0xDE24-0xF38B: Step history sample buffer

See [eeprom_layout.h](../../ref/pw_firm/include/eeprom_layout.h) for the full layout.

## Credits

- [PocketWalker](https://github.com/h4lfheart/pocketwalker) - Original emulator
- [PokéWalker Firmware Decompilation](https://github.com/h4lfheart/pw_firm) - Firmware decompilation
- [PokéWalker EEPROM Editor](https://github.com/h4lfheart/pokewalker-eeprom-editor) - Save editor
- [melonDS-IR](https://github.com/DaveuRrr/melonDS-IR) - IR communication

## License

See [LICENSE](../../LICENSE) for details.
