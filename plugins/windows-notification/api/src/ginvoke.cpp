
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
            const auto wmsg = std::wstring_view{e.message()};
            if (not wmsg.empty())
            {
                ptr = wsview_to_char(wmsg);
                if (not ptr)
                    throw 42;
                std::string msg{ptr};
                g_free(const_cast<char *>(ptr));  // WTF? Deletion is not modification!
                return {{ e.code(), std::move(msg) }};
            }
            else
                return {{ e.code(), "<no error description>" }};
        }
        catch (...)
        {
            g_free(const_cast<char *>(ptr));
            return {{ e.code(), "<failed to stringify error>" }};
        }
    }
    catch (...)
    {
        // This is not the exception you are looking for.
        return {};
    }
}
