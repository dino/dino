
#ifndef DYN_MOD_HPP
#define DYN_MOD_HPP

namespace dyn_mod
{
    using punny_func = void();

    punny_func &load_symbol(
        const wchar_t *mod_path,
        const  char   *mod_dbgnym,
        const  char   *symbol);

    template<typename T>
    inline T &load_symbol(
        const wchar_t *const mod_path, const char *const mod_dbgnym,
        const char *const symbol)
    {
        return reinterpret_cast<T &>(load_symbol(mod_path, mod_dbgnym, symbol));
    }
}

#define dyn_load_symbol_ns(mod_name, namespace, symbol) \
    ::dyn_mod::load_symbol<decltype(namespace::symbol)>( \
        L ## mod_name, mod_name, #symbol)

#define dyn_load_symbol(mod_name, symbol)  dyn_load_symbol_ns(mod_name, ,symbol)

#endif
