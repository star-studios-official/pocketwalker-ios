cmake_minimum_required(VERSION 3.20)
project(PocketWalkerCore LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build the core library
file(GLOB_RECURSE CORE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../core/**/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../core/**/*.h
)

# Exclude desktop-specific sources
list(FILTER CORE_SOURCES EXCLUDE REGEX ".*desktop.*")

add_library(pocketwalker_core STATIC ${CORE_SOURCES})

target_include_directories(pocketwalker_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/../core
    ${CMAKE_CURRENT_SOURCE_DIR}/PocketWalkerCore
)

# Build the C API wrapper
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

# iOS-specific settings
if(IOS)
    set_target_properties(pocketwalker_core PROPERTIES
        XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH YES
    )
    
    set_target_properties(pocketwalker_capi PROPERTIES
        XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH YES
    )
endif()
