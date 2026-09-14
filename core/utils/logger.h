#pragma once

#include <cstdlib>

// std::println / std::format are C++23. Apple Clang doesn't have them yet.
// Provide a portable logger using fprintf when <print> isn't available.
#if __has_include(<print>) && defined(__cpp_lib_print) && __cpp_lib_print >= 202207L
#include <print>
#include <format>

class Log
{
public:
    template <typename... Args>
    static void Info(std::format_string<Args...> fmt, Args&&... args)
    {
#ifndef NDEBUG
        std::println("[INFO] {}", std::format(fmt, std::forward<Args>(args)...));
#endif
    }

    template <typename... Args>
    static void Warn(std::format_string<Args...> fmt, Args&&... args)
    {
#ifndef NDEBUG
        std::println(stderr, "[WARN] {}", std::format(fmt, std::forward<Args>(args)...));
#endif
    }

    template <typename... Args>
    static void Error(std::format_string<Args...> fmt, Args&&... args)
    {
#ifndef NDEBUG
        std::println(stderr, "[ERROR] {}", std::format(fmt, std::forward<Args>(args)...));
#endif
    }

    template <typename... Args>
    static void Fatal(std::format_string<Args...> fmt, Args&&... args)
    {
#ifndef NDEBUG
        std::println(stderr, "[FATAL] {}", std::format(fmt, std::forward<Args>(args)...));
#endif
        std::abort();
    }
};
#else
// Fallback: no-op logger for compilers without C++23 print/format
class Log
{
public:
    template <typename...>
    static void Info(...) {}
    template <typename...>
    static void Warn(...) {}
    template <typename...>
    static void Error(...) {}
    template <typename...>
    static void Fatal(...) { std::abort(); }
};
#endif