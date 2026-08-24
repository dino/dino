#pragma once

#include <string>
#include <string_view>
#include <glib.h>

std::wstring sview_to_wstr(const std::string_view str);
gchar* wsview_to_char(const std::wstring_view wstr);