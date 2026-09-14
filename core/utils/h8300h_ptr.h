#pragma once
#include <bit>
#include <concepts>
#include <cstddef>
#include <cstdint>

// Portable byteswap: detail::byteswap is C++23, provide a shim for C++20 compilers
namespace detail {
    template <typename T>
    requires std::integral<T>
    inline constexpr T byteswap(T value) noexcept {
        if constexpr (sizeof(T) == 1) {
            return value;
        } else if constexpr (sizeof(T) == 2) {
            return static_cast<T>(__builtin_bswap16(static_cast<unsigned short>(value)));
        } else if constexpr (sizeof(T) == 4) {
            return static_cast<T>(__builtin_bswap32(static_cast<unsigned int>(value)));
        } else if constexpr (sizeof(T) == 8) {
            return static_cast<T>(__builtin_bswap64(static_cast<unsigned long long>(value)));
        }
    }
}

// provides an h8/300h big endian byte swap ptr for u16 and u32
// holy moly this is ugly

template <std::integral T>
class h8300h_ptr
{
public:
    struct ref
    {
        h8300h_ptr* p;

        operator T() const { return detail::byteswap(*p->ptr); }

        ref& operator=(T val)
        {
            *p = val;
            return *this;
        }

        ref& operator++()
        {
            *p = (T)(detail::byteswap(*p->ptr) + 1);
            return *this;
        }

        T operator++(int)
        {
            T old = detail::byteswap(*p->ptr);
            ++*this;
            return old;
        }

        ref& operator--()
        {
            *p = (T)(detail::byteswap(*p->ptr) - 1);
            return *this;
        }

        T operator--(int)
        {
            T old = detail::byteswap(*p->ptr);
            --*this;
            return old;
        }
    };

    h8300h_ptr() : ptr(nullptr)
    {
    }

    h8300h_ptr(std::nullptr_t) : ptr(nullptr)
    {
    }

    explicit h8300h_ptr(T* ptr) : ptr(ptr)
    {
    }

    ref operator*() { return ref{this}; }
    T operator*() const { return detail::byteswap(*ptr); }

    h8300h_ptr& operator=(T val)
    {
        *ptr = detail::byteswap(val);
        return *this;
    }

    h8300h_ptr& operator+=(T val)
    {
        *this = **this + val;
        return *this;
    }

    h8300h_ptr& operator-=(T val)
    {
        *this = **this - val;
        return *this;
    }

    h8300h_ptr& operator++()
    {
        *this = **this + 1;
        return *this;
    }

    bool operator==(T val) const { return **this == val; }
    bool operator>=(T val) const { return **this >= val; }
    bool operator<=(T val) const { return **this <= val; }
    bool operator>(T val) const { return **this > val; }
    bool operator<(T val) const { return **this < val; }

    T* ptr;
};
