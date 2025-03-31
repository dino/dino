
#ifndef HEXIFY_HPP
#define HEXIFY_HPP
#include <cstdint>

constexpr void hexify32(std::uint32_t val, char *const end) noexcept
{
    auto p = end-1;
    for (auto i = 0; i < 32/4; ++i, --p, val >>= 4)
        *p = "0123456789ABCDEF"[val & ((1u<<4)-1u)];
}
#endif
