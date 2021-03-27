// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Foundation_Collections_0_H
#define WINRT_Windows_Foundation_Collections_0_H
namespace winrt::Windows::Foundation
{
    struct EventRegistrationToken;
}
namespace winrt::Windows::Foundation::Collections
{
    enum class CollectionChange : int32_t
    {
        Reset = 0,
        ItemInserted = 1,
        ItemRemoved = 2,
        ItemChanged = 3,
    };
    template <typename T> struct IIterable;
    template <typename T> struct IIterator;
    template <typename K, typename V> struct IKeyValuePair;
    template <typename K> struct IMapChangedEventArgs;
    template <typename K, typename V> struct IMapView;
    template <typename K, typename V> struct IMap;
    template <typename K, typename V> struct IObservableMap;
    template <typename T> struct IObservableVector;
    struct IPropertySet;
    struct IVectorChangedEventArgs;
    template <typename T> struct IVectorView;
    template <typename T> struct IVector;
    struct PropertySet;
    struct StringMap;
    struct ValueSet;
    template <typename K, typename V> struct MapChangedEventHandler;
    template <typename T> struct VectorChangedEventHandler;
}
namespace winrt::impl
{
    template <typename T> struct category<Windows::Foundation::Collections::IIterable<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0xFAA585EA,0x6214,0x4217,{ 0xAF,0xDA,0x7F,0x46,0xDE,0x58,0x69,0xB3 } };
    };
    template <typename T> struct category<Windows::Foundation::Collections::IIterator<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x6A79E863,0x4300,0x459A,{ 0x99,0x66,0xCB,0xB6,0x60,0x96,0x3E,0xE1 } };
    };
    template <typename K, typename V> struct category<Windows::Foundation::Collections::IKeyValuePair<K, V>>
    {
        using type = pinterface_category<K, V>;
        static constexpr guid value{ 0x02B51929,0xC1C4,0x4A7E,{ 0x89,0x40,0x03,0x12,0xB5,0xC1,0x85,0x00 } };
    };
    template <typename K> struct category<Windows::Foundation::Collections::IMapChangedEventArgs<K>>
    {
        using type = pinterface_category<K>;
        static constexpr guid value{ 0x9939F4DF,0x050A,0x4C0F,{ 0xAA,0x60,0x77,0x07,0x5F,0x9C,0x47,0x77 } };
    };
    template <typename K, typename V> struct category<Windows::Foundation::Collections::IMapView<K, V>>
    {
        using type = pinterface_category<K, V>;
        static constexpr guid value{ 0xE480CE40,0xA338,0x4ADA,{ 0xAD,0xCF,0x27,0x22,0x72,0xE4,0x8C,0xB9 } };
    };
    template <typename K, typename V> struct category<Windows::Foundation::Collections::IMap<K, V>>
    {
        using type = pinterface_category<K, V>;
        static constexpr guid value{ 0x3C2925FE,0x8519,0x45C1,{ 0xAA,0x79,0x19,0x7B,0x67,0x18,0xC1,0xC1 } };
    };
    template <typename K, typename V> struct category<Windows::Foundation::Collections::IObservableMap<K, V>>
    {
        using type = pinterface_category<K, V>;
        static constexpr guid value{ 0x65DF2BF5,0xBF39,0x41B5,{ 0xAE,0xBC,0x5A,0x9D,0x86,0x5E,0x47,0x2B } };
    };
    template <typename T> struct category<Windows::Foundation::Collections::IObservableVector<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x5917EB53,0x50B4,0x4A0D,{ 0xB3,0x09,0x65,0x86,0x2B,0x3F,0x1D,0xBC } };
    };
    template <> struct category<Windows::Foundation::Collections::IPropertySet>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::Collections::IVectorChangedEventArgs>
    {
        using type = interface_category;
    };
    template <typename T> struct category<Windows::Foundation::Collections::IVectorView<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0xBBE1FA4C,0xB0E3,0x4583,{ 0xBA,0xEF,0x1F,0x1B,0x2E,0x48,0x3E,0x56 } };
    };
    template <typename T> struct category<Windows::Foundation::Collections::IVector<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x913337E9,0x11A1,0x4345,{ 0xA3,0xA2,0x4E,0x7F,0x95,0x6E,0x22,0x2D } };
    };
    template <> struct category<Windows::Foundation::Collections::PropertySet>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::Collections::StringMap>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::Collections::ValueSet>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::Collections::CollectionChange>
    {
        using type = enum_category;
    };
    template <typename K, typename V> struct category<Windows::Foundation::Collections::MapChangedEventHandler<K, V>>
    {
        using type = pinterface_category<K, V>;
        static constexpr guid value{ 0x179517F3,0x94EE,0x41F8,{ 0xBD,0xDC,0x76,0x8A,0x89,0x55,0x44,0xF3 } };
    };
    template <typename T> struct category<Windows::Foundation::Collections::VectorChangedEventHandler<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x0C051752,0x9FBF,0x4C70,{ 0xAA,0x0C,0x0E,0x4C,0x82,0xD9,0xA7,0x61 } };
    };
    template <typename T> struct name<Windows::Foundation::Collections::IIterable<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IIterable`1<", name_v<T>, L">") };
    };
    template <typename T> struct name<Windows::Foundation::Collections::IIterator<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IIterator`1<", name_v<T>, L">") };
    };
    template <typename K, typename V> struct name<Windows::Foundation::Collections::IKeyValuePair<K, V>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IKeyValuePair`2<", name_v<K>, L", ", name_v<V>, L">") };
    };
    template <typename K> struct name<Windows::Foundation::Collections::IMapChangedEventArgs<K>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IMapChangedEventArgs`1<", name_v<K>, L">") };
    };
    template <typename K, typename V> struct name<Windows::Foundation::Collections::IMapView<K, V>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IMapView`2<", name_v<K>, L", ", name_v<V>, L">") };
    };
    template <typename K, typename V> struct name<Windows::Foundation::Collections::IMap<K, V>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IMap`2<", name_v<K>, L", ", name_v<V>, L">") };
    };
    template <typename K, typename V> struct name<Windows::Foundation::Collections::IObservableMap<K, V>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IObservableMap`2<", name_v<K>, L", ", name_v<V>, L">") };
    };
    template <typename T> struct name<Windows::Foundation::Collections::IObservableVector<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IObservableVector`1<", name_v<T>, L">") };
    };
    template <> struct name<Windows::Foundation::Collections::IPropertySet>
    {
        static constexpr auto & value{ L"Windows.Foundation.Collections.IPropertySet" };
    };
    template <> struct name<Windows::Foundation::Collections::IVectorChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.Foundation.Collections.IVectorChangedEventArgs" };
    };
    template <typename T> struct name<Windows::Foundation::Collections::IVectorView<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IVectorView`1<", name_v<T>, L">") };
    };
    template <typename T> struct name<Windows::Foundation::Collections::IVector<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.IVector`1<", name_v<T>, L">") };
    };
    template <> struct name<Windows::Foundation::Collections::PropertySet>
    {
        static constexpr auto & value{ L"Windows.Foundation.Collections.PropertySet" };
    };
    template <> struct name<Windows::Foundation::Collections::StringMap>
    {
        static constexpr auto & value{ L"Windows.Foundation.Collections.StringMap" };
    };
    template <> struct name<Windows::Foundation::Collections::ValueSet>
    {
        static constexpr auto & value{ L"Windows.Foundation.Collections.ValueSet" };
    };
    template <> struct name<Windows::Foundation::Collections::CollectionChange>
    {
        static constexpr auto & value{ L"Windows.Foundation.Collections.CollectionChange" };
    };
    template <typename K, typename V> struct name<Windows::Foundation::Collections::MapChangedEventHandler<K, V>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.MapChangedEventHandler`2<", name_v<K>, L", ", name_v<V>, L">") };
    };
    template <typename T> struct name<Windows::Foundation::Collections::VectorChangedEventHandler<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.Collections.VectorChangedEventHandler`1<", name_v<T>, L">") };
    };
    template <typename T> struct guid_storage<Windows::Foundation::Collections::IIterable<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IIterable<T>>::value };
    };
    template <typename T> struct guid_storage<Windows::Foundation::Collections::IIterator<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IIterator<T>>::value };
    };
    template <typename K, typename V> struct guid_storage<Windows::Foundation::Collections::IKeyValuePair<K, V>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IKeyValuePair<K, V>>::value };
    };
    template <typename K> struct guid_storage<Windows::Foundation::Collections::IMapChangedEventArgs<K>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IMapChangedEventArgs<K>>::value };
    };
    template <typename K, typename V> struct guid_storage<Windows::Foundation::Collections::IMapView<K, V>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IMapView<K, V>>::value };
    };
    template <typename K, typename V> struct guid_storage<Windows::Foundation::Collections::IMap<K, V>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IMap<K, V>>::value };
    };
    template <typename K, typename V> struct guid_storage<Windows::Foundation::Collections::IObservableMap<K, V>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IObservableMap<K, V>>::value };
    };
    template <typename T> struct guid_storage<Windows::Foundation::Collections::IObservableVector<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IObservableVector<T>>::value };
    };
    template <> struct guid_storage<Windows::Foundation::Collections::IPropertySet>
    {
        static constexpr guid value{ 0x8A43ED9F,0xF4E6,0x4421,{ 0xAC,0xF9,0x1D,0xAB,0x29,0x86,0x82,0x0C } };
    };
    template <> struct guid_storage<Windows::Foundation::Collections::IVectorChangedEventArgs>
    {
        static constexpr guid value{ 0x575933DF,0x34FE,0x4480,{ 0xAF,0x15,0x07,0x69,0x1F,0x3D,0x5D,0x9B } };
    };
    template <typename T> struct guid_storage<Windows::Foundation::Collections::IVectorView<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IVectorView<T>>::value };
    };
    template <typename T> struct guid_storage<Windows::Foundation::Collections::IVector<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::IVector<T>>::value };
    };
    template <typename K, typename V> struct guid_storage<Windows::Foundation::Collections::MapChangedEventHandler<K, V>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::MapChangedEventHandler<K, V>>::value };
    };
    template <typename T> struct guid_storage<Windows::Foundation::Collections::VectorChangedEventHandler<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::Collections::VectorChangedEventHandler<T>>::value };
    };
    template <> struct default_interface<Windows::Foundation::Collections::PropertySet>
    {
        using type = Windows::Foundation::Collections::IPropertySet;
    };
    template <> struct default_interface<Windows::Foundation::Collections::StringMap>
    {
        using type = Windows::Foundation::Collections::IMap<hstring, hstring>;
    };
    template <> struct default_interface<Windows::Foundation::Collections::ValueSet>
    {
        using type = Windows::Foundation::Collections::IPropertySet;
    };
    template <typename T> struct abi<Windows::Foundation::Collections::IIterable<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall First(void**) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::Collections::IIterator<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Current(arg_out<T>) noexcept = 0;
            virtual int32_t __stdcall get_HasCurrent(bool*) noexcept = 0;
            virtual int32_t __stdcall MoveNext(bool*) noexcept = 0;
            virtual int32_t __stdcall GetMany(uint32_t, arg_out<T>, uint32_t*) noexcept = 0;
        };
    };
    template <typename K, typename V> struct abi<Windows::Foundation::Collections::IKeyValuePair<K, V>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Key(arg_out<K>) noexcept = 0;
            virtual int32_t __stdcall get_Value(arg_out<V>) noexcept = 0;
        };
    };
    template <typename K> struct abi<Windows::Foundation::Collections::IMapChangedEventArgs<K>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CollectionChange(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Key(arg_out<K>) noexcept = 0;
        };
    };
    template <typename K, typename V> struct abi<Windows::Foundation::Collections::IMapView<K, V>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Lookup(arg_in<K>, arg_out<V>) noexcept = 0;
            virtual int32_t __stdcall get_Size(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall HasKey(arg_in<K>, bool*) noexcept = 0;
            virtual int32_t __stdcall Split(void**, void**) noexcept = 0;
        };
    };
    template <typename K, typename V> struct abi<Windows::Foundation::Collections::IMap<K, V>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Lookup(arg_in<K>, arg_out<V>) noexcept = 0;
            virtual int32_t __stdcall get_Size(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall HasKey(arg_in<K>, bool*) noexcept = 0;
            virtual int32_t __stdcall GetView(void**) noexcept = 0;
            virtual int32_t __stdcall Insert(arg_in<K>, arg_in<V>, bool*) noexcept = 0;
            virtual int32_t __stdcall Remove(arg_in<K>) noexcept = 0;
            virtual int32_t __stdcall Clear() noexcept = 0;
        };
    };
    template <typename K, typename V> struct abi<Windows::Foundation::Collections::IObservableMap<K, V>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_MapChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_MapChanged(winrt::event_token) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::Collections::IObservableVector<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_VectorChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_VectorChanged(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::Collections::IPropertySet>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::Foundation::Collections::IVectorChangedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CollectionChange(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Index(uint32_t*) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::Collections::IVectorView<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetAt(uint32_t, arg_out<T>) noexcept = 0;
            virtual int32_t __stdcall get_Size(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall IndexOf(arg_in<T>, uint32_t*, bool*) noexcept = 0;
            virtual int32_t __stdcall GetMany(uint32_t, uint32_t, arg_out<T>, uint32_t*) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::Collections::IVector<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetAt(uint32_t, arg_out<T>) noexcept = 0;
            virtual int32_t __stdcall get_Size(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall GetView(void**) noexcept = 0;
            virtual int32_t __stdcall IndexOf(arg_in<T>, uint32_t*, bool*) noexcept = 0;
            virtual int32_t __stdcall SetAt(uint32_t, arg_in<T>) noexcept = 0;
            virtual int32_t __stdcall InsertAt(uint32_t, arg_in<T>) noexcept = 0;
            virtual int32_t __stdcall RemoveAt(uint32_t) noexcept = 0;
            virtual int32_t __stdcall Append(arg_in<T>) noexcept = 0;
            virtual int32_t __stdcall RemoveAtEnd() noexcept = 0;
            virtual int32_t __stdcall Clear() noexcept = 0;
            virtual int32_t __stdcall GetMany(uint32_t, uint32_t, arg_out<T>, uint32_t*) noexcept = 0;
            virtual int32_t __stdcall ReplaceAll(uint32_t, arg_out<T>) noexcept = 0;
        };
    };
    template <typename K, typename V> struct abi<Windows::Foundation::Collections::MapChangedEventHandler<K, V>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, void*) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::Collections::VectorChangedEventHandler<T>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, void*) noexcept = 0;
        };
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_Collections_IIterable
    {
        auto First() const;
    };
    template <typename T> struct consume<Windows::Foundation::Collections::IIterable<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IIterable<D, T>;
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_Collections_IIterator
    {
        [[nodiscard]] auto Current() const;
        [[nodiscard]] auto HasCurrent() const;
        auto MoveNext() const;
        auto GetMany(array_view<T> items) const;

        auto& operator++()
        {
            if (!MoveNext())
            {
                static_cast<D&>(*this) = nullptr;
            }

            return *this;
        }

        T operator*() const
        {
            return Current();
        }
    };
    template <typename T> struct consume<Windows::Foundation::Collections::IIterator<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IIterator<D, T>;
    };
    template <typename D, typename K, typename V>
    struct consume_Windows_Foundation_Collections_IKeyValuePair
    {
        [[nodiscard]] auto Key() const;
        [[nodiscard]] auto Value() const;

        bool operator==(Windows::Foundation::Collections::IKeyValuePair<K, V> const& other) const
        {
            return Key() == other.Key() && Value() == other.Value();
        }

        bool operator!=(Windows::Foundation::Collections::IKeyValuePair<K, V> const& other) const
        {
            return !(*this == other);
        }
    };
    template <typename K, typename V> struct consume<Windows::Foundation::Collections::IKeyValuePair<K, V>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IKeyValuePair<D, K, V>;
    };
    template <typename D, typename K>
    struct consume_Windows_Foundation_Collections_IMapChangedEventArgs
    {
        [[nodiscard]] auto CollectionChange() const;
        [[nodiscard]] auto Key() const;
    };
    template <typename K> struct consume<Windows::Foundation::Collections::IMapChangedEventArgs<K>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IMapChangedEventArgs<D, K>;
    };
    template <typename D, typename K, typename V>
    struct consume_Windows_Foundation_Collections_IMapView
    {
        auto Lookup(impl::param_type<K> const& key) const;
        [[nodiscard]] auto Size() const;
        auto HasKey(impl::param_type<K> const& key) const;
        auto Split(Windows::Foundation::Collections::IMapView<K, V>& first, Windows::Foundation::Collections::IMapView<K, V>& second) const;

        auto TryLookup(param_type<K> const& key) const noexcept
        {
            if constexpr (std::is_base_of_v<Windows::Foundation::IUnknown, V>)
            {
                V result{ nullptr };
                WINRT_IMPL_SHIM(Windows::Foundation::Collections::IMapView<K, V>)->Lookup(get_abi(key), put_abi(result));
                return result;
            }
            else
            {
                std::optional<V> result;
                V value{ empty_value<V>() };

                if (error_ok == WINRT_IMPL_SHIM(Windows::Foundation::Collections::IMapView<K, V>)->Lookup(get_abi(key), put_abi(value)))
                {
                    result = std::move(value);
                }

                return result;
            }
        }
    };
    template <typename K, typename V> struct consume<Windows::Foundation::Collections::IMapView<K, V>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IMapView<D, K, V>;
    };
    template <typename D, typename K, typename V>
    struct consume_Windows_Foundation_Collections_IMap
    {
        auto Lookup(impl::param_type<K> const& key) const;
        [[nodiscard]] auto Size() const;
        auto HasKey(impl::param_type<K> const& key) const;
        auto GetView() const;
        auto Insert(impl::param_type<K> const& key, impl::param_type<V> const& value) const;
        auto Remove(impl::param_type<K> const& key) const;
        auto Clear() const;

        auto TryLookup(param_type<K> const& key) const noexcept
        {
            if constexpr (std::is_base_of_v<Windows::Foundation::IUnknown, V>)
            {
                V result{ nullptr };
                WINRT_IMPL_SHIM(Windows::Foundation::Collections::IMap<K, V>)->Lookup(get_abi(key), put_abi(result));
                return result;
            }
            else
            {
                std::optional<V> result;
                V value{ empty_value<V>() };

                if (error_ok == WINRT_IMPL_SHIM(Windows::Foundation::Collections::IMap<K, V>)->Lookup(get_abi(key), put_abi(value)))
                {
                    result = std::move(value);
                }

                return result;
            }
        }
    };
    template <typename K, typename V> struct consume<Windows::Foundation::Collections::IMap<K, V>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IMap<D, K, V>;
    };
    template <typename D, typename K, typename V>
    struct consume_Windows_Foundation_Collections_IObservableMap
    {
        auto MapChanged(Windows::Foundation::Collections::MapChangedEventHandler<K, V> const& vhnd) const;
        using MapChanged_revoker = impl::event_revoker<Windows::Foundation::Collections::IObservableMap<K, V>, &impl::abi_t<Windows::Foundation::Collections::IObservableMap<K, V>>::remove_MapChanged>;
        MapChanged_revoker MapChanged(auto_revoke_t, Windows::Foundation::Collections::MapChangedEventHandler<K, V> const& vhnd) const;
        auto MapChanged(winrt::event_token const& token) const noexcept;
    };
    template <typename K, typename V> struct consume<Windows::Foundation::Collections::IObservableMap<K, V>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IObservableMap<D, K, V>;
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_Collections_IObservableVector
    {
        auto VectorChanged(Windows::Foundation::Collections::VectorChangedEventHandler<T> const& vhnd) const;
        using VectorChanged_revoker = impl::event_revoker<Windows::Foundation::Collections::IObservableVector<T>, &impl::abi_t<Windows::Foundation::Collections::IObservableVector<T>>::remove_VectorChanged>;
        VectorChanged_revoker VectorChanged(auto_revoke_t, Windows::Foundation::Collections::VectorChangedEventHandler<T> const& vhnd) const;
        auto VectorChanged(winrt::event_token const& token) const noexcept;
    };
    template <typename T> struct consume<Windows::Foundation::Collections::IObservableVector<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IObservableVector<D, T>;
    };
    template <typename D>
    struct consume_Windows_Foundation_Collections_IPropertySet
    {
    };
    template <> struct consume<Windows::Foundation::Collections::IPropertySet>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IPropertySet<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_Collections_IVectorChangedEventArgs
    {
        [[nodiscard]] auto CollectionChange() const;
        [[nodiscard]] auto Index() const;
    };
    template <> struct consume<Windows::Foundation::Collections::IVectorChangedEventArgs>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IVectorChangedEventArgs<D>;
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_Collections_IVectorView
    {
        auto GetAt(uint32_t index) const;
        [[nodiscard]] auto Size() const;
        auto IndexOf(impl::param_type<T> const& value, uint32_t& index) const;
        auto GetMany(uint32_t startIndex, array_view<T> items) const;
    };
    template <typename T> struct consume<Windows::Foundation::Collections::IVectorView<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IVectorView<D, T>;
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_Collections_IVector
    {
        auto GetAt(uint32_t index) const;
        [[nodiscard]] auto Size() const;
        auto GetView() const;
        auto IndexOf(impl::param_type<T> const& value, uint32_t& index) const;
        auto SetAt(uint32_t index, impl::param_type<T> const& value) const;
        auto InsertAt(uint32_t index, impl::param_type<T> const& value) const;
        auto RemoveAt(uint32_t index) const;
        auto Append(impl::param_type<T> const& value) const;
        auto RemoveAtEnd() const;
        auto Clear() const;
        auto GetMany(uint32_t startIndex, array_view<T> items) const;
        auto ReplaceAll(array_view<T const> items) const;
    };
    template <typename T> struct consume<Windows::Foundation::Collections::IVector<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_Collections_IVector<D, T>;
    };
}
#endif
