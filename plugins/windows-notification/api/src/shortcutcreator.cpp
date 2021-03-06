
#include "shortcutcreator.h"
#include "win32.hpp"
#include "converter.hpp"
#include "ginvoke.hpp"

#include <objbase.h>      // COM stuff
#include <shlobj.h>       // IShellLink
#include <propvarutil.h>  // InitPropVariantFromString
#include <propkey.h>      // PKEY_AppUserModel_ID
#include <winrt/base.h>   // At least one COM header must have been previously
// included, for `winrt::create_instance` to work with the `GUID` type.

#include <memory>

namespace {

#define checked(func, args) \
    if (const auto hr = ((func)args); FAILED(hr)) \
    { \
        g_warning("%s%s failed: hresult %#08" PRIX32, \
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
            g_critical("PropVariantClear failed: hresult %#08" PRIX32,
                static_cast<std::uint32_t>(hr));
    }

    auto str() const
    {
        wchar_t *str;
        checked(::PropVariantToStringAlloc,(var, &str));
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
            ImplEnsureAumiddedShortcutExists, R"(Programs\Dino)", aumid);
    }
}
