// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Foundation_1_H
#define WINRT_Windows_Foundation_1_H
#include "Windows.Foundation.Collections.0.h"
#include "Windows.Foundation.0.h"
namespace winrt::Windows::Foundation
{
    struct __declspec(empty_bases) IAsyncAction :
        Windows::Foundation::IInspectable,
        impl::consume_t<IAsyncAction>,
        impl::require<Windows::Foundation::IAsyncAction, Windows::Foundation::IAsyncInfo>
    {
        IAsyncAction(std::nullptr_t = nullptr) noexcept {}
        IAsyncAction(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename TProgress>
    struct __declspec(empty_bases) IAsyncActionWithProgress :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::IAsyncActionWithProgress<TProgress>>,
        impl::require<Windows::Foundation::IAsyncActionWithProgress<TProgress>, Windows::Foundation::IAsyncInfo>
    {
        static_assert(impl::has_category_v<TProgress>, "TProgress must be WinRT type.");
        IAsyncActionWithProgress(std::nullptr_t = nullptr) noexcept {}
        IAsyncActionWithProgress(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IAsyncInfo :
        Windows::Foundation::IInspectable,
        impl::consume_t<IAsyncInfo>
    {
        IAsyncInfo(std::nullptr_t = nullptr) noexcept {}
        IAsyncInfo(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename TResult, typename TProgress>
    struct __declspec(empty_bases) IAsyncOperationWithProgress :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>>,
        impl::require<Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress>, Windows::Foundation::IAsyncInfo>
    {
        static_assert(impl::has_category_v<TResult>, "TResult must be WinRT type.");
        static_assert(impl::has_category_v<TProgress>, "TProgress must be WinRT type.");
        IAsyncOperationWithProgress(std::nullptr_t = nullptr) noexcept {}
        IAsyncOperationWithProgress(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename TResult>
    struct __declspec(empty_bases) IAsyncOperation :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::IAsyncOperation<TResult>>,
        impl::require<Windows::Foundation::IAsyncOperation<TResult>, Windows::Foundation::IAsyncInfo>
    {
        static_assert(impl::has_category_v<TResult>, "TResult must be WinRT type.");
        IAsyncOperation(std::nullptr_t = nullptr) noexcept {}
        IAsyncOperation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IClosable :
        Windows::Foundation::IInspectable,
        impl::consume_t<IClosable>
    {
        IClosable(std::nullptr_t = nullptr) noexcept {}
        IClosable(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDeferral :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDeferral>,
        impl::require<Windows::Foundation::IDeferral, Windows::Foundation::IClosable>
    {
        IDeferral(std::nullptr_t = nullptr) noexcept {}
        IDeferral(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDeferralFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDeferralFactory>
    {
        IDeferralFactory(std::nullptr_t = nullptr) noexcept {}
        IDeferralFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IGetActivationFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IGetActivationFactory>
    {
        IGetActivationFactory(std::nullptr_t = nullptr) noexcept {}
        IGetActivationFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IGuidHelperStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IGuidHelperStatics>
    {
        IGuidHelperStatics(std::nullptr_t = nullptr) noexcept {}
        IGuidHelperStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IMemoryBuffer :
        Windows::Foundation::IInspectable,
        impl::consume_t<IMemoryBuffer>,
        impl::require<Windows::Foundation::IMemoryBuffer, Windows::Foundation::IClosable>
    {
        IMemoryBuffer(std::nullptr_t = nullptr) noexcept {}
        IMemoryBuffer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IMemoryBufferFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IMemoryBufferFactory>
    {
        IMemoryBufferFactory(std::nullptr_t = nullptr) noexcept {}
        IMemoryBufferFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IMemoryBufferReference :
        Windows::Foundation::IInspectable,
        impl::consume_t<IMemoryBufferReference>,
        impl::require<Windows::Foundation::IMemoryBufferReference, Windows::Foundation::IClosable>
    {
        IMemoryBufferReference(std::nullptr_t = nullptr) noexcept {}
        IMemoryBufferReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IPropertyValue :
        Windows::Foundation::IInspectable,
        impl::consume_t<IPropertyValue>
    {
        IPropertyValue(std::nullptr_t = nullptr) noexcept {}
        IPropertyValue(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IPropertyValueStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IPropertyValueStatics>
    {
        IPropertyValueStatics(std::nullptr_t = nullptr) noexcept {}
        IPropertyValueStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename T>
    struct __declspec(empty_bases) IReferenceArray :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::IReferenceArray<T>>,
        impl::require<Windows::Foundation::IReferenceArray<T>, Windows::Foundation::IPropertyValue>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IReferenceArray(std::nullptr_t = nullptr) noexcept {}
        IReferenceArray(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    template <typename T>
    struct __declspec(empty_bases) IReference :
        Windows::Foundation::IInspectable,
        impl::consume_t<Windows::Foundation::IReference<T>>,
        impl::require<Windows::Foundation::IReference<T>, Windows::Foundation::IPropertyValue>
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        IReference(std::nullptr_t = nullptr) noexcept {}
        IReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
        IReference(T const& value) : IReference<T>(impl::reference_traits<T>::make(value))
        {
        }

    private:

        IReference<T>(IInspectable const& value) : IReference<T>(value.as<IReference<T>>())
        {
        }
    };
    struct __declspec(empty_bases) IStringable :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStringable>
    {
        IStringable(std::nullptr_t = nullptr) noexcept {}
        IStringable(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUriEscapeStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUriEscapeStatics>
    {
        IUriEscapeStatics(std::nullptr_t = nullptr) noexcept {}
        IUriEscapeStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUriRuntimeClass :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUriRuntimeClass>
    {
        IUriRuntimeClass(std::nullptr_t = nullptr) noexcept {}
        IUriRuntimeClass(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUriRuntimeClassFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUriRuntimeClassFactory>
    {
        IUriRuntimeClassFactory(std::nullptr_t = nullptr) noexcept {}
        IUriRuntimeClassFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUriRuntimeClassWithAbsoluteCanonicalUri :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUriRuntimeClassWithAbsoluteCanonicalUri>
    {
        IUriRuntimeClassWithAbsoluteCanonicalUri(std::nullptr_t = nullptr) noexcept {}
        IUriRuntimeClassWithAbsoluteCanonicalUri(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IWwwFormUrlDecoderEntry :
        Windows::Foundation::IInspectable,
        impl::consume_t<IWwwFormUrlDecoderEntry>
    {
        IWwwFormUrlDecoderEntry(std::nullptr_t = nullptr) noexcept {}
        IWwwFormUrlDecoderEntry(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IWwwFormUrlDecoderRuntimeClass :
        Windows::Foundation::IInspectable,
        impl::consume_t<IWwwFormUrlDecoderRuntimeClass>,
        impl::require<Windows::Foundation::IWwwFormUrlDecoderRuntimeClass, Windows::Foundation::Collections::IIterable<Windows::Foundation::IWwwFormUrlDecoderEntry>, Windows::Foundation::Collections::IVectorView<Windows::Foundation::IWwwFormUrlDecoderEntry>>
    {
        IWwwFormUrlDecoderRuntimeClass(std::nullptr_t = nullptr) noexcept {}
        IWwwFormUrlDecoderRuntimeClass(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IWwwFormUrlDecoderRuntimeClassFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IWwwFormUrlDecoderRuntimeClassFactory>
    {
        IWwwFormUrlDecoderRuntimeClassFactory(std::nullptr_t = nullptr) noexcept {}
        IWwwFormUrlDecoderRuntimeClassFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
