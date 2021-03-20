
#ifndef GINVOKE_HPP
#define GINVOKE_HPP

#include <type_traits>
#include <string>
#include <string_view>
#include <sstream>
#include <iomanip>
#include <utility>
#include <optional>
#include <variant>
#include <iterator>
#include <functional>
#include <exception>
#include <cstdint>
#include <cinttypes>

#include <glib.h>

#include "overload.hpp"
#include "make_array.hpp"
#include "hexify.hpp"


namespace glib {

namespace impl
{
    using static_c_str = const char *;
    using varstring_t = std::variant<std::string, static_c_str>;
    struct varstring : varstring_t
    {
        varstring(std::string  &&s) noexcept : varstring_t{std::move(s)} {}
        varstring(static_c_str &&s) noexcept : varstring_t{std::move(s)} {}
        varstring(std::nullptr_t) = delete;
        varstring(const varstring &) = delete;
        varstring(varstring &&) = default;

        const char* c_str() const && = delete;
        const char* c_str() const &
        {
            return std::visit(overload{
                [](const std::string  &s){ return s.c_str(); },
                [](const static_c_str  s){ return s; }
            }, static_cast<const varstring_t &>(*this));
        }
    };

    struct hresult
    {
        std::int32_t code;
        varstring message;
    };
    std::optional<hresult> get_if_hresult_error(std::exception_ptr) noexcept;
}

template<typename OStream, typename T, std::enable_if_t<!std::is_enum_v<T>,int> = 0>
inline auto &describe_argument(OStream &s, const T &a) { return s << a; }
template<typename OStream, typename T, std::enable_if_t< std::is_enum_v<T>,int> = 0>
inline auto &describe_argument(OStream &s, const T &a) { return s << static_cast<std::underlying_type_t<T>>(a); }

template<typename OStream>
inline auto &describe_argument(OStream &s,  std::string_view const a) { return s << std::quoted(a); }
template<typename OStream>
inline auto &describe_argument(OStream &s, const  std::string &    a) { return s << std::quoted(a); }
template<typename OStream>
inline auto &describe_argument(OStream &s, const  char *     const a) { return s << std::quoted(a); }
// TODO: overload for const GString *
template<typename OStream>
inline auto &describe_argument(OStream &s, std::wstring_view const a) = delete;  // not implemented
template<typename OStream>
inline auto &describe_argument(OStream &s, const std::wstring &    a) = delete;  // not implemented
template<typename OStream>
inline auto &describe_argument(OStream &s, const wchar_t *   const a) = delete;  // not implemented
// TODO: handle wide strings maybe

inline impl::varstring describe_arguments() noexcept { return {""}; }

template<typename... Arg>
inline impl::varstring describe_arguments(const Arg &... a) noexcept try
{
    std::ostringstream ss;
    ((describe_argument(ss,a) << ','), ...);
    auto s = std::move(ss).str();
    s.pop_back();
    return {std::move(s)};
}
catch (...)
{
    return {"<failed to stringify arguments>"};
}


#define FORMAT "%s(%s) failed: %s"
template<typename... Arg>
inline void log_invocation_failure(const char *e, const char *func_name, const Arg &... a) noexcept
{
    const auto args = describe_arguments(a...);
    g_warning(FORMAT, func_name, args.c_str(), e);
}
template<typename... Arg>
inline void log_invocation_failure_desc(const char* e, const char* e_desc, const char* func_name, const Arg&... a) noexcept
{
    const auto args = describe_arguments(a...);
    g_warning(FORMAT": %s", func_name, args.c_str(), e, e_desc);
}
#undef FORMAT

struct regular_void {};

template<typename Invokable, typename... Arg>
inline auto invoke(Invokable &&i, const Arg &... a)
{
    if constexpr (std::is_void_v<decltype(std::invoke(std::forward<Invokable>(i), a...))>)
    {
        std::invoke(std::forward<Invokable>(i), a...);
        return regular_void{};
    }
    else
        return std::invoke(std::forward<Invokable>(i), a...);
}

template<typename Invokable, typename... Arg>
inline auto try_invoke(const char *func_name, Invokable &&i, const Arg &... a) noexcept
    -> std::optional<decltype(invoke(std::forward<Invokable>(i), a...))>
try
{
    return invoke(std::forward<Invokable>(i), a...);
}
catch (const std::exception &e)
{
    log_invocation_failure(e.what(), func_name, a...);
    return {};
}
catch (...)
{
    if (const auto e = impl::get_if_hresult_error(std::current_exception()))
    {
        auto hr = make_array("hresult 0x01234567\0");
        hexify32(static_cast<std::uint32_t>(e->code), std::end(hr)-1);
        log_invocation_failure_desc(std::begin(hr), e->message.c_str(), func_name, a...);
    }
    else
        log_invocation_failure("unknown error", func_name, a...);

    return {};
}

}  // namespace glib


#define g_try_invoke(invokable, ...)  glib::try_invoke(#invokable, invokable, __VA_ARGS__)
#define g_try_invoke0(invokable)      glib::try_invoke(#invokable, invokable)

#endif
