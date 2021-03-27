// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Foundation_Collections_1_H
#define WINRT_Windows_Foundation_Collections_1_H
#include "Windows.Foundation.Collections.0.h"
namespace winrt::Windows::Foundation::Collections
{
    template <typename T>
    struct __declspec(empty_bases) IIterable :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IIterable<T>>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IIterable(std::nullptr_t = nullptr) noexcept {}
        IIterable(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename T>
    struct __declspec(empty_bases) IIterator :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IIterator<T>>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IIterator(std::nullptr_t = nullptr) noexcept {}
        IIterator(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}

        using iterator_category = std::input_iterator_tag;
        using value_type = T;
        using difference_type = ptrdiff_t;
        using pointer = T*;
        using reference = T&;
    };
    template <typename K, typename V>
    struct __declspec(empty_bases) IKeyValuePair :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IKeyValuePair<K, V>>
    {
        static_assert(impl::has_category_v<K>, "K must be WinRT type.");
        static_assert(impl::has_category_v<V>, "V must be WinRT type.");
        IKeyValuePair(std::nullptr_t = nullptr) noexcept {}
        IKeyValuePair(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename K>
    struct __declspec(empty_bases) IMapChangedEventArgs :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IMapChangedEventArgs<K>>
    {
        static_assert(impl::has_category_v<K>, "K must be WinRT type.");
        IMapChangedEventArgs(std::nullptr_t = nullptr) noexcept {}
        IMapChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename K, typename V>
    struct __declspec(empty_bases) IMapView :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IMapView<K, V>>,
        impl::require<Windows::Foundation::Collections::IMapView<K, V>, Windows::Foundation::Collections::IIterable<Windows::Foundation::Collections::IKeyValuePair<K, V>>>
    {
        static_assert(impl::has_category_v<K>, "K must be WinRT type.");
        static_assert(impl::has_category_v<V>, "V must be WinRT type.");
        IMapView(std::nullptr_t = nullptr) noexcept {}
        IMapView(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename K, typename V>
    struct __declspec(empty_bases) IMap :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IMap<K, V>>,
        impl::require<Windows::Foundation::Collections::IMap<K, V>, Windows::Foundation::Collections::IIterable<Windows::Foundation::Collections::IKeyValuePair<K, V>>>
    {
        static_assert(impl::has_category_v<K>, "K must be WinRT type.");
        static_assert(impl::has_category_v<V>, "V must be WinRT type.");
        IMap(std::nullptr_t = nullptr) noexcept {}
        IMap(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename K, typename V>
    struct __declspec(empty_bases) IObservableMap :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IObservableMap<K, V>>,
        impl::require<Windows::Foundation::Collections::IObservableMap<K, V>, Windows::Foundation::Collections::IIterable<Windows::Foundation::Collections::IKeyValuePair<K, V>>, Windows::Foundation::Collections::IMap<K, V>>
    {
        static_assert(impl::has_category_v<K>, "K must be WinRT type.");
        static_assert(impl::has_category_v<V>, "V must be WinRT type.");
        IObservableMap(std::nullptr_t = nullptr) noexcept {}
        IObservableMap(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename T>
    struct __declspec(empty_bases) IObservableVector :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IObservableVector<T>>,
        impl::require<Windows::Foundation::Collections::IObservableVector<T>, Windows::Foundation::Collections::IIterable<T>, Windows::Foundation::Collections::IVector<T>>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IObservableVector(std::nullptr_t = nullptr) noexcept {}
        IObservableVector(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IPropertySet :
        Windows::Foundation::IInspectable,
        impl::consume_t<IPropertySet>,
        impl::require<Windows::Foundation::Collections::IPropertySet, Windows::Foundation::Collections::IIterable<Windows::Foundation::Collections::IKeyValuePair<hstring, Windows::Foundation::IInspectable>>, Windows::Foundation::Collections::IMap<hstring, Windows::Foundation::IInspectable>, Windows::Foundation::Collections::IObservableMap<hstring, Windows::Foundation::IInspectable>>
    {
        IPropertySet(std::nullptr_t = nullptr) noexcept {}
        IPropertySet(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IVectorChangedEventArgs :
        Windows::Foundation::IInspectable,
        impl::consume_t<IVectorChangedEventArgs>
    {
        IVectorChangedEventArgs(std::nullptr_t = nullptr) noexcept {}
        IVectorChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename T>
    struct __declspec(empty_bases) IVectorView :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IVectorView<T>>,
        impl::require<Windows::Foundation::Collections::IVectorView<T>, Windows::Foundation::Collections::IIterable<T>>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IVectorView(std::nullptr_t = nullptr) noexcept {}
        IVectorView(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename T>
    struct __declspec(empty_bases) IVector :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::Collections::IVector<T>>,
        impl::require<Windows::Foundation::Collections::IVector<T>, Windows::Foundation::Collections::IIterable<T>>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IVector(std::nullptr_t = nullptr) noexcept {}
        IVector(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
