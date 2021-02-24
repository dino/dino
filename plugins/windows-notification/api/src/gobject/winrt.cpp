#include <iostream>

#include "gobject/winrt-private.h"
#include "converter.hpp"

gboolean winrt_InitApartment()
{
    try
    {
        winrt::init_apartment();
        return true;
    }
    catch(const winrt::hresult_error& e)
    {
        auto message = wsview_to_char(e.message());
        std::cerr << message << '\n';
        delete[] message;
        if (e.code() == -2147417850 /* RPC_E_CHANGED_MODE */) // harmless
        {
            return true;
        }
    }
    
    return false;
}