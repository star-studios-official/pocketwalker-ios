cmake_minimum_required(VERSION 3.20)
project(PocketWalker LANGUAGES C CXX Swift)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Only build when targeting iOS
if(NOT IOS)
    message(STATUS "Not targeting iOS, skipping iOS build")
    return()
endif()

# ---------------------------------------------------------------------------
# pocketwalker_core — the C++ emulator core (CPU, SoC, peripherals)
# ---------------------------------------------------------------------------

file(GLOB_RECURSE CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../core/**/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../core/**/*.h
)

# Exclude desktop-specific sources
list(FILTER CORE_SOURCES EXCLUDE REGEX ".*desktop.*")

add_library(pocketwalker_core STATIC ${CORE_SOURCES})
target_include_directories(pocketwalker_core PUBLIC
    # Repo root: core files use #include "core/memory/interface.h"
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    # Also allow direct includes from core/
    ${CMAKE_CURRENT_SOURCE_DIR}/../core
)
set_target_properties(pocketwalker_core PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)

# ---------------------------------------------------------------------------
# pocketwalker_capi — C API wrapper bridging C++ core to Swift
# ---------------------------------------------------------------------------

add_library(pocketwalker_capi STATIC
    PocketWalkerCore/pocketwalker_capi.cpp
    PocketWalkerCore/include/pocketwalker_capi.h
)

target_include_directories(pocketwalker_capi PUBLIC
    PocketWalkerCore/include
)

target_link_libraries(pocketwalker_capi PUBLIC
    pocketwalker_core
)

set_target_properties(pocketwalker_capi PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)

# ---------------------------------------------------------------------------
# pocketwalker_ios_app — the SwiftUI iOS app (MACOSX_BUNDLE)
# ---------------------------------------------------------------------------

set(POCKETWALKER_SWIFT_SOURCES
    PocketWalker/App.swift
    PocketWalker/ContentView.swift
    PocketWalker/PocketWalkerBridge.swift
    PocketWalker/EmulatorFileManager.swift
    PocketWalker/HealthManager.swift
    PocketWalker/AudioManager.swift
)

add_executable(pocketwalker_ios_app MACOSX_BUNDLE
    ${POCKETWALKER_SWIFT_SOURCES}
)

set_target_properties(pocketwalker_ios_app PROPERTIES
    OUTPUT_NAME "PocketWalker"
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "com.pocketwalker.PocketWalker"
    MACOSX_BUNDLE_BUNDLE_IDENTIFIER "com.pocketwalker.PocketWalker"
    MACOSX_BUNDLE_BUNDLE_VERSION "1"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.pocketwalker.PocketWalker"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/PocketWalker/Info.plist"
    MACOSX_BUNDLE_ICON_FILE "AppIcon"
    MACOSX_BUNDLE_LAUNCH_SCREEN_STORYBOARD ""
    MACOSX_BUNDLE_SCREEN_ORIENTATIONS "UIInterfaceOrientationPortrait"
    MACOSX_BUNDLE_RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/PocketWalker/Assets.xcassets"
    XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    XCODE_ATTRIBUTE_INFOPLIST_KEY_CFBundleDisplayName "PocketWalker"
    XCODE_ATTRIBUTE_INFOPLIST_KEY_UIApplicationSceneManifest_Generation YES
    XCODE_ATTRIBUTE_INFOPLIST_KEY_UISupportedInterfaceOrientations "UIInterfaceOrientationPortrait"
    XCODE_ATTRIBUTE_INFOPLIST_KEY_UILaunchScreen_Generation YES
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/PocketWalker/PocketWalker.entitlements"
    XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/PocketWalker/PocketWalker-Bridging-Header.h"
    XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ""
    LINKER_LANGUAGE Swift
)

target_link_libraries(pocketwalker_ios_app PRIVATE
    pocketwalker_capi
)

# HealthKit framework
find_library(HEALTHKIT_FRAMEWORK HealthKit)
if(HEALTHKIT_FRAMEWORK)
    target_link_libraries(pocketwalker_ios_app PRIVATE ${HEALTHKIT_FRAMEWORK})
endif()

# AVFoundation framework (for audio)
find_library(AVFOUNDATION_FRAMEWORK AVFoundation)
if(AVFOUNDATION_FRAMEWORK)
    target_link_libraries(pocketwalker_ios_app PRIVATE ${AVFOUNDATION_FRAMEWORK})
endif()

# Asset catalog
set_source_files_properties(
    "${CMAKE_CURRENT_SOURCE_DIR}/PocketWalker/Assets.xcassets"
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources"
)
target_sources(pocketwalker_ios_app PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/PocketWalker/Assets.xcassets"
)
