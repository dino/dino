// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_UI_H
#define WINRT_Windows_UI_H
#include "base.h"
static_assert(winrt::check_version(CPPWINRT_VERSION, "2.0.190620.2"), "Mismatched C++/WinRT headers.");
#include "impl/Windows.UI.2.h"
namespace winrt::impl
{
    template <typename D> auto consume_Windows_UI_IColorHelperStatics<D>::FromArgb(uint8_t a, uint8_t r, uint8_t g, uint8_t b) const
    {
        Windows::UI::Color returnValue;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorHelperStatics)->FromArgb(a, r, g, b, put_abi(returnValue)));
        return returnValue;
    }
    template <typename D> auto consume_Windows_UI_IColorHelperStatics2<D>::ToDisplayName(Windows::UI::Color const& color) const
    {
        void* returnValue{};
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorHelperStatics2)->ToDisplayName(impl::bind_in(color), &returnValue));
        return hstring{ returnValue, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::AliceBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_AliceBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::AntiqueWhite() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_AntiqueWhite(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Aqua() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Aqua(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Aquamarine() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Aquamarine(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Azure() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Azure(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Beige() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Beige(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Bisque() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Bisque(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Black() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Black(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::BlanchedAlmond() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_BlanchedAlmond(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Blue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Blue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::BlueViolet() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_BlueViolet(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Brown() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Brown(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::BurlyWood() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_BurlyWood(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::CadetBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_CadetBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Chartreuse() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Chartreuse(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Chocolate() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Chocolate(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Coral() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Coral(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::CornflowerBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_CornflowerBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Cornsilk() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Cornsilk(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Crimson() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Crimson(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Cyan() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Cyan(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkCyan() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkCyan(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkGoldenrod() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkGoldenrod(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkGray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkGray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkKhaki() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkKhaki(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkMagenta() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkMagenta(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkOliveGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkOliveGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkOrange() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkOrange(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkOrchid() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkOrchid(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkRed() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkRed(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkSalmon() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkSalmon(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkSeaGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkSeaGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkSlateBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkSlateBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkSlateGray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkSlateGray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkTurquoise() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkTurquoise(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DarkViolet() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DarkViolet(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DeepPink() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DeepPink(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DeepSkyBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DeepSkyBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DimGray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DimGray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::DodgerBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_DodgerBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Firebrick() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Firebrick(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::FloralWhite() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_FloralWhite(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::ForestGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_ForestGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Fuchsia() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Fuchsia(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Gainsboro() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Gainsboro(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::GhostWhite() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_GhostWhite(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Gold() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Gold(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Goldenrod() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Goldenrod(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Gray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Gray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Green() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Green(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::GreenYellow() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_GreenYellow(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Honeydew() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Honeydew(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::HotPink() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_HotPink(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::IndianRed() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_IndianRed(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Indigo() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Indigo(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Ivory() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Ivory(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Khaki() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Khaki(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Lavender() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Lavender(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LavenderBlush() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LavenderBlush(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LawnGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LawnGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LemonChiffon() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LemonChiffon(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightCoral() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightCoral(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightCyan() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightCyan(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightGoldenrodYellow() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightGoldenrodYellow(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightGray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightGray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightPink() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightPink(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightSalmon() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightSalmon(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightSeaGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightSeaGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightSkyBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightSkyBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightSlateGray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightSlateGray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightSteelBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightSteelBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LightYellow() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LightYellow(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Lime() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Lime(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::LimeGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_LimeGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Linen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Linen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Magenta() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Magenta(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Maroon() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Maroon(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumAquamarine() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumAquamarine(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumOrchid() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumOrchid(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumPurple() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumPurple(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumSeaGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumSeaGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumSlateBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumSlateBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumSpringGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumSpringGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumTurquoise() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumTurquoise(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MediumVioletRed() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MediumVioletRed(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MidnightBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MidnightBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MintCream() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MintCream(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::MistyRose() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_MistyRose(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Moccasin() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Moccasin(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::NavajoWhite() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_NavajoWhite(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Navy() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Navy(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::OldLace() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_OldLace(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Olive() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Olive(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::OliveDrab() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_OliveDrab(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Orange() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Orange(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::OrangeRed() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_OrangeRed(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Orchid() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Orchid(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PaleGoldenrod() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PaleGoldenrod(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PaleGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PaleGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PaleTurquoise() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PaleTurquoise(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PaleVioletRed() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PaleVioletRed(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PapayaWhip() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PapayaWhip(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PeachPuff() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PeachPuff(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Peru() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Peru(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Pink() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Pink(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Plum() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Plum(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::PowderBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_PowderBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Purple() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Purple(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Red() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Red(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::RosyBrown() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_RosyBrown(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::RoyalBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_RoyalBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SaddleBrown() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SaddleBrown(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Salmon() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Salmon(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SandyBrown() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SandyBrown(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SeaGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SeaGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SeaShell() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SeaShell(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Sienna() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Sienna(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Silver() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Silver(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SkyBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SkyBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SlateBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SlateBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SlateGray() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SlateGray(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Snow() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Snow(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SpringGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SpringGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::SteelBlue() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_SteelBlue(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Tan() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Tan(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Teal() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Teal(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Thistle() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Thistle(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Tomato() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Tomato(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Transparent() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Transparent(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Turquoise() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Turquoise(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Violet() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Violet(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Wheat() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Wheat(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::White() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_White(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::WhiteSmoke() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_WhiteSmoke(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::Yellow() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_Yellow(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IColorsStatics<D>::YellowGreen() const
    {
        Windows::UI::Color value;
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IColorsStatics)->get_YellowGreen(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_UI_IUIContentRoot<D>::UIContext() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::UI::IUIContentRoot)->get_UIContext(&value));
        return Windows::UI::UIContext{ value, take_ownership_from_abi };
    }
    template <typename D>
    struct produce<D, Windows::UI::IColorHelper> : produce_base<D, Windows::UI::IColorHelper>
    {
    };
    template <typename D>
    struct produce<D, Windows::UI::IColorHelperStatics> : produce_base<D, Windows::UI::IColorHelperStatics>
    {
        int32_t __stdcall FromArgb(uint8_t a, uint8_t r, uint8_t g, uint8_t b, struct struct_Windows_UI_Color* returnValue) noexcept final try
        {
            zero_abi<Windows::UI::Color>(returnValue);
            typename D::abi_guard guard(this->shim());
            *returnValue = detach_from<Windows::UI::Color>(this->shim().FromArgb(a, r, g, b));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::UI::IColorHelperStatics2> : produce_base<D, Windows::UI::IColorHelperStatics2>
    {
        int32_t __stdcall ToDisplayName(struct struct_Windows_UI_Color color, void** returnValue) noexcept final try
        {
            clear_abi(returnValue);
            typename D::abi_guard guard(this->shim());
            *returnValue = detach_from<hstring>(this->shim().ToDisplayName(*reinterpret_cast<Windows::UI::Color const*>(&color)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::UI::IColors> : produce_base<D, Windows::UI::IColors>
    {
    };
    template <typename D>
    struct produce<D, Windows::UI::IColorsStatics> : produce_base<D, Windows::UI::IColorsStatics>
    {
        int32_t __stdcall get_AliceBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().AliceBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_AntiqueWhite(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().AntiqueWhite());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Aqua(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Aqua());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Aquamarine(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Aquamarine());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Azure(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Azure());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Beige(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Beige());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Bisque(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Bisque());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Black(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Black());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_BlanchedAlmond(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().BlanchedAlmond());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Blue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Blue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_BlueViolet(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().BlueViolet());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Brown(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Brown());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_BurlyWood(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().BurlyWood());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_CadetBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().CadetBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Chartreuse(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Chartreuse());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Chocolate(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Chocolate());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Coral(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Coral());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_CornflowerBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().CornflowerBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Cornsilk(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Cornsilk());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Crimson(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Crimson());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Cyan(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Cyan());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkCyan(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkCyan());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkGoldenrod(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkGoldenrod());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkGray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkGray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkKhaki(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkKhaki());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkMagenta(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkMagenta());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkOliveGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkOliveGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkOrange(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkOrange());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkOrchid(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkOrchid());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkRed(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkRed());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkSalmon(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkSalmon());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkSeaGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkSeaGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkSlateBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkSlateBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkSlateGray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkSlateGray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkTurquoise(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkTurquoise());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DarkViolet(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DarkViolet());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DeepPink(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DeepPink());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DeepSkyBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DeepSkyBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DimGray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DimGray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DodgerBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().DodgerBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Firebrick(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Firebrick());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_FloralWhite(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().FloralWhite());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ForestGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().ForestGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Fuchsia(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Fuchsia());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Gainsboro(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Gainsboro());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_GhostWhite(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().GhostWhite());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Gold(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Gold());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Goldenrod(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Goldenrod());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Gray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Gray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Green(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Green());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_GreenYellow(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().GreenYellow());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Honeydew(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Honeydew());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_HotPink(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().HotPink());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_IndianRed(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().IndianRed());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Indigo(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Indigo());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Ivory(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Ivory());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Khaki(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Khaki());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Lavender(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Lavender());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LavenderBlush(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LavenderBlush());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LawnGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LawnGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LemonChiffon(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LemonChiffon());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightCoral(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightCoral());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightCyan(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightCyan());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightGoldenrodYellow(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightGoldenrodYellow());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightGray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightGray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightPink(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightPink());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightSalmon(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightSalmon());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightSeaGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightSeaGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightSkyBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightSkyBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightSlateGray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightSlateGray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightSteelBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightSteelBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LightYellow(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LightYellow());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Lime(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Lime());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LimeGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().LimeGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Linen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Linen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Magenta(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Magenta());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Maroon(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Maroon());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumAquamarine(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumAquamarine());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumOrchid(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumOrchid());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumPurple(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumPurple());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumSeaGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumSeaGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumSlateBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumSlateBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumSpringGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumSpringGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumTurquoise(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumTurquoise());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MediumVioletRed(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MediumVioletRed());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MidnightBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MidnightBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MintCream(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MintCream());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_MistyRose(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().MistyRose());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Moccasin(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Moccasin());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_NavajoWhite(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().NavajoWhite());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Navy(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Navy());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_OldLace(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().OldLace());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Olive(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Olive());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_OliveDrab(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().OliveDrab());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Orange(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Orange());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_OrangeRed(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().OrangeRed());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Orchid(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Orchid());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PaleGoldenrod(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PaleGoldenrod());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PaleGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PaleGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PaleTurquoise(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PaleTurquoise());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PaleVioletRed(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PaleVioletRed());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PapayaWhip(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PapayaWhip());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PeachPuff(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PeachPuff());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Peru(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Peru());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Pink(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Pink());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Plum(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Plum());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PowderBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().PowderBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Purple(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Purple());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Red(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Red());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_RosyBrown(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().RosyBrown());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_RoyalBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().RoyalBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SaddleBrown(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SaddleBrown());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Salmon(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Salmon());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SandyBrown(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SandyBrown());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SeaGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SeaGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SeaShell(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SeaShell());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Sienna(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Sienna());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Silver(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Silver());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SkyBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SkyBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SlateBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SlateBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SlateGray(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SlateGray());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Snow(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Snow());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SpringGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SpringGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SteelBlue(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().SteelBlue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Tan(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Tan());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Teal(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Teal());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Thistle(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Thistle());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Tomato(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Tomato());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Transparent(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Transparent());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Turquoise(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Turquoise());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Violet(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Violet());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Wheat(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Wheat());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_White(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().White());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_WhiteSmoke(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().WhiteSmoke());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Yellow(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().Yellow());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_YellowGreen(struct struct_Windows_UI_Color* value) noexcept final try
        {
            zero_abi<Windows::UI::Color>(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::Color>(this->shim().YellowGreen());
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::UI::IUIContentRoot> : produce_base<D, Windows::UI::IUIContentRoot>
    {
        int32_t __stdcall get_UIContext(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::UI::UIContext>(this->shim().UIContext());
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::UI::IUIContext> : produce_base<D, Windows::UI::IUIContext>
    {
    };
}
namespace winrt::Windows::UI
{
    inline auto ColorHelper::FromArgb(uint8_t a, uint8_t r, uint8_t g, uint8_t b)
    {
        return impl::call_factory<ColorHelper, Windows::UI::IColorHelperStatics>([&](auto&& f) { return f.FromArgb(a, r, g, b); });
    }
    inline auto ColorHelper::ToDisplayName(Windows::UI::Color const& color)
    {
        return impl::call_factory<ColorHelper, Windows::UI::IColorHelperStatics2>([&](auto&& f) { return f.ToDisplayName(color); });
    }
    inline auto Colors::AliceBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.AliceBlue(); });
    }
    inline auto Colors::AntiqueWhite()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.AntiqueWhite(); });
    }
    inline auto Colors::Aqua()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Aqua(); });
    }
    inline auto Colors::Aquamarine()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Aquamarine(); });
    }
    inline auto Colors::Azure()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Azure(); });
    }
    inline auto Colors::Beige()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Beige(); });
    }
    inline auto Colors::Bisque()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Bisque(); });
    }
    inline auto Colors::Black()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Black(); });
    }
    inline auto Colors::BlanchedAlmond()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.BlanchedAlmond(); });
    }
    inline auto Colors::Blue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Blue(); });
    }
    inline auto Colors::BlueViolet()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.BlueViolet(); });
    }
    inline auto Colors::Brown()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Brown(); });
    }
    inline auto Colors::BurlyWood()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.BurlyWood(); });
    }
    inline auto Colors::CadetBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.CadetBlue(); });
    }
    inline auto Colors::Chartreuse()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Chartreuse(); });
    }
    inline auto Colors::Chocolate()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Chocolate(); });
    }
    inline auto Colors::Coral()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Coral(); });
    }
    inline auto Colors::CornflowerBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.CornflowerBlue(); });
    }
    inline auto Colors::Cornsilk()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Cornsilk(); });
    }
    inline auto Colors::Crimson()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Crimson(); });
    }
    inline auto Colors::Cyan()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Cyan(); });
    }
    inline auto Colors::DarkBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkBlue(); });
    }
    inline auto Colors::DarkCyan()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkCyan(); });
    }
    inline auto Colors::DarkGoldenrod()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkGoldenrod(); });
    }
    inline auto Colors::DarkGray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkGray(); });
    }
    inline auto Colors::DarkGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkGreen(); });
    }
    inline auto Colors::DarkKhaki()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkKhaki(); });
    }
    inline auto Colors::DarkMagenta()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkMagenta(); });
    }
    inline auto Colors::DarkOliveGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkOliveGreen(); });
    }
    inline auto Colors::DarkOrange()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkOrange(); });
    }
    inline auto Colors::DarkOrchid()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkOrchid(); });
    }
    inline auto Colors::DarkRed()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkRed(); });
    }
    inline auto Colors::DarkSalmon()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkSalmon(); });
    }
    inline auto Colors::DarkSeaGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkSeaGreen(); });
    }
    inline auto Colors::DarkSlateBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkSlateBlue(); });
    }
    inline auto Colors::DarkSlateGray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkSlateGray(); });
    }
    inline auto Colors::DarkTurquoise()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkTurquoise(); });
    }
    inline auto Colors::DarkViolet()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DarkViolet(); });
    }
    inline auto Colors::DeepPink()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DeepPink(); });
    }
    inline auto Colors::DeepSkyBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DeepSkyBlue(); });
    }
    inline auto Colors::DimGray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DimGray(); });
    }
    inline auto Colors::DodgerBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.DodgerBlue(); });
    }
    inline auto Colors::Firebrick()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Firebrick(); });
    }
    inline auto Colors::FloralWhite()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.FloralWhite(); });
    }
    inline auto Colors::ForestGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.ForestGreen(); });
    }
    inline auto Colors::Fuchsia()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Fuchsia(); });
    }
    inline auto Colors::Gainsboro()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Gainsboro(); });
    }
    inline auto Colors::GhostWhite()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.GhostWhite(); });
    }
    inline auto Colors::Gold()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Gold(); });
    }
    inline auto Colors::Goldenrod()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Goldenrod(); });
    }
    inline auto Colors::Gray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Gray(); });
    }
    inline auto Colors::Green()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Green(); });
    }
    inline auto Colors::GreenYellow()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.GreenYellow(); });
    }
    inline auto Colors::Honeydew()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Honeydew(); });
    }
    inline auto Colors::HotPink()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.HotPink(); });
    }
    inline auto Colors::IndianRed()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.IndianRed(); });
    }
    inline auto Colors::Indigo()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Indigo(); });
    }
    inline auto Colors::Ivory()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Ivory(); });
    }
    inline auto Colors::Khaki()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Khaki(); });
    }
    inline auto Colors::Lavender()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Lavender(); });
    }
    inline auto Colors::LavenderBlush()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LavenderBlush(); });
    }
    inline auto Colors::LawnGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LawnGreen(); });
    }
    inline auto Colors::LemonChiffon()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LemonChiffon(); });
    }
    inline auto Colors::LightBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightBlue(); });
    }
    inline auto Colors::LightCoral()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightCoral(); });
    }
    inline auto Colors::LightCyan()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightCyan(); });
    }
    inline auto Colors::LightGoldenrodYellow()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightGoldenrodYellow(); });
    }
    inline auto Colors::LightGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightGreen(); });
    }
    inline auto Colors::LightGray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightGray(); });
    }
    inline auto Colors::LightPink()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightPink(); });
    }
    inline auto Colors::LightSalmon()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightSalmon(); });
    }
    inline auto Colors::LightSeaGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightSeaGreen(); });
    }
    inline auto Colors::LightSkyBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightSkyBlue(); });
    }
    inline auto Colors::LightSlateGray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightSlateGray(); });
    }
    inline auto Colors::LightSteelBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightSteelBlue(); });
    }
    inline auto Colors::LightYellow()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LightYellow(); });
    }
    inline auto Colors::Lime()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Lime(); });
    }
    inline auto Colors::LimeGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.LimeGreen(); });
    }
    inline auto Colors::Linen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Linen(); });
    }
    inline auto Colors::Magenta()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Magenta(); });
    }
    inline auto Colors::Maroon()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Maroon(); });
    }
    inline auto Colors::MediumAquamarine()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumAquamarine(); });
    }
    inline auto Colors::MediumBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumBlue(); });
    }
    inline auto Colors::MediumOrchid()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumOrchid(); });
    }
    inline auto Colors::MediumPurple()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumPurple(); });
    }
    inline auto Colors::MediumSeaGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumSeaGreen(); });
    }
    inline auto Colors::MediumSlateBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumSlateBlue(); });
    }
    inline auto Colors::MediumSpringGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumSpringGreen(); });
    }
    inline auto Colors::MediumTurquoise()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumTurquoise(); });
    }
    inline auto Colors::MediumVioletRed()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MediumVioletRed(); });
    }
    inline auto Colors::MidnightBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MidnightBlue(); });
    }
    inline auto Colors::MintCream()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MintCream(); });
    }
    inline auto Colors::MistyRose()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.MistyRose(); });
    }
    inline auto Colors::Moccasin()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Moccasin(); });
    }
    inline auto Colors::NavajoWhite()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.NavajoWhite(); });
    }
    inline auto Colors::Navy()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Navy(); });
    }
    inline auto Colors::OldLace()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.OldLace(); });
    }
    inline auto Colors::Olive()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Olive(); });
    }
    inline auto Colors::OliveDrab()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.OliveDrab(); });
    }
    inline auto Colors::Orange()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Orange(); });
    }
    inline auto Colors::OrangeRed()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.OrangeRed(); });
    }
    inline auto Colors::Orchid()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Orchid(); });
    }
    inline auto Colors::PaleGoldenrod()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PaleGoldenrod(); });
    }
    inline auto Colors::PaleGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PaleGreen(); });
    }
    inline auto Colors::PaleTurquoise()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PaleTurquoise(); });
    }
    inline auto Colors::PaleVioletRed()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PaleVioletRed(); });
    }
    inline auto Colors::PapayaWhip()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PapayaWhip(); });
    }
    inline auto Colors::PeachPuff()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PeachPuff(); });
    }
    inline auto Colors::Peru()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Peru(); });
    }
    inline auto Colors::Pink()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Pink(); });
    }
    inline auto Colors::Plum()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Plum(); });
    }
    inline auto Colors::PowderBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.PowderBlue(); });
    }
    inline auto Colors::Purple()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Purple(); });
    }
    inline auto Colors::Red()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Red(); });
    }
    inline auto Colors::RosyBrown()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.RosyBrown(); });
    }
    inline auto Colors::RoyalBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.RoyalBlue(); });
    }
    inline auto Colors::SaddleBrown()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SaddleBrown(); });
    }
    inline auto Colors::Salmon()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Salmon(); });
    }
    inline auto Colors::SandyBrown()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SandyBrown(); });
    }
    inline auto Colors::SeaGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SeaGreen(); });
    }
    inline auto Colors::SeaShell()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SeaShell(); });
    }
    inline auto Colors::Sienna()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Sienna(); });
    }
    inline auto Colors::Silver()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Silver(); });
    }
    inline auto Colors::SkyBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SkyBlue(); });
    }
    inline auto Colors::SlateBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SlateBlue(); });
    }
    inline auto Colors::SlateGray()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SlateGray(); });
    }
    inline auto Colors::Snow()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Snow(); });
    }
    inline auto Colors::SpringGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SpringGreen(); });
    }
    inline auto Colors::SteelBlue()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.SteelBlue(); });
    }
    inline auto Colors::Tan()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Tan(); });
    }
    inline auto Colors::Teal()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Teal(); });
    }
    inline auto Colors::Thistle()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Thistle(); });
    }
    inline auto Colors::Tomato()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Tomato(); });
    }
    inline auto Colors::Transparent()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Transparent(); });
    }
    inline auto Colors::Turquoise()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Turquoise(); });
    }
    inline auto Colors::Violet()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Violet(); });
    }
    inline auto Colors::Wheat()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Wheat(); });
    }
    inline auto Colors::White()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.White(); });
    }
    inline auto Colors::WhiteSmoke()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.WhiteSmoke(); });
    }
    inline auto Colors::Yellow()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.Yellow(); });
    }
    inline auto Colors::YellowGreen()
    {
        return impl::call_factory<Colors, Windows::UI::IColorsStatics>([&](auto&& f) { return f.YellowGreen(); });
    }
}
namespace std
{
    template<> struct hash<winrt::Windows::UI::IColorHelper> : winrt::impl::hash_base<winrt::Windows::UI::IColorHelper> {};
    template<> struct hash<winrt::Windows::UI::IColorHelperStatics> : winrt::impl::hash_base<winrt::Windows::UI::IColorHelperStatics> {};
    template<> struct hash<winrt::Windows::UI::IColorHelperStatics2> : winrt::impl::hash_base<winrt::Windows::UI::IColorHelperStatics2> {};
    template<> struct hash<winrt::Windows::UI::IColors> : winrt::impl::hash_base<winrt::Windows::UI::IColors> {};
    template<> struct hash<winrt::Windows::UI::IColorsStatics> : winrt::impl::hash_base<winrt::Windows::UI::IColorsStatics> {};
    template<> struct hash<winrt::Windows::UI::IUIContentRoot> : winrt::impl::hash_base<winrt::Windows::UI::IUIContentRoot> {};
    template<> struct hash<winrt::Windows::UI::IUIContext> : winrt::impl::hash_base<winrt::Windows::UI::IUIContext> {};
    template<> struct hash<winrt::Windows::UI::ColorHelper> : winrt::impl::hash_base<winrt::Windows::UI::ColorHelper> {};
    template<> struct hash<winrt::Windows::UI::Colors> : winrt::impl::hash_base<winrt::Windows::UI::Colors> {};
    template<> struct hash<winrt::Windows::UI::UIContentRoot> : winrt::impl::hash_base<winrt::Windows::UI::UIContentRoot> {};
    template<> struct hash<winrt::Windows::UI::UIContext> : winrt::impl::hash_base<winrt::Windows::UI::UIContext> {};
}
#endif
