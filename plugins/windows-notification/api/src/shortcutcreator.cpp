
#include "shortcutcreator.h"
#include "win32.hpp"
#include "converter.hpp"
#include "ginvoke.hpp"
#include "dyn_mod.hpp"

#include <objbase.h>      // COM stuff
#include <shlobj.h>       // IShellLink
#include <propvarutil.h>  // InitPropVariantFromString
#include <propkey.h>      // PKEY_AppUserModel_ID
#include <winrt/base.h>   // At least one COM header must have been previously
// included, for `winrt::create_instance` to work with the `GUID` type.

#include <memory>

namespace dyn
{
    // PropVariantToString is a pain to use, and
    // MinGW 6.0.0 doesn't have libpropsys.a in the first place;
    // MinGW 9.0.0 doesn't have PropVariantToStringAlloc in its libpropsys.a.
    // So...
    constexpr auto PropVariantToStringAlloc = [](const auto &... arg)
    {
        static const auto &f =
            dyn_load_symbol("propsys.dll", PropVariantToStringAlloc);
        return f(arg...);
    };
}

namespace {

#define checked(func, args) \
    if (const auto hr = ((func)args); FAILED(hr)) \
    { \
        g_warning("%s%s failed: hresult 0x%08" PRIX32, \
            #func, #args, static_cast<std::uint32_t>(hr)); \
        winrt::throw_hresult(hr); \
    }

struct property
{
    property() noexcept : var{} {}

    explicit property(const std::wstring &value)
    {
        checked(::InitPropVariantFromString,(value.c_str(), &var));
    }

    ~property()
    {
        if (const auto hr = ::PropVariantClear(&var); FAILED(hr))
            g_critical("PropVariantClear failed: hresult 0x%08" PRIX32,
                static_cast<std::uint32_t>(hr));
    }

    auto str() const
    {
        wchar_t *str;
        checked(dyn::PropVariantToStringAlloc,(var, &str));
        return std::unique_ptr
            <wchar_t, decltype(&::CoTaskMemFree)>
            {    str,          &::CoTaskMemFree };
    }

    operator const PROPVARIANT &() const noexcept { return  var; }
    operator       PROPVARIANT *()       noexcept { return &var; }

private:
    PROPVARIANT var;
};

bool ImplEnsureAumiddedShortcutExists(
    const std::string_view menu_rel_path, const std::string_view narrow_aumid)
{
    if (menu_rel_path.empty())
        throw std::runtime_error{"empty menu-relative shortcut path"};

    const auto aumid = sview_to_wstr(narrow_aumid);
    if (aumid.empty())
    {
        return false;
    }

    const auto exe_path = GetExePath();
    const auto shortcut_path = GetEnv(L"APPDATA")
        + LR"(\Microsoft\Windows\Start Menu\)"
        + sview_to_wstr(menu_rel_path) + L".lnk";

    const auto lnk = winrt::create_instance<IShellLinkW>(CLSID_ShellLink);
    const auto file = lnk.as<IPersistFile>();
    const auto store = lnk.as<IPropertyStore>();

    if (SUCCEEDED(file->Load(shortcut_path.c_str(), STGM_READWRITE)))
    {
        property aumid_prop;
        checked(store->GetValue,(PKEY_AppUserModel_ID, aumid_prop));
        if (aumid_prop.str().get() != aumid)
            checked(store->SetValue,(PKEY_AppUserModel_ID, property{aumid}));

        std::array<wchar_t, MAX_PATH+1> targ_path;
        checked(lnk->GetPath,(targ_path.data(), targ_path.size(), nullptr, 0));
        if (targ_path.data() != exe_path)
            checked(lnk->SetPath,(exe_path.c_str()));
    }
    else
    {
        checked(store->SetValue,(PKEY_AppUserModel_ID, property{aumid}));
        checked(lnk->SetPath,(exe_path.c_str()));
    }

    checked(store->Commit,());

    if (file->IsDirty() != S_FALSE)  // not the same as `== S_OK`
    {
        constexpr auto set_file_as_current = TRUE;
        checked(file->Save,(shortcut_path.c_str(), set_file_as_current));
    }

    return true;
}

#undef checked

}  // nameless namespace


extern "C"
{
    gboolean EnsureAumiddedShortcutExists(const gchar *const aumid) noexcept
    {
        return g_try_invoke(
            ImplEnsureAumiddedShortcutExists, R"(Programs\Dino)", aumid)
                .value_or(false);
    }
}
