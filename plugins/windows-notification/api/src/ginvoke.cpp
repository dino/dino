
#include "ginvoke.hpp"
#include "converter.hpp"

#include <winrt/base.h>


namespace glib::impl
{
    std::optional<hresult> get_if_hresult_error(const std::exception_ptr p) noexcept try
    {
        std::rethrow_exception(p);
    }
    catch (const winrt::hresult_error& e)
    {
        const char *ptr = nullptr;
        try
        {
            ptr = wsview_to_char(e.message());
            std::string msg{ptr};
            g_free(const_cast<char *>(ptr));  // WTF? Deletion is not modification!
            return {{ e.code(), {std::move(msg)} }};
        }
        catch (...)
        {
            g_free(const_cast<char *>(ptr));
            return {{ e.code(), {"<failed to stringify>"} }};
        }
    }
    catch (...)
    {
        // This is not the exception you are looking for.
        return {};
    }
}
