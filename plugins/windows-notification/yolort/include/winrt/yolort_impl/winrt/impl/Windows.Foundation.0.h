// C++/WinRT v2.0.190620.2
// Patched with YoloRT

// Copyright (c) Microsoft Corporation. All rights reserved.
// Copyright © 2021, mjk <yuubi-san@users.noreply.github.com>
// Licensed under the MIT License.

#ifndef WINRT_Windows_Foundation_0_H
#define WINRT_Windows_Foundation_0_H
namespace winrt::Windows::Foundation
{
    enum class AsyncStatus : int32_t
    {
        Canceled = 2,
        Completed = 1,
        Error = 3,
        Started = 0,
    };
    enum class PropertyType : int32_t
    {
        Empty = 0,
        UInt8 = 1,
        Int16 = 2,
        UInt16 = 3,
        Int32 = 4,
        UInt32 = 5,
        Int64 = 6,
        UInt64 = 7,
        Single = 8,
        Double = 9,
        Char16 = 10,
        Boolean = 11,
        String = 12,
        Inspectable = 13,
        DateTime = 14,
        TimeSpan = 15,
        Guid = 16,
        Point = 17,
        Size = 18,
        Rect = 19,
        OtherType = 20,
        UInt8Array = 1025,
        Int16Array = 1026,
        UInt16Array = 1027,
        Int32Array = 1028,
        UInt32Array = 1029,
        Int64Array = 1030,
        UInt64Array = 1031,
        SingleArray = 1032,
        DoubleArray = 1033,
        Char16Array = 1034,
        BooleanArray = 1035,
        StringArray = 1036,
        InspectableArray = 1037,
        DateTimeArray = 1038,
        TimeSpanArray = 1039,
        GuidArray = 1040,
        PointArray = 1041,
        SizeArray = 1042,
        RectArray = 1043,
        OtherTypeArray = 1044,
    };
    struct IAsyncAction;
    template <typename TProgress> struct IAsyncActionWithProgress;
    struct IAsyncInfo;
    template <typename TResult, typename TProgress> struct IAsyncOperationWithProgress;
    template <typename TResult> struct IAsyncOperation;
    struct IClosable;
    struct IDeferral;
    struct IDeferralFactory;
    struct IGetActivationFactory;
    struct IGuidHelperStatics;
    struct IMemoryBuffer;
    struct IMemoryBufferFactory;
    struct IMemoryBufferReference;
    struct IPropertyValue;
    struct IPropertyValueStatics;
    template <typename T> struct IReferenceArray;
    template <typename T> struct IReference;
    struct IStringable;
    struct IUriEscapeStatics;
    struct IUriRuntimeClass;
    struct IUriRuntimeClassFactory;
    struct IUriRuntimeClassWithAbsoluteCanonicalUri;
    struct IWwwFormUrlDecoderEntry;
    struct IWwwFormUrlDecoderRuntimeClass;
    struct IWwwFormUrlDecoderRuntimeClassFactory;
    struct Deferral;
    struct GuidHelper;
    struct MemoryBuffer;
    struct PropertyValue;
    struct Uri;
    struct WwwFormUrlDecoder;
    struct WwwFormUrlDecoderEntry;
    struct AsyncActionCompletedHandler;
    template <typename TProgress> struct AsyncActionProgressHandler;
    template <typename TProgress> struct AsyncActionWithProgressCompletedHandler;
    template <typename TResult> struct AsyncOperationCompletedHandler;
    template <typename TResult, typename TProgress> struct AsyncOperationProgressHandler;
    template <typename TResult, typename TProgress> struct AsyncOperationWithProgressCompletedHandler;
    struct DeferralCompletedHandler;
    template <typename T> struct EventHandler;
    template <typename TSender, typename TResult> struct TypedEventHandler;
}
namespace winrt::impl
{
    template <typename Async>
    auto wait_for(Async const& async, Windows::Foundation::TimeSpan const& timeout);
    template <typename Async>
    auto wait_get(Async const& async);
    template <> struct category<Windows::Foundation::IAsyncAction>
    {
        using type = interface_category;
    };
    template <typename TProgress> struct category<Windows::Foundation::IAsyncActionWithProgress<TProgress>>
    {
        using type = pinterface_category<TProgress>;
        static constexpr guid value{ 0x1F6DB258,0xE803,0x48A1,{ 0x95,0x46,0xEB,0x73,0x53,0x39,0x88,0x84 } };
    };
    template <> struct category<Windows::Foundation::IAsyncInfo>
    {
        using type = interface_category;
    };
    template <typename TResult, typename TProgress> struct category<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>
    {
        using type = pinterface_category<TResult, TProgress>;
        static constexpr guid value{ 0xB5D036D7,0xE297,0x498F,{ 0xBA,0x60,0x02,0x89,0xE7,0x6E,0x23,0xDD } };
    };
    template <typename TResult> struct category<Windows::Foundation::IAsyncOperation<TResult>>
    {
        using type = pinterface_category<TResult>;
        static constexpr guid value{ 0x9FC2B0BB,0xE446,0x44E2,{ 0xAA,0x61,0x9C,0xAB,0x8F,0x63,0x6A,0xF2 } };
    };
    template <> struct category<Windows::Foundation::IClosable>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IDeferral>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IDeferralFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IGetActivationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IGuidHelperStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IMemoryBuffer>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IMemoryBufferFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IMemoryBufferReference>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IPropertyValue>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IPropertyValueStatics>
    {
        using type = interface_category;
    };
    template <typename T> struct category<Windows::Foundation::IReferenceArray<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x61C17707,0x2D65,0x11E0,{ 0x9A,0xE8,0xD4,0x85,0x64,0x01,0x54,0x72 } };
    };
    template <typename T> struct category<Windows::Foundation::IReference<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x61C17706,0x2D65,0x11E0,{ 0x9A,0xE8,0xD4,0x85,0x64,0x01,0x54,0x72 } };
    };
    template <> struct category<Windows::Foundation::IStringable>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IUriEscapeStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IUriRuntimeClass>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IUriRuntimeClassFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IUriRuntimeClassWithAbsoluteCanonicalUri>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IWwwFormUrlDecoderEntry>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IWwwFormUrlDecoderRuntimeClass>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::IWwwFormUrlDecoderRuntimeClassFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Foundation::Deferral>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::GuidHelper>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::MemoryBuffer>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::PropertyValue>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::Uri>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::WwwFormUrlDecoder>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::WwwFormUrlDecoderEntry>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Foundation::AsyncStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Foundation::PropertyType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Foundation::AsyncActionCompletedHandler>
    {
        using type = delegate_category;
    };
    template <typename TProgress> struct category<Windows::Foundation::AsyncActionProgressHandler<TProgress>>
    {
        using type = pinterface_category<TProgress>;
        static constexpr guid value{ 0x6D844858,0x0CFF,0x4590,{ 0xAE,0x89,0x95,0xA5,0xA5,0xC8,0xB4,0xB8 } };
    };
    template <typename TProgress> struct category<Windows::Foundation::AsyncActionWithProgressCompletedHandler<TProgress>>
    {
        using type = pinterface_category<TProgress>;
        static constexpr guid value{ 0x9C029F91,0xCC84,0x44FD,{ 0xAC,0x26,0x0A,0x6C,0x4E,0x55,0x52,0x81 } };
    };
    template <typename TResult> struct category<Windows::Foundation::AsyncOperationCompletedHandler<TResult>>
    {
        using type = pinterface_category<TResult>;
        static constexpr guid value{ 0xFCDCF02C,0xE5D8,0x4478,{ 0x91,0x5A,0x4D,0x90,0xB7,0x4B,0x83,0xA5 } };
    };
    template <typename TResult, typename TProgress> struct category<Windows::Foundation::AsyncOperationProgressHandler<TResult, TProgress>>
    {
        using type = pinterface_category<TResult, TProgress>;
        static constexpr guid value{ 0x55690902,0x0AAB,0x421A,{ 0x87,0x78,0xF8,0xCE,0x50,0x26,0xD7,0x58 } };
    };
    template <typename TResult, typename TProgress> struct category<Windows::Foundation::AsyncOperationWithProgressCompletedHandler<TResult, TProgress>>
    {
        using type = pinterface_category<TResult, TProgress>;
        static constexpr guid value{ 0xE85DF41D,0x6AA7,0x46E3,{ 0xA8,0xE2,0xF0,0x09,0xD8,0x40,0xC6,0x27 } };
    };
    template <> struct category<Windows::Foundation::DeferralCompletedHandler>
    {
        using type = delegate_category;
    };
    template <typename T> struct category<Windows::Foundation::EventHandler<T>>
    {
        using type = pinterface_category<T>;
        static constexpr guid value{ 0x9DE1C535,0x6AE1,0x11E0,{ 0x84,0xE1,0x18,0xA9,0x05,0xBC,0xC5,0x3F } };
    };
    template <typename TSender, typename TResult> struct category<Windows::Foundation::TypedEventHandler<TSender, TResult>>
    {
        using type = pinterface_category<TSender, TResult>;
        static constexpr guid value{ 0x9DE1C534,0x6AE1,0x11E0,{ 0x84,0xE1,0x18,0xA9,0x05,0xBC,0xC5,0x3F } };
    };
    template <> struct name<Windows::Foundation::IAsyncAction>
    {
        static constexpr auto & value{ L"Windows.Foundation.IAsyncAction" };
    };
    template <typename TProgress> struct name<Windows::Foundation::IAsyncActionWithProgress<TProgress>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.IAsyncActionWithProgress`1<", name_v<TProgress>, L">") };
    };
    template <> struct name<Windows::Foundation::IAsyncInfo>
    {
        static constexpr auto & value{ L"Windows.Foundation.IAsyncInfo" };
    };
    template <typename TResult, typename TProgress> struct name<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.IAsyncOperationWithProgress`2<", name_v<TResult>, L", ", name_v<TProgress>, L">") };
    };
    template <typename TResult> struct name<Windows::Foundation::IAsyncOperation<TResult>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.IAsyncOperation`1<", name_v<TResult>, L">") };
    };
    template <> struct name<Windows::Foundation::IClosable>
    {
        static constexpr auto & value{ L"Windows.Foundation.IClosable" };
    };
    template <> struct name<Windows::Foundation::IDeferral>
    {
        static constexpr auto & value{ L"Windows.Foundation.IDeferral" };
    };
    template <> struct name<Windows::Foundation::IDeferralFactory>
    {
        static constexpr auto & value{ L"Windows.Foundation.IDeferralFactory" };
    };
    template <> struct name<Windows::Foundation::IGetActivationFactory>
    {
        static constexpr auto & value{ L"Windows.Foundation.IGetActivationFactory" };
    };
    template <> struct name<Windows::Foundation::IGuidHelperStatics>
    {
        static constexpr auto & value{ L"Windows.Foundation.IGuidHelperStatics" };
    };
    template <> struct name<Windows::Foundation::IMemoryBuffer>
    {
        static constexpr auto & value{ L"Windows.Foundation.IMemoryBuffer" };
    };
    template <> struct name<Windows::Foundation::IMemoryBufferFactory>
    {
        static constexpr auto & value{ L"Windows.Foundation.IMemoryBufferFactory" };
    };
    template <> struct name<Windows::Foundation::IMemoryBufferReference>
    {
        static constexpr auto & value{ L"Windows.Foundation.IMemoryBufferReference" };
    };
    template <> struct name<Windows::Foundation::IPropertyValue>
    {
        static constexpr auto & value{ L"Windows.Foundation.IPropertyValue" };
    };
    template <> struct name<Windows::Foundation::IPropertyValueStatics>
    {
        static constexpr auto & value{ L"Windows.Foundation.IPropertyValueStatics" };
    };
    template <typename T> struct name<Windows::Foundation::IReferenceArray<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.IReferenceArray`1<", name_v<T>, L">") };
    };
    template <typename T> struct name<Windows::Foundation::IReference<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.IReference`1<", name_v<T>, L">") };
    };
    template <> struct name<Windows::Foundation::IStringable>
    {
        static constexpr auto & value{ L"Windows.Foundation.IStringable" };
    };
    template <> struct name<Windows::Foundation::IUriEscapeStatics>
    {
        static constexpr auto & value{ L"Windows.Foundation.IUriEscapeStatics" };
    };
    template <> struct name<Windows::Foundation::IUriRuntimeClass>
    {
        static constexpr auto & value{ L"Windows.Foundation.IUriRuntimeClass" };
    };
    template <> struct name<Windows::Foundation::IUriRuntimeClassFactory>
    {
        static constexpr auto & value{ L"Windows.Foundation.IUriRuntimeClassFactory" };
    };
    template <> struct name<Windows::Foundation::IUriRuntimeClassWithAbsoluteCanonicalUri>
    {
        static constexpr auto & value{ L"Windows.Foundation.IUriRuntimeClassWithAbsoluteCanonicalUri" };
    };
    template <> struct name<Windows::Foundation::IWwwFormUrlDecoderEntry>
    {
        static constexpr auto & value{ L"Windows.Foundation.IWwwFormUrlDecoderEntry" };
    };
    template <> struct name<Windows::Foundation::IWwwFormUrlDecoderRuntimeClass>
    {
        static constexpr auto & value{ L"Windows.Foundation.IWwwFormUrlDecoderRuntimeClass" };
    };
    template <> struct name<Windows::Foundation::IWwwFormUrlDecoderRuntimeClassFactory>
    {
        static constexpr auto & value{ L"Windows.Foundation.IWwwFormUrlDecoderRuntimeClassFactory" };
    };
    template <> struct name<Windows::Foundation::Deferral>
    {
        static constexpr auto & value{ L"Windows.Foundation.Deferral" };
    };
    template <> struct name<Windows::Foundation::GuidHelper>
    {
        static constexpr auto & value{ L"Windows.Foundation.GuidHelper" };
    };
    template <> struct name<Windows::Foundation::MemoryBuffer>
    {
        static constexpr auto & value{ L"Windows.Foundation.MemoryBuffer" };
    };
    template <> struct name<Windows::Foundation::PropertyValue>
    {
        static constexpr auto & value{ L"Windows.Foundation.PropertyValue" };
    };
    template <> struct name<Windows::Foundation::Uri>
    {
        static constexpr auto & value{ L"Windows.Foundation.Uri" };
    };
    template <> struct name<Windows::Foundation::WwwFormUrlDecoder>
    {
        static constexpr auto & value{ L"Windows.Foundation.WwwFormUrlDecoder" };
    };
    template <> struct name<Windows::Foundation::WwwFormUrlDecoderEntry>
    {
        static constexpr auto & value{ L"Windows.Foundation.WwwFormUrlDecoderEntry" };
    };
    template <> struct name<Windows::Foundation::AsyncStatus>
    {
        static constexpr auto & value{ L"Windows.Foundation.AsyncStatus" };
    };
    template <> struct name<Windows::Foundation::PropertyType>
    {
        static constexpr auto & value{ L"Windows.Foundation.PropertyType" };
    };
    template <> struct name<Windows::Foundation::AsyncActionCompletedHandler>
    {
        static constexpr auto & value{ L"Windows.Foundation.AsyncActionCompletedHandler" };
    };
    template <typename TProgress> struct name<Windows::Foundation::AsyncActionProgressHandler<TProgress>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.AsyncActionProgressHandler`1<", name_v<TProgress>, L">") };
    };
    template <typename TProgress> struct name<Windows::Foundation::AsyncActionWithProgressCompletedHandler<TProgress>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.AsyncActionWithProgressCompletedHandler`1<", name_v<TProgress>, L">") };
    };
    template <typename TResult> struct name<Windows::Foundation::AsyncOperationCompletedHandler<TResult>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.AsyncOperationCompletedHandler`1<", name_v<TResult>, L">") };
    };
    template <typename TResult, typename TProgress> struct name<Windows::Foundation::AsyncOperationProgressHandler<TResult, TProgress>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.AsyncOperationProgressHandler`2<", name_v<TResult>, L", ", name_v<TProgress>, L">") };
    };
    template <typename TResult, typename TProgress> struct name<Windows::Foundation::AsyncOperationWithProgressCompletedHandler<TResult, TProgress>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.AsyncOperationWithProgressCompletedHandler`2<", name_v<TResult>, L", ", name_v<TProgress>, L">") };
    };
    template <> struct name<Windows::Foundation::DeferralCompletedHandler>
    {
        static constexpr auto & value{ L"Windows.Foundation.DeferralCompletedHandler" };
    };
    template <typename T> struct name<Windows::Foundation::EventHandler<T>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.EventHandler`1<", name_v<T>, L">") };
    };
    template <typename TSender, typename TResult> struct name<Windows::Foundation::TypedEventHandler<TSender, TResult>>
    {
        static constexpr auto value{ zcombine(L"Windows.Foundation.TypedEventHandler`2<", name_v<TSender>, L", ", name_v<TResult>, L">") };
    };
    template <> struct guid_storage<Windows::Foundation::IAsyncAction>
    {
        static constexpr guid value{ 0x5A648006,0x843A,0x4DA9,{ 0x86,0x5B,0x9D,0x26,0xE5,0xDF,0xAD,0x7B } };
    };
    template <typename TProgress> struct guid_storage<Windows::Foundation::IAsyncActionWithProgress<TProgress>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::IAsyncActionWithProgress<TProgress>>::value };
    };
    template <> struct guid_storage<Windows::Foundation::IAsyncInfo>
    {
        static constexpr guid value{ 0x00000036,0x0000,0x0000,{ 0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 } };
    };
    template <typename TResult, typename TProgress> struct guid_storage<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>::value };
    };
    template <typename TResult> struct guid_storage<Windows::Foundation::IAsyncOperation<TResult>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::IAsyncOperation<TResult>>::value };
    };
    template <> struct guid_storage<Windows::Foundation::IClosable>
    {
        static constexpr guid value{ 0x30D5A829,0x7FA4,0x4026,{ 0x83,0xBB,0xD7,0x5B,0xAE,0x4E,0xA9,0x9E } };
    };
    template <> struct guid_storage<Windows::Foundation::IDeferral>
    {
        static constexpr guid value{ 0xD6269732,0x3B7F,0x46A7,{ 0xB4,0x0B,0x4F,0xDC,0xA2,0xA2,0xC6,0x93 } };
    };
    template <> struct guid_storage<Windows::Foundation::IDeferralFactory>
    {
        static constexpr guid value{ 0x65A1ECC5,0x3FB5,0x4832,{ 0x8C,0xA9,0xF0,0x61,0xB2,0x81,0xD1,0x3A } };
    };
    template <> struct guid_storage<Windows::Foundation::IGetActivationFactory>
    {
        static constexpr guid value{ 0x4EDB8EE2,0x96DD,0x49A7,{ 0x94,0xF7,0x46,0x07,0xDD,0xAB,0x8E,0x3C } };
    };
    template <> struct guid_storage<Windows::Foundation::IGuidHelperStatics>
    {
        static constexpr guid value{ 0x59C7966B,0xAE52,0x5283,{ 0xAD,0x7F,0xA1,0xB9,0xE9,0x67,0x8A,0xDD } };
    };
    template <> struct guid_storage<Windows::Foundation::IMemoryBuffer>
    {
        static constexpr guid value{ 0xFBC4DD2A,0x245B,0x11E4,{ 0xAF,0x98,0x68,0x94,0x23,0x26,0x0C,0xF8 } };
    };
    template <> struct guid_storage<Windows::Foundation::IMemoryBufferFactory>
    {
        static constexpr guid value{ 0xFBC4DD2B,0x245B,0x11E4,{ 0xAF,0x98,0x68,0x94,0x23,0x26,0x0C,0xF8 } };
    };
    template <> struct guid_storage<Windows::Foundation::IMemoryBufferReference>
    {
        static constexpr guid value{ 0xFBC4DD29,0x245B,0x11E4,{ 0xAF,0x98,0x68,0x94,0x23,0x26,0x0C,0xF8 } };
    };
    template <> struct guid_storage<Windows::Foundation::IPropertyValue>
    {
        static constexpr guid value{ 0x4BD682DD,0x7554,0x40E9,{ 0x9A,0x9B,0x82,0x65,0x4E,0xDE,0x7E,0x62 } };
    };
    template <> struct guid_storage<Windows::Foundation::IPropertyValueStatics>
    {
        static constexpr guid value{ 0x629BDBC8,0xD932,0x4FF4,{ 0x96,0xB9,0x8D,0x96,0xC5,0xC1,0xE8,0x58 } };
    };
    template <typename T> struct guid_storage<Windows::Foundation::IReferenceArray<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::IReferenceArray<T>>::value };
    };
    template <typename T> struct guid_storage<Windows::Foundation::IReference<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::IReference<T>>::value };
    };
    template <> struct guid_storage<Windows::Foundation::IStringable>
    {
        static constexpr guid value{ 0x96369F54,0x8EB6,0x48F0,{ 0xAB,0xCE,0xC1,0xB2,0x11,0xE6,0x27,0xC3 } };
    };
    template <> struct guid_storage<Windows::Foundation::IUriEscapeStatics>
    {
        static constexpr guid value{ 0xC1D432BA,0xC824,0x4452,{ 0xA7,0xFD,0x51,0x2B,0xC3,0xBB,0xE9,0xA1 } };
    };
    template <> struct guid_storage<Windows::Foundation::IUriRuntimeClass>
    {
        static constexpr guid value{ 0x9E365E57,0x48B2,0x4160,{ 0x95,0x6F,0xC7,0x38,0x51,0x20,0xBB,0xFC } };
    };
    template <> struct guid_storage<Windows::Foundation::IUriRuntimeClassFactory>
    {
        static constexpr guid value{ 0x44A9796F,0x723E,0x4FDF,{ 0xA2,0x18,0x03,0x3E,0x75,0xB0,0xC0,0x84 } };
    };
    template <> struct guid_storage<Windows::Foundation::IUriRuntimeClassWithAbsoluteCanonicalUri>
    {
        static constexpr guid value{ 0x758D9661,0x221C,0x480F,{ 0xA3,0x39,0x50,0x65,0x66,0x73,0xF4,0x6F } };
    };
    template <> struct guid_storage<Windows::Foundation::IWwwFormUrlDecoderEntry>
    {
        static constexpr guid value{ 0x125E7431,0xF678,0x4E8E,{ 0xB6,0x70,0x20,0xA9,0xB0,0x6C,0x51,0x2D } };
    };
    template <> struct guid_storage<Windows::Foundation::IWwwFormUrlDecoderRuntimeClass>
    {
        static constexpr guid value{ 0xD45A0451,0xF225,0x4542,{ 0x92,0x96,0x0E,0x1D,0xF5,0xD2,0x54,0xDF } };
    };
    template <> struct guid_storage<Windows::Foundation::IWwwFormUrlDecoderRuntimeClassFactory>
    {
        static constexpr guid value{ 0x5B8C6B3D,0x24AE,0x41B5,{ 0xA1,0xBF,0xF0,0xC3,0xD5,0x44,0x84,0x5B } };
    };
    template <> struct guid_storage<Windows::Foundation::AsyncActionCompletedHandler>
    {
        static constexpr guid value{ 0xA4ED5C81,0x76C9,0x40BD,{ 0x8B,0xE6,0xB1,0xD9,0x0F,0xB2,0x0A,0xE7 } };
    };
    template <typename TProgress> struct guid_storage<Windows::Foundation::AsyncActionProgressHandler<TProgress>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::AsyncActionProgressHandler<TProgress>>::value };
    };
    template <typename TProgress> struct guid_storage<Windows::Foundation::AsyncActionWithProgressCompletedHandler<TProgress>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::AsyncActionWithProgressCompletedHandler<TProgress>>::value };
    };
    template <typename TResult> struct guid_storage<Windows::Foundation::AsyncOperationCompletedHandler<TResult>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::AsyncOperationCompletedHandler<TResult>>::value };
    };
    template <typename TResult, typename TProgress> struct guid_storage<Windows::Foundation::AsyncOperationProgressHandler<TResult, TProgress>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::AsyncOperationProgressHandler<TResult, TProgress>>::value };
    };
    template <typename TResult, typename TProgress> struct guid_storage<Windows::Foundation::AsyncOperationWithProgressCompletedHandler<TResult, TProgress>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::AsyncOperationWithProgressCompletedHandler<TResult, TProgress>>::value };
    };
    template <> struct guid_storage<Windows::Foundation::DeferralCompletedHandler>
    {
        static constexpr guid value{ 0xED32A372,0xF3C8,0x4FAA,{ 0x9C,0xFB,0x47,0x01,0x48,0xDA,0x38,0x88 } };
    };
    template <typename T> struct guid_storage<Windows::Foundation::EventHandler<T>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::EventHandler<T>>::value };
    };
    template <typename TSender, typename TResult> struct guid_storage<Windows::Foundation::TypedEventHandler<TSender, TResult>>
    {
        static constexpr guid value{ pinterface_guid<Windows::Foundation::TypedEventHandler<TSender, TResult>>::value };
    };
    template <> struct default_interface<Windows::Foundation::Deferral>
    {
        using type = Windows::Foundation::IDeferral;
    };
    template <> struct default_interface<Windows::Foundation::MemoryBuffer>
    {
        using type = Windows::Foundation::IMemoryBuffer;
    };
    template <> struct default_interface<Windows::Foundation::Uri>
    {
        using type = Windows::Foundation::IUriRuntimeClass;
    };
    template <> struct default_interface<Windows::Foundation::WwwFormUrlDecoder>
    {
        using type = Windows::Foundation::IWwwFormUrlDecoderRuntimeClass;
    };
    template <> struct default_interface<Windows::Foundation::WwwFormUrlDecoderEntry>
    {
        using type = Windows::Foundation::IWwwFormUrlDecoderEntry;
    };
    template <> struct abi<Windows::Foundation::IAsyncAction>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall put_Completed(void*) noexcept = 0;
            virtual int32_t __stdcall get_Completed(void**) noexcept = 0;
            virtual int32_t __stdcall GetResults() noexcept = 0;
        };
    };
    template <typename TProgress> struct abi<Windows::Foundation::IAsyncActionWithProgress<TProgress>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall put_Progress(void*) noexcept = 0;
            virtual int32_t __stdcall get_Progress(void**) noexcept = 0;
            virtual int32_t __stdcall put_Completed(void*) noexcept = 0;
            virtual int32_t __stdcall get_Completed(void**) noexcept = 0;
            virtual int32_t __stdcall GetResults() noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IAsyncInfo>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Id(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_ErrorCode(winrt::hresult*) noexcept = 0;
            virtual int32_t __stdcall Cancel() noexcept = 0;
            virtual int32_t __stdcall Close() noexcept = 0;
        };
    };
    template <typename TResult, typename TProgress> struct abi<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall put_Progress(void*) noexcept = 0;
            virtual int32_t __stdcall get_Progress(void**) noexcept = 0;
            virtual int32_t __stdcall put_Completed(void*) noexcept = 0;
            virtual int32_t __stdcall get_Completed(void**) noexcept = 0;
            virtual int32_t __stdcall GetResults(arg_out<TResult>) noexcept = 0;
        };
    };
    template <typename TResult> struct abi<Windows::Foundation::IAsyncOperation<TResult>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall put_Completed(void*) noexcept = 0;
            virtual int32_t __stdcall get_Completed(void**) noexcept = 0;
            virtual int32_t __stdcall GetResults(arg_out<TResult>) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IClosable>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Close() noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IDeferral>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Complete() noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IDeferralFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IGetActivationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetActivationFactory(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IGuidHelperStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateNewGuid(winrt::guid*) noexcept = 0;
            virtual int32_t __stdcall get_Empty(winrt::guid*) noexcept = 0;
            virtual int32_t __stdcall Equals(winrt::guid const&, winrt::guid const&, bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IMemoryBuffer>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateReference(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IMemoryBufferFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IMemoryBufferReference>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Capacity(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall add_Closed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Closed(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IPropertyValue>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Type(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_IsNumericScalar(bool*) noexcept = 0;
            virtual int32_t __stdcall GetUInt8(uint8_t*) noexcept = 0;
            virtual int32_t __stdcall GetInt16(int16_t*) noexcept = 0;
            virtual int32_t __stdcall GetUInt16(uint16_t*) noexcept = 0;
            virtual int32_t __stdcall GetInt32(int32_t*) noexcept = 0;
            virtual int32_t __stdcall GetUInt32(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall GetInt64(int64_t*) noexcept = 0;
            virtual int32_t __stdcall GetUInt64(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall GetSingle(float*) noexcept = 0;
            virtual int32_t __stdcall GetDouble(double*) noexcept = 0;
            virtual int32_t __stdcall GetChar16(char16_t*) noexcept = 0;
            virtual int32_t __stdcall GetBoolean(bool*) noexcept = 0;
            virtual int32_t __stdcall GetString(void**) noexcept = 0;
            virtual int32_t __stdcall GetGuid(winrt::guid*) noexcept = 0;
            virtual int32_t __stdcall GetDateTime(int64_t*) noexcept = 0;
            virtual int32_t __stdcall GetTimeSpan(int64_t*) noexcept = 0;
            virtual int32_t __stdcall GetPoint(Windows::Foundation::Point*) noexcept = 0;
            virtual int32_t __stdcall GetSize(Windows::Foundation::Size*) noexcept = 0;
            virtual int32_t __stdcall GetRect(Windows::Foundation::Rect*) noexcept = 0;
            virtual int32_t __stdcall GetUInt8Array(uint32_t*, uint8_t**) noexcept = 0;
            virtual int32_t __stdcall GetInt16Array(uint32_t*, int16_t**) noexcept = 0;
            virtual int32_t __stdcall GetUInt16Array(uint32_t*, uint16_t**) noexcept = 0;
            virtual int32_t __stdcall GetInt32Array(uint32_t*, int32_t**) noexcept = 0;
            virtual int32_t __stdcall GetUInt32Array(uint32_t*, uint32_t**) noexcept = 0;
            virtual int32_t __stdcall GetInt64Array(uint32_t*, int64_t**) noexcept = 0;
            virtual int32_t __stdcall GetUInt64Array(uint32_t*, uint64_t**) noexcept = 0;
            virtual int32_t __stdcall GetSingleArray(uint32_t*, float**) noexcept = 0;
            virtual int32_t __stdcall GetDoubleArray(uint32_t*, double**) noexcept = 0;
            virtual int32_t __stdcall GetChar16Array(uint32_t*, char16_t**) noexcept = 0;
            virtual int32_t __stdcall GetBooleanArray(uint32_t*, bool**) noexcept = 0;
            virtual int32_t __stdcall GetStringArray(uint32_t*, void***) noexcept = 0;
            virtual int32_t __stdcall GetInspectableArray(uint32_t*, void***) noexcept = 0;
            virtual int32_t __stdcall GetGuidArray(uint32_t*, winrt::guid**) noexcept = 0;
            virtual int32_t __stdcall GetDateTimeArray(uint32_t*, int64_t**) noexcept = 0;
            virtual int32_t __stdcall GetTimeSpanArray(uint32_t*, int64_t**) noexcept = 0;
            virtual int32_t __stdcall GetPointArray(uint32_t*, Windows::Foundation::Point**) noexcept = 0;
            virtual int32_t __stdcall GetSizeArray(uint32_t*, Windows::Foundation::Size**) noexcept = 0;
            virtual int32_t __stdcall GetRectArray(uint32_t*, Windows::Foundation::Rect**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IPropertyValueStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateEmpty(void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt8(uint8_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInt16(int16_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt16(uint16_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInt32(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt32(uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInt64(int64_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt64(uint64_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateSingle(float, void**) noexcept = 0;
            virtual int32_t __stdcall CreateDouble(double, void**) noexcept = 0;
            virtual int32_t __stdcall CreateChar16(char16_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateBoolean(bool, void**) noexcept = 0;
            virtual int32_t __stdcall CreateString(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInspectable(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateGuid(winrt::guid, void**) noexcept = 0;
            virtual int32_t __stdcall CreateDateTime(int64_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateTimeSpan(int64_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreatePoint(Windows::Foundation::Point, void**) noexcept = 0;
            virtual int32_t __stdcall CreateSize(Windows::Foundation::Size, void**) noexcept = 0;
            virtual int32_t __stdcall CreateRect(Windows::Foundation::Rect, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt8Array(uint32_t, uint8_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInt16Array(uint32_t, int16_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt16Array(uint32_t, uint16_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInt32Array(uint32_t, int32_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt32Array(uint32_t, uint32_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInt64Array(uint32_t, int64_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateUInt64Array(uint32_t, uint64_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateSingleArray(uint32_t, float*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateDoubleArray(uint32_t, double*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateChar16Array(uint32_t, char16_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateBooleanArray(uint32_t, bool*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateStringArray(uint32_t, void**, void**) noexcept = 0;
            virtual int32_t __stdcall CreateInspectableArray(uint32_t, void**, void**) noexcept = 0;
            virtual int32_t __stdcall CreateGuidArray(uint32_t, winrt::guid*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateDateTimeArray(uint32_t, int64_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateTimeSpanArray(uint32_t, int64_t*, void**) noexcept = 0;
            virtual int32_t __stdcall CreatePointArray(uint32_t, Windows::Foundation::Point*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateSizeArray(uint32_t, Windows::Foundation::Size*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateRectArray(uint32_t, Windows::Foundation::Rect*, void**) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::IReferenceArray<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Value(uint32_t* __winrt_impl_resultSize, T**) noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::IReference<T>>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Value(arg_out<T>) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IStringable>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ToString(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IUriEscapeStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall UnescapeComponent(void*, void**) noexcept = 0;
            virtual int32_t __stdcall EscapeComponent(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IUriRuntimeClass>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AbsoluteUri(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayUri(void**) noexcept = 0;
            virtual int32_t __stdcall get_Domain(void**) noexcept = 0;
            virtual int32_t __stdcall get_Extension(void**) noexcept = 0;
            virtual int32_t __stdcall get_Fragment(void**) noexcept = 0;
            virtual int32_t __stdcall get_Host(void**) noexcept = 0;
            virtual int32_t __stdcall get_Password(void**) noexcept = 0;
            virtual int32_t __stdcall get_Path(void**) noexcept = 0;
            virtual int32_t __stdcall get_Query(void**) noexcept = 0;
            virtual int32_t __stdcall get_QueryParsed(void**) noexcept = 0;
            virtual int32_t __stdcall get_RawUri(void**) noexcept = 0;
            virtual int32_t __stdcall get_SchemeName(void**) noexcept = 0;
            virtual int32_t __stdcall get_UserName(void**) noexcept = 0;
            virtual int32_t __stdcall get_Port(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Suspicious(bool*) noexcept = 0;
            virtual int32_t __stdcall Equals(void*, bool*) noexcept = 0;
            virtual int32_t __stdcall CombineUri(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IUriRuntimeClassFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateUri(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateWithRelativeUri(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IUriRuntimeClassWithAbsoluteCanonicalUri>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AbsoluteCanonicalUri(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayIri(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IWwwFormUrlDecoderEntry>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_Value(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IWwwFormUrlDecoderRuntimeClass>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetFirstValueByName(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::IWwwFormUrlDecoderRuntimeClassFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateWwwFormUrlDecoder(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::AsyncActionCompletedHandler>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, int32_t) noexcept = 0;
        };
    };
    template <typename TProgress> struct abi<Windows::Foundation::AsyncActionProgressHandler<TProgress>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, arg_in<TProgress>) noexcept = 0;
        };
    };
    template <typename TProgress> struct abi<Windows::Foundation::AsyncActionWithProgressCompletedHandler<TProgress>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, int32_t) noexcept = 0;
        };
    };
    template <typename TResult> struct abi<Windows::Foundation::AsyncOperationCompletedHandler<TResult>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, int32_t) noexcept = 0;
        };
    };
    template <typename TResult, typename TProgress> struct abi<Windows::Foundation::AsyncOperationProgressHandler<TResult, TProgress>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, arg_in<TProgress>) noexcept = 0;
        };
    };
    template <typename TResult, typename TProgress> struct abi<Windows::Foundation::AsyncOperationWithProgressCompletedHandler<TResult, TProgress>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Foundation::DeferralCompletedHandler>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke() noexcept = 0;
        };
    };
    template <typename T> struct abi<Windows::Foundation::EventHandler<T>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*, arg_in<T>) noexcept = 0;
        };
    };
    template <typename TSender, typename TResult> struct abi<Windows::Foundation::TypedEventHandler<TSender, TResult>>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(arg_in<TSender>, arg_in<TResult>) noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_Foundation_IAsyncAction
    {
        auto Completed(Windows::Foundation::AsyncActionCompletedHandler const& handler) const;
        [[nodiscard]] auto Completed() const;
        auto GetResults() const;
        void get() const
        {
            wait_get(static_cast<Windows::Foundation::IAsyncAction const&>(static_cast<D const&>(*this)));
        }
        auto wait_for(Windows::Foundation::TimeSpan const& timeout) const
        {
            return impl::wait_for(static_cast<Windows::Foundation::IAsyncAction const&>(static_cast<D const&>(*this)), timeout);
        }
    };
    template <> struct consume<Windows::Foundation::IAsyncAction>
    {
        template <typename D> using type = consume_Windows_Foundation_IAsyncAction<D>;
    };
    template <typename D, typename TProgress>
    struct consume_Windows_Foundation_IAsyncActionWithProgress
    {
        auto Progress(Windows::Foundation::AsyncActionProgressHandler<TProgress> const& handler) const;
        [[nodiscard]] auto Progress() const;
        auto Completed(Windows::Foundation::AsyncActionWithProgressCompletedHandler<TProgress> const& handler) const;
        [[nodiscard]] auto Completed() const;
        auto GetResults() const;
        void get() const
        {
            wait_get(static_cast<Windows::Foundation::IAsyncActionWithProgress<TProgress> const&>(static_cast<D const&>(*this)));
        }
        auto wait_for(Windows::Foundation::TimeSpan const& timeout) const
        {
            return impl::wait_for(static_cast<Windows::Foundation::IAsyncActionWithProgress<TProgress> const&>(static_cast<D const&>(*this)), timeout);
        }
    };
    template <typename TProgress> struct consume<Windows::Foundation::IAsyncActionWithProgress<TProgress>>
    {
        template <typename D> using type = consume_Windows_Foundation_IAsyncActionWithProgress<D, TProgress>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IAsyncInfo
    {
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto Status() const;
        [[nodiscard]] auto ErrorCode() const;
        auto Cancel() const;
        auto Close() const;
    };
    template <> struct consume<Windows::Foundation::IAsyncInfo>
    {
        template <typename D> using type = consume_Windows_Foundation_IAsyncInfo<D>;
    };
    template <typename D, typename TResult, typename TProgress>
    struct consume_Windows_Foundation_IAsyncOperationWithProgress
    {
        auto Progress(Windows::Foundation::AsyncOperationProgressHandler<TResult, TProgress> const& handler) const;
        [[nodiscard]] auto Progress() const;
        auto Completed(Windows::Foundation::AsyncOperationWithProgressCompletedHandler<TResult, TProgress> const& handler) const;
        [[nodiscard]] auto Completed() const;
        auto GetResults() const;
        TResult get() const
        {
            return wait_get(static_cast<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress> const&>(static_cast<D const&>(*this)));
        }
        auto wait_for(Windows::Foundation::TimeSpan const& timeout) const
        {
            return impl::wait_for(static_cast<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress> const&>(static_cast<D const&>(*this)), timeout);
        }
    };
    template <typename TResult, typename TProgress> struct consume<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>
    {
        template <typename D> using type = consume_Windows_Foundation_IAsyncOperationWithProgress<D, TResult, TProgress>;
    };
    template <typename D, typename TResult>
    struct consume_Windows_Foundation_IAsyncOperation
    {
        auto Completed(Windows::Foundation::AsyncOperationCompletedHandler<TResult> const& handler) const;
        [[nodiscard]] auto Completed() const;
        auto GetResults() const;
        TResult get() const
        {
            return wait_get(static_cast<Windows::Foundation::IAsyncOperation<TResult> const&>(static_cast<D const&>(*this)));
        }
        auto wait_for(Windows::Foundation::TimeSpan const& timeout) const
        {
            return impl::wait_for(static_cast<Windows::Foundation::IAsyncOperation<TResult> const&>(static_cast<D const&>(*this)), timeout);
        }
    };
    template <typename TResult> struct consume<Windows::Foundation::IAsyncOperation<TResult>>
    {
        template <typename D> using type = consume_Windows_Foundation_IAsyncOperation<D, TResult>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IClosable
    {
        auto Close() const;
    };
    template <> struct consume<Windows::Foundation::IClosable>
    {
        template <typename D> using type = consume_Windows_Foundation_IClosable<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IDeferral
    {
        auto Complete() const;
    };
    template <> struct consume<Windows::Foundation::IDeferral>
    {
        template <typename D> using type = consume_Windows_Foundation_IDeferral<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IDeferralFactory
    {
        auto Create(Windows::Foundation::DeferralCompletedHandler const& handler) const;
    };
    template <> struct consume<Windows::Foundation::IDeferralFactory>
    {
        template <typename D> using type = consume_Windows_Foundation_IDeferralFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IGetActivationFactory
    {
        auto GetActivationFactory(param::hstring const& activatableClassId) const;
    };
    template <> struct consume<Windows::Foundation::IGetActivationFactory>
    {
        template <typename D> using type = consume_Windows_Foundation_IGetActivationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IGuidHelperStatics
    {
        auto CreateNewGuid() const;
        [[nodiscard]] auto Empty() const;
        auto Equals(winrt::guid const& target, winrt::guid const& value) const;
    };
    template <> struct consume<Windows::Foundation::IGuidHelperStatics>
    {
        template <typename D> using type = consume_Windows_Foundation_IGuidHelperStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IMemoryBuffer
    {
        auto CreateReference() const;
    };
    template <> struct consume<Windows::Foundation::IMemoryBuffer>
    {
        template <typename D> using type = consume_Windows_Foundation_IMemoryBuffer<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IMemoryBufferFactory
    {
        auto Create(uint32_t capacity) const;
    };
    template <> struct consume<Windows::Foundation::IMemoryBufferFactory>
    {
        template <typename D> using type = consume_Windows_Foundation_IMemoryBufferFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IMemoryBufferReference
    {
        [[nodiscard]] auto Capacity() const;
        auto Closed(Windows::Foundation::TypedEventHandler<Windows::Foundation::IMemoryBufferReference, Windows::Foundation::IInspectable> const& handler) const;
        using Closed_revoker = impl::event_revoker<Windows::Foundation::IMemoryBufferReference, &impl::abi_t<Windows::Foundation::IMemoryBufferReference>::remove_Closed>;
        Closed_revoker Closed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::Foundation::IMemoryBufferReference, Windows::Foundation::IInspectable> const& handler) const;
        auto Closed(winrt::event_token const& cookie) const noexcept;
    };
    template <> struct consume<Windows::Foundation::IMemoryBufferReference>
    {
        template <typename D> using type = consume_Windows_Foundation_IMemoryBufferReference<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IPropertyValue
    {
        [[nodiscard]] auto Type() const;
        [[nodiscard]] auto IsNumericScalar() const;
        auto GetUInt8() const;
        auto GetInt16() const;
        auto GetUInt16() const;
        auto GetInt32() const;
        auto GetUInt32() const;
        auto GetInt64() const;
        auto GetUInt64() const;
        auto GetSingle() const;
        auto GetDouble() const;
        auto GetChar16() const;
        auto GetBoolean() const;
        auto GetString() const;
        auto GetGuid() const;
        auto GetDateTime() const;
        auto GetTimeSpan() const;
        auto GetPoint() const;
        auto GetSize() const;
        auto GetRect() const;
        auto GetUInt8Array(com_array<uint8_t>& value) const;
        auto GetInt16Array(com_array<int16_t>& value) const;
        auto GetUInt16Array(com_array<uint16_t>& value) const;
        auto GetInt32Array(com_array<int32_t>& value) const;
        auto GetUInt32Array(com_array<uint32_t>& value) const;
        auto GetInt64Array(com_array<int64_t>& value) const;
        auto GetUInt64Array(com_array<uint64_t>& value) const;
        auto GetSingleArray(com_array<float>& value) const;
        auto GetDoubleArray(com_array<double>& value) const;
        auto GetChar16Array(com_array<char16_t>& value) const;
        auto GetBooleanArray(com_array<bool>& value) const;
        auto GetStringArray(com_array<hstring>& value) const;
        auto GetInspectableArray(com_array<Windows::Foundation::IInspectable>& value) const;
        auto GetGuidArray(com_array<winrt::guid>& value) const;
        auto GetDateTimeArray(com_array<Windows::Foundation::DateTime>& value) const;
        auto GetTimeSpanArray(com_array<Windows::Foundation::TimeSpan>& value) const;
        auto GetPointArray(com_array<Windows::Foundation::Point>& value) const;
        auto GetSizeArray(com_array<Windows::Foundation::Size>& value) const;
        auto GetRectArray(com_array<Windows::Foundation::Rect>& value) const;
    };
    template <> struct consume<Windows::Foundation::IPropertyValue>
    {
        template <typename D> using type = consume_Windows_Foundation_IPropertyValue<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IPropertyValueStatics
    {
        auto CreateEmpty() const;
        auto CreateUInt8(uint8_t value) const;
        auto CreateInt16(int16_t value) const;
        auto CreateUInt16(uint16_t value) const;
        auto CreateInt32(int32_t value) const;
        auto CreateUInt32(uint32_t value) const;
        auto CreateInt64(int64_t value) const;
        auto CreateUInt64(uint64_t value) const;
        auto CreateSingle(float value) const;
        auto CreateDouble(double value) const;
        auto CreateChar16(char16_t value) const;
        auto CreateBoolean(bool value) const;
        auto CreateString(param::hstring const& value) const;
        auto CreateInspectable(Windows::Foundation::IInspectable const& value) const;
        auto CreateGuid(winrt::guid const& value) const;
        auto CreateDateTime(Windows::Foundation::DateTime const& value) const;
        auto CreateTimeSpan(Windows::Foundation::TimeSpan const& value) const;
        auto CreatePoint(Windows::Foundation::Point const& value) const;
        auto CreateSize(Windows::Foundation::Size const& value) const;
        auto CreateRect(Windows::Foundation::Rect const& value) const;
        auto CreateUInt8Array(array_view<uint8_t const> value) const;
        auto CreateInt16Array(array_view<int16_t const> value) const;
        auto CreateUInt16Array(array_view<uint16_t const> value) const;
        auto CreateInt32Array(array_view<int32_t const> value) const;
        auto CreateUInt32Array(array_view<uint32_t const> value) const;
        auto CreateInt64Array(array_view<int64_t const> value) const;
        auto CreateUInt64Array(array_view<uint64_t const> value) const;
        auto CreateSingleArray(array_view<float const> value) const;
        auto CreateDoubleArray(array_view<double const> value) const;
        auto CreateChar16Array(array_view<char16_t const> value) const;
        auto CreateBooleanArray(array_view<bool const> value) const;
        auto CreateStringArray(array_view<hstring const> value) const;
        auto CreateInspectableArray(array_view<Windows::Foundation::IInspectable const> value) const;
        auto CreateGuidArray(array_view<winrt::guid const> value) const;
        auto CreateDateTimeArray(array_view<Windows::Foundation::DateTime const> value) const;
        auto CreateTimeSpanArray(array_view<Windows::Foundation::TimeSpan const> value) const;
        auto CreatePointArray(array_view<Windows::Foundation::Point const> value) const;
        auto CreateSizeArray(array_view<Windows::Foundation::Size const> value) const;
        auto CreateRectArray(array_view<Windows::Foundation::Rect const> value) const;
    };
    template <> struct consume<Windows::Foundation::IPropertyValueStatics>
    {
        template <typename D> using type = consume_Windows_Foundation_IPropertyValueStatics<D>;
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_IReferenceArray
    {
        [[nodiscard]] auto Value() const;
    };
    template <typename T> struct consume<Windows::Foundation::IReferenceArray<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_IReferenceArray<D, T>;
    };
    template <typename D, typename T>
    struct consume_Windows_Foundation_IReference
    {
        [[nodiscard]] auto Value() const;
    };
    template <typename T> struct consume<Windows::Foundation::IReference<T>>
    {
        template <typename D> using type = consume_Windows_Foundation_IReference<D, T>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IStringable
    {
        auto ToString() const;
    };
    template <> struct consume<Windows::Foundation::IStringable>
    {
        template <typename D> using type = consume_Windows_Foundation_IStringable<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IUriEscapeStatics
    {
        auto UnescapeComponent(param::hstring const& toUnescape) const;
        auto EscapeComponent(param::hstring const& toEscape) const;
    };
    template <> struct consume<Windows::Foundation::IUriEscapeStatics>
    {
        template <typename D> using type = consume_Windows_Foundation_IUriEscapeStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IUriRuntimeClass
    {
        [[nodiscard]] auto AbsoluteUri() const;
        [[nodiscard]] auto DisplayUri() const;
        [[nodiscard]] auto Domain() const;
        [[nodiscard]] auto Extension() const;
        [[nodiscard]] auto Fragment() const;
        [[nodiscard]] auto Host() const;
        [[nodiscard]] auto Password() const;
        [[nodiscard]] auto Path() const;
        [[nodiscard]] auto Query() const;
        [[nodiscard]] auto QueryParsed() const;
        [[nodiscard]] auto RawUri() const;
        [[nodiscard]] auto SchemeName() const;
        [[nodiscard]] auto UserName() const;
        [[nodiscard]] auto Port() const;
        [[nodiscard]] auto Suspicious() const;
        auto Equals(Windows::Foundation::Uri const& pUri) const;
        auto CombineUri(param::hstring const& relativeUri) const;
    };
    template <> struct consume<Windows::Foundation::IUriRuntimeClass>
    {
        template <typename D> using type = consume_Windows_Foundation_IUriRuntimeClass<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IUriRuntimeClassFactory
    {
        auto CreateUri(param::hstring const& uri) const;
        auto CreateWithRelativeUri(param::hstring const& baseUri, param::hstring const& relativeUri) const;
    };
    template <> struct consume<Windows::Foundation::IUriRuntimeClassFactory>
    {
        template <typename D> using type = consume_Windows_Foundation_IUriRuntimeClassFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IUriRuntimeClassWithAbsoluteCanonicalUri
    {
        [[nodiscard]] auto AbsoluteCanonicalUri() const;
        [[nodiscard]] auto DisplayIri() const;
    };
    template <> struct consume<Windows::Foundation::IUriRuntimeClassWithAbsoluteCanonicalUri>
    {
        template <typename D> using type = consume_Windows_Foundation_IUriRuntimeClassWithAbsoluteCanonicalUri<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IWwwFormUrlDecoderEntry
    {
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto Value() const;
    };
    template <> struct consume<Windows::Foundation::IWwwFormUrlDecoderEntry>
    {
        template <typename D> using type = consume_Windows_Foundation_IWwwFormUrlDecoderEntry<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IWwwFormUrlDecoderRuntimeClass
    {
        auto GetFirstValueByName(param::hstring const& name) const;
    };
    template <> struct consume<Windows::Foundation::IWwwFormUrlDecoderRuntimeClass>
    {
        template <typename D> using type = consume_Windows_Foundation_IWwwFormUrlDecoderRuntimeClass<D>;
    };
    template <typename D>
    struct consume_Windows_Foundation_IWwwFormUrlDecoderRuntimeClassFactory
    {
        auto CreateWwwFormUrlDecoder(param::hstring const& query) const;
    };
    template <> struct consume<Windows::Foundation::IWwwFormUrlDecoderRuntimeClassFactory>
    {
        template <typename D> using type = consume_Windows_Foundation_IWwwFormUrlDecoderRuntimeClassFactory<D>;
    };
}
#endif
