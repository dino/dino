
#include "dyn_mod.hpp"
#include "win32.hpp"

#include <glib.h>
#include <windows.h>

namespace dyn_mod
{
    auto load_module(const wchar_t *const path, const char *const dbgnym)
    {
        const auto mod = ::LoadLibraryW(path);
        if (mod)
            return mod;
        const win32_error e{};
        g_warning("failed to load %s", dbgnym);
        throw e;
    }

    punny_func &load_symbol(
        const wchar_t *const mod_path, const char *const mod_dbgnym,
        const char *const symbol)
    {
        const auto p = reinterpret_cast<punny_func *>(
            ::GetProcAddress(load_module(mod_path, mod_dbgnym), symbol));
        if (p)
            return *p;
        const win32_error e{};
        g_warning("couldn't find %s in %s", symbol, mod_dbgnym);
        throw e;
    }
}
