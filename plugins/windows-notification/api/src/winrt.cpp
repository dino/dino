#include <winrt/base.h>

#include "winrt.h"

gboolean Initialize()
{
    winrt::init_apartment();
}