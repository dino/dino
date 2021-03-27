// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_Streams_1_H
#define WINRT_Windows_Storage_Streams_1_H
#include "Windows.Foundation.0.h"
#include "Windows.Storage.Streams.0.h"
namespace winrt::Windows::Storage::Streams
{
    struct __declspec(empty_bases) IBuffer :
        Windows::Foundation::IInspectable,
        impl::consume_t<IBuffer>
    {
        IBuffer(std::nullptr_t = nullptr) noexcept {}
        IBuffer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IBufferFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IBufferFactory>
    {
        IBufferFactory(std::nullptr_t = nullptr) noexcept {}
        IBufferFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IBufferStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IBufferStatics>
    {
        IBufferStatics(std::nullptr_t = nullptr) noexcept {}
        IBufferStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IContentTypeProvider :
        Windows::Foundation::IInspectable,
        impl::consume_t<IContentTypeProvider>
    {
        IContentTypeProvider(std::nullptr_t = nullptr) noexcept {}
        IContentTypeProvider(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDataReader :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDataReader>
    {
        IDataReader(std::nullptr_t = nullptr) noexcept {}
        IDataReader(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDataReaderFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDataReaderFactory>
    {
        IDataReaderFactory(std::nullptr_t = nullptr) noexcept {}
        IDataReaderFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDataReaderStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDataReaderStatics>
    {
        IDataReaderStatics(std::nullptr_t = nullptr) noexcept {}
        IDataReaderStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDataWriter :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDataWriter>
    {
        IDataWriter(std::nullptr_t = nullptr) noexcept {}
        IDataWriter(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDataWriterFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDataWriterFactory>
    {
        IDataWriterFactory(std::nullptr_t = nullptr) noexcept {}
        IDataWriterFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IFileRandomAccessStreamStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IFileRandomAccessStreamStatics>
    {
        IFileRandomAccessStreamStatics(std::nullptr_t = nullptr) noexcept {}
        IFileRandomAccessStreamStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IInputStream :
        Windows::Foundation::IInspectable,
        impl::consume_t<IInputStream>,
        impl::require<Windows::Storage::Streams::IInputStream, Windows::Foundation::IClosable>
    {
        IInputStream(std::nullptr_t = nullptr) noexcept {}
        IInputStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IInputStreamReference :
        Windows::Foundation::IInspectable,
        impl::consume_t<IInputStreamReference>
    {
        IInputStreamReference(std::nullptr_t = nullptr) noexcept {}
        IInputStreamReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IOutputStream :
        Windows::Foundation::IInspectable,
        impl::consume_t<IOutputStream>,
        impl::require<Windows::Storage::Streams::IOutputStream, Windows::Foundation::IClosable>
    {
        IOutputStream(std::nullptr_t = nullptr) noexcept {}
        IOutputStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IRandomAccessStream :
        Windows::Foundation::IInspectable,
        impl::consume_t<IRandomAccessStream>,
        impl::require<Windows::Storage::Streams::IRandomAccessStream, Windows::Foundation::IClosable, Windows::Storage::Streams::IInputStream, Windows::Storage::Streams::IOutputStream>
    {
        IRandomAccessStream(std::nullptr_t = nullptr) noexcept {}
        IRandomAccessStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IRandomAccessStreamReference :
        Windows::Foundation::IInspectable,
        impl::consume_t<IRandomAccessStreamReference>
    {
        IRandomAccessStreamReference(std::nullptr_t = nullptr) noexcept {}
        IRandomAccessStreamReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IRandomAccessStreamReferenceStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IRandomAccessStreamReferenceStatics>
    {
        IRandomAccessStreamReferenceStatics(std::nullptr_t = nullptr) noexcept {}
        IRandomAccessStreamReferenceStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IRandomAccessStreamStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IRandomAccessStreamStatics>
    {
        IRandomAccessStreamStatics(std::nullptr_t = nullptr) noexcept {}
        IRandomAccessStreamStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IRandomAccessStreamWithContentType :
        Windows::Foundation::IInspectable,
        impl::consume_t<IRandomAccessStreamWithContentType>,
        impl::require<Windows::Storage::Streams::IRandomAccessStreamWithContentType, Windows::Foundation::IClosable, Windows::Storage::Streams::IInputStream, Windows::Storage::Streams::IOutputStream, Windows::Storage::Streams::IRandomAccessStream, Windows::Storage::Streams::IContentTypeProvider>
    {
        IRandomAccessStreamWithContentType(std::nullptr_t = nullptr) noexcept {}
        IRandomAccessStreamWithContentType(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
