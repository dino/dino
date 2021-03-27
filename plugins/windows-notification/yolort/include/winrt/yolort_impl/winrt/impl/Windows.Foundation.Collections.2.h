// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Foundation_Collections_2_H
#define WINRT_Windows_Foundation_Collections_2_H
#include "Windows.Foundation.Collections.1.h"
namespace winrt::Windows::Foundation::Collections
{
    template <typename K, typename V>
    struct MapChangedEventHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<K>, "K must be WinRT type.");
        static_assert(impl::has_category_v<V>, "V must be WinRT type.");
        MapChangedEventHandler(std::nullptr_t = nullptr) noexcept {}
        MapChangedEventHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> MapChangedEventHandler(L lambda);
        template <typename F> MapChangedEventHandler(F* function);
        template <typename O, typename M> MapChangedEventHandler(O* object, M method);
        template <typename O, typename M> MapChangedEventHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> MapChangedEventHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::Collections::IObservableMap<K, V> const& sender, Windows::Foundation::Collections::IMapChangedEventArgs<K> const& event) const;
    };
    template <typename T>
    struct VectorChangedEventHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        VectorChangedEventHandler(std::nullptr_t = nullptr) noexcept {}
        VectorChangedEventHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> VectorChangedEventHandler(L lambda);
        template <typename F> VectorChangedEventHandler(F* function);
        template <typename O, typename M> VectorChangedEventHandler(O* object, M method);
        template <typename O, typename M> VectorChangedEventHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> VectorChangedEventHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::Collections::IObservableVector<T> const& sender, Windows::Foundation::Collections::IVectorChangedEventArgs const& event) const;
    };
    struct __declspec(empty_bases) PropertySet : Windows::Foundation::Collections::IPropertySet
    {
        PropertySet(std::nullptr_t) noexcept {}
        PropertySet(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::Collections::IPropertySet(ptr, take_ownership_from_abi) {}
        PropertySet();
    };
    struct __declspec(empty_bases) StringMap : Windows::Foundation::Collections::IMap<hstring, hstring>,
        impl::require<StringMap, Windows::Foundation::Collections::IObservableMap<hstring, hstring>>
    {
        StringMap(std::nullptr_t) noexcept {}
        StringMap(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::Collections::IMap<hstring, hstring>(ptr, take_ownership_from_abi) {}
        StringMap();
    };
    struct __declspec(empty_bases) ValueSet : Windows::Foundation::Collections::IPropertySet
    {
        ValueSet(std::nullptr_t) noexcept {}
        ValueSet(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::Collections::IPropertySet(ptr, take_ownership_from_abi) {}
        ValueSet();
    };
}
#endif
