
// Copyright © 2021, mjk <yuubi-san@users.noreply.github.com>

// It is safe to assume that every other line
// here has UB (but refer to the filename).

#ifndef YOLORT_WRAP_IPP
#define YOLORT_WRAP_IPP

// just microsoft things
#if __has_include(<version>)
#include <version>     // for __cpp_lib_coroutine in winrt/base.h
#endif
#include <cstring>     // for memcmp in winrt/base.h
#include <cstddef>
using std::nullptr_t;  // for unqualified nullptr_t in winrt/base.h
#include <climits>     // for UINT_MAX in winrt/base.h
#include <cassert>

namespace yolort
{
  inline void memcpy(
    void *      const dst,
    std::size_t const dstsize [[maybe_unused]],
    const void *const src,
    std::size_t const srcsize ) noexcept
  {
    assert( dst );
    assert( src );
    assert( srcsize <= dstsize );
    std::memcpy( dst, src, srcsize );
  }
}


#include <intrin.h>
// work around the `undefined reference to _ReturnAddress` for now...
#define _ReturnAddress() __builtin_return_address(0)
#include <cstdint>
// mingw apparently doesn't(?) yet implement this one as of gcc 10:
template<typename Dummy = int>
inline unsigned char _InterlockedCompareExchange128(
  std::int64_t volatile *const pcurrent,
  std::int64_t const desired_hi,
  std::int64_t const desired_lo,
  std::int64_t *const pexpected ) noexcept
{
#ifdef _WIN64
  return __sync_bool_compare_and_swap
  (
    reinterpret_cast<__int128_t volatile *>(pcurrent),
    *reinterpret_cast<__int128_t *>(pexpected),
    __int128_t{desired_hi} << 64 | desired_lo
  );
#else
  static_assert( !sizeof(Dummy), "not implemented for 32-bit targets" );
  return {};
#endif
}


// just libstdc++ things

#include <charconv>
#if !defined(__cpp_lib_to_chars) or __cpp_lib_to_chars < 201611
#include <type_traits>
#include <sstream>
#include <algorithm>
namespace std
{
  // release the Kraken!

  #if __GNUC__ < 10  // maybe 9 already has this, dunno
  enum class chars_format
  {
      scientific = 0b001,
      fixed      = 0b010,
      hex        = 0b100,
      general    = fixed | scientific,
  };
  #endif

  template<
    typename Float,
    enable_if_t<is_floating_point_v<Float>, int> = 0
  >
  inline to_chars_result to_chars(
    char *const first, char *const last,
    Float const value,
    chars_format const fmt [[maybe_unused]] ) noexcept
  {
    assert( fmt == chars_format::general );
    try
    {
      ostringstream os;
      os << value;
      const auto &s = os.str();
      if ( s.size() > static_cast<std::size_t>(last-first) )
        return { last, errc::value_too_large };
      return { copy(s.begin(), s.end(), first), {} };
    }
    catch ( ... )
    {
      return { last, errc::value_too_large };
    }
  }
}
#endif  // __cpp_lib_to_chars

#endif  // YOLORT_WRAP_IPP


#ifdef HEADER_IMPL
  #define __pragma(...)
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wattributes"
  #pragma GCC diagnostic ignored "-Wunused-parameter"
  #pragma GCC diagnostic ignored "-Wconversion"
  #pragma GCC diagnostic ignored "-Wpedantic"
  #pragma GCC diagnostic ignored "-Wstrict-aliasing"
  // ^ warning: dereferencing type-punned pointer will break strict-aliasing
  //  rules
  //  if (result == *(int64_t*)&current_value)
  //                ^~~~~~~~~~~~~~~~~~~~~~~~
  #pragma GCC diagnostic ignored "-Wclass-memaccess"
  // ^ warning: 'void* memset(void*, int, size_t)' clearing an object of type
  //  'struct winrt::com_array<unsigned char>' with no trivial copy-assignment;
  //  use value-initialization instead
  // Y U NO C++, MS??
	  #include HEADER_IMPL
  #pragma GCC diagnostic pop
  #undef __pragma
#endif
