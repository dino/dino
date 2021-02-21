#include <iostream>

#include "gobject/winrt-private.h"

gboolean winrt_InitApartment()
{
    try
    {
        //winrt::init_apartment(); // TODO: FIXME
        return true;
    }
    catch(const std::exception& e)
    {
        std::cerr << e.what() << '\n';
    }
    
    return false;
}