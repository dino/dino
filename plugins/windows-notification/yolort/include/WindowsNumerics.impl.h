
// Copyright © 2021, mjk <yuubi-san@users.noreply.github.com>

//  This file is merely to cheaply plug compilability holes in windows 10 winrt
// APIs that use types from the non-free(?) WindowsNumerics library
// unconditionally, i. e., unguarded by __has_include.
//  MinGW will probably have a complete implementation in the future, at which
// point this file may turn into a part of the problem it solves now (FIXME).

#ifndef YOLORT_WINDOWSNUMERICS_IMPL_H
#define YOLORT_WINDOWSNUMERICS_IMPL_H

#include <tuple>
#include <array>

_WINDOWS_NUMERICS_BEGIN_NAMESPACE_
{
  // These definitions make sense to *me*, but one cannot be sure microsoft
  // didn't add proprietary extensions to mathematics.

#define define_mathy_type(name, T, N, ...) \
  struct name \
  { \
  private: \
    constexpr auto _tie() const \
    { \
      auto members = std::tie( __VA_ARGS__ ); \
      static_assert( std::tuple_size_v<decltype(members)> == (N) ); \
      return members; \
    } \
  public: \
    T __VA_ARGS__; \
    friend constexpr auto operator==( const name &l, const name &r ) \
    { return l._tie() == r._tie(); } \
  }

#define define_vector_type(T,N,...) define_mathy_type(T##N, T, N, __VA_ARGS__)
  define_vector_type(float,2,x,y);
  define_vector_type(float,3,x,y,z);
  define_vector_type(float,4,x,y,z,w);
#undef define_vector_type

#define define_matrix_type(T,N,M)   struct T##N##x##M : std::array<T, N*M> {}
  define_matrix_type(float,2,2);
  define_matrix_type(float,2,3);
  define_matrix_type(float,2,4);
  define_matrix_type(float,3,2);
  define_matrix_type(float,3,3);
  define_matrix_type(float,3,4);
  define_matrix_type(float,4,2);
  define_matrix_type(float,4,3);
  define_matrix_type(float,4,4);
#undef define_matrix_type

  define_mathy_type(quaternion, float, 4, a,b,c,d );
  define_mathy_type(plane, float, 3+1, x,y,z, d );

#undef define_mathy_type
}
_WINDOWS_NUMERICS_END_NAMESPACE_

#endif  // YOLORT_WINDOWSNUMERICS_IMPL_H
