#pragma once

#include <string>
#include <string_view>

std::wstring sview_to_wstr(const std::string_view str);
char* wsview_to_char(const std::wstring_view wstr);