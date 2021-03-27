// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_UI_1_H
#define WINRT_Windows_UI_1_H
#include "Windows.UI.0.h"
namespace winrt::Windows::UI
{
    struct __declspec(empty_bases) IColorHelper :
        Windows::Foundation::IInspectable,
        impl::consume_t<IColorHelper>
    {
        IColorHelper(std::nullptr_t = nullptr) noexcept {}
        IColorHelper(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IColorHelperStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IColorHelperStatics>
    {
        IColorHelperStatics(std::nullptr_t = nullptr) noexcept {}
        IColorHelperStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IColorHelperStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IColorHelperStatics2>
    {
        IColorHelperStatics2(std::nullptr_t = nullptr) noexcept {}
        IColorHelperStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IColors :
        Windows::Foundation::IInspectable,
        impl::consume_t<IColors>
    {
        IColors(std::nullptr_t = nullptr) noexcept {}
        IColors(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IColorsStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IColorsStatics>
    {
        IColorsStatics(std::nullptr_t = nullptr) noexcept {}
        IColorsStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUIContentRoot :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUIContentRoot>
    {
        IUIContentRoot(std::nullptr_t = nullptr) noexcept {}
        IUIContentRoot(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUIContext :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUIContext>
    {
        IUIContext(std::nullptr_t = nullptr) noexcept {}
        IUIContext(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
