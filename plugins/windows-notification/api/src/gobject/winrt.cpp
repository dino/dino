#include <iostream>

#include "gobject/winrt-private.h"

gboolean winrt_InitApartment()
{
    try
    {
        winrt::init_apartment(); // TODO: FIXME, header only works with unity build
        return true;
    }
    catch(const std::exception& e)
    {
        std::cerr << e.what() << '\n';
    }
    
    return false;
}