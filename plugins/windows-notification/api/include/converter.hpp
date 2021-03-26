#pragma once

#include <glib.h>
#include <string>

std::wstring char_to_wstr(const gchar* str);
char* wstr_to_char(const std::wstring& wstr);