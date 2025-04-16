#include <stringapiset.h>

#include "converter.hpp"

// Convert a wide Unicode string to an UTF8 string
char* wsview_to_char(const std::wstring_view wstr)
{
    if(wstr.empty())
    {
        return nullptr;
    }
    int final_size = WideCharToMultiByte(CP_UTF8, 0, wstr.data(), (int)wstr.size(), nullptr, 0, nullptr, nullptr);
    gchar* strTo = g_new0(gchar, final_size + 1);
    WideCharToMultiByte(CP_UTF8, 0, wstr.data(), (int)wstr.size(), strTo, final_size, nullptr, nullptr);
    return strTo;
}

// Convert an UTF8 string to a wide Unicode String
std::wstring sview_to_wstr(const std::string_view str)
{
    if(str.empty())
    {
        return std::wstring();
    }
    int final_size = MultiByteToWideChar(CP_UTF8, 0, str.data(), (int)str.size(), nullptr, 0);
    std::wstring wstrTo(final_size, 0);
    MultiByteToWideChar(CP_UTF8, 0, str.data(), (int)str.size(), wstrTo.data(), final_size);
    return wstrTo;
}