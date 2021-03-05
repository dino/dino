
#ifndef MAKE_ARRAY_HPP
#define MAKE_ARRAY_HPP
#include <array>
#include <algorithm>

template<std::size_t N>
inline auto make_array(const char (&from_literal)[N]) noexcept
{
    static_assert( N );
    std::array<char,N-1> a;
    std::copy(+from_literal, from_literal+a.size(), a.begin());
    return a;
}
#endif
