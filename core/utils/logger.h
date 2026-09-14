#pragma once

#include <cstdio>
#include <cstdlib>
#include <string>

// Portable logger: uses std::println when available, falls back to fprintf.
// In release builds (NDEBUG defined), all logging is compiled out.

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

// Fallback: fully no-op logger for compilers without C++23 print/format.
// Uses empty variadic templates to avoid -Wnon-pod-varargs.
class Log
{
public:
    // Accept any arguments and do nothing. The template pack prevents
    // the compiler from trying to pass non-trivial types through
    // variadic C functions.
    template <typename... Args>
    static void Info(Args&&...) {}

    template <typename... Args>
    static void Warn(Args&&...) {}

    template <typename... Args>
    static void Error(Args&&...) {}

    template <typename... Args>
    [[noreturn]] static void Fatal(Args&&...) { std::abort(); }
};

#endif
